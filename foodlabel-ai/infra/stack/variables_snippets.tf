# variables_snippets.tf — add/merge into your stack
variable "project_id" { type = string }
variable "region"     { type = string  default = "europe-west1" }
variable "service_name" { type = string default = "foodlabel-backend" }

# env selector: dev | acc | prod
variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev","acc","prod"], var.environment)
    error_message = "environment must be one of dev, acc, prod"
  }
}

locals {
  # Example per-env settings (adjust as needed)
  env_suffix        = var.environment
  db_instance_name  = "foodlabel-psql-${local.env_suffix}"
  db_name           = "foodscanner"
  db_user           = "foodlabel"
  cloud_run_name    = "${var.service_name}-${local.env_suffix}"
  region            = var.region
}
