#!/bin/bash
# Start all services for presentation

echo "▶️  Starting Todo App services..."

ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128 << 'REMOTE'
  set -e  # Exit on error within remote session
  
  # Check disk space and cleanup if needed
  DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
  
  if [ "$DISK_USAGE" -gt 85 ]; then
    echo "⚠️  Disk usage at ${DISK_USAGE}%, cleaning up..."
    
    # Clean Docker
    docker system prune -f > /dev/null 2>&1 || true
    
    # Clean minikube cache
    rm -rf ~/.minikube/cache/preloaded-tarball/* > /dev/null 2>&1 || true
    
    # Trim logs
    echo "alitarek" | sudo -S journalctl --vacuum-size=10M > /dev/null 2>&1 || true
    
    NEW_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "   Disk usage reduced to ${NEW_USAGE}%"
  fi
  
  echo "   Checking minikube status..."
  
  # Check if minikube is already running
  if minikube status | grep -q "Running"; then
    echo "   ✅ Minikube already running"
  else
    echo "   Starting minikube..."
    
    # Try to start minikube (resume existing cluster)
    if minikube start --driver=docker --cpus=2 --memory=2048; then
      echo "   ✅ Minikube started successfully"
    else
      echo "⚠️  Minikube failed to start, checking if cluster is corrupted..."
      
      # If start failed, try to get status
      if minikube status 2>&1 | grep -q "does not exist"; then
        echo "   No existing cluster found, creating new one..."
      else
        echo "   Existing cluster appears corrupted, deleting..."
        minikube delete || true
      fi
      
      echo "   Creating fresh minikube cluster..."
      minikube start --driver=docker --cpus=2 --memory=2048
    fi
  fi
  
  # Verify API server is responding
  echo "   Verifying Kubernetes API server..."
  MAX_RETRIES=15
  RETRY=0
  while [ $RETRY -lt $MAX_RETRIES ]; do
    if kubectl cluster-info > /dev/null 2>&1; then
      echo "   ✅ API server is responding"
      break
    fi
    echo "   Waiting for API server... ($((RETRY+1))/$MAX_RETRIES)"
    sleep 3
    RETRY=$((RETRY+1))
  done
  
  if [ $RETRY -eq $MAX_RETRIES ]; then
    echo "❌ API server not responding after $MAX_RETRIES attempts"
    echo "   This likely indicates a deeper issue. Attempting full cluster recreation..."
    minikube delete
    minikube start --driver=docker --cpus=2 --memory=2048
    
    # Wait again after recreation
    sleep 10
    if ! kubectl cluster-info > /dev/null 2>&1; then
      echo "❌ FATAL: API server still not responding after recreation"
      echo "   Manual intervention required. Check 'minikube logs' for details."
      exit 1
    fi
  fi
  
  # Check if namespace and pods exist
  echo "   Checking application deployment..."
  
  NEEDS_DEPLOYMENT=false
  
  if ! kubectl get namespace todo-app > /dev/null 2>&1; then
    echo "   ⚠️  Namespace not found, will deploy application"
    NEEDS_DEPLOYMENT=true
  elif ! kubectl get deployment todo-app -n todo-app > /dev/null 2>&1; then
    echo "   ⚠️  Application deployment not found, will deploy"
    NEEDS_DEPLOYMENT=true
  else
    echo "   ✅ Application deployment exists"
  fi
  
  if [ "$NEEDS_DEPLOYMENT" = true ]; then
    echo ""
    echo "📦 Deploying application to Kubernetes..."
    
    # Create manifests directory on remote if not exists
    mkdir -p ~/k8s-manifests
    
    echo "   Applying namespace..."
    kubectl apply -f ~/k8s-manifests/namespace.yaml
    
    echo "   Applying secrets and configmaps..."
    kubectl apply -f ~/k8s-manifests/secret.yaml
    kubectl apply -f ~/k8s-manifests/configmap.yaml
    
    echo "   Deploying MongoDB..."
    kubectl apply -f ~/k8s-manifests/mongodb-deployment.yaml
    
    echo "   Waiting for MongoDB to be ready..."
    kubectl wait --for=condition=ready pod -l app=mongodb -n todo-app --timeout=120s || {
      echo "   ⚠️  MongoDB taking longer than expected..."
      kubectl get pods -n todo-app -l app=mongodb
    }
    
    echo "   Deploying Todo application..."
    kubectl apply -f ~/k8s-manifests/deployment.yaml
    kubectl apply -f ~/k8s-manifests/service.yaml
    
    echo "   ✅ Deployment complete"
  fi
  
  # Wait for pods to be ready
  echo "   Waiting for application pods to be ready..."
  if kubectl wait --for=condition=ready pod -l app=todo-app -n todo-app --timeout=120s 2>/dev/null; then
    echo "   ✅ Application pods are ready"
  else
    echo "   ⚠️  Pods not ready yet, checking status..."
    kubectl get pods -n todo-app 2>/dev/null || echo "   No pods found"
  fi
  
  echo "   Setting up iptables rules..."
  if bash ~/scripts/setup-iptables.sh; then
    echo "   ✅ iptables configured"
  else
    echo "   ⚠️  iptables setup failed (may need manual configuration)"
  fi
  
  echo ""
  echo "✅ All services started"
  echo "🌐 Application accessible at: http://192.168.74.128:30080"
  
  echo ""
  echo "📊 Current status:"
  kubectl get pods -n todo-app 2>/dev/null || echo "   No pods found - application may need deployment"
REMOTE

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Script failed. Check the errors above."
  exit 1
fi

echo ""
echo "Testing application..."
sleep 5
if curl -s http://192.168.74.128:30080 | grep -q "<h4"; then
  echo "✅ Application is responding"
else
  echo "⚠️  Application not responding yet"
  echo "   This could mean:"
  echo "   - Pods are still starting (wait a minute and try again)"
  echo "   - Application needs to be deployed"
  echo "   - iptables rules need adjustment"
fi
