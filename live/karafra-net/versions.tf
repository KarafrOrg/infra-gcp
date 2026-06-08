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
  host                   = var.kube_host
  token                  = var.kube_token
}

provider "google" {}
