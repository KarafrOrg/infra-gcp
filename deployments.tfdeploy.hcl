store "varset" "credentials" {
  name     = "infra-gcp-variables"
  category = "terraform"
}

identity_token "gcp" {
  audience = [
    "//iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
  ]
}

deployment "production" {
  inputs = {
    gcp_identity_token        = identity_token.gcp.jwt
    gcp_audience              = "//iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
    gcp_service_account_email = store.varset.credentials.gcp_service_account_email

    gcp_project_name = "karafra-net"
    gcp_region       = "europe-central2"
    gcp_zone         = "europe-central2-a"

    gcp_service_service_accounts = {
      "k8s-admin" = {
        display_name = "Kubernetes Admin Service Account"
        description  = "Service account for Kubernetes cluster administration"
        roles = [
          "roles/container.admin",
          "roles/iam.serviceAccountUser"
        ]
      }
      "secret-manager-reader" = {
        display_name = "Secrets Manager Reader Service Account"
        description  = "Service account for reading secrets from Google Secret Manager"
        roles = [
          "roles/secretmanager.secretAccessor",
          "roles/iam.serviceAccountUser"
        ]
      }
      "secret-manager-writer" = {
        display_name = "Secrets Manager Writer Service Account"
        description  = "Service account for writing secrets to Google Secret Manager"
        roles = [
          "roles/secretmanager.secretVersionAdder",
          "roles/iam.serviceAccountUser"
        ]
      }
      "secret-manager-operator" = {
        display_name = "Secrets Manager Operator Service Account"
        description  = "Service account for managing secrets in Google Secret Manager with limited permissions"
        roles = [
          "roles/secretmanager.secretAccessor",
          "roles/secretmanager.secretVersionAdder",
          "roles/iam.serviceAccountUser"
        ]
      }
      "secrets-manager-admin" = {
        display_name = "Secrets Manager Admin Service Account"
        description  = "Service account for managing secrets in Google Secret Manager"
        roles = [
          "roles/secretmanager.admin",
          "roles/iam.serviceAccountUser"
        ]
      }
    }
  }
}
