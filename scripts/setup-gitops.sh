#!/bin/bash

# Apply Crossplane resources directly via ArgoCD using local manifests
echo "🚀 Setting up ArgoCD for local development..."

echo "📝 Note: For production use, you should:"
echo "   1. Push this repository to GitHub/GitLab"
echo "   2. Update ArgoCD applications to use your Git repository"
echo "   3. Enable GitOps for automatic synchronization"
echo ""

# For now, we'll manage resources directly with kubectl
echo "🔧 Current setup uses direct kubectl commands:"
echo "   ✅ Crossplane compositions: Applied via 'make deploy-compositions'"
echo "   ✅ Azure resources: Applied via 'make test-azure'"
echo ""

echo "🌐 ArgoCD UI is available at: http://argocd.local"
echo "📊 ArgoCD admin password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo ""

echo "💡 To set up full GitOps:"
echo "   1. Initialize git repository: git init"
echo "   2. Create GitHub repository"
echo "   3. Push code: git remote add origin <your-repo-url> && git push"
echo "   4. Update ArgoCD applications with your repository URL"
echo "   5. Apply ArgoCD applications: kubectl apply -f argocd/applications/"
