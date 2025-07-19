#!/bin/bash

# Configure Azure Provider for Crossplane using existing credentials
echo "🔧 Configuring Azure Provider for Crossplane..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found. Please create it with your Azure credentials."
    echo "You can use the load-secrets.sh script to create secrets from .env file."
    echo "Run: ./scripts/load-secrets.sh"
    exit 1
fi

# Load environment variables from .env file
echo "📄 Loading environment variables from .env file..."
set -a # automatically export all variables
source .env
set +a # stop automatically exporting

# Validate required environment variables
missing_vars=()
if [ -z "$AZURE_CLIENT_ID" ]; then missing_vars+=("AZURE_CLIENT_ID"); fi
if [ -z "$AZURE_CLIENT_SECRET" ]; then missing_vars+=("AZURE_CLIENT_SECRET"); fi
if [ -z "$AZURE_TENANT_ID" ]; then missing_vars+=("AZURE_TENANT_ID"); fi
if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then missing_vars+=("AZURE_SUBSCRIPTION_ID"); fi

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "❌ Missing required environment variables in .env file:"
    for var in "${missing_vars[@]}"; do
        echo "   - $var"
    done
    exit 1
fi

# Check if Azure CLI is installed (optional, for verification)
if command -v az &> /dev/null; then
    echo "✅ Azure CLI is installed"
    
    # Check if user is logged in to Azure (optional, for verification)
    if az account show >/dev/null 2>&1; then
        echo "✅ You are logged in to Azure"
        current_sub=$(az account show --query id --output tsv)
        if [ "$current_sub" = "$AZURE_SUBSCRIPTION_ID" ]; then
            echo "✅ Current subscription matches the one in .env file"
        else
            echo "⚠️  Current subscription ($current_sub) differs from .env file ($AZURE_SUBSCRIPTION_ID)"
        fi
    else
        echo "⚠️  Not logged in to Azure CLI (this is optional for Crossplane)"
    fi
else
    echo "⚠️  Azure CLI not installed (this is optional for Crossplane)"
fi

# Call the load-secrets script to create Kubernetes secrets
echo "🔐 Creating Kubernetes secrets from .env file..."
./scripts/load-secrets.sh

echo "✅ Azure Provider configured successfully!"
echo ""
echo "📋 Configuration Summary:"
echo "   Client ID: $AZURE_CLIENT_ID"
echo "   Tenant ID: $AZURE_TENANT_ID"
echo "   Subscription ID: $AZURE_SUBSCRIPTION_ID"
echo ""
echo "🔐 Secrets created in Kubernetes:"
echo "   - azure-secret (crossplane-system namespace)"
echo "   - azure-credentials (azure-resources namespace)"
echo ""
echo "⚙️ ProviderConfig created: default"
