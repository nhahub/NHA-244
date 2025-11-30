#!/bin/bash
# Start all services for presentation

echo "▶️  Starting Todo App services..."

ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128 << 'REMOTE'
  echo "   Starting minikube..."
  minikube start
  
  echo "   Waiting for pods to be ready..."
  kubectl wait --for=condition=ready pod -l app=todo-app -n todo-app --timeout=120s
  
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
curl -s http://192.168.74.128:30080 | grep -q "<h4" && echo "✅ Application is responding" || echo "⚠️  Application not responding yet, wait a moment"
