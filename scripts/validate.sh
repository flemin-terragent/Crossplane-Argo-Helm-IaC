#!/bin/bash

# Validation script to check if the setup is working correctly
echo "🔍 Validating Crossplane-ArgoCD-Helm Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Counter for issues
issues=0

echo "========================================"
echo "🔧 PREREQUISITES CHECK"
echo "========================================"

# Check Docker
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        print_status 0 "Docker is installed and running"
    else
        print_status 1 "Docker is installed but not running"
        issues=$((issues + 1))
    fi
else
    print_status 1 "Docker is not installed"
    issues=$((issues + 1))
fi

# Check kubectl
if command -v kubectl &> /dev/null; then
    if kubectl cluster-info &> /dev/null; then
        print_status 0 "kubectl is installed and can connect to cluster"
    else
        print_status 1 "kubectl is installed but cannot connect to cluster"
        issues=$((issues + 1))
    fi
else
    print_status 1 "kubectl is not installed"
    issues=$((issues + 1))
fi

# Check Helm
if command -v helm &> /dev/null; then
    print_status 0 "Helm is installed"
else
    print_status 1 "Helm is not installed"
    issues=$((issues + 1))
fi

# Check Azure CLI
if command -v az &> /dev/null; then
    if az account show &> /dev/null; then
        print_status 0 "Azure CLI is installed and authenticated"
    else
        print_warning "Azure CLI is installed but not authenticated (run 'az login')"
    fi
else
    print_status 1 "Azure CLI is not installed"
    issues=$((issues + 1))
fi

echo ""
echo "========================================"
echo "🎯 KUBERNETES CLUSTER CHECK"
echo "========================================"

# Check if current context is docker-desktop
current_context=$(kubectl config current-context 2>/dev/null)
if [ "$current_context" = "docker-desktop" ]; then
    print_status 0 "Using docker-desktop context"
else
    print_warning "Current context is $current_context (expected: docker-desktop)"
fi

# Check namespaces
namespaces=("crossplane-system" "argocd" "azure-resources")
for ns in "${namespaces[@]}"; do
    if kubectl get namespace "$ns" &> /dev/null; then
        print_status 0 "Namespace $ns exists"
    else
        print_warning "Namespace $ns does not exist"
    fi
done

echo ""
echo "========================================"
echo "🔧 CROSSPLANE CHECK"
echo "========================================"

# Check if Crossplane is installed
if kubectl get pods -n crossplane-system -l app=crossplane &> /dev/null; then
    # Check if Crossplane pods are running
    crossplane_ready=$(kubectl get pods -n crossplane-system -l app=crossplane -o jsonpath='{.items[*].status.phase}' | grep -c Running)
    crossplane_total=$(kubectl get pods -n crossplane-system -l app=crossplane --no-headers | wc -l)
    
    if [ "$crossplane_ready" -eq "$crossplane_total" ] && [ "$crossplane_total" -gt 0 ]; then
        print_status 0 "Crossplane is installed and running ($crossplane_ready/$crossplane_total pods)"
    else
        print_status 1 "Crossplane is installed but not all pods are running ($crossplane_ready/$crossplane_total pods)"
    fi
    
    # Check Azure provider
    if kubectl get provider provider-azure &> /dev/null; then
        provider_status=$(kubectl get provider provider-azure -o jsonpath='{.status.conditions[?(@.type=="Healthy")].status}' 2>/dev/null)
        if [ "$provider_status" = "True" ]; then
            print_status 0 "Azure provider is installed and healthy"
        else
            print_warning "Azure provider is installed but not healthy"
        fi
    else
        print_warning "Azure provider is not installed"
    fi
    
    # Check ProviderConfig
    if kubectl get providerconfig default &> /dev/null; then
        print_status 0 "ProviderConfig exists"
    else
        print_warning "ProviderConfig does not exist"
    fi
else
    print_status 1 "Crossplane is not installed"
    issues=$((issues + 1))
fi

echo ""
echo "========================================"
echo "🚀 ARGOCD CHECK"
echo "========================================"

# Check if ArgoCD is installed
if kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server &> /dev/null; then
    # Check if ArgoCD pods are running
    argocd_ready=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[*].status.phase}' | grep -c Running)
    argocd_total=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server --no-headers | wc -l)
    
    if [ "$argocd_ready" -eq "$argocd_total" ] && [ "$argocd_total" -gt 0 ]; then
        print_status 0 "ArgoCD is installed and running ($argocd_ready/$argocd_total pods)"
    else
        print_status 1 "ArgoCD is installed but not all pods are running ($argocd_ready/$argocd_total pods)"
    fi
    
    # Check ArgoCD applications
    app_count=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l)
    if [ "$app_count" -gt 0 ]; then
        print_status 0 "ArgoCD applications exist ($app_count applications)"
    else
        print_warning "No ArgoCD applications found"
    fi
else
    print_status 1 "ArgoCD is not installed"
    issues=$((issues + 1))
fi

echo ""
echo "========================================"
echo "☁️ AZURE RESOURCES CHECK"
echo "========================================"

# Check Azure infrastructure claims
if kubectl get azureinfrastructure -n azure-resources &> /dev/null; then
    claim_count=$(kubectl get azureinfrastructure -n azure-resources --no-headers | wc -l)
    print_status 0 "Azure infrastructure claims exist ($claim_count claims)"
    
    # Check resource status
    ready_claims=$(kubectl get azureinfrastructure -n azure-resources -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -c True)
    if [ "$ready_claims" -gt 0 ]; then
        print_status 0 "Some Azure resources are ready ($ready_claims/$claim_count)"
    else
        print_warning "No Azure resources are ready yet"
    fi
else
    print_warning "No Azure infrastructure claims found"
fi

# Check actual Azure resources
if kubectl get resourcegroup &> /dev/null; then
    rg_count=$(kubectl get resourcegroup --no-headers 2>/dev/null | wc -l)
    if [ "$rg_count" -gt 0 ]; then
        print_status 0 "Azure resource group resources exist ($rg_count resources)"
    else
        print_warning "No Azure resource group resources found"
    fi
else
    print_warning "Cannot check Azure resource group resources"
fi

echo ""
echo "========================================"
echo "📊 SUMMARY"
echo "========================================"

if [ $issues -eq 0 ]; then
    echo -e "${GREEN}🎉 All critical components are working correctly!${NC}"
else
    echo -e "${RED}⚠️ Found $issues critical issues that need attention.${NC}"
fi

echo ""
echo "🔧 Next steps:"
echo "1. Fix any critical issues shown above"
echo "2. Run 'make monitor' to check detailed status"
echo "3. Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "4. Check applications: kubectl get applications -n argocd"
echo "5. Monitor Azure resources: kubectl get resourcegroup"

echo ""
echo "📋 Quick commands:"
echo "- make status           # Quick status check"
echo "- make monitor          # Detailed monitoring"
echo "- make argocd-password  # Get ArgoCD password"
echo "- make argocd-ui        # Start ArgoCD UI port-forward"

exit $issues
