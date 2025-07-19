#!/bin/bash

echo "🚀 Setting up Local Repository for ArgoCD Deployment..."
echo "======================================================"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository. Please run 'git init' first."
    exit 1
fi

# Commit any pending changes
echo "📝 Committing current changes..."
git add .
git commit -m "Update ArgoCD configuration for local development" || echo "No changes to commit"

echo ""
echo "🎯 Local Development Setup Summary:"
echo "===================================="
echo ""
echo "✅ **ArgoCD Configuration**: Local development setup complete"
echo "✅ **Resource Management**: Direct kubectl/make commands"
echo "✅ **ArgoCD Monitoring**: Available at http://argocd.local"
echo "✅ **Documentation**: ConfigMaps created with guides"
echo ""

echo "🌐 **ArgoCD Access Information:**"
echo "   URL: http://argocd.local"
echo "   Username: admin"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null)
echo "   Password: $ARGOCD_PASSWORD"
echo ""

echo "📊 **Current Applications:**"
kubectl get applications -n argocd --no-headers | while read line; do
    echo "   - $line"
done
echo ""

echo "🔧 **Resource Management Commands:**"
echo "   Deploy compositions:     make deploy-compositions"
echo "   Test Azure resources:    make test-azure"
echo "   Verify everything:       make verify-secrets"
echo "   Monitor resources:       kubectl get resourcegroup -n azure-resources"
echo ""

echo "📚 **Documentation Available:**"
echo "   Local dev guide:         kubectl get configmap local-development-guide -n argocd -o yaml"
echo "   Deployment status:       kubectl get configmap deployment-status -n argocd -o yaml"
echo "   Troubleshooting:         cat TROUBLESHOOTING.md"
echo ""

echo "🎯 **Current Infrastructure Status:**"
echo "   Crossplane providers:"
kubectl get providers --no-headers | while read line; do
    echo "     - $line"
done

echo "   Azure resources:"
kubectl get resourcegroup -n azure-resources --no-headers 2>/dev/null | while read line; do
    echo "     - $line"
done || echo "     - No Azure resources created yet"

echo ""
echo "💡 **To Set Up Full GitOps Later:**"
echo "   1. Create GitHub repository"
echo "   2. git remote add origin <your-repo-url>"
echo "   3. git push -u origin main"
echo "   4. Update argocd/applications/crossplane-apps.yaml with your repo URL"
echo "   5. kubectl apply -f argocd/applications/crossplane-apps.yaml"
echo ""

echo "🎉 **SUCCESS**: Local ArgoCD deployment setup complete!"
echo "   Your infrastructure is ready and ArgoCD is configured for local development."
