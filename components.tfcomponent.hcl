component "google-service-account" {
  source = "./modules/google-service-account"

  providers = {
    google = provider.google.main
  }

  inputs = {
    service_accounts = var.gcp_service_service_accounts
    gcp_project_name = var.gcp_project_name
  }
}

component "google-workload-identity-federation" {
  source = "./modules/google-workload-identity-federation"

  providers = {
    google = provider.google.main
  }

  inputs = {
    gcp_project_name              = var.gcp_project_name
    workload_identity_federations = var.workload_identity_federations
  }
}