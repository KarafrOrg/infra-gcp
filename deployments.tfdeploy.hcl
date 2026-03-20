store "varset" "credentials" {
  name     = "infra-gcp-variables"
  category = "terraform"
}

identity_token "gcp" {
  audience = [
    "//iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
  ]
}

deployment "production" {
  inputs = {
    gcp_identity_token        = identity_token.gcp.jwt
    gcp_audience              = "//iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
    gcp_service_account_email = store.varset.credentials.gcp_service_account_email

    gcp_project_name = "karafra-net"
    gcp_region       = "europe-central2"
    gcp_zone         = "europe-central2-a"

    # Kubernetes configuration
    k3s_context_name = "k3s-production"

    # GCP Service Accounts
    gcp_service_service_accounts = {
      "k8s-admin" = {
        display_name = "K3s Admin Service Account"
        description  = "Service account for K3s cluster administration"
        roles = [
          "roles/container.admin",
          "roles/iam.serviceAccountUser"
        ]
      }
      "k8s-secret-reader" = {
        display_name = "K8s secrets reader service account"
        description  = "Service account for K3s pods to read secrets from Secret Manager"
        roles = [
          "roles/secretmanager.secretAccessor"
        ]
      }
      "k8s-storage-admin" = {
        display_name = "K3s Storage Admin Service Account"
        description  = "Service account for K3s pods to manage Cloud Storage"
        roles = [
          "roles/storage.objectAdmin"
        ]
      }
      "k8s-monitoring" = {
        display_name = "K3s Monitoring Service Account"
        description  = "Service account for K3s monitoring workloads"
        roles = [
          "roles/monitoring.metricWriter",
          "roles/logging.logWriter",
          "roles/cloudtrace.agent"
        ]
      }
    }

    # K3s CA Certificate References (managed externally in Secret Manager)
    # Upload CA certificates to Secret Manager manually or via CI/CD before running this
    # This only creates Pub/Sub topics for rotation notifications
    k3s_ca_certificate_refs = {
      "k3s-production" = {
        enable_pub_sub = true
        labels = {
          environment = "production"
          cluster     = "k3s-production"
          managed_by  = "terraform-stacks"
        }
      }
    }

    # Pub/Sub configuration
    pub_sub_topic_prefix = "k3s-ca-rotation"

    # K3s Workload Identity Federation
    k3s_clusters = {
      "k3s-production" = {
        issuer_uri        = "https://kubernetes.default.svc.cluster.local"
        display_name      = "K3s Production Cluster"
        description       = "Workload Identity Federation for production K3s cluster"
        default_namespace = "default"
        allowed_audiences = ["sts.googleapis.com"]

        kubernetes_service_accounts = {
          "cluster-admin" = {
            namespace                 = "kube-system"
            gcp_service_account_email = "k8s-admin@karafra-net.iam.gserviceaccount.com"
            create_k8s_sa             = true
            k8s_sa_labels = {
              app  = "cluster-admin"
              tier = "infrastructure"
            }
          }

          "default-app" = {
            namespace                 = "default"
            gcp_service_account_email = "k8s-secret-reader@karafra-net.iam.gserviceaccount.com"
            create_k8s_sa             = true
          }
        }
      }
    }

    secret_replication_automatic = true
    pub_sub_topic_prefix         = "k8s-ca-rotation"
  }
}
