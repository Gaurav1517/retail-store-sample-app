# Retail Store Sample App — Production K8s Deployment

This directory contains a production-grade **Helm chart** for deploying the retail store sample application on Kubernetes with NGINX Ingress as the load balancer, automatic TLS via cert-manager, and stateful databases with PVCs.

---

## 📋 Prerequisites

### Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **kubectl** | Latest | Kubernetes CLI |
| **Helm** | v3+ | Package manager for Kubernetes |

### Minimum Hardware Requirements

**For testing on a single node** (kubeadm/k3s/minikube/kind), your node should have at least:

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **CPU** | **4 cores** | 8 cores |
| **Memory** | **8 GB RAM** | 16 GB RAM |
| **Disk** | 30 GB free | 50 GB free |

These numbers account for:
- The OS and Kubernetes control plane components (~1.5 GB RAM, 1 core)
- All 15+ application pods (UI, Catalog+MySQL, Cart+DynamoDB, Checkout+Redis, Orders+PostgreSQL+RabbitMQ)
- PVCs for MySQL (5 GB), PostgreSQL (5 GB), RabbitMQ (5 GB)
- A buffer for burst/peak usage

**Breakdown per service (when using `values-testing.yaml`):**

| Component | CPU Request | Mem Request | CPU Limit | Mem Limit |
|-----------|------------|------------|-----------|-----------|
| UI | 128m | 256 Mi | 500m | 512 Mi |
| Catalog | 128m | 128 Mi | 500m | 256 Mi |
| MySQL | 100m | 256 Mi | 500m | 512 Mi |
| Cart | 128m | 256 Mi | 500m | 512 Mi |
| DynamoDB | 50m | 128 Mi | 200m | 256 Mi |
| Checkout | 128m | 128 Mi | 500m | 256 Mi |
| Redis | 50m | 64 Mi | 100m | 128 Mi |
| Orders | 128m | 256 Mi | 500m | 512 Mi |
| PostgreSQL | 100m | 256 Mi | 500m | 512 Mi |
| RabbitMQ | 50m | 128 Mi | 250m | 256 Mi |
| Ingress Controller | ~100m | ~150 Mi | ~500m | ~512 Mi |
| **Total (approx)** | **~1.2 cores** | **~2.2 GB** | **~4.5 cores** | **~4.0 GB** |

> **💡 Tip:** If your node is smaller (e.g., 2-core, 4 GB RAM t3.medium/t3a.medium on AWS), use `values-testing.yaml` and manually reduce `replicaCount: 1` for everything.

---

## 📁 Directory Structure

```
k8s/
├── helm/
│   ├── Chart.yaml                    # Chart definition
│   ├── values.yaml                   # Base values (dev defaults)
│   ├── values-production.yaml        # ⭐ Production overrides (for cloud clusters)
│   ├── values-testing.yaml           # ⭐ Testing overrides (for single-node clusters)
│   └── templates/
│       ├── _helpers.tpl              # Template helpers
│       ├── namespace.yaml            # Namespace + ResourceQuota
│       ├── serviceaccount.yaml       # Service accounts
│       ├── configmaps.yaml           # ConfigMaps
│       ├── secrets.yaml              # Database secrets
│       ├── hpa.yaml                  # Horizontal Pod Autoscalers
│       ├── pdb.yaml                  # Pod Disruption Budgets
│       ├── catalog/                  # Catalog service + MySQL
│       ├── cart/                     # Cart service + DynamoDB
│       ├── checkout/                 # Checkout service + Redis
│       ├── orders/                   # Orders service + PostgreSQL + RabbitMQ
│       └── ui/                       # UI service + Ingress + cert-manager
├── deploy.sh                         # ⭐ Deployment script (Bash)
├── deploy.ps1                        # Deployment script (PowerShell)
└── README.md                         # This file
```

---

## 🚀 Deployment Options

Choose your path based on your cluster type:

