variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_name" {
  description = "The project name used for resource naming"
  type        = string
  default     = "cdrive"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "CIDR range for Kubernetes pods"
  type        = string
  default     = "10.16.0.0/16"
}

variable "services_cidr" {
  description = "CIDR range for Kubernetes services"
  type        = string
  default     = "10.24.0.0/20"
}

variable "master_cidr" {
  description = "CIDR range for GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "preemptible" {
  description = "Use preemptible instances for cost savings (not recommended for production)"
  type        = bool
  default     = false
}

variable "general_node_count" {
  description = "Initial number of nodes for general workloads"
  type        = number
  default     = 1
}

variable "general_min_node_count" {
  description = "Minimum number of nodes for general workloads"
  type        = number
  default     = 1
}

variable "general_max_node_count" {
  description = "Maximum number of nodes for general workloads"
  type        = number
  default     = 5
}

variable "general_machine_type" {
  description = "Machine type for general workloads"
  type        = string
  default     = "e2-standard-2"
}

variable "monitoring_node_count" {
  description = "Initial number of nodes for monitoring workloads"
  type        = number
  default     = 1
}

variable "monitoring_machine_type" {
  description = "Machine type for monitoring workloads"
  type        = string
  default     = "e2-standard-4"
} 