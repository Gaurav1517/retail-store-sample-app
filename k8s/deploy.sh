#!/bin/bash
set -e

# ============================================================
# Retail Store Sample App - Production K8s Deployment Script
# ============================================================
# This script deploys the retail-store application to a Kubernetes
# cluster using Helm with production-grade configuration.
#
# Prerequisites:
#   - kubectl configured to your cluster
#   - Helm v3 installed (helm version)
#   - NGINX Ingress Controller installed in cluster
#   - cert-manager installed in cluster (for TLS)
#
# Usage:
#   chmod +x deploy.sh
#   ./deploy.sh
# ============================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  Retail Store Sample App - Production K8s Deployment${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Configuration
NAMESPACE="retail-store"
RELEASE_NAME="retail-store"
CHART_DIR="./helm"
VALUES_FILE="./helm/values-production.yaml"

# Check prerequisites
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}ERROR: kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi
echo -e "  ${GREEN}✓ kubectl found${NC}"

# Check helm
if ! command -v helm &> /dev/null; then
    echo -e "${RED}ERROR: Helm is not installed. Please install Helm v3 first.${NC}"
    echo "  Run: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    exit 1
fi
echo -e "  ${GREEN}✓ Helm found${NC}"

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}ERROR: Cannot connect to Kubernetes cluster. Check your kubeconfig.${NC}"
    exit 1
fi
echo -e "  ${GREEN}✓ Connected to cluster${NC}"

echo ""

# Install NGINX Ingress Controller if not installed
echo -e "${YELLOW}[2/6] Checking NGINX Ingress Controller...${NC}"
if kubectl get namespace ingress-nginx &> /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ NGINX Ingress Controller already installed${NC}"
else
    echo -e "  ${YELLOW}Installing NGINX Ingress Controller...${NC}"
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
    echo -e "  ${GREEN}✓ NGINX Ingress Controller installed${NC}"
    echo -e "  ${YELLOW}Waiting for Ingress Controller to be ready...${NC}"
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=120s
fi
echo ""

# Install cert-manager if not installed
echo -e "${YELLOW}[3/6] Checking cert-manager...${NC}"
if kubectl get namespace cert-manager &> /dev/null 2>&1; then
    echo -e "  ${YELLOW}cert-manager namespace exists. Checking if webhook is healthy...${NC}"
    WEBHOOK_POD=$(kubectl get pods -n cert-manager -l app=webhook -o name 2>/dev/null | head -1)
    if [ -z "$WEBHOOK_POD" ]; then
        echo -e "  ${YELLOW}Webhook pod not found. Reapplying cert-manager...${NC}"
        kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
    fi
    echo -e "  ${YELLOW}Waiting for cert-manager pods to be ready...${NC}"
    kubectl wait --namespace cert-manager \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=120s 2>/dev/null || true
    kubectl wait --namespace cert-manager \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=webhook \
      --timeout=120s
    echo -e "  ${GREEN}✓ cert-manager ready${NC}"
else
    echo -e "  ${YELLOW}Installing cert-manager...${NC}"
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
    echo -e "  ${GREEN}✓ cert-manager installed${NC}"
    echo -e "  ${YELLOW}Waiting for cert-manager to be ready...${NC}"
    kubectl wait --namespace cert-manager \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=120s
    kubectl wait --namespace cert-manager \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=webhook \
      --timeout=120s
fi
echo ""

# Helm dependency update
echo -e "${YELLOW}[4/6] Updating Helm chart...${NC}"
cd "$(dirname "$0")"

if [ ! -f "$VALUES_FILE" ]; then
    echo -e "${RED}ERROR: Values file not found: $VALUES_FILE${NC}"
    exit 1
fi

if [ ! -d "$CHART_DIR" ]; then
    echo -e "${RED}ERROR: Chart directory not found: $CHART_DIR${NC}"
    exit 1
fi

echo -e "  ${GREEN}✓ Chart files verified${NC}"
echo ""

# Deploy with Helm
echo -e "${YELLOW}[5/6] Deploying retail-store application with Helm...${NC}"
echo -e "  Release: ${RELEASE_NAME}"
echo -e "  Namespace: ${NAMESPACE}"
echo -e "  Values: ${VALUES_FILE}"
echo ""

helm upgrade --install ${RELEASE_NAME} ${CHART_DIR} \
  --namespace ${NAMESPACE} \
  --create-namespace \
  --values ${VALUES_FILE} \
  --wait \
  --timeout 10m

echo ""
echo -e "${GREEN}✓ Deployment completed successfully${NC}"
echo ""

# Show deployment status
echo -e "${YELLOW}[6/6] Deployment status:${NC}"
echo ""
echo -e "${BLUE}--- Pods ---${NC}"
kubectl get pods -n ${NAMESPACE}
echo ""
echo -e "${BLUE}--- Services ---${NC}"
kubectl get svc -n ${NAMESPACE}
echo ""
echo -e "${BLUE}--- Ingress ---${NC}"
kubectl get ingress -n ${NAMESPACE}
echo ""
echo -e "${BLUE}--- HPA ---${NC}"
kubectl get hpa -n ${NAMESPACE}
echo ""
echo -e "${BLUE}--- PVC ---${NC}"
kubectl get pvc -n ${NAMESPACE}
echo ""

# Get the Ingress URL
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
INGRESS_HOST=$(kubectl get ingress -n ${NAMESPACE} -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null || echo "")
if [ -n "$INGRESS_HOST" ]; then
    echo -e "  Access the application at:"
    echo -e "  ${GREEN}https://${INGRESS_HOST}${NC}"
    echo ""
    echo -e "  Note: DNS propagation may take a few minutes."
    echo -e "  Ensure your domain's A record points to the Ingress Controller's LB."
fi
echo ""

# Show useful commands
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  Watch pods:     ${YELLOW}kubectl get pods -n ${NAMESPACE} -w${NC}"
echo -e "  View logs:      ${YELLOW}kubectl logs -n ${NAMESPACE} deployment/retail-store-ui -f${NC}"
echo -e "  Describe pod:   ${YELLOW}kubectl describe pod -n ${NAMESPACE} <pod-name>${NC}"
echo -e "  Uninstall:      ${YELLOW}helm uninstall ${RELEASE_NAME} -n ${NAMESPACE}${NC}"
echo ""
