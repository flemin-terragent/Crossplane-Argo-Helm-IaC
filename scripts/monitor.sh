#!/bin/bash

# Monitor and troubleshoot the deployment
echo "🔍 Monitoring Crossplane, ArgoCD, and Azure Resources..."

echo "========================================"
echo "🎯 KUBERNETES CLUSTER STATUS"
echo "========================================"
kubectl cluster-info
kubectl get nodes

echo ""
echo "========================================"
echo "🔧 CROSSPLANE STATUS"
echo "========================================"
echo "Crossplane pods:"
kubectl get pods -n crossplane-system

echo ""
echo "Crossplane providers:"
kubectl get providers

echo ""
echo "Provider configurations:"
kubectl get providerconfigs

echo ""
echo "Composite resource definitions:"
kubectl get xrd

echo ""
echo "Compositions:"
kubectl get compositions

echo ""
echo "========================================"
echo "🚀 ARGOCD STATUS"
echo "========================================"
echo "ArgoCD pods:"
kubectl get pods -n argocd

echo ""
echo "ArgoCD applications:"
kubectl get applications -n argocd

echo ""
echo "ArgoCD application details:"
kubectl get applications -n argocd -o wide

echo ""
echo "========================================"
echo "☁️ AZURE RESOURCES STATUS"
echo "========================================"
echo "Azure infrastructure claims:"
kubectl get azureinfrastructure -n azure-resources

echo ""
echo "Azure resource groups:"
kubectl get resourcegroup

echo ""
echo "Azure resource group details:"
kubectl get resourcegroup -o wide

echo ""
echo "========================================"
echo "🐛 TROUBLESHOOTING INFO"
echo "========================================"
echo "Recent events in crossplane-system:"
kubectl get events -n crossplane-system --sort-by='.lastTimestamp' | tail -10

echo ""
echo "Recent events in argocd:"
kubectl get events -n argocd --sort-by='.lastTimestamp' | tail -10

echo ""
echo "Recent events in azure-resources:"
kubectl get events -n azure-resources --sort-by='.lastTimestamp' | tail -10

echo ""
echo "========================================"
echo "📊 SUMMARY"
echo "========================================"
echo "✅ To access ArgoCD UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "   Open: http://localhost:8080"
echo ""
echo "🔍 To check specific resource details:"
echo "   kubectl describe azureinfrastructure -n azure-resources"
echo "   kubectl describe application <app-name> -n argocd"
echo ""
echo "📋 To check logs:"
echo "   kubectl logs -n crossplane-system -l app=crossplane"
echo "   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server"
