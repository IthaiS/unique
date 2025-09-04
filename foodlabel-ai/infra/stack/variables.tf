variable "project_id" { 
type=string }
variable "region" { type=string, default="europe-west1" }
variable "github_repository" { type=string, default="IthaiS/unique" }
variable "dev_ref" { type=string, default="refs/heads/develop" }
variable "prod_ref" { type=string, default="refs/heads/main" }
variable "pool_id" { type=string, default="github-pool" }
variable "provider_dev_id" { type=string, default="github-provider-dev" }
variable "provider_prod_id" { type=string, default="github-provider-prod" 
}
variable "deploy_sa_dev_id" { type=string, default="github-deployer-dev" }
variable "deploy_sa_prod_id" { type=string, default="github-deployer-prod" 
}
variable "ar_repository_id" { type=string, default="foodlabel-repo" }
variable "run_service_name" { type=string, default="foodlabel-backend" }
variable "create_cloud_run" { type=bool, default=true }
variable "run_image" { type=string, 
default="gcr.io/google-samples/hello-app:1.0" }
variable "runtime_sa_id" { type=string, default="foodlabel-runtime" }
