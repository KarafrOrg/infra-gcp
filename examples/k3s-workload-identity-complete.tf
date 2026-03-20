# Example: K3s Workload Identity Federation Setup
#
# This example demonstrates how to use all modules together to set up
# Workload Identity Federation for a K3s cluster.

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.7"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

# ============================================================
# Variables
# ============================================================

variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "k8s_cluster_name" {
  description = "Name of the K3s cluster"
  type        = string
  default     = "my-k8s-cluster"
}

variable "k8s_issuer_uri" {
  description = "OIDC issuer URI for K3s cluster"
  type        = string
  # Example: "https://kubernetes.default.svc.cluster.local"
  # Or external: "https://k3s.example.com"
}

variable "k8s_ca_certificate_path" {
  description = "Path to K3s CA certificate PEM file"
  type        = string
  default     = "./ca-certificates/k8s-ca.pem"
}

# ============================================================
# Providers
# ============================================================

provider "google" {
  project = var.gcp_project_name
  region  = var.gcp_region
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.k8s_cluster_name
}

# ============================================================
# Module 1: GCP Service Accounts
# ============================================================

module "gcp_service_accounts" {
  source = "./modules/google-service-account"

  gcp_project_name = var.gcp_project_name

  service_accounts = {
    # Backend application service account
    app-backend = {
      display_name = "Backend Application SA"
      description  = "Service account for backend application pods"
      roles = [
        "roles/storage.objectViewer",
        "roles/bigquery.dataViewer",
        "roles/cloudtrace.agent"
      ]
    }

    # Frontend application service account
    app-frontend = {
      display_name = "Frontend Application SA"
      description  = "Service account for frontend application pods"
      roles = [
        "roles/storage.objectViewer"
      ]
    }

    # Monitoring service account
    monitoring = {
      display_name = "Monitoring SA"
      description  = "Service account for monitoring agents"
      roles = [
        "roles/monitoring.metricWriter",
        "roles/logging.logWriter"
      ]
    }
  }
}

# ============================================================
# Module 2: Secret Manager - K3s CA Certificate
# ============================================================

module "k8s_ca_secrets" {
  source = "./modules/google-secret-manager"

  gcp_project_name = var.gcp_project_name

  k8s_ca_certificates = {
    (var.k8s_cluster_name) = {
      ca_certificate  = file(var.k8s_ca_certificate_path)
      display_name    = "${var.k8s_cluster_name} CA Certificate"
      description     = "CA certificate for ${var.k8s_cluster_name} - rotates when K3s CA changes"
      rotation_period = "2592000s" # 30 days
      enable_pub_sub  = true

      labels = {
        environment = "production"
        cluster     = var.k8s_cluster_name
        managed_by  = "terraform"
      }
    }
  }

  secret_replication_automatic = true
  pub_sub_topic_prefix        = "k8s-ca-rotation"
}

# ============================================================
# Module 3: Workload Identity Federation
# ============================================================

module "workload_identity" {
  source = "./modules/google-workload-identity-federation"

  gcp_project_name = var.gcp_project_name

  k8s_clusters = {
    (var.k8s_cluster_name) = {
      issuer_uri        = var.k8s_issuer_uri
      display_name      = "${var.k8s_cluster_name} Workload Identity"
      description       = "Workload Identity Federation for ${var.k8s_cluster_name}"
      default_namespace = "default"
      allowed_audiences = ["sts.googleapis.com"]

      kubernetes_service_accounts = {
        # Backend in production namespace
        app-backend = {
          namespace                 = "production"
          gcp_service_account_email = module.gcp_service_accounts.service_accounts["app-backend"].email
        }

        # Frontend in production namespace
        app-frontend = {
          namespace                 = "production"
          gcp_service_account_email = module.gcp_service_accounts.service_accounts["app-frontend"].email
        }

        # Monitoring in monitoring namespace
        monitoring-agent = {
          namespace                 = "monitoring"
          gcp_service_account_email = module.gcp_service_accounts.service_accounts["monitoring"].email
        }

        # Example: Service account in default namespace
        default-app = {
          # Uses default_namespace from cluster config
          gcp_service_account_email = module.gcp_service_accounts.service_accounts["app-backend"].email
        }
      }
    }
  }

