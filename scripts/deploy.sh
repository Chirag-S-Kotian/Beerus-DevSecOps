#!/bin/bash

# Consolidated deployment script for CDrive
# Usage: ./scripts/deploy.sh [method] [component] [environment]
# Methods: k8s, helm
# Components: app, monitoring, all
# Environments: dev, prod, test
# Example: ./scripts/deploy.sh k8s app dev

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Show usage information
show_usage() {
  echo -e "${BOLD}Usage:${NC} $0 [method] [component] [environment]"
  echo -e "${BOLD}Methods:${NC}"
  echo "  k8s        - Deploy using Kubernetes manifests"
  echo "  helm       - Deploy using Helm charts"
  echo -e "${BOLD}Components:${NC}"
  echo "  app        - Deploy only the application (server and client)"
  echo "  monitoring - Deploy only the monitoring stack (Prometheus and Grafana)"
  echo "  all        - Deploy both application and monitoring"
  echo -e "${BOLD}Environments:${NC}"
  echo "  dev        - Development environment (default)"
  echo "  prod       - Production environment"
  echo "  test       - Test environment"
  echo -e "${BOLD}Examples:${NC}"
  echo "  $0 k8s app dev      - Deploy app to dev environment using kubectl"
  echo "  $0 helm all prod    - Deploy everything to prod environment using Helm"
  echo "  $0 k8s monitoring   - Deploy monitoring to dev environment using kubectl"
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_usage
  exit 0
fi

# Set defaults and parse arguments
METHOD=${1:-k8s}
COMPONENT=${2:-app}
ENVIRONMENT=${3:-dev}

# Validate method
if [[ "$METHOD" != "k8s" && "$METHOD" != "helm" ]]; then
  echo -e "${RED}Error:${NC} Invalid method '$METHOD'. Must be one of: k8s, helm"
  show_usage
  exit 1
fi

# Validate component
if [[ "$COMPONENT" != "app" && "$COMPONENT" != "monitoring" && "$COMPONENT" != "all" ]]; then
  echo -e "${RED}Error:${NC} Invalid component '$COMPONENT'. Must be one of: app, monitoring, all"
  show_usage
  exit 1
fi

# Check for environment file
ENV_FILE=".env"
if [ -f ".env.${ENVIRONMENT}" ]; then
  ENV_FILE=".env.${ENVIRONMENT}"
  echo -e "${BLUE}Using environment file: ${ENV_FILE}${NC}"
else
  echo -e "${YELLOW}Environment file .env.${ENVIRONMENT} not found, using default .env${NC}"
fi

# Check if the environment file exists
if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}Error:${NC} Environment file $ENV_FILE not found"
  echo "Please create one using .env.example as a template"
  exit 1
fi

echo -e "${GREEN}Starting deployment with method ${BOLD}$METHOD${NC}${GREEN}, component ${BOLD}$COMPONENT${NC}${GREEN}, environment ${BOLD}$ENVIRONMENT${NC}${GREEN}...${NC}"

# Source the environment file
source "$ENV_FILE"

# Check if kubectl is installed for k8s method
if [ "$METHOD" == "k8s" ]; then
  if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error:${NC} kubectl is not installed"
    exit 1
  fi
fi

# Check if helm is installed for helm method
if [ "$METHOD" == "helm" ]; then
  if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error:${NC} helm is not installed"
    exit 1
  fi
fi

# Create namespace if it doesn't exist
create_namespace() {
  local namespace=$1
  kubectl get namespace $namespace > /dev/null 2>&1 || kubectl create namespace $namespace
  echo -e "${GREEN}Ensured namespace ${BOLD}$namespace${NC}${GREEN} exists${NC}"
}

