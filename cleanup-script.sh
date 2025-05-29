#!/bin/bash

# GKE Autopilot Cluster Cleanup Script
# This script removes all created resources to avoid charges

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

# Load environment variables if available
if [[ -f "cluster-vars.sh" ]]; then
    source cluster-vars.sh
    print_status "Loaded environment variables from cluster-vars.sh"
fi

# Set default values if not already set
export my_region=${my_region:-"us-central1"}
export my_cluster=${my_cluster:-"autopilot-cluster-1"}

print_warning "This script will delete ALL resources created by this project!"
print_status "Cluster: $my_cluster"
print_status "Region: $my_region"

# Confirm deletion
read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleanup cancelled."
    exit 0
fi

print_status "Starting cleanup process..."

# Check if kubectl is available and cluster is accessible
if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
    print_status "Deleting Kubernetes resources..."
    
    # Delete services first (to release load balancers)
    print_status "Deleting services..."
    kubectl delete service nginx-1-service --ignore-not-found=true
    kubectl delete service nginx-service --ignore-not-found=true
    kubectl delete service nginx-nodeport-service --ignore-not-found=true
    
    # Delete pods
    print_status "Deleting pods..."
    kubectl delete pod new-nginx --ignore-not-found=true
    
    # Delete deployments
    print_status "Deleting deployments..."
    kubectl delete deployment nginx-1 --ignore-not-found=true
    
    # Wait for resources to be deleted
    print_status "Waiting for resources to be fully deleted..."
    sleep 30
    
    print_success "Kubernetes resources deleted successfully!"
else
    print_warning "kubectl not available or cluster not accessible. Skipping resource deletion."
fi

# Delete the GKE cluster
if command -v gcloud &> /dev/null; then
    print_status "Deleting GKE cluster..."
    print_warning "This may take 5-10 minutes..."
    
    if gcloud container clusters delete $my_cluster --region $my_region --quiet; then
        print_success "Cluster '$my_cluster' deleted successfully!"
    else
        print_error "Failed to delete cluster. You may need to delete it manually from the Console."
    fi
else
    print_error "gcloud CLI not found. Please delete the cluster manually."
fi

# Clean up local files (optional)
read -p "Do you want to clean up generated files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleaning up generated files..."
    
    # Remove generated files
    rm -f cluster-vars.sh
    rm -f deployment-info.txt
    rm -f ~/.kube/config.backup
    
    print_success "Generated files cleaned up!"
fi

print_success "Cleanup completed!"
print_status "Summary of actions taken:"
echo "  ✓ Deleted Kubernetes services"
echo "  ✓ Deleted Kubernetes pods"
echo "  ✓ Deleted Kubernetes deployments"
echo "  ✓ Deleted GKE cluster"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  ✓ Cleaned up generated files"
fi

print_warning "Please verify in the Google Cloud Console that all resources have been deleted."
print_status "You can also check with: gcloud container clusters list"
