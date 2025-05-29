#!/bin/bash

# GKE Autopilot Cluster Setup Script
# This script creates a GKE Autopilot cluster and configures kubectl

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

# Default values
DEFAULT_REGION="us-central1"
DEFAULT_CLUSTER_NAME="autopilot-cluster-1"

# Set environment variables
export my_region=${MY_REGION:-$DEFAULT_REGION}
export my_cluster=${MY_CLUSTER:-$DEFAULT_CLUSTER_NAME}

print_status "Starting GKE Autopilot cluster setup..."
print_status "Region: $my_region"
print_status "Cluster name: $my_cluster"

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI not found. Please install Google Cloud SDK."
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_error "No active gcloud authentication found. Please run 'gcloud auth login'"
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project)
if [[ -z "$PROJECT_ID" ]]; then
    print_error "No project set. Please run 'gcloud config set project PROJECT_ID'"
    exit 1
fi

print_status "Using project: $PROJECT_ID"

# Enable required APIs
print_status "Enabling required APIs..."
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com

# Create the autopilot cluster
print_status "Creating GKE Autopilot cluster..."
print_warning "This may take 5-10 minutes..."

if gcloud container clusters create-auto $my_cluster --region $my_region; then
    print_success "Cluster '$my_cluster' created successfully!"
else
    print_error "Failed to create cluster"
    exit 1
fi

# Configure kubectl
print_status "Configuring kubectl..."
if gcloud container clusters get-credentials $my_cluster --region $my_region; then
    print_success "kubectl configured successfully!"
else
    print_error "Failed to configure kubectl"
    exit 1
fi

# Enable bash completion for kubectl
print_status "Setting up kubectl bash completion..."
source <(kubectl completion bash)

# Verify cluster connection
print_status "Verifying cluster connection..."
echo "Cluster info:"
kubectl cluster-info

echo ""
echo "Current context:"
kubectl config current-context

echo ""
echo "Available nodes:"
kubectl get nodes

print_success "GKE Autopilot cluster setup completed!"
print_status "You can now deploy applications to your cluster."

# Export variables for current session
echo ""
print_status "Environment variables set:"
echo "export my_region=$my_region"
echo "export my_cluster=$my_cluster"

# Save variables to a file for future sessions
cat > cluster-vars.sh << EOF
#!/bin/bash
# GKE Cluster Environment Variables
export my_region=$my_region
export my_cluster=$my_cluster
export PROJECT_ID=$PROJECT_ID
EOF

print_success "Environment variables saved to cluster-vars.sh"
print_status "Source this file in new sessions: source cluster-vars.sh"
