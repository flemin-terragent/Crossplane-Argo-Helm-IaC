#!/bin/bash
# Create Azure credentials in JSON format for Crossplane

# Load environment variables
source .env

# Create JSON credentials
cat > /tmp/azure-creds.json << EOF
{
  "clientId": "$AZURE_CLIENT_ID",
  "clientSecret": "$AZURE_CLIENT_SECRET",
  "subscriptionId": "$AZURE_SUBSCRIPTION_ID",
  "tenantId": "$AZURE_TENANT_ID"
}
EOF

# Create the secret
kubectl create secret generic azure-credentials \
  --from-file=creds=/tmp/azure-creds.json \
  -n crossplane-system \
  --dry-run=client -o yaml | kubectl apply -f -

# Clean up
rm -f /tmp/azure-creds.json

echo "Azure credentials secret created successfully!"
