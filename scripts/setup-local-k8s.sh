#!/bin/bash

# Setup Local Kubernetes Environment
echo "🚀 Setting up Local Kubernetes Environment..."

# Check if Docker Desktop is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker Desktop is not running. Please start Docker Desktop and enable Kubernetes."
    exit 1
fi

# Check if Kubernetes is enabled in Docker Desktop
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ Kubernetes is not enabled in Docker Desktop. Please enable it in Docker Desktop settings."
    exit 1
fi

echo "✅ Docker Desktop with Kubernetes is running"

# Create necessary namespaces
echo "📁 Creating namespaces..."
kubectl create namespace crossplane-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace azure-resources --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Namespaces created successfully"

# Check if kubectl context is set to docker-desktop
CURRENT_CONTEXT=$(kubectl config current-context)
if [ "$CURRENT_CONTEXT" != "docker-desktop" ]; then
    echo "⚠️  Current context is $CURRENT_CONTEXT. Switching to docker-desktop..."
    kubectl config use-context docker-desktop
fi

echo "✅ Local Kubernetes environment setup completed!"
echo "Current context: $(kubectl config current-context)"
echo "Available nodes:"
kubectl get nodes
