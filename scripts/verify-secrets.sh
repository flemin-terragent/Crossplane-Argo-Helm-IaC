#!/bin/bash

# Verify Azure secrets configuration
echo "🔍 Verifying Azure secrets configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✅ $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
    fi
}

echo ""
echo "========================================"
echo "🔍 Environment File Check"
echo "========================================"

# Check if .env file exists
if [ -f ".env" ]; then
    print_status 0 ".env file exists"
    
    # Check if .env file contains required variables
    if grep -q "AZURE_CLIENT_ID=" .env; then
        print_status 0 "AZURE_CLIENT_ID found in .env"
    else
        print_status 1 "AZURE_CLIENT_ID not found in .env"
    fi
    
    if grep -q "AZURE_CLIENT_SECRET=" .env; then
        print_status 0 "AZURE_CLIENT_SECRET found in .env"
    else
        print_status 1 "AZURE_CLIENT_SECRET not found in .env"
    fi
    
    if grep -q "AZURE_TENANT_ID=" .env; then
        print_status 0 "AZURE_TENANT_ID found in .env"
    else
        print_status 1 "AZURE_TENANT_ID not found in .env"
    fi
    
    if grep -q "AZURE_SUBSCRIPTION_ID=" .env; then
        print_status 0 "AZURE_SUBSCRIPTION_ID found in .env"
    else
        print_status 1 "AZURE_SUBSCRIPTION_ID not found in .env"
    fi
else
    print_status 1 ".env file does not exist"
fi

echo ""
echo "========================================"
echo "🔍 Kubernetes Secrets Check"
echo "========================================"

# Check if azure-secret exists in crossplane-system namespace
if kubectl get secret azure-secret -n crossplane-system &> /dev/null; then
    print_status 0 "azure-secret exists in crossplane-system namespace"
    
    # Check if secret contains required keys
    if kubectl get secret azure-secret -n crossplane-system -o jsonpath='{.data.clientId}' | base64 -d &> /dev/null; then
        print_status 0 "clientId key exists in azure-secret"
    else
        print_status 1 "clientId key missing in azure-secret"
    fi
    
    if kubectl get secret azure-secret -n crossplane-system -o jsonpath='{.data.clientSecret}' | base64 -d &> /dev/null; then
        print_status 0 "clientSecret key exists in azure-secret"
    else
        print_status 1 "clientSecret key missing in azure-secret"
    fi
    
    if kubectl get secret azure-secret -n crossplane-system -o jsonpath='{.data.tenantId}' | base64 -d &> /dev/null; then
        print_status 0 "tenantId key exists in azure-secret"
    else
        print_status 1 "tenantId key missing in azure-secret"
    fi
    
    if kubectl get secret azure-secret -n crossplane-system -o jsonpath='{.data.subscriptionId}' | base64 -d &> /dev/null; then
        print_status 0 "subscriptionId key exists in azure-secret"
    else
        print_status 1 "subscriptionId key missing in azure-secret"
    fi
else
    print_status 1 "azure-secret does not exist in crossplane-system namespace"
fi

# Check if azure-credentials exists in crossplane-system namespace  
if kubectl get secret azure-credentials -n crossplane-system &> /dev/null; then
    print_status 0 "azure-credentials exists in crossplane-system namespace"
else
    print_status 1 "azure-credentials does not exist in crossplane-system namespace"
fi

echo ""
echo "========================================"
echo "🔍 ProviderConfig Check"
echo "========================================"

# Check if ProviderConfig exists
if kubectl get providerconfig.azure.upbound.io default &> /dev/null; then
    print_status 0 "ProviderConfig 'default' exists"
    
    # Check if ProviderConfig references the correct secret
    secret_ref=$(kubectl get providerconfig.azure.upbound.io default -o jsonpath='{.spec.credentials.secretRef.name}' 2>/dev/null)
    if [[ "$secret_ref" == "azure-credentials" ]]; then
        print_status 0 "ProviderConfig references azure-credentials"
    else
        print_status 1 "ProviderConfig does not reference azure-credentials (references: $secret_ref)"
    fi
else
    print_status 1 "ProviderConfig 'default' does not exist"
fi

echo ""
echo "========================================"
echo "🔍 Credential Values Check"
echo "========================================"

if [ -f ".env" ]; then
    source .env
    
    # Obfuscate sensitive values for display
    client_id_display="${AZURE_CLIENT_ID:0:8}...${AZURE_CLIENT_ID: -4}"
    tenant_id_display="${AZURE_TENANT_ID:0:8}...${AZURE_TENANT_ID: -4}"
    subscription_id_display="${AZURE_SUBSCRIPTION_ID:0:8}...${AZURE_SUBSCRIPTION_ID: -4}"
    client_secret_length=${#AZURE_CLIENT_SECRET}
    
    echo "Client ID: $client_id_display"
    echo "Tenant ID: $tenant_id_display"
    echo "Subscription ID: $subscription_id_display"
    echo "Client Secret: [SET - length: $client_secret_length]"
fi

echo ""
echo "========================================"
echo "📋 Summary and Next Steps"
echo "========================================"

echo "🔧 Configuration commands:"
echo "  make load-secrets     # Load secrets from .env file"
echo "  make configure-azure  # Configure Azure provider"
echo ""
echo "🔍 Verification commands:"
echo "  kubectl get secrets -n crossplane-system"
echo "  kubectl get providerconfig.azure.upbound.io"
echo ""
echo "📄 View secret details (obfuscated):"
echo "  kubectl get secret azure-secret -n crossplane-system -o yaml"
echo "  kubectl get secret azure-credentials -n crossplane-system -o yaml"