| Cluster Type | Recommended Values | Load Balancer | TLS |
|-------------|-------------------|---------------|-----|
| **EKS / AKS / GKE** (cloud) | `values-production.yaml` | ✅ Auto-provisioned (NLB/ALB) | ✅ Let's Encrypt |
| **kubeadm on EC2** (single node) | `values-testing.yaml` | ⚠️ See NodePort/MetalLB notes | ❌ Skip for testing |
| **Minikube / Kind** (local) | `values-testing.yaml` | ⚠️ Use `minikube tunnel` | ❌ Skip for testing |
| **k3s** (single node) | `values-testing.yaml` | ⚠️ See NodePort/MetalLB notes | ❌ Skip for testing |

---

### Option A: Deploy on a Cloud Cluster (EKS, AKS, GKE)

This is the **production path** — it provisions a cloud Load Balancer and auto-generates Let's Encrypt SSL certificates.

#### Step 1: Configure

Edit `helm/values-production.yaml` and verify these fields:

```yaml
# Your domain (must be one you control, with DNS access)
ingress:
  hosts:
    - store.amyxjack02.shop
  tls:
    - hosts:
        - store.amyxjack02.shop
      secretName: retail-store-tls

# Your email for Let's Encrypt notifications
certManager:
  email: gaurav.cloud000@gmail.com

# Storage class (adjust for your cloud provider)
#   EKS:          gp2 or gp3
#   AKS:          managed-csi
#   GKE:          standard-rwo
#   Minikube:     standard
storageClass: gp2
```

#### Step 2: Run the deploy script

```bash
cd k8s
chmod +x deploy.sh
./deploy.sh
```

This will:
1. ✅ Install NGINX Ingress Controller (if not present)
2. ✅ Install cert-manager (if not present)
3. ✅ Deploy all services via Helm

#### Step 3: Set up DNS

After deployment, get the Load Balancer address:

```bash
# Get the external IP or hostname
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

- If the **`EXTERNAL-IP`** column shows an **IP address** → Create an **A record** in your DNS provider:
  ```
  Type: A
  Name: store
  Value: <EXTERNAL-IP>
  ```
- If it shows a **hostname** (e.g., `xxxx.elb.amazonaws.com`) → Create a **CNAME record**:
  ```
  Type: CNAME
  Name: store
  Value: <EXTERNAL-HOSTNAME>
  ```

#### Step 4: Access

Wait 5–10 minutes for DNS propagation, then visit:

```
https://store.amyxjack02.shop
```

---

### Option B: Deploy on a Single-Node Cluster (kubeadm, minikube, kind, k3s)

This is the **testing path** — reduced resource usage, no cloud LB needed.

#### Step 1: Configure

Edit `helm/values-testing.yaml` and set your storage class:

```yaml
# For each stateful service (mysql, postgresql, rabbitmq):
storageClass: ""          # ← Set to your cluster's default storage class
```

Common values:
- **kubeadm (local-path-provisioner):** `local-path` or `standard`
- **Minikube:** `standard`
- **Kind:** use `spec: {}` or install a CSI driver
- **k3s:** `local-path`

#### Step 2: Deploy

```bash
cd k8s

# Option 1: Use the deploy script (auto-installs NGINX Ingress)
chmod +x deploy.sh
./deploy.sh

# Option 2: If you want to test without cert-manager/TLS:
#   Edit deploy.sh and comment out the cert-manager section,
#   OR deploy manually (see below).
```

> ⚠️ **Note:** The `deploy.sh` uses `values-production.yaml` by default. For testing, either:
> - Edit `deploy.sh` and change `VALUES_FILE` to `./helm/values-testing.yaml`, OR
> - Run Helm manually (see manual deploy section)

#### Step 3: Access the Application

On a single-node cluster, `LoadBalancer` services will stay `<pending>` because there's no cloud LB. Use one of these alternatives:

**Option 1 — Direct NodePort access (no LoadBalancer needed):**

```bash
# Find the NodePort for the NGINX Ingress Controller
kubectl get svc -n ingress-nginx ingress-nginx-controller
# Output: 80:30779/TCP, 443:32439/TCP

# Access using any node's IP + NodePort
# (if running locally, use 127.0.0.1 or the node's private IP)
curl http://<NODE-IP>:30779
```

**Option 2 — MetalLB (on-prem LoadBalancer for kubeadm/k3s):**

```bash
# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.4/config/manifests/metallb-native.yaml

