# WIF Module

Creates:
- Workload Identity Pool + Provider for GitHub OIDC
- Deployer Service Account
- Basic IAM bindings

Usage:
```hcl
module "wif" {
  source = "../wif"
  project_id = "your-project"
  github_repository = "IthaiS/unique"
  github_ref = "refs/heads/main"
}
```
