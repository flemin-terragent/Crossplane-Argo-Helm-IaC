#!/bin/bash

# Deploy Applications using ArgoCD
echo "🚀 Deploying Applications using ArgoCD..."

# Check if ArgoCD is installed and running
if ! kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server | grep -q Running; then
    echo "❌ ArgoCD is not running. Please install ArgoCD first using ./scripts/install-argocd.sh"
    exit 1
fi

# Check if Crossplane is installed and running
if ! kubectl get pods -n crossplane-system -l app=crossplane | grep -q Running; then
    echo "❌ Crossplane is not running. Please install Crossplane first using ./scripts/install-crossplane.sh"
    exit 1
fi

# Apply Crossplane configurations
echo "📋 Applying Crossplane configurations..."
kubectl apply -f crossplane/compositions/
kubectl apply -f crossplane/providers/

# Wait for compositions to be ready
echo "⏳ Waiting for Crossplane compositions to be ready..."
sleep 10

# Apply ArgoCD project
echo "📁 Creating ArgoCD project..."
kubectl apply -f argocd/azure-project.yaml

# Deploy ArgoCD applications
echo "🚀 Deploying ArgoCD applications..."
kubectl apply -f argocd/crossplane-infrastructure-app.yaml
kubectl apply -f argocd/azure-resources-app.yaml

# Wait for applications to sync
echo "⏳ Waiting for applications to sync..."
sleep 15

# Check application status
echo "📊 Checking application status..."
kubectl get applications -n argocd

echo "✅ Applications deployed successfully!"
echo ""
echo "🌐 To access ArgoCD UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "   Open: http://localhost:8080"
echo ""
echo "🔍 To check application status:"
echo "   kubectl get applications -n argocd"
echo "   kubectl get azureinfrastructure -n azure-resources"
echo ""
echo "📋 To check Azure resources:"
echo "   kubectl get resourcegroup"
echo "   kubectl describe resourcegroup"
