required_providers {
  google = {
    source  = "hashicorp/google"
    version = "~> 7.24"
  }
  kubernetes = {
    source  = "hashicorp/kubernetes"
    version = "~> 2.35"
  }
}

provider "google" "main" {
  config {
    project = var.gcp_project_name
    region  = var.gcp_region
    zone    = var.gcp_zone
    external_credentials {
      audience              = var.gcp_audience
      service_account_email = var.gcp_service_account_email
      identity_token        = var.gcp_identity_token
    }
  }
}

provider "kubernetes" "k8s" {
  config {
    client_certificate     = var.KUBE_CLIENT_CERT_DATA
    client_key             = var.KUBE_CLIENT_KEY_DATA
    cluster_ca_certificate = var.KUBE_CLUSTER_CA_CERT_DATA
    host                   = var.KUBE_HOST
  }
}
