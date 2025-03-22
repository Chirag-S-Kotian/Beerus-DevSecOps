output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "The name of the GKE cluster"
}

output "kubernetes_cluster_endpoint" {
  value       = "https://${google_container_cluster.primary.endpoint}"
  description = "The endpoint for the GKE cluster"
  sensitive   = true
}

output "kubernetes_cluster_ca_certificate" {
  value       = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  description = "The public certificate authority of the GKE cluster"
  sensitive   = true
}

output "gcp_network_name" {
  value       = google_compute_network.vpc_network.name
  description = "The name of the VPC network"
}

output "gcp_subnet_name" {
  value       = google_compute_subnetwork.subnet.name
  description = "The name of the VPC subnet"
}

output "gcp_service_account_email" {
  value       = google_service_account.gke_sa.email
  description = "The email of the service account used by GKE nodes"
}

output "gcr_repository_url" {
  value       = "${var.region}.gcr.io/${var.project_id}"
  description = "The URL of the GCR repository"
}