#!/bin/bash

# Install Crossplane
echo "🔧 Installing Crossplane..."

# Add Crossplane Helm repository
echo "📦 Adding Crossplane Helm repository..."
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane
echo "⚙️ Installing Crossplane in crossplane-system namespace..."
helm upgrade --install crossplane crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace \
  --wait

# Wait for Crossplane to be ready
echo "⏳ Waiting for Crossplane to be ready..."
kubectl wait --for=condition=ready pod -l app=crossplane --namespace crossplane-system --timeout=300s

# Install Azure Provider
echo "🔌 Installing Azure Provider..."
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-azure:v0.19.0
EOF

# Wait for Azure Provider to be ready
echo "⏳ Waiting for Azure Provider to be ready..."
kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-azure --timeout=300s

echo "✅ Crossplane and Azure Provider installed successfully!"

# Show installed providers
echo "📋 Installed providers:"
kubectl get providers
