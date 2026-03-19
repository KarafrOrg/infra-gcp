store "varset" "credentials" {
  name     = "infra-gcp-variables"
  category = "terraform"
}

deployment "production" {
  inputs = {
    gcp_project_name = "karafra-net"
    gcp_region       = "europe-central2"
    gcp_zone         = "europe-central2-a"

    service_accounts = {
      "k8s-admin" = {
        display_name = "Kubernetes Admin Service Account"
        description  = "Service account for Kubernetes cluster administration"
        roles = [
          "roles/container.admin",
          "roles/iam.serviceAccountUser",
          "roles/compute.admin"
        ]
      }
    }
  }
}
