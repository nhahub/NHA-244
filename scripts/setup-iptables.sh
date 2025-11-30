#!/bin/bash
# Setup iptables rules for Todo App external access
# This script configures NAT rules to forward traffic from VM IP to minikube
# Run this after minikube starts to enable external access

set -e

echo "🔧 Setting up iptables rules for Todo App external access..."

# Get minikube IP dynamically
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "192.168.49.2")
VM_IP="192.168.74.128"
APP_PORT="30080"

echo "   VM IP: $VM_IP"
echo "   Minikube IP: $MINIKUBE_IP"
echo "   Application Port: $APP_PORT"

# Check if rules already exist to avoid duplicates
if sudo iptables -t nat -L PREROUTING -n | grep -q "$APP_PORT.*$MINIKUBE_IP"; then
    echo "⚠️  NAT rules already exist, skipping..."
else
    # Forward port from VM IP to minikube IP
    echo "   Adding PREROUTING rule..."
    sudo iptables -t nat -A PREROUTING -p tcp -d $VM_IP --dport $APP_PORT -j DNAT --to-destination $MINIKUBE_IP:$APP_PORT

    # Enable MASQUERADE for return traffic
    echo "   Adding POSTROUTING rule..."
    sudo iptables -t nat -A POSTROUTING -p tcp -d $MINIKUBE_IP --dport $APP_PORT -j MASQUERADE

    # Allow forwarding to minikube
    echo "   Adding FORWARD rule..."
    sudo iptables -I FORWARD -s 0.0.0.0/0 -d $MINIKUBE_IP -p tcp --dport $APP_PORT -j ACCEPT

    echo "✅ iptables rules configured successfully!"
fi

echo ""
echo "🌐 Application accessible at: http://$VM_IP:$APP_PORT"
echo ""

# Display current NAT rules for verification
echo "📋 Current NAT rules for port $APP_PORT:"
sudo iptables -t nat -L PREROUTING -n -v | grep $APP_PORT || echo "   No PREROUTING rules found"

echo ""
echo "⚠️  Note: These rules are not persistent across reboots."
echo "   Run this script again after system restart or minikube restart."
