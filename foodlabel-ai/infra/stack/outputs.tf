output "artifact_registry_repo" { value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}" }
output "deploy_dev_service_account_email" { value = google_service_account.deploy_dev.email }
output "deploy_prod_service_account_email" { value = google_service_account.deploy_prod.email }
output "wif_provider_dev_name" { value = google_iam_workload_identity_pool_provider.dev.name }
output "wif_provider_prod_name" { value = google_iam_workload_identity_pool_provider.prod.name }
output "runtime_service_account_email" { value = google_service_account.runtime.email }
output "cloud_run_service_uri" { value = try(google_cloud_run_v2_service.backend[0].uri, null) }
