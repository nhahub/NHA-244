#!/bin/bash
# Stop all services to save resources

echo "🛑 Stopping Todo App services..."

ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128 << 'REMOTE'
  echo "   Stopping minikube..."
  minikube stop
  
  echo "   Verifying shutdown..."
  docker ps
  
  echo "✅ All services stopped"
  echo "💾 Resources freed, cluster state preserved"
REMOTE

echo ""
echo "To start again, run: ./scripts/start-services.sh"
