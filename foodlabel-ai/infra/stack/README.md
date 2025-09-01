# Infra Stack

Creates:
- WIF pool + dev/prod providers
- Deployer SAs + IAM
- Artifact Registry repo
- Secret Manager (Sentry, Slack)
- Cloud Run service (optional)
- Optional Firestore

Usage:
```bash
cd foodlabel-ai/infra/stack
cp terraform.tfvars.example terraform.tfvars
terraform init -upgrade
terraform plan
terraform apply
```
