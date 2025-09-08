# -------------------------------------------------------------------
# Enable APIs (added sqladmin)
# -------------------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "vision.googleapis.com",
    "sqladmin.googleapis.com", # <--- added for Cloud SQL
  ])
  project = var.project_id
  service = each.key
}

# -------------------------------------------------------------------
# Workload Identity Federation (unchanged)
# -------------------------------------------------------------------
resource "google_iam_workload_identity_pool" "pool" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub pool"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [workload_identity_pool_id, display_name]
  }
}

resource "google_iam_workload_identity_pool_provider" "dev" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_dev_id
  display_name                       = "GitHub provider (dev)"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  attribute_condition = "attribute.repository == \"${var.github_repository}\" && attribute.ref == \"${var.dev_ref}\""
  oidc { issuer_uri = "https://token.actions.githubusercontent.com" }
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
  attribute_condition = "attribute.repository == \"${var.github_repository}\" && attribute.ref == \"${var.prod_ref}\""
  oidc { issuer_uri = "https://token.actions.githubusercontent.com" }
}

locals {
  pool_name   = google_iam_workload_identity_pool.pool.name
  repo_member = "principalSet://iam.googleapis.com/${local.pool_name}/attribute.repository/${var.github_repository}"
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

# -------------------------------------------------------------------
# Artifact Registry (unchanged)
# -------------------------------------------------------------------
resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.ar_repository_id
  format        = "DOCKER"
}

# -------------------------------------------------------------------
# RUNTIME SERVICE ACCOUNT (unchanged)
# -------------------------------------------------------------------
resource "google_service_account" "runtime" {
  account_id   = var.runtime_sa_id
  display_name = "FoodLabel runtime"
  project      = var.project_id
}

# -------------------------------------------------------------------
# Cloud SQL (Postgres) + Secrets (NEW)
# -------------------------------------------------------------------
resource "random_password" "db_pass" {
  length  = 20
  special = true
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "foodscanner-db-password"
  replication {
    auto {}
  }
}


resource "google_secret_manager_secret_version" "db_password_v" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_pass.result
}

resource "random_password" "jwt_secret" {
  length  = 40
  special = true
}

resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "foodscanner-jwt-secret"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "jwt_secret_v" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = random_password.jwt_secret.result
}

# Cloud SQL instance (public IP, dev-friendly)
resource "google_sql_database_instance" "pg" {
  name             = var.db_instance_name
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "dev"
        value = var.authorized_cidr
      }
    }
  }

  deletion_protection = true
  depends_on          = [google_project_service.apis]
}

resource "google_sql_database" "db" {
  name     = var.db_name
  instance = google_sql_database_instance.pg.name
}

resource "google_sql_user" "user" {
  name     = var.db_user
  instance = google_sql_database_instance.pg.name
  password = random_password.db_pass.result
}

# -------------------------------------------------------------------
# Cloud Run service (with env + secret refs MERGED)
# -------------------------------------------------------------------
resource "google_cloud_run_v2_service" "backend" {
  project             = var.project_id
  count               = var.create_cloud_run ? 1 : 0
  name                = var.run_service_name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = true

  template {
    service_account = google_service_account.runtime.email
    timeout         = "60s"

    containers {
      image = var.run_image

      ports { container_port = 8080 }

      # ---------- Plain env (safe values) ----------
      env {
        name  = "POLICY_DIR"
        value = "backend/policies"
      }
      env {
        name  = "POLICY_FILE"
        value = "policy_v2.json"
      }
      env {
        name  = "DB_HOST"
        value = google_sql_database_instance.pg.public_ip_address
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name  = "DB_NAME"
        value = var.db_name
      }
      env {
        name  = "DB_USER"
        value = var.db_user
      }

      # ---------- Secret-backed env ----------
      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.jwt_secret.secret_id
            version = "latest"
          }
        }
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_version.db_password_v,
    google_secret_manager_secret_version.jwt_secret_v,
    google_sql_database.db,
    google_sql_user.user,
  ]
}