# Process and deploy application using kubectl
deploy_app_k8s() {
  echo -e "${BLUE}Processing application manifests...${NC}"
  
  # Create environment file for Kubernetes with appropriate image references
  cat > ".env.k8s-${ENVIRONMENT}" << EOF
DATABASE_URL=${DATABASE_URL}
JWT_SECRET=${JWT_SECRET}
NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
SERVER_IMAGE=${SERVER_IMAGE}
CLIENT_IMAGE=${CLIENT_IMAGE}
EOF

  # Process manifests with environment variables
  chmod +x scripts/env-config.sh
  ./scripts/env-config.sh "${ENVIRONMENT}" ".env.k8s-${ENVIRONMENT}"
  
  echo -e "${BLUE}Deploying application to Kubernetes...${NC}"
  create_namespace cdrive
  kubectl apply -f "k8s/processed-${ENVIRONMENT}/"
  
  echo -e "${BLUE}Waiting for deployments to be ready...${NC}"
  kubectl rollout status deployment/server -n cdrive
  kubectl rollout status deployment/client -n cdrive
  
  # Clean up temporary file
  rm -f ".env.k8s-${ENVIRONMENT}"
  
  echo -e "${GREEN}✅ Application deployed successfully${NC}"
}

# Process and deploy monitoring using kubectl
deploy_monitoring_k8s() {
  echo -e "${BLUE}Processing monitoring manifests...${NC}"
  
  # Base64 encode Grafana credentials for Kubernetes secrets
  GRAFANA_USER=${GRAFANA_ADMIN_USER:-admin}
  GRAFANA_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-admin}
  
  GRAFANA_USER_B64=$(echo -n "$GRAFANA_USER" | base64)
  GRAFANA_PASSWORD_B64=$(echo -n "$GRAFANA_PASSWORD" | base64)
  
  # Create environment file
  cat > ".env.monitoring-${ENVIRONMENT}" << EOF
GRAFANA_ADMIN_USER=$GRAFANA_USER
GRAFANA_ADMIN_PASSWORD=$GRAFANA_PASSWORD
GRAFANA_ADMIN_USER_B64=$GRAFANA_USER_B64
GRAFANA_ADMIN_PASSWORD_B64=$GRAFANA_PASSWORD_B64
EOF

  # Process manifests with environment variables
  chmod +x scripts/env-config.sh
  ./scripts/env-config.sh "monitoring" ".env.monitoring-${ENVIRONMENT}"
  
  echo -e "${BLUE}Deploying monitoring stack to Kubernetes...${NC}"
  create_namespace monitoring
  kubectl apply -f "k8s/processed-monitoring/"
  
  echo -e "${BLUE}Waiting for monitoring deployments to be ready...${NC}"
  kubectl rollout status deployment/prometheus -n monitoring
  kubectl rollout status deployment/grafana -n monitoring
  
  # Clean up temporary file
  rm -f ".env.monitoring-${ENVIRONMENT}"
  
  echo -e "${GREEN}✅ Monitoring stack deployed successfully${NC}"
}

# Deploy application using Helm
deploy_app_helm() {
  echo -e "${BLUE}Deploying application using Helm...${NC}"
  
  create_namespace cdrive
  
  # Prepare values file from environment variables
  cat > ".helm-values-${ENVIRONMENT}.yaml" << EOF
server:
  image: ${SERVER_IMAGE}
  env:
    DATABASE_URL: ${DATABASE_URL}
    JWT_SECRET: ${JWT_SECRET}

client:
  image: ${CLIENT_IMAGE}
  env:
    NEXT_PUBLIC_API_URL: ${NEXT_PUBLIC_API_URL}
EOF

  # Deploy using Helm
  helm upgrade --install cdrive ./helm/cdrive \
    --namespace cdrive \
    -f ".helm-values-${ENVIRONMENT}.yaml"
  
  # Clean up temporary file
  rm -f ".helm-values-${ENVIRONMENT}.yaml"
  
  echo -e "${GREEN}✅ Application deployed successfully with Helm${NC}"
}

