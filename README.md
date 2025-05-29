# Deploying GKE Autopilot Clusters from Cloud Shell

A comprehensive guide to building, deploying, and managing Google Kubernetes Engine (GKE) Autopilot clusters using Cloud Shell and kubectl.

## Video

https://youtu.be/tdGnPpgAJxU

## 📋 Overview

This project demonstrates how to:
- Deploy GKE Autopilot clusters using the command line
- Configure kubectl and kubeconfig files
- Deploy and manage Pods in Kubernetes
- Use Container Registry for container storage and deployment
- Inspect and troubleshoot cluster resources

## 🎯 Objectives

By following this guide, you will learn to:
- ✅ Use kubectl to build and manipulate GKE clusters
- ✅ Use kubectl and configuration files to deploy Pods
- ✅ Use Container Registry to store and deploy containers
- ✅ Connect to and inspect GKE clusters
- ✅ Deploy Pods using both imperative and declarative approaches
- ✅ Perform live troubleshooting and introspection of running Pods

## 🚀 Prerequisites

- Google Cloud Platform account with billing enabled
- Access to Google Cloud Console
- Basic understanding of Kubernetes concepts
- Familiarity with command line operations

## 📁 Project Structure

```
gke-autopilot-deployment/
├── README.md                 # This file
├── scripts/
│   ├── setup-cluster.sh      # Cluster creation script
│   ├── deploy-nginx.sh       # Pod deployment script
│   └── cleanup.sh           # Resource cleanup script
├── manifests/
│   ├── new-nginx-pod.yaml   # Pod manifest file
│   └── nginx-service.yaml   # Service manifest file
├── html/
│   └── test.html           # Sample HTML file for testing
└── docs/
    └── troubleshooting.md  # Common issues and solutions
```

## 🛠️ Setup Instructions

### Step 1: Environment Setup

1. Open Google Cloud Console and activate Cloud Shell
2. Set up environment variables:

```bash
export my_region=us-central1  # Replace with your preferred region
export my_cluster=autopilot-cluster-1
```

### Step 2: Create GKE Autopilot Cluster

Run the cluster creation script:

```bash
# Clone this repository
git clone https://github.com/yourusername/gke-autopilot-deployment.git
cd gke-autopilot-deployment

# Make scripts executable
chmod +x scripts/*.sh

# Create the cluster
./scripts/setup-cluster.sh
```

Or manually create the cluster:

```bash
gcloud container clusters create-auto $my_cluster --region $my_region
```

### Step 3: Connect to the Cluster

```bash
gcloud container clusters get-credentials $my_cluster --region $my_region
```

### Step 4: Verify Cluster Connection

```bash
kubectl cluster-info
kubectl config current-context
kubectl get nodes
```

## 📦 Deploying Applications

### Deploy Nginx Pod (Imperative Approach)

```bash
# Deploy nginx
kubectl create deployment --image nginx nginx-1

# Get pod name
export my_nginx_pod=$(kubectl get pods -l app=nginx-1 -o jsonpath='{.items[0].metadata.name}')

# Copy test file to pod
kubectl cp html/test.html $my_nginx_pod:/usr/share/nginx/html/test.html

# Expose the pod
kubectl expose pod $my_nginx_pod --port 80 --type LoadBalancer
```

### Deploy Nginx Pod (Declarative Approach)

```bash
# Apply the manifest
kubectl apply -f manifests/new-nginx-pod.yaml

# Apply the service
kubectl apply -f manifests/nginx-service.yaml
```

## 🔍 Monitoring and Troubleshooting

### View Cluster Resources

```bash
# View all pods
kubectl get pods

# View services
kubectl get services

# View resource usage
kubectl top nodes  
kubectl top pods
```

### Pod Introspection

```bash
# Describe a pod
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name> -f --timestamps

# Execute commands in pod
kubectl exec -it <pod-name> -- /bin/bash
```

### Port Forwarding for Testing

```bash
# Forward local port to pod
kubectl port-forward <pod-name> 8080:80

# Test in another terminal
curl http://localhost:8080/test.html
```

## 📝 Configuration Files

### Pod Manifest (new-nginx-pod.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: new-nginx
  labels:
    name: new-nginx
spec:
  containers:
  - name: new-nginx
    image: nginx
    ports:
    - containerPort: 80
```

### Service Manifest (nginx-service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    name: new-nginx
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

## 🧹 Cleanup

To avoid incurring charges, clean up your resources:

```bash
# Run cleanup script
./scripts/cleanup.sh

# Or manually delete resources
kubectl delete service nginx-service
kubectl delete pod new-nginx
kubectl delete deployment nginx-1
gcloud container clusters delete $my_cluster --region $my_region
```

## 📚 Key Commands Reference

| Command | Description |
|---------|-------------|
| `gcloud container clusters create-auto` | Create autopilot cluster |
| `kubectl get pods` | List all pods |
| `kubectl describe pod <pod-name>` | Get detailed pod information |
| `kubectl logs <pod-name>` | View pod logs |
| `kubectl exec -it <pod-name> -- /bin/bash` | Interactive shell in pod |
| `kubectl port-forward <pod-name> <local-port>:<pod-port>` | Forward ports |
| `kubectl apply -f <file.yaml>` | Apply configuration from file |
| `kubectl delete <resource> <name>` | Delete a resource |

## 🔧 Troubleshooting

### Common Issues

1. **Pod stuck in Pending state**
   - Check node resources: `kubectl top nodes`
   - Check events: `kubectl describe pod <pod-name>`

2. **Can't connect to cluster**
   - Verify credentials: `kubectl config current-context`
   - Re-run: `gcloud container clusters get-credentials`

3. **External IP pending**
   - Wait a few minutes for LoadBalancer provisioning
   - Check service status: `kubectl get services`

For more troubleshooting tips, see [docs/troubleshooting.md](docs/troubleshooting.md).

## 📖 Additional Resources

- [Google Cloud Kubernetes Engine Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🏷️ Tags

`kubernetes` `gke` `google-cloud` `autopilot` `cloud-shell` `kubectl` `containers` `devops`
