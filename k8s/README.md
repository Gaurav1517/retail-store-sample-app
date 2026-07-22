# Retail Store Sample App - Production K8s Deployment

This directory contains a production-grade **Helm chart** for deploying the retail store sample application on Kubernetes with Ingress (NGINX) as the load balancer.

## 📁 Directory Structure

```
k8s/
├── helm/
│   ├── Chart.yaml                    # Chart definition
│   ├── values.yaml                   # Base values (sensible defaults)
│   ├── values-production.yaml        # Production overrides (PVCs, Ingress, TLS, HPA)
│   └── templates/
│       ├── _helpers.tpl              # Template helpers
│       ├── namespace.yaml            # Namespace + ResourceQuota
│       ├── serviceaccount.yaml       # Service accounts for all services
│       ├── configmaps.yaml           # ConfigMaps for all services
│       ├── secrets.yaml              # Secrets for databases
│       ├── hpa.yaml                  # Horizontal Pod Autoscalers
│       ├── pdb.yaml                  # Pod Disruption Budgets
│       ├── catalog/                  # Catalog service + MySQL
│       ├── cart/                     # Cart service + DynamoDB
│       ├── checkout/                 # Checkout service + Redis
│       ├── orders/                   # Orders service + PostgreSQL + RabbitMQ
│       └── ui/                       # UI service + Ingress + cert-manager
├── deploy.sh                         # Deployment script (Bash)
├── deploy.ps1                        # Deployment script (PowerShell)
└── README.md                         # This file
```

## 🚀 Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| **kubectl** | Latest | Kubernetes CLI |
| **Helm** | v3+ | Package manager for Kubernetes |
| **NGINX Ingress Controller** | v1.10.0+ | Ingress / Load Balancer |
| **cert-manager** | v1.14.4+ | Automatic TLS certificates |

### Verify Prerequisites

```bash
kubectl version --client
helm version
```

## 🎯 Production Features

| Feature | Implementation |
|---------|---------------|
| **Namespace Isolation** | Dedicated `retail-store` namespace with ResourceQuota |
| **Ingress (Load Balancer)** | NGINX Ingress Controller with TLS via cert-manager |
| **Stateful Databases** | MySQL (10Gi PVC), PostgreSQL (10Gi PVC), RabbitMQ (10Gi PVC) |
| **Ephemeral Databases** | DynamoDB Local, Redis (for development/testing) |
| **Horizontal Pod Autoscaler** | CPU-based autoscaling for all services |
| **Pod Disruption Budget** | Ensures high availability during node maintenance |
| **Security Contexts** | Read-only root filesystem, non-root user, capability drop |
| **Resource Limits** | CPU/Memory requests and limits for all containers |
| **Readiness Probes** | HTTP health checks for all services |
| **Prometheus Metrics** | Metrics annotations for monitoring |
| **Zero-Downtime Updates** | RollingUpdate strategy with maxUnavailable=1 |

## 🛠 Deployment

### 1. Configure Production Values

Edit `helm/values-production.yaml` and replace these placeholders:

```yaml
# Your domain name
hosts:
  - retail-store.yourdomain.com   # → your actual domain
tls:
  - hosts:
      - retail-store.yourdomain.com
    secretName: retail-store-tls

# Your email for Let's Encrypt
certManager:
  email: your-email@example.com   # → your email

# Your storage class (adjust per cluster)
storageClass: gp2   # EKS: gp2, Minikube: standard, AKS: managed-csi
```

### 2. Deploy (Option A: Bash)

```bash
cd k8s
chmod +x deploy.sh
./deploy.sh
```

### 3. Deploy (Option B: PowerShell)

```powershell
cd k8s
.\deploy.ps1
```

### 4. Deploy (Option C: Manual Helm)

```bash
# Install NGINX Ingress Controller (if not installed)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# Install cert-manager (if not installed)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml

# Deploy the application
helm upgrade --install retail-store ./helm \
  --namespace retail-store \
  --create-namespace \
  --values ./helm/values-production.yaml \
  --wait \
  --timeout 10m
```

## 📊 Verification

After deployment, verify the resources:

```bash
# Check pods
kubectl get pods -n retail-store

# Check services
kubectl get svc -n retail-store

# Check ingress
kubectl get ingress -n retail-store

# Check HPA
kubectl get hpa -n retail-store

# Check PVCs
kubectl get pvc -n retail-store

# Check logs
kubectl logs -n retail-store deployment/retail-store-ui -f
```

## 🔄 Architecture

```
                         ┌──────────────┐
                         │   Ingress    │ (NGINX - Load Balancer)
                         │  (TLS/HTTPS) │
                         └──────┬───────┘
                                │
                         ┌──────▼───────┐
                         │   UI:8080   │
                         └──────┬───────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
  ┌─────▼──────┐         ┌─────▼──────┐          ┌─────▼──────┐
  │  Catalog   │         │   Cart     │          │  Checkout  │
  │   :8080    │         │   :8080    │          │   :8080    │
  └─────┬──────┘         └─────┬──────┘          └─────┬──────┘
        │                      │                       │
  ┌─────▼──────┐         ┌─────▼──────┐          ┌─────▼──────┐
  │   MySQL    │         │  DynamoDB  │          │   Redis    │
  │    PVC     │         │  (Local)   │          │  (Local)   │
  └────────────┘         └────────────┘          └────────────┘
                                │
                          ┌─────▼──────┐
                          │   Orders   │
                          │   :8080    │
                          └─────┬──────┘
                          ┌─────┴──────┐
                          │ PostgreSQL │
                          │    PVC     │
                          │ + RabbitMQ │
                          │    PVC     │
                          └────────────┘
```

## 🧹 Cleanup

```bash
# Uninstall the application
helm uninstall retail-store -n retail-store

# Delete the namespace (removes all resources)
kubectl delete namespace retail-store

# Remove NGINX Ingress Controller (optional)
kubectl delete namespace ingress-nginx

# Remove cert-manager (optional)
kubectl delete namespace cert-manager
```

## ⚠️ Notes

1. **DynamoDB Local & Redis** are ephemeral (no PVC). In production, replace with AWS DynamoDB and ElastiCache.
2. **MySQL, PostgreSQL, RabbitMQ** use PVCs. Data persists across pod restarts.
3. Update `storageClass` in `values-production.yaml` based on your cluster:
   - **EKS**: `gp2` or `gp3`
   - **Minikube**: `standard`
   - **AKS**: `managed-csi`
   - **GKE**: `standard-rwo`
4. Ensure your domain's DNS A-record points to the Ingress Controller's Load Balancer IP/Hostname.
5. Let's Encrypt certificates auto-renew. No manual intervention needed.
