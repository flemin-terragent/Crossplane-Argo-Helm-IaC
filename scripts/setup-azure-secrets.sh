#!/bin/bash

# Copy Azure secrets from crossplane-system to terraform namespace
# This script ensures Terraform applications can access Azure credentials

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔐 Setting up Azure secrets for Terraform namespace...${NC}"
echo "================================================"

# Create terraform namespace if it doesn't exist
echo -e "${YELLOW}📁 Creating terraform namespace...${NC}"
kubectl create namespace terraform --dry-run=client -o yaml | kubectl apply -f -

# Get the existing azure-secret from crossplane-system namespace
echo -e "${YELLOW}📋 Copying Azure secrets from crossplane-system...${NC}"

# Extract the secret data
CLIENT_ID=$(kubectl get secret azure-secret -n crossplane-system -o jsonpath='{.data.clientId}')
CLIENT_SECRET=$(kubectl get secret azure-secret -n crossplane-system -o jsonpath='{.data.clientSecret}')
SUBSCRIPTION_ID=$(kubectl get secret azure-secret -n crossplane-system -o jsonpath='{.data.subscriptionId}')
TENANT_ID=$(kubectl get secret azure-secret -n crossplane-system -o jsonpath='{.data.tenantId}')

# Validate that we got the data
if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ] || [ -z "$SUBSCRIPTION_ID" ] || [ -z "$TENANT_ID" ]; then
    echo -e "${RED}❌ Failed to extract Azure credentials from crossplane-system namespace${NC}"
    exit 1
fi

# Delete existing secret if it exists
kubectl delete secret azure-secret -n terraform --ignore-not-found=true

# Create the azure-secret in terraform namespace
echo -e "${YELLOW}🔧 Creating azure-secret in terraform namespace...${NC}"
kubectl create secret generic azure-secret \
    -n terraform \
    --from-literal=clientId="$(echo $CLIENT_ID | base64 -d)" \
    --from-literal=clientSecret="$(echo $CLIENT_SECRET | base64 -d)" \
    --from-literal=subscriptionId="$(echo $SUBSCRIPTION_ID | base64 -d)" \
    --from-literal=tenantId="$(echo $TENANT_ID | base64 -d)"

# Also create the azure-secret in azure-resources namespace if it doesn't exist
echo -e "${YELLOW}🔧 Ensuring azure-secret exists in azure-resources namespace...${NC}"
kubectl create namespace azure-resources --dry-run=client -o yaml | kubectl apply -f -

kubectl delete secret azure-secret -n azure-resources --ignore-not-found=true
kubectl create secret generic azure-secret \
    -n azure-resources \
    --from-literal=clientId="$(echo $CLIENT_ID | base64 -d)" \
    --from-literal=clientSecret="$(echo $CLIENT_SECRET | base64 -d)" \
    --from-literal=subscriptionId="$(echo $SUBSCRIPTION_ID | base64 -d)" \
    --from-literal=tenantId="$(echo $TENANT_ID | base64 -d)"

# Verify the secrets
echo -e "${GREEN}🔍 Verifying secrets...${NC}"
echo "Terraform namespace:"
kubectl get secret azure-secret -n terraform -o jsonpath='{.data}' | jq -r 'keys[]'

echo "Azure-resources namespace:"
kubectl get secret azure-secret -n azure-resources -o jsonpath='{.data}' | jq -r 'keys[]'

echo -e "${GREEN}✅ Azure secrets setup complete!${NC}"
echo -e "${YELLOW}📝 Secrets are now available in:${NC}"
echo -e "${YELLOW}   - terraform namespace${NC}"
echo -e "${YELLOW}   - azure-resources namespace${NC}"
echo -e "${YELLOW}   - crossplane-system namespace (original)${NC}"
