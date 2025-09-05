#!/usr/bin/env bash
# tf_teardown_guarded.sh — Ordered Terraform teardown with guard awareness
#
# Features:
#  - Destroys in safe order for your stack (Cloud Run -> WIF bindings -> WIF providers -> WIF pool -> SAs -> Artifact Registry -> full destroy)
#  - Detects lifecycle.prevent_destroy guards and warns with friendly messages
#  - Optional PATCH_GUARDS=1 temporarily flips prevent_destroy=true -> false, applies, and restores files
#
# Usage examples:
#   ./tf_teardown_guarded.sh
#   APPLY=1 VARS='-var-file=env/prod.tfvars' ./tf_teardown_guarded.sh
#   APPLY=1 TARGETS_ONLY=1 VARS='-var-file=env/prod.tfvars' ./tf_teardown_guarded.sh
#   APPLY=1 PATCH_GUARDS=1 VARS='-var-file=env/prod.tfvars' ./tf_teardown_guarded.sh
#
set -euo pipefail

APPLY="${APPLY:-0}"
VARS="${VARS:-}"
PARALLELISM="${PARALLELISM:-10}"
TARGETS_ONLY="${TARGETS_ONLY:-0}"
PATCH_GUARDS="${PATCH_GUARDS:-0}"
PLAN_PREFIX="${PLAN_PREFIX:-destroy}"
TFBIN="${TERRAFORM:-terraform}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; exit 1; }; }
need "$TFBIN"

echo "== Init =="
"$TFBIN" init -upgrade
echo "== Validate =="
"$TFBIN" validate

# ---------- Guard scan ----------
echo "== Scanning for lifecycle.prevent_destroy guards =="
GUARDED_FILES=$(grep -RlE 'lifecycle\s*{[^}]*prevent_destroy\s*=\s*true' . --include='*.tf' || true)
if [[ -n "${GUARDED_FILES}" ]]; then
  echo "Found guards in:"
  echo "${GUARDED_FILES}"
  echo
  echo "ℹ️  If a destroy plan includes these guarded resources, Terraform will hard-fail."
  echo "    This script respects guards by default. Set PATCH_GUARDS=1 to temporarily disable them during apply."
fi

# Helper to run targeted plan/apply
plan_apply() {
  local label="$1"; shift
  local extra_targets=("$@")
  local plan_out="${PLAN_PREFIX}.${label}.tfplan"

  echo
  echo "---- ${label} ----"
  local args=(-destroy -refresh=true -parallelism="${PARALLELISM}")
  # forward vars
  if [[ -n "${VARS}" ]]; then
    # shellcheck disable=SC2206
    args+=(${VARS})
  fi
  # add targets
  for t in "${extra_targets[@]}"; do
    args+=(-target="$t")
  done

  "$TFBIN" plan "${args[@]}" -out="${plan_out}" | tee "plan.${label}.log"

  if [[ "${APPLY}" != "1" ]]; then
    echo "(plan only; set APPLY=1 to apply ${label})"
    return 0
  fi

  # Optionally patch prevent_destroy guards
  local patched=0
  if [[ "${PATCH_GUARDS}" = "1" && -n "${GUARDED_FILES}" ]]; then
    echo "Patching prevent_destroy -> false (temporary)"
    patched=1
    BACKUPS=()
    trap 'ec=$?; if [[ "${patched}" = "1" ]]; then echo "Restoring originals..."; for b in "${BACKUPS[@]:-}"; do mv -f "$b" "${b%.bak}"; done; fi; exit $ec' EXIT
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      cp "$f" "$f.bak"
      BACKUPS+=("$f.bak")
      # flip only true->false to preserve layout/comments
      # macOS/BSD sed compatibility:
      if sed --version >/dev/null 2>&1; then
        sed -i -E 's/(prevent_destroy[[:space:]]*=[[:space:]]*)true/\1false/g' "$f"
      else
        sed -E -i '' 's/(prevent_destroy[[:space:]]*=[[:space:]]*)true/\1false/g' "$f"
      fi
    done <<< "${GUARDED_FILES}"
  fi

  "$TFBIN" apply -parallelism="${PARALLELISM}" "${plan_out}"

  if [[ "${patched}" = "1" ]]; then
    echo "Reverting temporary guard patches…"
    for b in "${BACKUPS[@]:-}"; do mv -f "$b" "${b%.bak}"; done
    patched=0
    trap - EXIT
  fi
}

# Resource addresses from your stack (both indexed and non-indexed variants)
CR="google_cloud_run_v2_service.backend"
CR0="google_cloud_run_v2_service.backend[0]"

WIF_BIND_DEV="google_service_account_iam_binding.wif_dev"
WIF_BIND_PROD="google_service_account_iam_binding.wif_prod"

WIF_PROV_DEV="google_iam_workload_identity_pool_provider.dev"
WIF_PROV_PROD="google_iam_workload_identity_pool_provider.prod"
WIF_POOL="google_iam_workload_identity_pool.pool"

SA_RUNTIME="google_service_account.runtime"
SA_DEPLOY_DEV="google_service_account.deploy_dev"
SA_DEPLOY_PROD="google_service_account.deploy_prod"

AR_REPO="google_artifact_registry_repository.repo"

echo "== Ordered teardown (targeted passes) =="
# 1) Cloud Run (front-door)
plan_apply "01-cloud-run" "$CR" "$CR0"

# 2) WIF SA bindings
plan_apply "02-wif-bindings" "$WIF_BIND_DEV" "$WIF_BIND_PROD"

# 3) WIF providers
plan_apply "03-wif-providers" "$WIF_PROV_DEV" "$WIF_PROV_PROD"

# 4) WIF pool (guard likely present - will be respected unless PATCH_GUARDS=1)
plan_apply "04-wif-pool" "$WIF_POOL"

# 5) Service accounts
plan_apply "05-service-accounts" "$SA_RUNTIME" "$SA_DEPLOY_DEV" "$SA_DEPLOY_PROD"

# 6) Artifact Registry repo (may need manual image cleanup)
plan_apply "06-artifact-registry" "$AR_REPO"

if [[ "${TARGETS_ONLY}" != "1" ]]; then
  echo "== Final pass: full destroy (remaining resources, including enabled APIs) =="
  plan_apply "99-full-destroy"
else
  echo "TARGETS_ONLY=1 set — skipping final full destroy."
fi

echo
echo "Done. Review plan.*.log for details."
if [[ -n "${GUARDED_FILES}" && "${PATCH_GUARDS}" != "1" ]]; then
  echo
  echo "Note: Guards were detected and respected. If you intend a full teardown including guarded resources, re-run with:"
  echo "  APPLY=1 PATCH_GUARDS=1 VARS='${VARS}' ./tf_teardown_guarded.sh"
fi
