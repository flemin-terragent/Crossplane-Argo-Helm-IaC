#!/bin/bash

# Script to securely input Azure Client Secret
echo "🔐 Azure Client Secret Input"
echo "This script will help you securely add the Azure Client Secret to your .env file"
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found."
    echo "Would you like to create one from the template? (y/n)"
    read -r create_env
    if [ "$create_env" = "y" ] || [ "$create_env" = "Y" ]; then
        if [ -f ".env.template" ]; then
            cp .env.template .env
            echo "✅ .env file created from template"
        else
            echo "❌ .env.template not found"
            exit 1
        fi
    else
        echo "Please create a .env file first"
        exit 1
    fi
fi

# Load current .env file
source .env

# Display current configuration (obfuscated)
echo "📋 Current configuration:"
echo "  AZURE_CLIENT_ID: ${AZURE_CLIENT_ID}"
echo "  AZURE_TENANT_ID: ${AZURE_TENANT_ID}"
echo "  AZURE_SUBSCRIPTION_ID: ${AZURE_SUBSCRIPTION_ID}"
echo "  AZURE_CLIENT_SECRET: $([ -n "$AZURE_CLIENT_SECRET" ] && echo "[SET]" || echo "[NOT SET]")"
echo ""

# Check if client secret is already set
if [ -n "$AZURE_CLIENT_SECRET" ]; then
    echo "⚠️  Client secret is already set."
    echo "Do you want to update it? (y/n)"
    read -r update_secret
    if [ "$update_secret" != "y" ] && [ "$update_secret" != "Y" ]; then
        echo "Keeping existing client secret."
        exit 0
    fi
fi

# Prompt for client secret
echo "🔑 Please enter the Azure Client Secret:"
echo "Note: The input will be hidden for security"
read -s -p "Client Secret: " client_secret
echo ""

# Validate input
if [ -z "$client_secret" ]; then
    echo "❌ Client secret cannot be empty"
    exit 1
fi

# Update .env file
echo "💾 Updating .env file..."

# Create a temporary file
temp_file=$(mktemp)

# Copy .env to temp file, updating the client secret line
while IFS= read -r line; do
    if [[ $line == AZURE_CLIENT_SECRET=* ]]; then
        echo "AZURE_CLIENT_SECRET=$client_secret" >> "$temp_file"
    else
        echo "$line" >> "$temp_file"
    fi
done < .env

# Replace original .env file
mv "$temp_file" .env

echo "✅ Client secret updated successfully!"
echo ""
echo "🔍 Next steps:"
echo "1. Verify your configuration: make verify-secrets"
echo "2. Load secrets to Kubernetes: make load-secrets"
echo "3. Configure Azure provider: make configure-azure"
echo ""
echo "🔐 Security note: The .env file is in .gitignore and will not be committed to version control"
