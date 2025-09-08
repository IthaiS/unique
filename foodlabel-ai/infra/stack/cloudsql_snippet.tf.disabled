# cloudsql_snippet.tf — Cloud SQL (Postgres) basics
resource "google_sql_database_instance" "psql" {
  name             = local.db_instance_name
  database_version = "POSTGRES_15"
  region           = local.region

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      # For private IP, add a VPC and private_network
      # For simplicity, allow public IP but use IAM connector from Cloud Run
      ipv4_enabled = true
      authorized_networks = [] # keep empty for now
    }
  }
}

resource "google_sql_user" "db_user" {
  name     = local.db_user
  instance = google_sql_database_instance.psql.name
  password = random_password.db_pass.result
}

resource "random_password" "db_pass" {
  length  = 24
  special = true
}

resource "google_sql_database" "app_db" {
  name     = local.db_name
  instance = google_sql_database_instance.psql.name
}

output "db_instance_connection_name" {
  value = google_sql_database_instance.psql.connection_name
}
