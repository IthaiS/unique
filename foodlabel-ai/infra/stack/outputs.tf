output "deploy_dev_service_account_email" {
  value = google_service_account.deploy_dev.email
}

output "deploy_prod_service_account_email" {
  value = google_service_account.deploy_prod.email
}

output "runtime_service_account_email" {
  value = google_service_account.runtime.email
}

output "artifact_registry_repository_url" {
  value = google_artifact_registry_repository.repo.id
}

output "cloud_run_service_url" {
  value = google_cloud_run_v2_service.backend[0].uri
  description = "URL of the deployed Cloud Run service"
}