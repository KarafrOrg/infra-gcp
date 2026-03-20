component "google-service-account" {
  source = "./modules/google-service-account"

  providers = {
    google = provider.google.main
  }

  inputs = {
    google-service-service_accounts = var.gcp_service_service_accounts
  }
}
