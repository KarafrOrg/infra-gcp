resource "google_service_account" "service_accounts" {
  for_each     = var.service_accounts
  account_id   = each.key
  display_name = try(each.value.display_name, each.key)
  description  = try(each.value.description)
}