# Deploy monitoring using Helm
deploy_monitoring_helm() {
  echo -e "${BLUE}Deploying monitoring stack using Helm...${NC}"
  
  create_namespace monitoring
  
  # Prepare values file for monitoring
  cat > ".helm-monitoring-values-${ENVIRONMENT}.yaml" << EOF
grafana:
  adminUser: ${GRAFANA_ADMIN_USER:-admin}
  adminPassword: ${GRAFANA_ADMIN_PASSWORD:-admin}
EOF

  # Use official Helm charts for monitoring
  # Add Helm repositories if they don't exist
  helm repo list | grep -q "prometheus-community" || helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo list | grep -q "grafana" || helm repo add grafana https://grafana.github.io/helm-charts
  helm repo update
  
  # Install Prometheus
  helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace monitoring \
    -f ".helm-monitoring-values-${ENVIRONMENT}.yaml"
  
  # Install Grafana
  helm upgrade --install grafana grafana/grafana \
    --namespace monitoring \
    -f ".helm-monitoring-values-${ENVIRONMENT}.yaml"
  
  # Clean up temporary file
  rm -f ".helm-monitoring-values-${ENVIRONMENT}.yaml"
  
  echo -e "${GREEN}✅ Monitoring stack deployed successfully with Helm${NC}"
}

# Main deployment logic
if [ "$METHOD" == "k8s" ]; then
  if [[ "$COMPONENT" == "app" || "$COMPONENT" == "all" ]]; then
    deploy_app_k8s
  fi
  
  if [[ "$COMPONENT" == "monitoring" || "$COMPONENT" == "all" ]]; then
    deploy_monitoring_k8s
  fi
elif [ "$METHOD" == "helm" ]; then
  if [[ "$COMPONENT" == "app" || "$COMPONENT" == "all" ]]; then
    deploy_app_helm
  fi
  
  if [[ "$COMPONENT" == "monitoring" || "$COMPONENT" == "all" ]]; then
    deploy_monitoring_helm
  fi
fi

echo -e "${GREEN}${BOLD}Deployment completed successfully!${NC}"

# Print access information if we can
if [ "$METHOD" == "k8s" ]; then
  if command -v minikube &> /dev/null; then
    if minikube status | grep -q "Running"; then
      MINIKUBE_IP=$(minikube ip)
      
      echo -e "${BOLD}Access URLs:${NC}"
      
      if [[ "$COMPONENT" == "app" || "$COMPONENT" == "all" ]]; then
        CLIENT_PORT=$(kubectl get svc client-service -n cdrive -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
        SERVER_PORT=$(kubectl get svc server-service -n cdrive -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
        
        if [ ! -z "$CLIENT_PORT" ]; then
          echo -e "  Client: ${BOLD}http://$MINIKUBE_IP:$CLIENT_PORT${NC}"
        fi
        if [ ! -z "$SERVER_PORT" ]; then
          echo -e "  Server API: ${BOLD}http://$MINIKUBE_IP:$SERVER_PORT${NC}"
        fi
      fi
      
      if [[ "$COMPONENT" == "monitoring" || "$COMPONENT" == "all" ]]; then
        PROMETHEUS_PORT=$(kubectl get svc prometheus-service -n monitoring -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
        GRAFANA_PORT=$(kubectl get svc grafana-service -n monitoring -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
        
        if [ ! -z "$PROMETHEUS_PORT" ]; then
          echo -e "  Prometheus: ${BOLD}http://$MINIKUBE_IP:$PROMETHEUS_PORT${NC}"
        fi
        if [ ! -z "$GRAFANA_PORT" ]; then
          echo -e "  Grafana: ${BOLD}http://$MINIKUBE_IP:$GRAFANA_PORT${NC}"
          echo -e "  Grafana credentials: ${BOLD}${GRAFANA_ADMIN_USER:-admin} / ${GRAFANA_ADMIN_PASSWORD:-admin}${NC}"
        fi
      fi
    fi
  fi
fi 