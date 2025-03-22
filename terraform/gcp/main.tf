terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    bucket = "cdrive-terraform-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id

  # Enable private Google access
  private_ip_google_access = true

  # Enable flow logs for network debugging
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_name}-gke-cluster"
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  network         = google_compute_network.vpc_network.self_link
  subnetwork      = google_compute_subnetwork.subnet.self_link

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.pods_cidr
    services_ipv4_cidr_block = var.services_cidr
  }

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable Network Policy
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Set master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.subnet_cidr
      display_name = "VPC"
    }
  }

  # Enable private cluster
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_cidr
  }
}

# Node Pool for general workloads
resource "google_container_node_pool" "general" {
  name       = "${var.project_name}-general-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.general_node_count

  node_config {
    preemptible  = var.preemptible
    machine_type = var.general_machine_type
    disk_size_gb = 50

    # Google recommends custom service accounts with minimal permissions
    service_account = google_service_account.gke_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Enable Workload Identity at the node level
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      role = "general"
    }

    # No taints for general node pool
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Use regional node locations for high availability
  autoscaling {
    min_node_count = var.general_min_node_count
    max_node_count = var.general_max_node_count
  }
}

# Node Pool for monitoring workloads (Prometheus, Grafana)
resource "google_container_node_pool" "monitoring" {
  name       = "${var.project_name}-monitoring-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.monitoring_node_count

  node_config {
    preemptible  = var.preemptible
    machine_type = var.monitoring_machine_type
    disk_size_gb = 100  # More disk for monitoring data

    # Google recommends custom service accounts with minimal permissions
    service_account = google_service_account.gke_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Enable Workload Identity at the node level
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      role = "monitoring"
    }

    # Ensure monitoring workloads run on this node pool only
    taint {
      key    = "monitoring"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Service Account for GKE nodes
resource "google_service_account" "gke_sa" {
  account_id   = "${var.project_name}-gke-sa"
  display_name = "GKE Service Account"
}

# Assign minimal required roles to the service account
resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectViewer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Create a GCR repository for Docker images
resource "google_container_registry" "registry" {
  project  = var.project_id
  location = "US"  # Multi-regional
}

# Outputs
output "kubernetes_cluster_name" {
  value = google_container_cluster.primary.name
}

output "kubernetes_cluster_host" {
  value     = google_container_cluster.primary.endpoint
  sensitive = true
}

output "gcp_region" {
  value = var.region
}

output "gcp_project_id" {
  value = var.project_id
}

output "gcr_repository_url" {
  value = "${var.region}.gcr.io/${var.project_id}"
} 