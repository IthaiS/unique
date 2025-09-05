# Terraform Teardown (Guard & Deletion Protection Aware)

This package contains a helper script for safely tearing down your FoodScanner GCP project with Terraform.

## Files
- `tf_teardown_guarded.sh` — the main script

## What it handles
- **Safe order** for your stack:
  1. Cloud Run services
  2. Workload Identity Federation (WIF) service account bindings
  3. WIF providers
  4. WIF pool
  5. Service accounts
  6. Artifact Registry repository
  7. Final full destroy (optional)
- Detects **`lifecycle.prevent_destroy = true`** (any resource).
- Detects **`deletion_protection = true`** (Cloud Run v2 service).
- By default: **respects** both protections (won’t apply a plan that would fail).
- Optional `PATCH_GUARDS=1`: temporarily sets both to `false`, applies, then **restores** your files.
  - For Cloud Run error “**cannot destroy service without setting deletion_protection=false and running `terraform apply`**”, this script can patch that for you when `PATCH_GUARDS=1`.

## Usage
Dry-run targeted passes + (optional) final destroy:
```bash
./tf_teardown_guarded.sh
```

Apply with your vars/tfvars:
```bash
APPLY=1 VARS='-var-file=env/prod.tfvars' ./tf_teardown_guarded.sh
```

Skip the final full destroy:
```bash
APPLY=1 TARGETS_ONLY=1 VARS='-var-file=env/prod.tfvars' ./tf_teardown_guarded.sh
```

Temporarily bypass protections (both `prevent_destroy` and Cloud Run `deletion_protection`):
```bash
APPLY=1 PATCH_GUARDS=1 VARS='-var-file=env/prod.tfvars' ./tf_teardown_guarded.sh
```

## Notes
- The script keeps **guards on by default** and will print clear guidance if a plan includes protected resources.
- When `PATCH_GUARDS=1`, the script:
  1) backs up touched `*.tf` files,  
  2) flips `prevent_destroy=true` → `false` and `deletion_protection=true` → `false`,  
  3) runs `terraform apply`,  
  4) restores your originals automatically.
- If Artifact Registry repo deletion fails, prune images first:
  ```bash
  gcloud artifacts docker images list --repository="REPO" --location="REGION"
  gcloud artifacts docker images delete "REGION-docker.pkg.dev/PROJECT/REPO/IMAGE@SHA" --delete-tags --quiet
  ```

## Troubleshooting
- **Cloud Run error**: “cannot destroy service without setting deletion_protection=false and running `terraform apply`”  
  → Use `PATCH_GUARDS=1`, or set `deletion_protection = false` in your TF for the service, run `terraform apply`, then destroy.
- **WIF pool has prevent_destroy**: same approach — either keep it, or use `PATCH_GUARDS=1` for a one-time teardown.
- **Stay safe**: Prefer default guarded mode. Only bypass if you intentionally want a full teardown.
