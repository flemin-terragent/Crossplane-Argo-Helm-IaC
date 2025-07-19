#!/bin/bash

# Test script to verify Azure Resource Group deployment
echo "🧪 Testing Azure Resource Group Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print test results
test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS: $2${NC}"
    else
        echo -e "${RED}❌ FAIL: $2${NC}"
    fi
}

echo "========================================"
echo "🔍 Testing Resource Group Claim"
echo "========================================"

# Check if the Azure infrastructure claim exists
if kubectl get azureinfrastructure my-azure-infrastructure -n azure-resources &> /dev/null; then
    test_result 0 "Azure infrastructure claim exists"
    
    # Check if the claim is ready
    ready_status=$(kubectl get azureinfrastructure my-azure-infrastructure -n azure-resources -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$ready_status" = "True" ]; then
        test_result 0 "Azure infrastructure claim is ready"
    else
        test_result 1 "Azure infrastructure claim is not ready yet"
        echo -e "${YELLOW}   Status: $ready_status${NC}"
    fi
else
    test_result 1 "Azure infrastructure claim does not exist"
fi

echo ""
echo "========================================"
echo "🔍 Testing Azure Resource Group"
echo "========================================"

# Check if the actual Azure resource group exists
if kubectl get resourcegroup &> /dev/null; then
    rg_count=$(kubectl get resourcegroup --no-headers 2>/dev/null | wc -l)
    if [ "$rg_count" -gt 0 ]; then
        test_result 0 "Azure resource group exists ($rg_count found)"
        
        # Show resource group details
        echo ""
        echo "Resource Group Details:"
        kubectl get resourcegroup -o wide
        
        # Check resource group status
        echo ""
        echo "Resource Group Status:"
        kubectl get resourcegroup -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q True
        if [ $? -eq 0 ]; then
            test_result 0 "Resource group is in Ready state"
        else
            test_result 1 "Resource group is not in Ready state"
        fi
    else
        test_result 1 "No Azure resource groups found"
    fi
else
    test_result 1 "Cannot check Azure resource groups"
fi

echo ""
echo "========================================"
echo "🔍 Testing ArgoCD Application"
echo "========================================"

# Check if ArgoCD application exists
if kubectl get application azure-resources-helm -n argocd &> /dev/null; then
    test_result 0 "ArgoCD application exists"
    
    # Check application sync status
    sync_status=$(kubectl get application azure-resources-helm -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null)
    if [ "$sync_status" = "Synced" ]; then
        test_result 0 "ArgoCD application is synced"
    else
        test_result 1 "ArgoCD application is not synced (Status: $sync_status)"
    fi
    
    # Check application health
    health_status=$(kubectl get application azure-resources-helm -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null)
    if [ "$health_status" = "Healthy" ]; then
        test_result 0 "ArgoCD application is healthy"
    else
        test_result 1 "ArgoCD application is not healthy (Status: $health_status)"
    fi
else
    test_result 1 "ArgoCD application does not exist"
fi

echo ""
echo "========================================"
echo "📊 Summary"
echo "========================================"

echo "🔍 Manual verification commands:"
echo "1. Check infrastructure claim:"
echo "   kubectl describe azureinfrastructure my-azure-infrastructure -n azure-resources"
echo ""
echo "2. Check resource group:"
echo "   kubectl get resourcegroup"
echo "   kubectl describe resourcegroup"
echo ""
echo "3. Check ArgoCD application:"
echo "   kubectl get application azure-resources-helm -n argocd"
echo "   kubectl describe application azure-resources-helm -n argocd"
echo ""
echo "4. Check Azure portal for actual resource group creation"
echo ""
echo "🌐 Access ArgoCD UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "   Open: http://localhost:8080"
