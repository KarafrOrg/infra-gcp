required_providers {
  google = {
    source  = "hashicorp/google"
    version = "~> 7.24"
  }
}

provider "google" "main" {
  config {
    project = var.gcp_project_name
    region  = var.gcp_region
    zone    = var.gcp_zone
  }
}

