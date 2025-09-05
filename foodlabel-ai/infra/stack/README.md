# Terraform Teardown (Guard-Aware)

This package contains a helper script for safely tearing down your FoodScanner GCP project with Terraform.

## Files

- `tf_teardown_guarded.sh` — the main script

## Features

- Runs teardown in **safe order** for your stack:
  1. Cloud Run services
  2. Workload Identity Federation (WIF) service account bindings
  3. WIF providers
  4. WIF pool
  5. Service accounts
  6. Artifact Registry repository
  7. Final full destroy (optional)

- Detects `lifecycle.prevent_destroy = true` guards in your Terraform files.
- By default: **respects guards**, aborts if Terraform tries to delete them, and prints clear messages.
- Optionally: `PATCH_GUARDS=1` temporarily flips guards to `false`, applies the destroy, then **restores your original files**.

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

Temporarily bypass guards:

```bash
APPLY=1 PATCH_GUARDS=1 VARS='-var-file=env/prod.tfvars' ./tf_teardown_guarded.sh
```

## Example Guard Message

If the script finds guarded resources:

```
== Scanning for lifecycle.prevent_destroy guards ==
Found guards in:
./main.tf: resource "google_iam_workload_identity_pool" "pool" {
    lifecycle { prevent_destroy = true }
}

ℹ️  If a destroy plan includes these guarded resources, Terraform will hard-fail.
    This script respects guards by default. Set PATCH_GUARDS=1 to temporarily disable them during apply.
```

## Recommendations

- Use **default mode** (guards respected) for safety.
- Only use `PATCH_GUARDS=1` if you are **absolutely sure** you want to tear down protected resources (like identity pools).
- Review `plan.*.log` files after each step.

---
© 2025 FoodScanner — Terraform Guard-Aware Teardown
