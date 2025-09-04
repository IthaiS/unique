output "project_id" { value = 
var.project_id }
output "region"     { value = var.region }
output "wif_provider_dev_name"  { value = 
google_iam_workload_identity_pool_provider.dev.name }
output "wif_provider_prod_name" { value = 
google_iam_workload_identity_pool_provider.prod.name }
output "deploy_dev_service_account_email"  { value = 
google_service_account.deploy_dev.email }
output "deploy_prod_service_account_email" { value = 
google_service_account.deploy_prod.email }
output "cloud_run_url" { value = 
try(google_cloud_run_v2_service.backend[0].uri, null) }
