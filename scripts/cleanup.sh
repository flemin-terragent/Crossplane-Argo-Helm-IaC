#!/bin/bash

# Cleanup script for the entire setup
echo "🧹 Cleaning up Crossplane, ArgoCD, and Azure Resources..."

# Function to confirm action
confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Delete ArgoCD applications first
if confirm "Delete ArgoCD applications?"; then
    echo "🗑️ Deleting ArgoCD applications..."
    kubectl delete -f argocd/azure-resources-app.yaml --ignore-not-found
    kubectl delete -f argocd/crossplane-infrastructure-app.yaml --ignore-not-found
    kubectl delete -f argocd/azure-project.yaml --ignore-not-found
    echo "✅ ArgoCD applications deleted"
fi

# Delete Azure infrastructure claims
if confirm "Delete Azure infrastructure claims?"; then
    echo "🗑️ Deleting Azure infrastructure claims..."
    kubectl delete -f crossplane/claims/ --ignore-not-found
    kubectl delete azureinfrastructure --all -n azure-resources --ignore-not-found
    echo "✅ Azure infrastructure claims deleted"
fi

# Delete Crossplane compositions and XRDs
if confirm "Delete Crossplane compositions and XRDs?"; then
    echo "🗑️ Deleting Crossplane compositions..."
    kubectl delete -f crossplane/compositions/ --ignore-not-found
    kubectl delete -f crossplane/providers/ --ignore-not-found
    echo "✅ Crossplane compositions deleted"
fi

# Uninstall ArgoCD
if confirm "Uninstall ArgoCD?"; then
    echo "🗑️ Uninstalling ArgoCD..."
    helm uninstall argocd -n argocd
    kubectl delete namespace argocd --ignore-not-found
    echo "✅ ArgoCD uninstalled"
fi

# Uninstall Crossplane
if confirm "Uninstall Crossplane?"; then
    echo "🗑️ Uninstalling Crossplane..."
    helm uninstall crossplane -n crossplane-system
    kubectl delete namespace crossplane-system --ignore-not-found
    echo "✅ Crossplane uninstalled"
fi

# Delete Azure resources namespace
if confirm "Delete Azure resources namespace?"; then
    echo "🗑️ Deleting Azure resources namespace..."
    kubectl delete namespace azure-resources --ignore-not-found
    echo "✅ Azure resources namespace deleted"
fi

# Delete Azure service principal (optional)
if confirm "Delete Azure service principal? (This will require Azure CLI login)"; then
    echo "🗑️ Listing Azure service principals with 'crossplane' in name..."
    if command -v az &> /dev/null && az account show >/dev/null 2>&1; then
        SP_LIST=$(az ad sp list --display-name "crossplane-sp" --query "[].displayName" --output tsv)
        if [ -n "$SP_LIST" ]; then
            echo "Found service principals:"
            echo "$SP_LIST"
            if confirm "Delete these service principals?"; then
                az ad sp list --display-name "crossplane-sp" --query "[].appId" --output tsv | while read -r app_id; do
                    echo "Deleting service principal: $app_id"
                    az ad sp delete --id "$app_id"
                done
                echo "✅ Service principals deleted"
            fi
        else
            echo "No service principals found with 'crossplane-sp' in name"
        fi
    else
        echo "⚠️ Azure CLI not available or not logged in. Skipping service principal deletion."
    fi
fi

echo ""
echo "🎉 Cleanup completed!"
echo ""
echo "📋 Verification commands:"
echo "   kubectl get namespaces"
echo "   kubectl get applications -n argocd"
echo "   kubectl get providers"
echo "   kubectl get compositions"
