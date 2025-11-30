# 🎮 Start/Stop Guide - Resource Management

This guide helps you manage resources efficiently by starting services only when needed for presentations or demos.

---

## 📊 Resource Impact

### When Running (Full Stack)
- **CPU Usage:** ~30-40% (minikube + containers)
- **Memory Usage:** ~3-4GB (minikube 2GB + Docker overhead)
- **Disk I/O:** Moderate (database writes, logs)

### When Stopped
- **CPU Usage:** ~0% (no containers running)
- **Memory Usage:** ~200MB (Docker daemon only)
- **Disk I/O:** Minimal

---

## 🛑 Stop Everything (Save Resources)

### Quick Stop (Recommended)
```bash
# SSH into VM
ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128

# Stop minikube (preserves cluster state)
minikube stop

# Verify everything stopped
docker ps
```

**Result:** 
- ✅ All Kubernetes pods stopped
- ✅ Minikube container stopped
- ✅ Resources freed
- ✅ Cluster state preserved (fast restart)

**Time to stop:** ~10 seconds

---

### Full Stop (Maximum Resource Savings)
```bash
# SSH into VM
ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128

# Delete minikube cluster
minikube delete

# Stop Docker daemon (optional, saves ~200MB RAM)
sudo systemctl stop docker

# Verify everything stopped
docker ps 2>/dev/null || echo "Docker stopped"
```

**Result:**
- ✅ All containers removed
- ✅ Cluster deleted
- ✅ Maximum resources freed
- ⚠️ Requires full redeployment on restart

**Time to stop:** ~20 seconds

---

## ▶️ Start Everything (For Presentation)

### Quick Start (After `minikube stop`)
```bash
# SSH into VM
ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128

# Start minikube
minikube start

# Wait for pods to be ready (automatic)
kubectl wait --for=condition=ready pod -l app=todo-app -n todo-app --timeout=120s

# Setup iptables rules for external access
bash ~/scripts/setup-iptables.sh

# Verify application is accessible
curl -s http://192.168.74.128:30080 | grep "<h4"
```

**Time to start:** ~30-45 seconds  
**Why fast?** Cluster state preserved, no redeployment needed

---

### Full Start (After `minikube delete`)
```bash
# SSH into VM
ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128

# Start Docker if stopped
sudo systemctl start docker

# Start minikube with resource limits
minikube start --driver=docker --cpus=2 --memory=2048

# Apply all Kubernetes manifests
cd ~/k8s-manifests
kubectl apply -f namespace.yaml
kubectl apply -f secret.yaml
kubectl apply -f configmap.yaml
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n todo-app --timeout=180s

# Setup iptables rules
bash ~/scripts/setup-iptables.sh

# Verify application
curl -s http://192.168.74.128:30080 | grep "<h4"
```

**Time to start:** ~3-5 minutes  
**Why slower?** Full cluster creation + image pulls + pod initialization

---

## 🚀 Automated Scripts

### Create Stop Script
```bash
# On local machine
cat > ~/Desktop/capstone-project/scripts/stop-services.sh << 'EOF'
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
EOF

chmod +x ~/Desktop/capstone-project/scripts/stop-services.sh
```

### Create Start Script
```bash
# On local machine
cat > ~/Desktop/capstone-project/scripts/start-services.sh << 'EOF'
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
EOF

chmod +x ~/Desktop/capstone-project/scripts/start-services.sh
```

---

## 📅 Typical Usage Workflow

### Daily Work (Not Presenting)
```bash
# Stop services when done
./scripts/stop-services.sh
```

### Before Presentation
```bash
# Start services 5 minutes before
./scripts/start-services.sh

# Verify everything is working
curl http://192.168.74.128:30080
```

### After Presentation
```bash
# Stop services to free resources
./scripts/stop-services.sh
```

---

## 🔍 Check Current Status

### Quick Status Check
```bash
# From local machine
ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128 'minikube status'
```

**Output if running:**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

**Output if stopped:**
```
🤷  Profile "minikube" not found. Run "minikube profile list" to view all profiles.
```

### Detailed Status Check
```bash
ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128 << 'EOF'
  echo "=== Minikube Status ==="
  minikube status
  
  echo -e "\n=== Pods Status ==="
  kubectl get pods -n todo-app 2>/dev/null || echo "Cluster not running"
  
  echo -e "\n=== Docker Containers ==="
  docker ps --format "table {{.Names}}\t{{.Status}}"
  
  echo -e "\n=== Resource Usage ==="
  free -h | grep Mem
  df -h / | grep -v Filesystem
EOF
```

---

## ⚡ Performance Comparison

| State | CPU Usage | Memory Usage | Startup Time | Use Case |
|-------|-----------|--------------|--------------|----------|
| **Stopped** | ~0% | ~200MB | - | Daily work, not presenting |
| **Running** | ~30-40% | ~3-4GB | - | Presentation, demo, testing |
| **Quick Start** | - | - | 30-45s | After `minikube stop` |
| **Full Start** | - | - | 3-5min | After `minikube delete` |

---

## 🎯 Recommendations

### For Daily Development
- **Stop services** when not actively working on the project
- Use **Quick Stop** (`minikube stop`) for fast restarts
- Keep Docker daemon running (minimal overhead)

### Before Presentation
- **Start services 5 minutes early** to ensure everything is ready
- Run **status check** to verify all pods are running
- Test **application access** from browser

### For Long-Term Storage
- Use **Full Stop** if not using for weeks
- Consider **backing up** minikube cluster state:
  ```bash
  kubectl get all -n todo-app -o yaml > backup.yaml
  ```

---

## 🆘 Troubleshooting

### Services Won't Start
```bash
# Check Docker daemon
sudo systemctl status docker

# Check disk space
df -h /

# Check minikube logs
minikube logs
```

### Application Not Accessible After Start
```bash
# Reapply iptables rules
bash ~/scripts/setup-iptables.sh

# Check pod status
kubectl get pods -n todo-app

# Check service
kubectl get svc -n todo-app
```

### Slow Startup
```bash
# Check if images need to be pulled
kubectl describe pod -n todo-app | grep -i "pulling\|pulled"

# Pre-pull images (optional)
minikube ssh docker pull alitarek123/todo-list-nodejs:master-7048b27
minikube ssh docker pull mongo:7-jammy
```

---

## 📝 Quick Reference Commands

```bash
# Stop everything
ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128 'minikube stop'

# Start everything
ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128 'minikube start && bash ~/scripts/setup-iptables.sh'

# Check status
ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128 'minikube status && kubectl get pods -n todo-app'

# Test application
curl -s http://192.168.74.128:30080 | grep "<h4"
```

---

**💡 Pro Tip:** Create desktop shortcuts for start/stop scripts for one-click resource management!
