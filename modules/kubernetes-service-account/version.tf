terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}
provider "kubernetes" {
  cluster_ca_certificate = ""
}
