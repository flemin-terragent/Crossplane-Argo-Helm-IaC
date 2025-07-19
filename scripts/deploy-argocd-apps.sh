#!/bin/bash

# Deploy ArgoCD applications with GitHub authentication
# This script sets up GitHub repository authentication and deploys all applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying ArgoCD applications with GitHub authentication...${NC}"
echo "================================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Set up GitHub repository secret
echo -e "${GREEN}Step 1: Setting up GitHub repository secret...${NC}"
"$SCRIPT_DIR/setup-github-repo-secret.sh"

# Step 2: Generate ArgoCD applications
echo -e "${GREEN}Step 2: Generating ArgoCD applications...${NC}"
"$SCRIPT_DIR/generate-argocd-apps.sh"

# Step 3: Delete existing applications to avoid conflicts
echo -e "${GREEN}Step 3: Cleaning up existing applications...${NC}"
kubectl delete application --all -n argocd --ignore-not-found=true

# Wait for cleanup
echo -e "${YELLOW}⏳ Waiting for cleanup to complete...${NC}"
sleep 10

# Step 4: Deploy applications
echo -e "${GREEN}Step 4: Deploying ArgoCD applications...${NC}"

# Deploy main applications
echo -e "${YELLOW}📦 Deploying crossplane applications...${NC}"
kubectl apply -f "$SCRIPT_DIR/../applications/crossplane-apps.yaml"

echo -e "${YELLOW}📦 Deploying azure resource group applications...${NC}"
kubectl apply -f "$SCRIPT_DIR/../applications/azure-rg-apps.yaml"

echo -e "${YELLOW}📦 Deploying development applications...${NC}"
kubectl apply -f "$SCRIPT_DIR/../applications/local-development.yaml"

# Step 5: Wait and check status
echo -e "${GREEN}Step 5: Checking application status...${NC}"
echo -e "${YELLOW}⏳ Waiting for applications to sync...${NC}"
sleep 15

# Show all applications
echo -e "${GREEN}📊 Current ArgoCD applications:${NC}"
kubectl get applications -n argocd

echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo -e "${YELLOW}💡 You can now access ArgoCD UI to monitor the applications${NC}"
echo -e "${YELLOW}🌐 ArgoCD URL: http://argocd.local${NC}"
echo -e "${YELLOW}👤 Username: admin${NC}"
echo -e "${YELLOW}🔑 Get password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d${NC}"
