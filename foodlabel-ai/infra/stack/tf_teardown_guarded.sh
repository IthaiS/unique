#!/usr/bin/env bash
# tf_teardown_guarded.sh — Ordered Terraform teardown with guard & deletion_protection awareness

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

echo "== Scanning *.tf for protections =="
GUARDED_FILES=$(grep -RlE 'lifecycle\s*{[^}]*prevent_destroy\s*=\s*true' . --include='*.tf' || true)
DELPROT_FILES=$(grep -RlE 'deletion_protection\s*=\s*true' . --include='*.tf' || true)

if [[ -n "${GUARDED_FILES}" ]]; then
  echo "Found lifecycle.prevent_destroy guards in:"
  echo "${GUARDED_FILES}"
  echo
fi

if [[ -n "${DELPROT_FILES}" ]]; then
  echo "Found deletion_protection=true in:"
  echo "${DELPROT_FILES}"
  echo "Cloud Run & Cloud SQL require disabling before destroy."
  echo
fi

plan_apply() {
  local label="$1"; shift
  local extra_targets=("$@")
  local plan_out="${PLAN_PREFIX}.${label}.tfplan"

  echo "---- ${label} ----"
  local args=(-destroy -refresh=true -parallelism="${PARALLELISM}")
  if [[ -n "${VARS}" ]]; then
    args+=(${VARS})
  fi
  for t in "${extra_targets[@]}"; do
    args+=(-target="$t")
  done

  "$TFBIN" plan "${args[@]}" -out="${plan_out}" | tee "plan.${label}.log"

  if [[ "${APPLY}" != "1" ]]; then
    echo "(plan only; set APPLY=1 to apply ${label})"
    return 0
  fi

  local patched=0
  if [[ "${PATCH_GUARDS}" = "1" && ( -n "${GUARDED_FILES}" || -n "${DELPROT_FILES}" ) ]]; then
    echo "Patching protections temporarily..."
    patched=1
    BACKUPS=()
    trap 'ec=$?; if [[ "${patched}" = "1" ]]; then echo "Restoring originals..."; for b in "${BACKUPS[@]:-}"; do mv -f "$b" "${b%.bak}"; done; fi; exit $ec' EXIT

    TMPFILES=$(printf "%s\n%s\n" "${GUARDED_FILES}" "${DELPROT_FILES}" | awk 'NF' | sort -u)
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      cp "$f" "$f.bak"
      BACKUPS+=("$f.bak")
      sed -i -E 's/(prevent_destroy[[:space:]]*=[[:space:]]*)true/\1false/g' "$f" || true
      sed -i -E 's/(deletion_protection[[:space:]]*=[[:space:]]*)true/\1false/g' "$f" || true
    done <<< "${TMPFILES}"
    $TFBIN apply -refresh-only -auto-approve ${VARS} || true
  fi

  "$TFBIN" apply -parallelism="${PARALLELISM}" "${plan_out}"

  if [[ "${patched}" = "1" ]]; then
    echo "Reverting temporary protection patches..."
    for b in "${BACKUPS[@]:-}"; do mv -f "$b" "${b%.bak}"; done
    patched=0
    trap - EXIT
  fi
}

CR="google_cloud_run_v2_service.backend"
CR0="google_cloud_run_v2_service.backend[0]"
SQL="google_sql_database_instance.db"

WIF_BIND_DEV="google_service_account_iam_binding.wif_dev"
WIF_BIND_PROD="google_service_account_iam_binding.wif_prod"
WIF_PROV_DEV="google_iam_workload_identity_pool_provider.dev"
WIF_PROV_PROD="google_iam_workload_identity_pool_provider.prod"
WIF_POOL="google_iam_workload_identity_pool.pool"

SA_RUNTIME="google_service_account.runtime"
SA_DEPLOY_DEV="google_service_account.deploy_dev"
SA_DEPLOY_PROD="google_service_account.deploy_prod"

AR_REPO="google_artifact_registry_repository.repo"

echo "== Ordered teardown =="
plan_apply "01-cloud-run" "$CR" "$CR0"
plan_apply "02-database" "$SQL"
plan_apply "03-wif-bindings" "$WIF_BIND_DEV" "$WIF_BIND_PROD"
plan_apply "04-wif-providers" "$WIF_PROV_DEV" "$WIF_PROD_PROV"
plan_apply "05-wif-pool" "$WIF_POOL"
plan_apply "06-service-accounts" "$SA_RUNTIME" "$SA_DEPLOY_DEV" "$SA_DEPLOY_PROD"
plan_apply "07-artifact-registry" "$AR_REPO"

if [[ "${TARGETS_ONLY}" != "1" ]]; then
  echo "== Final pass: full destroy =="
  plan_apply "99-full-destroy"
else
  echo "TARGETS_ONLY=1 set — skipping final destroy."
fi

echo "Done."
