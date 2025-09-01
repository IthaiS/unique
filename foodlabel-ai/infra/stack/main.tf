resource "google_project_service" "apis" {
  for_each = toset(["iam.googleapis.com","iamcredentials.googleapis.com","run.googleapis.com","artifactregistry.googleapis.com","secretmanager.googleapis.com","firestore.googleapis.com"])
  project  = var.project_id
  service  = each.key
}

resource "google_iam_workload_identity_pool" "pool" {
  project = var.project_id
  location = var.wif_location
  workload_identity_pool_id = var.pool_id
  display_name = "GitHub pool"
}
resource "google_iam_workload_identity_pool_provider" "dev" {
  project = var.project_id
  location = var.wif_location
  workload_identity_pool_id = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_dev_id
  display_name = "GitHub provider (dev)"
  attribute_mapping = {
    "google.subject"      = "assertion.sub"
    "attribute.repository"= "assertion.repository"
    "attribute.ref"       = "assertion.ref"
  }
  oidc { issuer_uri = "https://token.actions.githubusercontent.com" }
}
resource "google_iam_workload_identity_pool_provider" "prod" {
  project = var.project_id
  location = var.wif_location
  workload_identity_pool_id = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_prod_id
  display_name = "GitHub provider (prod)"
  attribute_mapping = {
    "google.subject"      = "assertion.sub"
    "attribute.repository"= "assertion.repository"
    "attribute.ref"       = "assertion.ref"
  }
  oidc { issuer_uri = "https://token.actions.githubusercontent.com" }
}

resource "google_service_account" "deploy_dev" { account_id=var.deploy_sa_dev_id display_name="GitHub Deployer (dev)" project=var.project_id }
resource "google_service_account" "deploy_prod" { account_id=var.deploy_sa_prod_id display_name="GitHub Deployer (prod)" project=var.project_id }

locals {
  pool = google_iam_workload_identity_pool.pool.name
  repo = var.github_repository
  dev_member_ref  = "principal://iam.googleapis.com/${local.pool}/attribute.repository/${local.repo}/attribute.ref/${var.dev_ref}"
  prod_member_ref = "principal://iam.googleapis.com/${local.pool}/attribute.repository/${local.repo}/attribute.ref/${var.prod_ref}"
}

resource "google_service_account_iam_binding" "wif_dev" { service_account_id=google_service_account.deploy_dev.name role="roles/iam.workloadIdentityUser" members=[local.dev_member_ref] }
resource "google_service_account_iam_binding" "wif_prod" { service_account_id=google_service_account.deploy_prod.name role="roles/iam.workloadIdentityUser" members=[local.prod_member_ref] }

resource "google_artifact_registry_repository" "repo" {
  location = var.region
  repository_id = var.ar_repository_id
  format = "DOCKER"
}
resource "google_artifact_registry_repository_iam_member" "writer_dev" { location=var.region repository=google_artifact_registry_repository.repo.repository_id role="roles/artifactregistry.writer" member="serviceAccount:${google_service_account.deploy_dev.email}" }
resource "google_artifact_registry_repository_iam_member" "writer_prod" { location=var.region repository=google_artifact_registry_repository.repo.repository_id role="roles/artifactregistry.writer" member="serviceAccount:${google_service_account.deploy_prod.email}" }

resource "google_secret_manager_secret" "sentry" { secret_id=var.sentry_dsn_secret_id replication{automatic=true} }
resource "google_secret_manager_secret" "slack"  { secret_id=var.slack_webhook_secret_id replication{automatic=true} }
resource "google_secret_manager_secret_version" "sentry_v1" { count=length(var.sentry_dsn_initial_value)>0?1:0 secret=google_secret_manager_secret.sentry.id secret_data=var.sentry_dsn_initial_value }
resource "google_secret_manager_secret_version" "slack_v1"  { count=length(var.slack_webhook_initial_value)>0?1:0 secret=google_secret_manager_secret.slack.id  secret_data=var.slack_webhook_initial_value }

resource "google_service_account" "runtime" { account_id=var.runtime_sa_id display_name="FoodLabel runtime" project=var.project_id }
resource "google_project_iam_member" "runtime_logging"   { project=var.project_id role="roles/logging.logWriter" member="serviceAccount:${google_service_account.runtime.email}" }
resource "google_project_iam_member" "runtime_trace"     { project=var.project_id role="roles/cloudtrace.agent"   member="serviceAccount:${google_service_account.runtime.email}" }
resource "google_project_iam_member" "runtime_firestore" { project=var.project_id role="roles/datastore.user"     member="serviceAccount:${google_service_account.runtime.email}" }
resource "google_secret_manager_secret_iam_member" "runtime_sentry" { secret_id=google_secret_manager_secret.sentry.id role="roles/secretmanager.secretAccessor" member="serviceAccount:${google_service_account.runtime.email}" }
resource "google_secret_manager_secret_iam_member" "runtime_slack"  { secret_id=google_secret_manager_secret.slack.id  role="roles/secretmanager.secretAccessor" member="serviceAccount:${google_service_account.runtime.email}" }

resource "google_cloud_run_v2_service" "backend" {
  count = var.create_cloud_run ? 1 : 0
  name  = var.run_service_name
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"
  template {
    service_account = google_service_account.runtime.email
    timeout = "60s"
    containers {
      image = var.run_image
      ports { container_port = 8080 }
      env { name = "ENV" value = "prod" }
    }
  }
}
