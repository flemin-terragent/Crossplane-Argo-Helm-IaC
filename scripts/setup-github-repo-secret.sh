#!/bin/bash

# Setup GitHub repository secret for ArgoCD
# This script creates the necessary secrets for ArgoCD to access private GitHub repositories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔐 Setting up GitHub repository secret for ArgoCD...${NC}"
echo "================================================"

# Load repository configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../argocd/config/repository-config.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Source the configuration
source "$CONFIG_FILE"

# Validate required variables
if [ -z "$GITHUB_REPO_URL" ] || [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ Required variables not set in configuration file${NC}"
    exit 1
fi

echo -e "${YELLOW}📝 Repository URL: $GITHUB_REPO_URL${NC}"
echo -e "${YELLOW}👤 Username: $GITHUB_USERNAME${NC}"
echo -e "${YELLOW}🔑 Token: ${GITHUB_TOKEN:0:12}...${NC}"

# Create ArgoCD repository secret
echo -e "${GREEN}🔧 Creating ArgoCD repository secret...${NC}"

# Delete existing secret if it exists
kubectl delete secret argocd-repo-secret -n argocd --ignore-not-found=true

# Create new secret
kubectl create secret generic argocd-repo-secret \
    -n argocd \
    --from-literal=type=git \
    --from-literal=url="$GITHUB_REPO_URL" \
    --from-literal=username="$GITHUB_USERNAME" \
    --from-literal=password="$GITHUB_TOKEN"

# Label the secret so ArgoCD can find it
kubectl label secret argocd-repo-secret -n argocd argocd.argoproj.io/secret-type=repository

echo -e "${GREEN}✅ ArgoCD repository secret created successfully!${NC}"

# Verify secret
echo -e "${GREEN}🔍 Verifying secret...${NC}"
kubectl get secret argocd-repo-secret -n argocd -o yaml | grep -E "(url|username)" | head -2

echo -e "${GREEN}🎉 GitHub repository authentication setup complete!${NC}"
echo -e "${YELLOW}💡 ArgoCD should now be able to access the private repository${NC}"
