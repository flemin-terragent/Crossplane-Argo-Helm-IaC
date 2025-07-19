#!/bin/bash

# Setup Git Server with proper configuration for ArgoCD
set -e

echo "🔧 Setting up Git Server for ArgoCD..."
echo "================================================"

# Kill existing server if running
pkill -f 'python.*8000' || true
sleep 2

# Create or update bare repository
BARE_REPO_PATH="/tmp/crossplane-argo-repo.git"
WORK_DIR="/Users/fleminpaulson/Crossplane-Argo-Helm"

echo "📁 Creating/updating bare Git repository..."
if [ ! -d "$BARE_REPO_PATH" ]; then
    git clone --bare "$WORK_DIR" "$BARE_REPO_PATH"
else
    cd "$WORK_DIR"
    git push "$BARE_REPO_PATH" master --force
fi

# Configure the bare repository
cd "$BARE_REPO_PATH"
git config http.receivepack true
git config http.uploadpack true
git config core.sharedRepository true
git config daemon.uploadpack true

# Set proper permissions
chmod -R 755 "$BARE_REPO_PATH"

# Start HTTP server with better configuration
echo "🌐 Starting Git HTTP server..."
cd "$(dirname "$BARE_REPO_PATH")"

# Create a simple Python HTTP server that serves Git repositories
python3 -c "
import http.server
import socketserver
import os
import subprocess
import threading
import time

PORT = 8000

class GitHTTPHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Handle Git HTTP requests
        if self.path.startswith('/crossplane-argo-repo.git'):
            # Set proper headers for Git
            self.send_response(200)
            self.send_header('Content-Type', 'application/x-git-upload-pack-advertisement')
            self.send_header('Cache-Control', 'no-cache, max-age=0, must-revalidate')
            self.end_headers()
            
            # Handle Git smart HTTP protocol
            if 'git-upload-pack' in self.path:
                process = subprocess.Popen(
                    ['git', 'upload-pack', '--stateless-rpc', '--advertise-refs', 'crossplane-argo-repo.git'],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    cwd='/tmp'
                )
                output, error = process.communicate()
                self.wfile.write(output)
                return
        
        # Default handler for other requests
        super().do_GET()

    def do_POST(self):
        # Handle Git push requests
        if self.path.startswith('/crossplane-argo-repo.git'):
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            
            if 'git-upload-pack' in self.path:
                process = subprocess.Popen(
                    ['git', 'upload-pack', '--stateless-rpc', 'crossplane-argo-repo.git'],
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    cwd='/tmp'
                )
                output, error = process.communicate(input=post_data)
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/x-git-upload-pack-result')
                self.end_headers()
                self.wfile.write(output)
                return
        
        # Default handler
        super().do_POST()

    def log_message(self, format, *args):
        print(f'[{time.strftime(\"%Y-%m-%d %H:%M:%S\")}] {format % args}')

# Start the server
with socketserver.TCPServer(('', PORT), GitHTTPHandler) as httpd:
    print(f'Git HTTP server started on port {PORT}')
    print(f'Repository URL: http://localhost:{PORT}/crossplane-argo-repo.git')
    print(f'PID: {os.getpid()}')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('Server stopped')
" > /tmp/git-server.log 2>&1 &

SERVER_PID=$!
sleep 3

# Test the server
echo "🧪 Testing Git server..."
if curl -s -I http://localhost:8000/crossplane-argo-repo.git > /dev/null 2>&1; then
    echo "✅ Git server is accessible!"
    echo "📋 Git Server Setup Complete!"
    echo "Repository URL: http://host.docker.internal:8000/crossplane-argo-repo.git"
    echo "Server PID: $SERVER_PID"
    echo "Server Log: /tmp/git-server.log"
    echo ""
    echo "💡 To stop the server later:"
    echo "   kill $SERVER_PID"
    echo "   or: pkill -f 'python.*8000'"
else
    echo "❌ Git server is not accessible!"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi
