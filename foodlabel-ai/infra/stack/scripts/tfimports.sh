#!/bin/bash

PROJECT_ID="sound-paratext-470818-m4"
REGION="europe-west1"

import_resource() {
  local resource=$1
  local id=$2

  # Check if resource is already in state
  if terraform state show "$resource" &>/dev/null; then
    echo "[INFO] $resource is already managed by Terraform."
  else
    echo "[IMPORT] Importing $resource..."
    if terraform import "$resource" "$id"; then
      echo "[SUCCESS] Imported $resource."
    else
      echo "[ERROR] Failed to import $resource. It may already exist or there was an error."
    fi
  fi
}

# Service Accounts
import_resource google_service_account.deploy_dev "projects/${PROJECT_ID}/serviceAccounts/github-deployer-dev@${PROJECT_ID}.iam.gserviceaccount.com"
import_resource google_service_account.deploy_prod "projects/${PROJECT_ID}/serviceAccounts/github-deployer-prod@${PROJECT_ID}.iam.gserviceaccount.com"
import_resource google_service_account.runtime "projects/${PROJECT_ID}/serviceAccounts/foodlabel-runtime@${PROJECT_ID}.iam.gserviceaccount.com"

# Artifact Registry Repository
import_resource google_artifact_registry_repository.repo "projects/${PROJECT_ID}/locations/${REGION}/repositories/foodlabel-repo"

# Workload Identity Pool
import_resource google_iam_workload_identity_pool.pool "projects/${PROJECT_ID}/locations/global/workloadIdentityPools/github-pool"

# Workload Identity Pool Providers
import_resource google_iam_workload_identity_pool_provider.dev "projects/${PROJECT_ID}/locations/global/workloadIdentityPools/github-pool/providers/github-provider-dev"
import_resource google_iam_workload_identity_pool_provider.prod "projects/${PROJECT_ID}/locations/global/workloadIdentityPools/github-pool/providers/github-provider-prod"

# Cloud Run Service
import_resource "google_cloud_run_v2_service.backend[0]"