# secrets_snippet.tf — Secret Manager entries
resource "google_secret_manager_secret" "jwt_secret" {
  secret_id  = "jwt-secret-${var.environment}"
  replication { automatic = true }
}

resource "google_secret_manager_secret_version" "jwt_secret_v" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = random_password.jwt_secret.result
}

resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

# Store DATABASE_URL as a single secret
resource "google_secret_manager_secret" "database_url" {
  secret_id  = "database-url-${var.environment}"
  replication { automatic = true }
}

resource "google_secret_manager_secret_version" "database_url_v" {
  secret      = google_secret_manager_secret.database_url.id
  secret_data = "postgresql://${google_sql_user.db_user.name}:${random_password.db_pass.result}@/${google_sql_database.app_db.name}?host=/cloudsql/${google_sql_database_instance.psql.connection_name}"
}

output "jwt_secret_id" {
  value = google_secret_manager_secret.jwt_secret.id
}

output "database_url_id" {
  value = google_secret_manager_secret.database_url.id
}
