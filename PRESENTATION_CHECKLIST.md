# 🎤 Presentation Day Checklist

## Pre-Presentation Setup (15 minutes before)

### 1. Verify VM and Minikube Status
```bash
# SSH into VM
ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128

# Check minikube status
minikube status

# If not running, start minikube
minikube start --driver=docker --cpus=2 --memory=2048
```

### 2. Verify Application Pods
```bash
# Check all pods are running
kubectl get pods -n todo-app

# Expected output:
# NAME                       READY   STATUS    RESTARTS   AGE
# mongodb-xxx                1/1     Running   0          Xm
# todo-app-xxx               1/1     Running   0          Xm
# todo-app-xxx               1/1     Running   0          Xm
```

### 3. Setup iptables Rules (if needed)
```bash
# Run the setup script
bash ~/scripts/setup-iptables.sh

# Or manually:
sudo iptables -t nat -A PREROUTING -p tcp -d 192.168.74.128 --dport 30080 -j DNAT --to-destination $(minikube ip):30080
sudo iptables -t nat -A POSTROUTING -p tcp -d $(minikube ip) --dport 30080 -j MASQUERADE
sudo iptables -I FORWARD -s 0.0.0.0/0 -d $(minikube ip) -p tcp --dport 30080 -j ACCEPT
```

### 4. Test Application Access
```bash
# From inside VM
curl -s http://192.168.74.128:30080 | grep "<h4"

# Expected: <h4 class="main-heading">Todos, just tasks - CI/CD Pipeline Active! 🚀</h4>
```

### 5. Open Browser Tabs (Before Presentation)
- ✅ Application: http://192.168.74.128:30080
- ✅ GitHub Repo: https://github.com/alitarek-dot/Todo-List-nodejs
- ✅ GitHub Actions: https://github.com/alitarek-dot/Todo-List-nodejs/actions
- ✅ Docker Hub: https://hub.docker.com/r/alitarek123/todo-list-nodejs/tags
- ✅ Documentation: https://github.com/nhahub/NHA-244

---

## During Presentation

