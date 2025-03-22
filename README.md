# CDrive - Cloud Storage Application

CDrive is a cloud storage application that allows users to upload, store, and manage their files securely in the cloud.

## Architecture

The application follows a client-server architecture:

- **Client**: Next.js application with a modern UI for file management
- **Server**: Express.js API with Neon PostgreSQL database using Prisma ORM
- **Storage**: Files are stored using Cloudinary

## DevSecOps Pipeline

This project implements a comprehensive DevSecOps pipeline using:

### Local Development

- **Docker & Docker Compose**: Containerized development environment
  ```bash
  # Start local environment
  docker-compose up -d
  ```

### CI/CD Pipeline

- **GitHub Actions**: Automated workflows for CI/CD
  - CI Pipeline: Linting, Testing, Security Scanning
  - CD Pipeline: Building and pushing Docker images to GCR, triggering deployments
  - Terraform Pipeline: Infrastructure provisioning on GCP

- **SonarQube**: Code quality and security analysis

- **Trivy**: Container security scanning for vulnerabilities

- **Google Cloud Platform (GCP)**: Cloud infrastructure
  - Google Container Registry (GCR): Storing Docker images
  - Google Kubernetes Engine (GKE): Running Kubernetes cluster

- **ArgoCD**: GitOps for Kubernetes deployments
  - Automatically syncs the state of the cluster with the desired state in Git

### Infrastructure as Code

- **Terraform**: Managing GCP resources
  - VPC Network and Subnet
  - GKE Cluster with separate node pools
  - Service Accounts and IAM permissions
  - Google Container Registry

- **Kubernetes**: Container orchestration
  - Base manifests for different environments (dev/prod)
  - Environment variable substitution using env-config.sh
  
- **Helm Charts**: Packaging Kubernetes applications
  - Simplified deployment with parameterized values
  - Alternative to raw Kubernetes manifests

### Monitoring and Observability

- **Prometheus**: Metrics collection and storage
  - Scrapes metrics from Kubernetes, applications, and infrastructure
  - Long-term metrics storage
  - Alerting capabilities

- **Grafana**: Metrics visualization and dashboards
  - Pre-configured dashboards for Kubernetes and application metrics
  - Custom dashboards for business metrics
  - Alert visualization

## Database

This project uses **Neon PostgreSQL** - a serverless, fault-tolerant, cloud-native PostgreSQL service with:
- Autoscaling capabilities
- Branching for development and testing
- Point-in-time recovery
- No infrastructure management required

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Terraform >= 1.0.0
- Google Cloud SDK
- Kubernetes cluster (for deployment)
- kubectl and Helm CLI
- Neon PostgreSQL account

### Environment Configuration

1. Create a `.env` file based on the provided `.env.example`:
   ```bash
   cp .env.example .env
   ```

2. Update the environment variables in the `.env` file:
   - Add your Neon PostgreSQL connection string
   - Set a strong JWT secret
   - Configure the API URL for the client

### Local Development

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/cdrive.git
   cd cdrive
   ```

2. Start the local environment
   ```bash
   docker-compose up -d
   ```

3. Access the application
   - Client: http://localhost:3000
   - Server API: http://localhost:4000

### Infrastructure Deployment

1. Initialize Terraform
   ```bash
   cd terraform/gcp
   terraform init
   ```

2. Review the infrastructure plan
   ```bash
   terraform plan
   ```

3. Apply the infrastructure
   ```bash
   terraform apply
   ```

### Deployment Options

Our unified deployment script supports both Kubernetes and Helm for deploying the application and monitoring stack:

```bash
# Usage: ./scripts/deploy.sh [method] [component] [environment]
# Methods: k8s, helm
# Components: app, monitoring, all
# Environments: dev, prod, test

# Examples:

# Deploy app using Kubernetes to dev environment
./scripts/deploy.sh k8s app dev

# Deploy everything using Helm to prod environment
./scripts/deploy.sh helm all prod

# Deploy only monitoring to test environment using Kubernetes
./scripts/deploy.sh k8s monitoring test
```

### Accessing Monitoring Tools

After deploying the monitoring stack, you can access:

- **Prometheus**: http://your-domain/prometheus
- **Grafana**: http://your-domain/grafana (default credentials: admin/admin)

## Security Features

- HTTPS for all production traffic
- Containerized applications with least privileges
- Regular security scanning with Trivy
- Code quality checks with SonarQube
- JWT-based authentication
- Non-root users in containers
- Private GKE cluster with authorized networks
- Secure management of environment variables

## License

[MIT](LICENSE)