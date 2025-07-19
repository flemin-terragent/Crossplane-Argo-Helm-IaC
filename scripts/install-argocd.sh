#!/bin/bash

# Install ArgoCD
echo "🚀 Installing ArgoCD..."

# Add ArgoCD Helm repository
echo "📦 Adding ArgoCD Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
echo "⚙️ Installing ArgoCD in argocd namespace..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set server.service.type=NodePort \
  --set server.service.nodePortHttp=30080 \
  --set server.service.nodePortHttps=30443 \
  --set server.extraArgs[0]="--insecure" \
  --wait

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --namespace argocd --timeout=300s

# Get ArgoCD admin password
echo "🔑 Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "✅ ArgoCD installed successfully!"
echo ""
echo "🌐 ArgoCD UI Access:"
echo "   URL: http://localhost:30080"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "💡 To access ArgoCD UI, run:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "   Then open: http://localhost:8080"