### Opening (2 minutes)
1. **Show live application** in browser (http://192.168.74.128:30080)
2. **Explain project scope**: "Complete DevOps workflow from code to production"
3. **Highlight key technologies**: Docker, Kubernetes, Ansible, GitHub Actions

### Architecture Overview (3 minutes)
1. **Show README architecture diagram** from GitHub
2. **Explain components**:
   - Node.js app (2 replicas for HA)
   - MongoDB (inside Kubernetes)
   - Minikube on Ubuntu VM
   - GitHub Actions CI/CD
3. **Highlight networking**: NAT rules for external access

### Live Demo: CI/CD Pipeline (7-10 minutes)

#### Step 1: Show Current Application
```bash
# In browser, show homepage with current text
http://192.168.74.128:30080
```

#### Step 2: Make Code Change
```bash
# On local machine
cd ~/Desktop/capstone-project/Todo-List-nodejs

# Edit homepage
nano views/home.ejs
# Change line 27 to: "Todos - Live Demo by [Your Name] 🎯"

# Save and exit (Ctrl+X, Y, Enter)
```

#### Step 3: Commit and Push
```bash
git add views/home.ejs
git commit -m "Presentation demo: Update homepage"
git push origin master
```

#### Step 4: Monitor CI/CD Pipeline
1. **Open GitHub Actions** tab (already open)
2. **Show workflow running** in real-time
3. **Explain each step**:
   - Checkout code
   - Build Docker image
   - Push to Docker Hub with tags (latest + master-SHA)
4. **Wait for completion** (~40-60 seconds)

#### Step 5: Verify Docker Hub
1. **Open Docker Hub** tab (already open)
2. **Show new image tag** with commit SHA
3. **Point out timestamp** matches push time

#### Step 6: Deploy to Kubernetes
```bash
# SSH into VM (in terminal)
ssh -i ~/.ssh/vm_ansible alitarek@192.168.74.128

# Get new commit SHA from GitHub Actions
NEW_TAG="master-<commit-sha>"

# Update deployment
kubectl set image deployment/todo-app \
  todo-app=alitarek123/todo-list-nodejs:$NEW_TAG \
  -n todo-app

# Watch rollout
kubectl rollout status deployment/todo-app -n todo-app

# Verify new image
kubectl describe pod -n todo-app | grep Image:
```

#### Step 7: Verify Changes
1. **Refresh browser** (http://192.168.74.128:30080)
2. **Show updated homepage** with new text
3. **Explain**: "Complete CI/CD cycle in under 2 minutes!"

### Technical Deep Dive (3-5 minutes)

#### Dockerization
```bash
# Show Dockerfile
cat ~/Desktop/capstone-project/Todo-List-nodejs/Dockerfile | head -20
```
- Multi-stage build for optimization
- Non-root user for security
- Image size: ~209MB

#### Kubernetes
```bash
# Show deployment details
kubectl get deployment -n todo-app -o wide
kubectl get pods -n todo-app -o wide
```
- 2 replicas for high availability
- Health probes configured
- Resource limits applied

#### Automation
```bash
# Show Ansible playbook
cat ~/Desktop/capstone-project/ansible/setup-vm.yml | head -30
```
- Automated VM provisioning
- Idempotent configuration
- Passwordless SSH

### Challenges & Solutions (2-3 minutes)
1. **Disk Space**: Cleaned up Docker images, freed 1GB
2. **MongoDB Connectivity**: Moved MongoDB inside Kubernetes
3. **Secret Keys**: Fixed secret key references in manifests
4. **External Access**: Configured iptables NAT rules

### Closing (1 minute)
- "Demonstrated modern DevOps practices"
- "Fully automated, reproducible, scalable"
- "Ready for questions"

---

## Quick Commands Reference

### Check Everything is Running
```bash
# Minikube status
minikube status

# All pods
kubectl get pods -n todo-app

# Services
kubectl get svc -n todo-app

# Recent logs
kubectl logs -n todo-app -l app=todo-app --tail=20
```

### Troubleshooting During Presentation

#### If Application Not Accessible
```bash
# Check iptables rules
sudo iptables -t nat -L PREROUTING -n -v | grep 30080

# Re-run setup script
bash ~/scripts/setup-iptables.sh

# Test from inside VM
curl -s http://192.168.74.128:30080 | head -20
```

#### If Pods Not Running
```bash
# Check pod status
kubectl get pods -n todo-app

# Check logs
kubectl logs -n todo-app <pod-name>

# Restart deployment
kubectl rollout restart deployment/todo-app -n todo-app
kubectl rollout restart deployment/mongodb -n todo-app
```

#### If Minikube Not Running
```bash
# Start minikube
minikube start --driver=docker --cpus=2 --memory=2048

# Wait for pods
kubectl wait --for=condition=ready pod -l app=todo-app -n todo-app --timeout=120s

# Setup iptables
bash ~/scripts/setup-iptables.sh
```

---

## Post-Presentation

### Cleanup (Optional)
```bash
# Stop minikube (saves resources)
minikube stop

# Or delete everything
minikube delete
docker stop mongodb
docker rm mongodb
```

### Save iptables Rules (For Future Use)
```bash
# Save current rules
sudo iptables-save > ~/iptables-backup.rules

# Restore later
sudo iptables-restore < ~/iptables-backup.rules
```

---

## Key Metrics to Mention

- **Infrastructure**: Ubuntu 24.04, 2 CPUs, 2GB RAM
- **Kubernetes**: v1.34.0, 2 app replicas, 1 MongoDB replica
- **Docker Image**: 209MB (optimized multi-stage build)
- **CI/CD Pipeline**: ~40-60 seconds from push to Docker Hub
- **Deployment Time**: ~30 seconds for rolling update
- **Uptime**: High availability with 2 replicas

---

## Backup Plan

If live demo fails:
1. **Show recorded video** (if available)
2. **Walk through GitHub Actions logs** from previous successful run
3. **Show Docker Hub images** with timestamps
4. **Explain architecture** using README diagrams
5. **Show code and manifests** to demonstrate understanding

---

## Questions You Might Get

**Q: Why MongoDB inside Kubernetes instead of external?**
A: Better networking, service discovery, and resource management. Kubernetes handles restarts and health checks automatically.

**Q: Why not use LoadBalancer instead of NodePort?**
A: Minikube doesn't support LoadBalancer natively. NodePort is sufficient for demo/dev environments.

**Q: How do you handle secrets in production?**
A: Use external secret managers like HashiCorp Vault, AWS Secrets Manager, or sealed-secrets for GitOps.

**Q: What about database backups?**
A: In production, use PersistentVolumes with backup solutions like Velero or cloud-native backup services.

**Q: How would you scale this?**
A: Horizontal Pod Autoscaler for app pods, StatefulSet for MongoDB with replication, and external managed database for production.

---

**Good luck with your presentation! 🚀**
