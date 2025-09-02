resource "google_project_service" "apis" {
  for_each = toset(["iam.googleapis.com", "iamcredentials.googleapis.com", "run.googleapis.com", "artifactregistry.googleapis.com", "secretmanager.googleapis.com", "firestore.googleapis.com"])
  project  = var.project_id
  service  = each.key
}

resource "google_iam_workload_identity_pool" "pool" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub pool"
}

resource "google_iam_workload_identity_pool_provider" "dev" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_dev_id
  display_name                       = "GitHub provider (dev)"

  # Map GitHub OIDC claims → provider attributes
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # 🔐 Restrict to your repo + branch
  # Must reference attributes defined above, not raw assertion.* claims.
  attribute_condition = "attribute.repository == \"${var.github_repository}\" && attribute.ref == \"${var.dev_ref}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
    # allowed_audiences optional; not required for GitHub Actions
  }
}

resource "google_iam_workload_identity_pool_provider" "prod" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_prod_id
  display_name                       = "GitHub provider (prod)"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # 🔐 Restrict to your repo + main branch (or release tag, see note below)
  attribute_condition = "attribute.repository == \"${var.github_repository}\" && attribute.ref == \"${var.prod_ref}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "deploy_dev" {
  account_id   = var.deploy_sa_dev_id
  display_name = "GitHub Deployer (dev)"
  project      = var.project_id
}

resource "google_service_account" "deploy_prod" {
  account_id   = var.deploy_sa_prod_id
  display_name = "GitHub Deployer (prod)"
  project      = var.project_id
}

locals {
  pool_name = google_iam_workload_identity_pool.pool.name
  # Single-attribute principalSet: restrict by repo via path
  repo_member = "principalSet://iam.googleapis.com/${local.pool_name}/attribute.repository/${var.github_repository}"
}


resource "google_service_account_iam_binding" "wif_dev" {
  service_account_id = google_service_account.deploy_dev.name
  role               = "roles/iam.workloadIdentityUser"
  members            = [local.repo_member]
}

resource "google_service_account_iam_binding" "wif_prod" {
  service_account_id = google_service_account.deploy_prod.name
  role               = "roles/iam.workloadIdentityUser"
  members            = [local.repo_member]
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.ar_repository_id
  format        = "DOCKER"
}

resource "google_service_account" "runtime" {
  account_id   = var.runtime_sa_id
  display_name = "FoodLabel runtime"
  project      = var.project_id
}

resource "google_cloud_run_v2_service" "backend" {
  count    = var.create_cloud_run ? 1 : 0
  name     = var.run_service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"
  template {
    service_account = google_service_account.runtime.email
    timeout         = "60s"
    containers {
      image = var.run_image
      ports {
        container_port = 8080
      }
    }
  }
}
