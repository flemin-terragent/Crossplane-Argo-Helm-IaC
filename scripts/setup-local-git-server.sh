#!/bin/bash

echo "🔧 Setting up Local Git Repository for ArgoCD..."
echo "================================================"

# Create a bare repository for ArgoCD to access
REPO_DIR="/tmp/crossplane-argo-repo.git"
CURRENT_DIR=$(pwd)

echo "📁 Creating bare Git repository at $REPO_DIR..."
if [ -d "$REPO_DIR" ]; then
    rm -rf "$REPO_DIR"
fi

# Create bare repository
git clone --bare "$CURRENT_DIR" "$REPO_DIR"

echo "🔄 Updating the bare repository..."
cd "$REPO_DIR"
git --bare update-server-info

# Start a simple HTTP server for the Git repository
echo "🌐 Starting Git HTTP server..."
cd "/tmp"

# Kill any existing server on port 8000
pkill -f "python.*8000" 2>/dev/null || true
pkill -f "python3.*8000" 2>/dev/null || true

# Start HTTP server in background
nohup python3 -m http.server 8000 > /tmp/git-server.log 2>&1 &
SERVER_PID=$!

echo "Git server started with PID: $SERVER_PID"
echo "Repository URL: http://localhost:8000/crossplane-argo-repo.git"

# Wait a moment for server to start
sleep 2

# Test if server is accessible
if curl -s "http://localhost:8000/crossplane-argo-repo.git/HEAD" > /dev/null; then
    echo "✅ Git server is accessible!"
else
    echo "❌ Git server is not accessible. Checking..."
    ps aux | grep python | grep 8000 || echo "Server not running"
fi

echo ""
echo "📋 Git Repository Setup Complete!"
echo "Repository URL: http://localhost:8000/crossplane-argo-repo.git"
echo "Server Log: /tmp/git-server.log"
echo ""
echo "💡 To stop the server later:"
echo "   pkill -f 'python.*8000'"

cd "$CURRENT_DIR"
