store "varset" "credentials" {
  name     = "infra-gcp-variables"
  category = "terraform"
}

identity_token "gcp" {
  audience = [
    "//iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
  ]
}

deployment_auto_approve "apply_from_default_branch_without_destroys" {
  check {
    condition = context.plan.changes.remove == 0 && context.operation == "apply"
    reason    = "Auto-approved: safe apply on main branch (no destroys)."
  }
}

deployment_group "default_branch_bound" {
  auto_approve_checks = [
    deployment_auto_approve.apply_from_default_branch_without_destroys
  ]
}

deployment "production" {
  deployment_group = deployment_group.default_branch_bound
  inputs = {
    gcp_identity_token        = identity_token.gcp.jwt
    gcp_audience              = "//iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
    gcp_service_account_email = store.varset.credentials.gcp_service_account_email

    gcp_project_name = "karafra-net"
    gcp_region       = "europe-central2"
    gcp_zone         = "europe-central2-a"

    kube_host             = store.varset.credentials.kube_host
    kube_client_cert_data = store.varset.credentials.kube_client_cert_data
    kube_client_key_data  = store.varset.credentials.kube_client_key_data
    kube_client_ca_cert   = store.varset.credentials.kube_client_ca_cert

    gcp_service_service_accounts = {
      "github-actions-infra-cluster" = {
        display_name = "GitHub Actions Service Account"
        description  = "Service account for GitHub Actions workflows"
        roles = [
          "roles/iam.workloadIdentityUser",
          "roles/secretmanager.secretAccessor",
          "roles/secretmanager.viewer",
          "roles/iam.serviceAccountTokenCreator",
        ]
      }
      "github-secret-rotator" = {
        display_name = "GitHub Secret Rotator Service Account"
        description  = "Service account for GitHub secret rotation workflows"
        roles = [
          "roles/secretmanager.secretAccessor",
          "roles/secretmanager.secretVersionManager",
          "roles/secretmanager.viewer",
          "roles/iam.serviceAccountTokenCreator",
          "roles/serviceusage.serviceUsageViewer"
        ]
      }
      "k8s-admin" = {
        display_name = "k8s Admin Service Account"
        description  = "Service account for k8s cluster administration"
        roles = [
          "roles/container.admin",
          "roles/iam.serviceAccountUser"
        ]
      }
      "k8s-secret-reader" = {
        display_name = "K8s secrets reader service account"
        description  = "Service account for k8s pods to read secrets from Secret Manager"
        roles = [
          "roles/secretmanager.secretAccessor"
        ]
      }
      "k8s-storage-admin" = {
        display_name = "k8s Storage Admin Service Account"
        description  = "Service account for k8s pods to manage Cloud Storage"
        roles = [
          "roles/storage.objectAdmin"
        ]
      }
      "k8s-monitoring" = {
        display_name = "k8s Monitoring Service Account"
        description  = "Service account for k8s monitoring workloads"
        roles = [
          "roles/monitoring.metricWriter",
          "roles/logging.logWriter",
          "roles/cloudtrace.agent"
        ]
      }
    }

    k8s_ca_certificate_refs = {
      "k8s-production" = {
        enable_pub_sub = true
        labels = {
          environment = "production"
          cluster     = "k8s-production"
          managed_by  = "terraform-stacks"
        }
      }
    }

    pub_sub_topic_prefix = "k8s-ca-rotation"

    secret_replication_automatic = true

    k8s_clusters = {
      "k8s-production" = {
        issuer_uri        = "https://kubernetes.default.svc.cluster.local"
        display_name      = "k8s Production Cluster"
        description       = "Workload Identity Federation for production k8s cluster"
        default_namespace = "default"
        allowed_audiences = ["sts.googleapis.com"]
        jwks_json_data    = store.varset.credentials.stable.jwks_json_data

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
    external_identity_pools = {
      "github-actions" = {
        display_name = "GitHub actions - KarafrOrg"
        description  = "Workload identity for GitHub Actions workflows"

        providers = {
          "github-oidc" = {
            display_name = "GitHub OIDC"

            oidc = {
              issuer_uri = "https://token.actions.githubusercontent.com"
            }

            attribute_mapping = {
              "google.subject"               = "assertion.sub"
              "attribute.repository"         = "assertion.repository"
              "attribute.repository_owner"   = "assertion.repository_owner"
              "attribute.ref"                = "assertion.ref"
              "attribute.workflow"           = "assertion.workflow"
              "attribute.actor"              = "assertion.actor"
              "attrbute.workflow_ref"        = "assertion.workflow_ref"
              "attribute.runner_environment" = "assertion.runner_environment"
            }

            attribute_condition = "assertion.repository_owner == 'KarafrOrg'"
          }
        }

        service_account_bindings = {
          "infra-cluster" = {
            service_account_email = "github-actions-infra-cluster@karafra-net.iam.gserviceaccount.com"
            attribute_name        = "repository"
            attribute_value       = "KarafrOrg/infra-cluster"
          }
        }
      }
    }
  }
}
