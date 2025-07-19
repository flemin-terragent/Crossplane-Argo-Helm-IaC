#!/bin/bash

# Configure ArgoCD Ingress
echo "🌐 Configuring ArgoCD Ingress..."

# Check if ingress controller is installed
if ! kubectl get deployment ingress-nginx-controller -n ingress-nginx &> /dev/null; then
    echo "📦 Installing NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
    
    echo "⏳ Waiting for ingress controller to be ready..."
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s
fi

# Apply ArgoCD ingress
echo "🔧 Applying ArgoCD ingress configuration..."
kubectl apply -f argocd/ingress/argocd-ingress.yaml

# Check if argocd.local is in hosts file
if ! grep -q "argocd.local" /etc/hosts; then
    echo "📝 Adding argocd.local to hosts file..."
    echo "Please run: sudo sh -c 'echo \"127.0.0.1 argocd.local\" >> /etc/hosts'"
    echo "Or manually add '127.0.0.1 argocd.local' to your /etc/hosts file"
fi

# Get ingress status
echo "📊 Ingress Status:"
kubectl get ingress -n argocd

echo ""
echo "✅ ArgoCD Ingress configured successfully!"
echo ""
echo "🌐 Access ArgoCD at: http://argocd.local"
echo "📝 Username: admin"
echo "🔑 Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo ""
echo "💡 If you can't access argocd.local, add this to your /etc/hosts:"
echo "   127.0.0.1 argocd.local"
