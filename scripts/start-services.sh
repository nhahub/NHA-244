#!/bin/bash
# Start all services for presentation

echo "▶️  Starting Todo App services..."

ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128 << 'REMOTE'
  # Check disk space and cleanup if needed
  DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
  
  if [ "$DISK_USAGE" -gt 85 ]; then
    echo "⚠️  Disk usage at ${DISK_USAGE}%, cleaning up..."
    
    # Clean Docker
    docker system prune -f > /dev/null 2>&1
    
    # Clean minikube cache
    rm -rf ~/.minikube/cache/preloaded-tarball/* > /dev/null 2>&1
    
    # Trim logs
    echo "alitarek" | sudo -S journalctl --vacuum-size=10M > /dev/null 2>&1
    
    NEW_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "   Disk usage reduced to ${NEW_USAGE}%"
  fi
  
  echo "   Starting minikube..."
  minikube start --driver=docker --cpus=2 --memory=2048
  
  echo "   Waiting for pods to be ready..."
  kubectl wait --for=condition=ready pod -l app=todo-app -n todo-app --timeout=120s 2>/dev/null || {
    echo "   Pods not ready yet, checking status..."
    kubectl get pods -n todo-app
  }
  
  echo "   Setting up iptables rules..."
  bash ~/scripts/setup-iptables.sh
  
  echo ""
  echo "✅ All services started"
  echo "🌐 Application accessible at: http://192.168.74.128:30080"
  
  echo ""
  echo "📊 Current status:"
  kubectl get pods -n todo-app
REMOTE

echo ""
echo "Testing application..."
sleep 5
curl -s http://192.168.74.128:30080 | grep -q "<h4" && echo "✅ Application is responding" || echo "⚠️  Application not responding yet, wait a moment"
