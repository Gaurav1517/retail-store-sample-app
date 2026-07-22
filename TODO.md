# Deployment Fix Plan ✅

## 1. ✅ Fix cert-manager webhook issue
- ✅ Updated `deploy.sh` to wait for webhook pod before proceeding
- ✅ Updated `deploy.ps1` to wait for webhook pod

## 2. ✅ Update values-production.yaml with actual domain and email
- ✅ Domain: `store.amyxjack02.shop`
- ✅ Email: `gaurav.cloud000@gmail.com`
- ✅ Added comment pointing to values-testing.yaml for single-node clusters

## 3. ✅ Create values-testing.yaml for single-node / testing clusters
- ✅ Reduced replica counts (1 everywhere)
- ✅ Reduced CPU/memory requests (roughly halved)
- ✅ Reduced PVC sizes (10Gi → 5Gi)
- ✅ Disabled HPA and PDB
- ✅ Disabled cert-manager (no TLS needed for testing)
- ✅ Kept same domain/email as production

## 4. ✅ Rewrite k8s/README.md with comprehensive deployment guide
- ✅ Hardware requirements table (min/recommended)
- ✅ Resource breakdown per service
- ✅ Three deployment paths (Cloud, Single-Node, Manual)
- ✅ DNS setup instructions
- ✅ LoadBalancer troubleshooting (NodePort, MetalLB, port-forward, minikube tunnel)
- ✅ Troubleshooting section for common issues
- ✅ Cleanup instructions

## 5. ✅ Update deploy.sh to support VALUES_FILE override via env var
- ✅ Added `VALUES_FILE_OVERRIDE` env var support

## 6. ⬜ [YOUR ACTION] Push to GitHub and deploy on K8s
```bash
# For single-node kubeadm (your current setup):
cd k8s
VALUES_FILE_OVERRIDE=./helm/values-testing.yaml ./deploy.sh

# Or manually without cert-manager:
helm upgrade --install retail-store ./helm \
  --namespace retail-store \
  --create-namespace \
  --values ./helm/values-testing.yaml \
  --wait --timeout 10m
```



