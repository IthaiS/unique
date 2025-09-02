# FoodLabel AI — Full Consolidated Super Pack (v0.9.0)

This archive contains the mobile app, backend, infra (Terraform), GitHub Actions workflows,
docs, and robust orchestration scripts.

## TL;DR
```bash
unzip foodlabel_ai_SUPER_PACK_CONSOLIDATED_FULL_robust_*.zip -d .
bash scripts/bootstrap_all.sh
```
The bootstrap will: chmod scripts, expand sub-zips, run a self-check, and print next steps.

### Next steps (after bootstrap)
```bash
# Provision infra (requires `terraform` and Google Cloud SDK installed)
cd foodlabel-ai/infra/stack
cp terraform.tfvars.example terraform.tfvars   # set your project_id etc.
terraform init -upgrade
terraform plan -out=tfplan 
terraform apply tfplan

# Export env from TF outputs and sync to GitHub repo secrets/vars (requires `gh auth login`)
cd ../../..
./scripts/write_env_from_tf.sh
REPO=IthaiS/unique ./scripts/gh_sync_secrets.sh q

# Mobile app
cd foodlabel-ai/mobile
./scripts/bootstrap_mobile.sh
flutter pub get && flutter test
# Run pointing to Cloud Run URL from .env.ci (if present)
flutter run --dart-define=BACKEND_BASE_URL=$(grep BACKEND_BASE_URL ../infra/.env.ci | cut -d= -f2)
```
