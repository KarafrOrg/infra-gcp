output "service_accounts" {
  value = {
    for sa_key, sa_value in google_service_account.service_accounts :
    sa_key => {
      email        = sa_value.email
      display_name = sa_value.display_name
      description  = sa_value.description
      roles        = try(var.service_accounts[sa_key].roles, [])
    }
  }
}
