#!/bin/bash

echo "🔧 Setting up Local Git Repository in Kubernetes Cluster..."
echo "=========================================================="

# Create a namespace for our git server
kubectl create namespace git-server --dry-run=client -o yaml | kubectl apply -f -

# Create a ConfigMap with our repository content
echo "📦 Creating ConfigMap with repository content..."
kubectl create configmap repo-content \
  --from-file=. \
  --namespace=git-server \
  --dry-run=client -o yaml | kubectl apply -f -

# Create a simple Git server deployment in the cluster
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: git-server
  namespace: git-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: git-server
  template:
    metadata:
      labels:
        app: git-server
    spec:
      containers:
      - name: git-server
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: repo-content
          mountPath: /usr/share/nginx/html
        - name: nginx-config
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: default.conf
      volumes:
      - name: repo-content
        configMap:
          name: repo-content
      - name: nginx-config
        configMap:
          name: nginx-git-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-git-config
  namespace: git-server
data:
  default.conf: |
    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            index index.html;
            autoindex on;
        }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: git-server
  namespace: git-server
spec:
  selector:
    app: git-server
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

echo "⏳ Waiting for git server to be ready..."
kubectl wait --for=condition=available deployment/git-server -n git-server --timeout=60s

echo "✅ Git server deployed in cluster!"
echo "Service URL: http://git-server.git-server.svc.cluster.local"

# Test the service
kubectl run test-curl --rm -i --tty --image=curlimages/curl -- curl -s http://git-server.git-server.svc.cluster.local/ | head -5 || true

echo ""
echo "📋 Local Git Server Setup Complete!"
echo "You can now use: http://git-server.git-server.svc.cluster.local"
