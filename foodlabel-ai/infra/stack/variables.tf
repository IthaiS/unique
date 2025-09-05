variable "project_id" {
  type = string
}

variable "pool_id" {
  type = string
}

variable "provider_dev_id" {
  type = string
}

variable "provider_prod_id" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "dev_ref" {
  type = string
}

variable "prod_ref" {
  type = string
}

variable "deploy_sa_dev_id" {
  type    = string
  default = "github-deployer-dev"
}

variable "deploy_sa_prod_id" {
  type    = string
  default = "github-deployer-prod"
}

variable "region" {
  type = string
}

variable "ar_repository_id" {
  type = string
}

variable "runtime_sa_id" {
  type = string
}

variable "create_cloud_run" {
  type    = bool
  default = false
}

variable "run_service_name" {
  type = string
}

variable "run_image" {
  type = string
}