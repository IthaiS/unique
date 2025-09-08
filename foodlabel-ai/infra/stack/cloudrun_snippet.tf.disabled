# cloudrun_snippet.tf — Cloud Run with Secret Manager envs and Cloud SQL connector
resource "google_artifact_registry_repository" "backend_repo" {
  repository_id = "backend"
  format        = "DOCKER"
  location      = var.region
}

resource "google_service_account" "run_sa" {
  account_id   = "cr-${var.service_name}-${var.environment}"
  display_name = "Cloud Run SA for ${var.service_name} ${var.environment}"
}

# Allow SA to access secrets
resource "google_secret_manager_secret_iam_member" "jwt_access" {
  secret_id = google_secret_manager_secret.jwt_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run_sa.email}"
}
resource "google_secret_manager_secret_iam_member" "dburl_access" {
  secret_id = google_secret_manager_secret.database_url.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run_sa.email}"
}

# Deploy a placeholder Cloud Run service (image pushed by CI)
resource "google_cloud_run_v2_service" "backend" {
  name     = local.cloud_run_name
  location = var.region
  template {
    service_account = google_service_account.run_sa.email
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.backend_repo.repository_id}/backend:${var.environment}"
      env {
        name = "ENV"
        value = var.environment
      }
      env {
        name = "POLICY_FILE"
        value = "policy_v2.json"
      }
      # Secret envs
      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.jwt_secret.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database_url.secret_id
            version = "latest"
          }
        }
      }
    }
    # Connect to Cloud SQL via connection (public IP db is fine for now)
    vpc_access {
      egress = "ALL_TRAFFIC"
    }
  }
  ingress = "INGRESS_TRAFFIC_ALL"
}

output "cloud_run_service_name" {
  value = google_cloud_run_v2_service.backend.name
}
