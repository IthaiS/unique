variable "project_id" { type = string }
variable "location" { type = string, default = "global" }
variable "github_repository" { type = string, default = "IthaiS/unique" }
variable "github_ref" { type = string, default = "refs/heads/main" }
variable "restrict_to_branch" { type = bool, default = true }
variable "pool_id" { type = string, default = "github-pool" }
variable "provider_id" { type = string, default = "github-provider" }
variable "service_account_id" { type = string, default = "github-deployer" }
variable "service_account_display_name" { type = string, default = "GitHub Deployer" }
variable "assign_deploy_roles" { type = bool, default = true }
