# Terraform Teardown (Guard & Deletion Protection Aware)

This package contains a helper script for safely tearing down your FoodScanner GCP project with Terraform.

## Files
- `tf_teardown_guarded.sh` — the main script

## What it handles
- **Safe order** for your stack:
  1. Cloud Run backend
  2. Cloud SQL instance
  3. WIF service account bindings
  4. WIF providers
  5. WIF pool
  6. Service accounts
  7. Artifact Registry repository
  8. Final full destroy
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


# Terraform Cleanup Script

This package provides a helper script to remove **local Terraform clutter** like plan files, logs, and state backups.

## Files
- `cleanup.sh` — the cleanup script

## What it does
- Deletes all `*.tfplan` and `*.tfplan.*` files
- Deletes `destroy.*.tfplan` and `plan.*.log` files
- Deletes `*.tfstate.backup` files
- Leaves your main `terraform.tfstate` intact (if using local state)
- Does **not** touch remote state (e.g., GCS backend)

## Why we keep `.terraform.lock.hcl` and `.terraform/`

This repo **does not delete**:

- `.terraform.lock.hcl`  
- `.terraform/`  

These files are critical for reproducibility and stability:

- **`.terraform.lock.hcl`**: pins the exact versions of Terraform providers (e.g., Google provider).  
  Deleting it can cause provider upgrades or incompatibility issues when re-initializing.  
- **`.terraform/` directory**: stores your initialized backend and downloaded providers.  
  Removing it will force a fresh init and may break your workflow if versions drift.

By design, `cleanup.sh` only removes *ephemeral* files (plans, logs, state backups), keeping your Terraform environment safe.


## Usage

Make the script executable:

```bash
chmod +x cleanup.sh
```

Run cleanup:

```bash
./cleanup.sh
```

Example output:

```
🧹 Cleaning Terraform artifacts...
./plan.dev.log
./destroy.prod.tfplan
✔ Cleanup complete!
```

## Recommendation

Add these patterns to your `.gitignore` so you never commit plan/log files:

```gitignore
*.tfplan
*.tfplan.*
destroy.*.tfplan
plan.*.log
*.tfstate
*.tfstate.*
.terraform/
.terraform/*
```

---
© 2025 FoodScanner — Terraform Cleanup Utility