# Configure an IP pool (use an unused subnet on your network)
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.200-192.168.1.210   # ← Replace with your network range
EOF

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
EOF
```

After a minute, the `ingress-nginx-controller` service will get a LoadBalancer IP from the pool.

**Option 3 — Port forwarding (quick test):**

```bash
kubectl port-forward -n retail-store svc/retail-store-ui 8080:80
# Then open http://localhost:8080
```

**Option 4 — `minikube tunnel` (Minikube only):**

```bash
minikube tunnel
# The ingress-nginx-controller will get a local IP
```

---

### Option C: Manual Helm Deployment

```bash
# 1. Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# Wait for it to be ready
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

# 2. (Optional) Install cert-manager for TLS
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml

# Wait for all cert-manager pods (controller + webhook)
kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/component=webhook --timeout=120s

# 3. Deploy with Helm
helm upgrade --install retail-store ./helm \
  --namespace retail-store \
  --create-namespace \
  --values ./helm/values-testing.yaml \    # ← Use values-testing.yaml for single-node
  --wait \
  --timeout 10m
```

---

## 🔍 Verification

After deployment, check everything is running:

```bash
# Pods
kubectl get pods -n retail-store
# All should be Running (not Pending/CrashLoopBackOff)

# Services
kubectl get svc -n retail-store

# Ingress
kubectl get ingress -n retail-store

# PVCs
kubectl get pvc -n retail-store

# Check logs for errors
kubectl logs -n retail-store deployment/retail-store-ui -f
```

---

## ❓ Troubleshooting

### Problem: Pods stuck in `Pending` state

```
Events:
  Warning  FailedScheduling  0/1 nodes available: 1 Insufficient cpu.
```

**Cause:** Not enough CPU/RAM on your node to fit all pods.

**Fix:**
- Use `helm/values-testing.yaml` (reduced resource requests)
- Reduce replica counts: set `replicaCount: 1` for all services
- If using a small EC2 instance, upgrade to a larger type (e.g., t3.large → t3.xlarge)
- Check available resources: `kubectl describe node`

### Problem: `cert-manager` webhook error during deployment

```
Error: Internal error occurred: failed calling webhook "webhook.cert-manager.io"
```

**Cause:** cert-manager's webhook pod isn't ready when Helm tries to create the ClusterIssuer.

**Fix:**
- The updated `deploy.sh` now waits for the webhook pod. Make sure you're using the latest version.
- Or for testing, use `values-testing.yaml` which has `certManager.createClusterIssuer: false`.

### Problem: LoadBalancer stays `<pending>` on kubeadm/on-prem

```
ingress-nginx-controller   LoadBalancer   10.102.144.154   <pending>     80:30779/TCP,443:32439/TCP   37m
```

**Cause:** No cloud LB provisioner. LoadBalancer type only works on EKS/AKS/GKE or with MetalLB.

**Fix:**
- Use NodePort: `curl http://<NODE-IP>:30779`
- Install MetalLB (see Option 2 above)
- Use `kubectl port-forward` for quick testing

### Problem: Pods crash with `CrashLoopBackOff`

**Cause:** Usually a missing secret or ConfigMap, or a database that hasn't finished initializing yet.

**Fix:**
```bash
kubectl describe pod -n retail-store <pod-name>     # Check events
kubectl logs -n retail-store <pod-name>             # Check logs
```

### Problem: MySQL/PostgreSQL won't start (PVC issues)

**Cause:** StorageClass not set or not available.

**Fix:**
```bash
# Check available storage classes
kubectl get storageclass
# Update values-testing.yaml with the correct class name
```

---

## 🧹 Cleanup

```bash
# Uninstall the application
helm uninstall retail-store -n retail-store
kubectl delete namespace retail-store

# Remove NGINX Ingress Controller (optional)
kubectl delete namespace ingress-nginx

# Remove cert-manager (optional)
kubectl delete namespace cert-manager

# Verify cleanup
kubectl get all -n retail-store  # Should show "No resources found"
```

