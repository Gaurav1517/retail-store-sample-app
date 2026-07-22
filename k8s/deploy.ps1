# ============================================================
# Retail Store Sample App - Production K8s Deployment Script
# ============================================================
# PowerShell version
#
# Prerequisites:
#   - kubectl configured to your cluster
#   - Helm v3 installed
#   - NGINX Ingress Controller installed
#   - cert-manager installed (for TLS)
#
# Usage:
#   .\deploy.ps1
# ============================================================

$ErrorActionPreference = 'Stop'

Write-Host '============================================================' -ForegroundColor Blue
Write-Host '  Retail Store Sample App - Production K8s Deployment' -ForegroundColor Blue
Write-Host '============================================================' -ForegroundColor Blue
Write-Host ''

$NAMESPACE = 'retail-store'
$RELEASE_NAME = 'retail-store'
$CHART_DIR = Join-Path $PSScriptRoot 'helm'
$VALUES_FILE = Join-Path $PSScriptRoot 'helm/values-production.yaml'

Write-Host '[1/6] Checking prerequisites...' -ForegroundColor Yellow

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host 'ERROR: kubectl is not installed. Please install kubectl first.' -ForegroundColor Red
    exit 1
}
Write-Host '  ✓ kubectl found' -ForegroundColor Green

if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host 'ERROR: Helm is not installed. Please install Helm v3 first.' -ForegroundColor Red
    exit 1
}
Write-Host '  ✓ Helm found' -ForegroundColor Green

try { kubectl cluster-info 2>$null | Out-Null } catch { }
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ERROR: Cannot connect to Kubernetes cluster. Check your kubeconfig.' -ForegroundColor Red
    exit 1
}
Write-Host '  ✓ Connected to cluster' -ForegroundColor Green

Write-Host ''
Write-Host '[2/6] Checking NGINX Ingress Controller...' -ForegroundColor Yellow
$ingressNs = kubectl get namespace ingress-nginx -o name --ignore-not-found
if ($ingressNs) {
    Write-Host '  ✓ NGINX Ingress Controller already installed' -ForegroundColor Green
}
else {
    Write-Host '  Installing NGINX Ingress Controller...' -ForegroundColor Yellow
    kubectl apply -f 'https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml'
    Write-Host '  ✓ NGINX Ingress Controller installed' -ForegroundColor Green
    Write-Host '  Waiting for Ingress Controller to be ready...' -ForegroundColor Yellow
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
}
Write-Host ''

Write-Host '[3/6] Checking cert-manager...' -ForegroundColor Yellow
$certNs = kubectl get namespace cert-manager -o name --ignore-not-found
if ($certNs) {
    Write-Host '  ✓ cert-manager already installed' -ForegroundColor Green
}
else {
    Write-Host '  Installing cert-manager...' -ForegroundColor Yellow
    kubectl apply -f 'https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml'
    Write-Host '  ✓ cert-manager installed' -ForegroundColor Green
    Write-Host '  Waiting for cert-manager to be ready...' -ForegroundColor Yellow
    kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
}
Write-Host ''

Write-Host '[4/6] Verifying Helm chart...' -ForegroundColor Yellow
if (-not (Test-Path $VALUES_FILE)) {
    Write-Host "ERROR: Values file not found: $VALUES_FILE" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $CHART_DIR)) {
    Write-Host "ERROR: Chart directory not found: $CHART_DIR" -ForegroundColor Red
    exit 1
}
Write-Host '  ✓ Chart files verified' -ForegroundColor Green
Write-Host ''

Write-Host '[5/6] Deploying retail-store application with Helm...' -ForegroundColor Yellow
Write-Host "  Release: $RELEASE_NAME"
Write-Host "  Namespace: $NAMESPACE"
Write-Host "  Values: $VALUES_FILE"
Write-Host ''

helm upgrade --install $RELEASE_NAME $CHART_DIR --namespace $NAMESPACE --create-namespace --values $VALUES_FILE --wait --timeout 10m

Write-Host ''
Write-Host '✓ Deployment completed successfully' -ForegroundColor Green
Write-Host ''

Write-Host '[6/6] Deployment status:' -ForegroundColor Yellow
Write-Host ''
Write-Host '--- Pods ---' -ForegroundColor Blue
kubectl get pods -n $NAMESPACE
Write-Host ''
Write-Host '--- Services ---' -ForegroundColor Blue
kubectl get svc -n $NAMESPACE
Write-Host ''
Write-Host '--- Ingress ---' -ForegroundColor Blue
kubectl get ingress -n $NAMESPACE
Write-Host ''
Write-Host '--- HPA ---' -ForegroundColor Blue
kubectl get hpa -n $NAMESPACE
Write-Host ''
Write-Host '--- PVC ---' -ForegroundColor Blue
kubectl get pvc -n $NAMESPACE
Write-Host ''

Write-Host '============================================================' -ForegroundColor Blue
Write-Host '  Deployment Complete!' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Blue
Write-Host ''

try { $ingressHost = kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].spec.rules[0].host}' 2>$null } catch { $ingressHost = $null }
if ($ingressHost) {
    Write-Host '  Access the application at:'
    Write-Host "  https://$ingressHost" -ForegroundColor Green
    Write-Host ''
    Write-Host '  Note: DNS propagation may take a few minutes.'
    Write-Host '  Ensure your domain''s A record points to the Ingress Controller''s LB.'
}
Write-Host ''

Write-Host 'Useful commands:' -ForegroundColor Blue
Write-Host "  Watch pods:     kubectl get pods -n $NAMESPACE -w"
Write-Host "  View logs:      kubectl logs -n $NAMESPACE deployment/retail-store-ui -f"
Write-Host "  Describe pod:   kubectl describe pod -n $NAMESPACE <pod-name>"
Write-Host "  Uninstall:      helm uninstall $RELEASE_NAME -n $NAMESPACE"
Write-Host ''
