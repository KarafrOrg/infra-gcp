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
    hostname = "app.terraform.io"
    organization = "karafrorg-homelab"

    workspaces {
      name = "karafrorg_homelab_project_dev"
    }
  }
}

provider "kubernetes" {
  host                   = var.kube_host
  cluster_ca_certificate = base64decode(var.kube_client_ca_cert)
  client_certificate     = base64decode(var.kube_client_cert_data)
  client_key             = base64decode(var.kube_client_key_data)
}

provider "google" {}

