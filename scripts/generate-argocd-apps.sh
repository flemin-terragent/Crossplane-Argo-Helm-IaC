#!/bin/bash

# Generate ArgoCD applications from templates using centralized configuration
# This script creates all ArgoCD applications with consistent repository settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Generating ArgoCD applications from templates...${NC}"
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

# Output directory
OUTPUT_DIR="$SCRIPT_DIR/../applications"
mkdir -p "$OUTPUT_DIR"

# Generate crossplane-apps.yaml
echo -e "${GREEN}📝 Generating crossplane-apps.yaml...${NC}"
cat > "$OUTPUT_DIR/crossplane-apps.yaml" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane-compositions
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${GITHUB_REPO_URL}
    targetRevision: ${TARGET_REVISION}
    path: ${CROSSPLANE_COMPOSITIONS_PATH}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${CROSSPLANE_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: azure-infrastructure
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${GITHUB_REPO_URL}
    targetRevision: ${TARGET_REVISION}
    path: ${CROSSPLANE_CLAIMS_PATH}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${AZURE_RESOURCES_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# Generate azure-rg-apps.yaml
echo -e "${GREEN}📝 Generating azure-rg-apps.yaml...${NC}"
cat > "$OUTPUT_DIR/azure-rg-apps.yaml" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane-azure-rg
  namespace: argocd
  labels:
    deployment-method: crossplane
spec:
  project: default
  source:
    repoURL: ${GITHUB_REPO_URL}
    targetRevision: ${TARGET_REVISION}
    path: ${CROSSPLANE_CLAIMS_PATH}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${AZURE_RESOURCES_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
  info:
  - name: "Description"
    value: "Deploy Azure Resource Group using Crossplane"
  - name: "Method"
    value: "Crossplane XRD/Composition"
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: terraform-azure-rg
  namespace: argocd
  labels:
    deployment-method: terraform
spec:
  project: default
  source:
    repoURL: ${GITHUB_REPO_URL}
    targetRevision: ${TARGET_REVISION}
    path: ${TERRAFORM_MANIFESTS_PATH}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${TERRAFORM_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
  info:
  - name: "Description"
    value: "Deploy Azure Resource Group using Terraform"
  - name: "Method"
    value: "Terraform Job in Kubernetes"
EOF

# Generate local-development.yaml
echo -e "${GREEN}📝 Generating local-development.yaml...${NC}"
cat > "$OUTPUT_DIR/local-development.yaml" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${GITHUB_REPO_URL}
    targetRevision: ${TARGET_REVISION}
    path: ${GUESTBOOK_PATH}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${DEFAULT_NAMESPACE}
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane-infrastructure
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${GITHUB_REPO_URL}
    targetRevision: ${TARGET_REVISION}
    path: ${HELM_GUESTBOOK_PATH}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${DEFAULT_NAMESPACE}
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
EOF

echo -e "${GREEN}✅ All ArgoCD applications generated successfully!${NC}"
echo -e "${YELLOW}📁 Applications saved to: $OUTPUT_DIR${NC}"
echo -e "${YELLOW}🔗 Repository URL: $GITHUB_REPO_URL${NC}"
echo -e "${YELLOW}🌿 Target Revision: $TARGET_REVISION${NC}"
