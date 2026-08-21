terraform {
  required_version = "~> 1.14"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.27.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
  }
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "karafra-net"

    workspaces {
      name = "infra-gcp"
    }
  }
}

provider "kubernetes" {
  host = "https://${var.k8s_cluster_host}:6443"

  client_certificate     = base64decode(var.k8s_cluster_client_certificate)
  client_key             = base64decode(var.k8s_cluster_token)
  cluster_ca_certificate = base64decode(var.k8s_cluster_certificate_authority)
}

provider "google" {}
