resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.default.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_name}.svc.id.goog[${var.namespace}/${var.project_name}]"
  ]
}

resource "google_project_iam_member" "cloudsql_client_membership" {
  role    = "roles/cloudsql.client"
  project = var.project_name
  member  = google_service_account.default.member
}