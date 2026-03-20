resource "google_service_account" "service_accounts" {
  for_each     = var.service_accounts
  account_id   = each.key
  display_name = try(each.value.display_name, each.key)
  description  = try(each.value.description)
}

resource "google_project_iam_member" "sa_roles" {
  for_each = merge([
    for sa_key, sa_value in var.service_accounts : {
      for role in coalesce(sa_value.roles, []) :
      "${sa_key}-${role}" => {
        sa   = sa_key
        role = role
      }
    }
  ]...)
  project = var.gcp_project_name
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.sa].email}"
}
