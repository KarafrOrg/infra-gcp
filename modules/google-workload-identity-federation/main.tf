resource "google_iam_workload_identity_pool" "simple" {
  for_each                  = var.workload_identity_federations
  workload_identity_pool_id = each.key
  display_name              = try(each.value.display_name, each.key)
  description               = try(each.value.description, "")
  project                   = var.gcp_project_name
}

resource "google_iam_workload_identity_pool_provider" "simple" {
  for_each = var.workload_identity_federations

  project                            = var.gcp_project_name
  workload_identity_pool_id          = google_iam_workload_identity_pool.simple[each.key].workload_identity_pool_id
  workload_identity_pool_provider_id = each.key

  oidc {
    issuer_uri        = each.value.issuer_uri
    allowed_audiences = ["sts.googleapis.com"]
  }

  attribute_mapping = {
    "google.subject"            = "assertion.sub"
    "attribute.namespace"       = "assertion['kubernetes.io/serviceaccount/namespace']"
    "attribute.service_account" = "assertion['kubernetes.io/serviceaccount/service-account.name']"
  }
}

resource "google_service_account_iam_member" "simple_pool_members" {
  for_each = var.workload_identity_federations

  service_account_id = "projects/${var.gcp_project_name}/serviceAccounts/${each.value.gcp_service_account_email}"
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.simple[each.key].name}/attribute.namespace/${each.value.namespace}/attribute.service_account/${each.value.ksa_name}"

  depends_on = [
    google_iam_workload_identity_pool.simple,
    google_iam_workload_identity_pool_provider.simple
  ]
}