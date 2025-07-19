#!/bin/bash

# Load Azure secrets from .env file and create Kubernetes secrets
echo "🔐 Loading Azure secrets from .env file..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found. Please create it with your Azure credentials."
    echo "Example .env file:"
    echo "AZURE_CLIENT_ID=your-client-id"
    echo "AZURE_CLIENT_SECRET=your-client-secret"
    echo "AZURE_TENANT_ID=your-tenant-id"
    echo "AZURE_SUBSCRIPTION_ID=your-subscription-id"
    exit 1
fi

# Load environment variables from .env file
echo "📄 Loading environment variables from .env file..."
set -a # automatically export all variables
source .env
set +a # stop automatically exporting

# Validate required environment variables
echo "🔍 Validating required environment variables..."
missing_vars=()

if [ -z "$AZURE_CLIENT_ID" ]; then
    missing_vars+=("AZURE_CLIENT_ID")
fi

if [ -z "$AZURE_CLIENT_SECRET" ]; then
    missing_vars+=("AZURE_CLIENT_SECRET")
fi

if [ -z "$AZURE_TENANT_ID" ]; then
    missing_vars+=("AZURE_TENANT_ID")
fi

if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
    missing_vars+=("AZURE_SUBSCRIPTION_ID")
fi

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "❌ Missing required environment variables:"
    for var in "${missing_vars[@]}"; do
        echo "   - $var"
    done
    echo "Please update your .env file with the missing variables."
    exit 1
fi

echo "✅ All required environment variables found"

# Check if crossplane-system namespace exists
if ! kubectl get namespace crossplane-system &> /dev/null; then
    echo "📁 Creating crossplane-system namespace..."
    kubectl create namespace crossplane-system
fi

# Create Kubernetes secret with Azure credentials
echo "🔐 Creating Kubernetes secret with Azure credentials..."
kubectl create secret generic azure-secret \
  --from-literal=clientId="$AZURE_CLIENT_ID" \
  --from-literal=clientSecret="$AZURE_CLIENT_SECRET" \
  --from-literal=tenantId="$AZURE_TENANT_ID" \
  --from-literal=subscriptionId="$AZURE_SUBSCRIPTION_ID" \
  --namespace crossplane-system \
  --dry-run=client -o yaml | kubectl apply -f -

# Create ProviderConfig using the secret
echo "⚙️ Creating ProviderConfig..."
cat <<EOF | kubectl apply -f -
apiVersion: azure.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: azure-secret
      key: clientSecret
  clientId: $AZURE_CLIENT_ID
  tenantId: $AZURE_TENANT_ID
  subscriptionId: $AZURE_SUBSCRIPTION_ID
EOF

# Create a backup secret in azure-resources namespace as well
echo "🔐 Creating backup secret in azure-resources namespace..."
if ! kubectl get namespace azure-resources &> /dev/null; then
    kubectl create namespace azure-resources
fi

kubectl create secret generic azure-credentials \
  --from-literal=client-id="$AZURE_CLIENT_ID" \
  --from-literal=client-secret="$AZURE_CLIENT_SECRET" \
  --from-literal=tenant-id="$AZURE_TENANT_ID" \
  --from-literal=subscription-id="$AZURE_SUBSCRIPTION_ID" \
  --namespace azure-resources \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Azure secrets loaded successfully!"
echo ""
echo "📋 Configuration Summary:"
echo "   Client ID: $AZURE_CLIENT_ID"
echo "   Tenant ID: $AZURE_TENANT_ID"
echo "   Subscription ID: $AZURE_SUBSCRIPTION_ID"
echo "   Client Secret: [HIDDEN]"
echo ""
echo "🔐 Secrets created:"
echo "   - azure-secret (in crossplane-system namespace)"
echo "   - azure-credentials (in azure-resources namespace)"
echo ""
echo "⚙️ ProviderConfig created: default"
echo ""
echo "🔍 To verify secrets:"
echo "   kubectl get secrets -n crossplane-system"
echo "   kubectl get secrets -n azure-resources"
echo "   kubectl get providerconfig"
