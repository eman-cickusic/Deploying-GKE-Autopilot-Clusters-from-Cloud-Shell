#!/bin/bash

# Nginx Pod Deployment Script
# This script deploys nginx pods and sets up services

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install kubectl."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please run setup-cluster.sh first."
    exit 1
fi

print_status "Starting nginx deployment..."

# Create test HTML file if it doesn't exist
if [[ ! -f "html/test.html" ]]; then
    print_status "Creating test HTML file..."
    mkdir -p html
    cat > html/test.html << 'EOF'
<header><title>This is title</title></header>
Hello world
EOF
    print_success "Created html/test.html"
fi

# Deploy nginx using imperative approach
print_status "Deploying nginx using imperative approach..."
kubectl create deployment --image nginx nginx-1

print_status "Waiting for nginx pod to be ready..."
kubectl wait --for=condition=ready pod -l app=nginx-1 --timeout=300s

# Get the pod name
export my_nginx_pod=$(kubectl get pods -l app=nginx-1 -o jsonpath='{.items[0].metadata.name}')
print_status "Pod name: $my_nginx_pod"

# Copy test file to pod
print_status "Copying test.html to nginx pod..."
kubectl cp html/test.html $my_nginx_pod:/usr/share/nginx/html/test.html

# Expose the pod with LoadBalancer service
print_status "Creating LoadBalancer service..."
kubectl expose deployment nginx-1 --port 80 --type LoadBalancer --name nginx-1-service

# Deploy nginx using declarative approach
print_status "Deploying nginx using declarative approach..."
kubectl apply -f manifests/new-nginx-pod.yaml

print_status "Waiting for new-nginx pod to be ready..."
kubectl wait --for=condition=ready pod new-nginx --timeout=300s

# Copy test file to declarative pod as well
print_status "Copying test.html to new-nginx pod..."
kubectl cp html/test.html new-nginx:/usr/share/nginx/html/test.html

# Apply service for declarative pod
kubectl apply -f manifests/nginx-service.yaml

print_success "Nginx deployments completed!"

# Show deployment status
print_status "Deployment Status:"
echo ""
echo "Pods:"
kubectl get pods

echo ""
echo "Services:"
kubectl get services

echo ""
echo "Deployments:"
kubectl get deployments

# Wait for external IPs
print_status "Waiting for external IPs to be assigned..."
print_warning "This may take a few minutes..."

timeout=300
while [[ $timeout -gt 0 ]]; do
    external_ip1=$(kubectl get service nginx-1-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    external_ip2=$(kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [[ -n "$external_ip1" && "$external_ip1" != "null" && -n "$external_ip2" && "$external_ip2" != "null" ]]; then
        break
    fi
    
    echo -n "."
    sleep 10
    ((timeout-=10))
done

echo ""

if [[ -n "$external_ip1" && "$external_ip1" != "null" ]]; then
    print_success "nginx-1-service external IP: $external_ip1"
    print_status "Test with: curl http://$external_ip1/test.html"
else
    print_warning "nginx-1-service external IP still pending"
fi

if [[ -n "$external_ip2" && "$external_ip2" != "null" ]]; then
    print_success "nginx-service external IP: $external_ip2"
    print_status "Test with: curl http://$external_ip2/test.html"
else
    print_warning "nginx-service external IP still pending"
fi

# Save deployment info
cat > deployment-info.txt << EOF
Nginx Deployment Information
Generated: $(date)

Pods:
$(kubectl get pods)

Services:
$(kubectl get services)

Deployments:
$(kubectl get deployments)

Test Commands:
EOF

if [[ -n "$external_ip1" && "$external_ip1" != "null" ]]; then
    echo "curl http://$external_ip1/test.html" >> deployment-info.txt
fi

if [[ -n "$external_ip2" && "$external_ip2" != "null" ]]; then
    echo "curl http://$external_ip2/test.html" >> deployment-info.txt
fi

print_success "Deployment information saved to deployment-info.txt"

print_status "To monitor your deployments, use:"
echo "  kubectl get pods -w"
echo "  kubectl logs -f <pod-name>"
echo "  kubectl describe pod <pod-name>"

print_status "To test your deployment:"
echo "  kubectl port-forward <pod-name> 8080:80"
echo "  curl http://localhost:8080/test.html"
