resource "google_project_service" "apis" { for_each=toset(["iam.googleapis.com","iamcredentials.googleapis.com"])
  project=var.project_id service=each.key }
resource "google_service_account" "deployer" {
  account_id=var.service_account_id display_name=var.service_account_display_name project=var.project_id
  depends_on=[google_project_service.apis] }
resource "google_iam_workload_identity_pool" "pool" {
  project=var.project_id location=var.location workload_identity_pool_id=var.pool_id display_name="GitHub pool" }
resource "google_iam_workload_identity_pool_provider" "provider" {
  project=var.project_id location=var.location workload_identity_pool_id=google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id=var.provider_id display_name="GitHub provider"
  attribute_mapping={ "google.subject":"assertion.sub","attribute.repository":"assertion.repository","attribute.ref":"assertion.ref" }
  oidc { issuer_uri="https://token.actions.githubusercontent.com" } }
locals { pool_name=google_iam_workload_identity_pool.pool.name
  repo_member="principalSet://iam.googleapis.com/${local.pool_name}/attribute.repository/${var.github_repository}"
  branch_member="principal://iam.googleapis.com/${local.pool_name}/attribute.repository/${var.github_repository}/attribute.ref/${var.github_ref}"
  wif_members=var.restrict_to_branch ? [local.branch_member] : [local.repo_member] }
resource "google_service_account_iam_binding" "allow_wif" {
  service_account_id=google_service_account.deployer.name role="roles/iam.workloadIdentityUser" members=local.wif_members }
resource "google_project_iam_member" "run_admin" { count=var.assign_deploy_roles?1:0 project=var.project_id role="roles/run.admin"
  member="serviceAccount:${google_service_account.deployer.email}" }
resource "google_project_iam_member" "iam_sa_user" { count=var.assign_deploy_roles?1:0 project=var.project_id role="roles/iam.serviceAccountUser"
  member="serviceAccount:${google_service_account.deployer.email}" }
resource "google_project_iam_member" "ar_writer" { count=var.assign_deploy_roles?1:0 project=var.project_id role="roles/artifactregistry.writer"
  member="serviceAccount:${google_service_account.deployer.email}" }
