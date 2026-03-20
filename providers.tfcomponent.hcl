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
    client_certificate     = var.kube_client_cert_data
    client_key             = var.kube_client_key_data
    cluster_ca_certificate = var.kube_client_ca_cert
    host                   = var.kube_host
  }
}