  depends_on = [
    module.gcp_service_accounts
  ]
}

# ============================================================
# Module 4: Kubernetes Service Accounts
# ============================================================

module "k8s_service_accounts" {
  source = "./modules/kubernetes-service-account"

  k8s_clusters = {
    (var.k8s_cluster_name) = {
      default_namespace = "default"

      kubernetes_service_accounts = {
        # Backend service account
        app-backend = {
          namespace                       = "production"
          gcp_service_account_email       = module.gcp_service_accounts.service_accounts["app-backend"].email
          create_k8s_sa                   = true
          automount_service_account_token = true

          k8s_sa_annotations = {
            "app.kubernetes.io/name"       = "backend"
            "app.kubernetes.io/component"  = "api"
          }

          k8s_sa_labels = {
            app         = "backend"
            environment = "production"
            tier        = "backend"
          }
        }

        # Frontend service account
        app-frontend = {
          namespace                       = "production"
          gcp_service_account_email       = module.gcp_service_accounts.service_accounts["app-frontend"].email
          create_k8s_sa                   = true
          automount_service_account_token = true

          k8s_sa_labels = {
            app         = "frontend"
            environment = "production"
            tier        = "frontend"
          }
        }

        # Monitoring service account
        monitoring-agent = {
          namespace                       = "monitoring"
          gcp_service_account_email       = module.gcp_service_accounts.service_accounts["monitoring"].email
          create_k8s_sa                   = true
          automount_service_account_token = true

          k8s_sa_labels = {
            app  = "monitoring"
            type = "infrastructure"
          }
        }

        # Default namespace service account
        default-app = {
          gcp_service_account_email       = module.gcp_service_accounts.service_accounts["app-backend"].email
          create_k8s_sa                   = true
          automount_service_account_token = true
        }
      }
    }
  }

  depends_on = [
    module.workload_identity
  ]
}

# ============================================================
# Outputs
# ============================================================

output "gcp_service_accounts" {
  description = "Created GCP service accounts"
  value = {
    for k, v in module.gcp_service_accounts.service_accounts :
    k => {
      email        = v.email
      display_name = v.display_name
    }
  }
}

output "ca_secrets" {
  description = "K3s CA certificate secrets"
  value = {
    for k, v in module.k8s_ca_secrets.k8s_ca_secrets :
    k => {
      secret_id = v.secret_id
      project   = v.project
    }
  }
  sensitive = true
}

output "rotation_pub_sub_topics" {
  description = "Pub/Sub topics for CA certificate rotation notifications"
  value       = module.k8s_ca_secrets.rotation_pub_sub_topics
}

output "workload_identity_pools" {
  description = "Workload Identity pools"
  value = {
    for k, v in module.workload_identity.workload_identity_pools :
    k => {
      pool_id      = v.pool_id
      display_name = v.display_name
    }
  }
}

output "kubernetes_service_accounts" {
  description = "Created Kubernetes service accounts"
  value = {
    for k, v in module.k8s_service_accounts.kubernetes_service_accounts :
    k => {
      name      = v.name
      namespace = v.namespace
    }
  }
}

output "setup_complete" {
  description = "Setup completion message"
  value       = <<-EOT

  ✅ K3s Workload Identity Federation Setup Complete!

  Cluster: ${var.k8s_cluster_name}

  Next steps:
  1. Deploy your applications using the created service accounts
  2. Monitor CA rotation via Pub/Sub topic: ${try(module.k8s_ca_secrets.rotation_pub_sub_topics[var.k8s_cluster_name].name, "N/A")}
  3. Test authentication from a pod

  Example pod specification:

  apiVersion: v1
  kind: Pod
  metadata:
    name: test-workload-identity
    namespace: production
  spec:
    serviceAccountName: app-backend
    containers:
    - name: test
      image: google/cloud-sdk:slim
      command: ["sleep", "infinity"]

  Test inside the pod:
  kubectl exec -it test-workload-identity -n production -- gcloud auth list

  EOT
}

