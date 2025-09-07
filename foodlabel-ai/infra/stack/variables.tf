# ------------------------------
# Core project / region
# ------------------------------
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default region for resources"
  type        = string
  default     = "europe-west1"
}

# ------------------------------
# Workload Identity Federation (WIF) / CI
# ------------------------------
variable "pool_id" {
  description = "WIF pool ID (e.g., github-pool)"
  type        = string
}

variable "provider_dev_id" {
  description = "WIF provider ID for dev (e.g., github-dev)"
  type        = string
}

variable "provider_prod_id" {
  description = "WIF provider ID for prod (e.g., github-prod)"
  type        = string
}

variable "github_repository" {
  description = "GitHub org/repo (e.g., myorg/myrepo) used in attribute conditions"
  type        = string
}

variable "dev_ref" {
  description = "Git ref for dev deployments (e.g., refs/heads/main)"
  type        = string
}

variable "prod_ref" {
  description = "Git ref for prod deployments (e.g., refs/tags/v*)"
  type        = string
}

variable "deploy_sa_dev_id" {
  description = "Service account ID for dev deployer"
  type        = string
  default     = "github-deployer-dev"
}

variable "deploy_sa_prod_id" {
  description = "Service account ID for prod deployer"
  type        = string
  default     = "github-deployer-prod"
}

# NOTE: This flag is not used directly in lifecycle.prevent_destroy (Terraform limitation),
# but kept here if you want to toggle behavior in the future.
variable "protect_identities" {
  description = "(Informational) Keep WIF pool guarded from destroy"
  type        = bool
  default     = true
}

# ------------------------------
# Artifact Registry / Runtime SA
# ------------------------------
variable "ar_repository_id" {
  description = "Artifact Registry repository ID (Docker)"
  type        = string
}

variable "runtime_sa_id" {
  description = "Service account ID for the running Cloud Run service"
  type        = string
}

# ------------------------------
# Cloud Run
# ------------------------------
variable "create_cloud_run" {
  description = "Create Cloud Run service"
  type        = bool
  default     = false
}

variable "run_service_name" {
  description = "Cloud Run service name"
  type        = string
}

variable "run_image" {
  description = "Full image reference for Cloud Run (e.g., REGION-docker.pkg.dev/PROJECT/REPO/IMAGE:TAG)"
  type        = string
}

# ------------------------------
# Cloud SQL (Postgres)
# ------------------------------
variable "db_instance_name" {
  description = "Cloud SQL instance name"
  type        = string
  default     = "foodscanner-pg"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "foodscanner"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "foodscanner"
}

variable "authorized_cidr" {
  description = "CIDR allowed to reach Cloud SQL public IP (dev convenience)"
  type        = string
  default     = "0.0.0.0/0"
}
