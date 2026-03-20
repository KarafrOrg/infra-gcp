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
    config_path    = var.k8s_kubeconfig_path
    config_context = var.k8s_context_name
  }
}

