gcp_project_name = "karafra-net"

enable_organization_policies = true
org_policy_config = {
  enforce_uniform_bucket_level_access         = true
  restrict_public_ip_cloud_sql                = true
  require_os_login                            = true
  require_shielded_vm                         = true
  disable_service_account_key_creation        = true
  enforce_automatic_iam_grants_for_default_sa = true
  enforce_detailed_audit_logging              = true

  restrict_vpc_peering         = true
  restrict_protocol_forwarding = true
  disable_default_network_creation = true
  restrict_vm_external_ip      = false  # Set to true if VMs should not have external IPs

  allowed_locations = [
    "in:eu-locations"
  ]

  allowed_ingress_settings = [
    "ALLOW_INTERNAL_ONLY",
    "ALLOW_INTERNAL_AND_GCLB"
  ]

  custom_policies = {}
}

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
  "github-actions-infra-gcp" = {
    display_name = "GitHub Actions Service Account"
    description  = "Service account for orchestrating GCP infrastructure changes from GitHub Actions workflows"
    roles = [
      "roles/owner"
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

pub_sub_topic_prefix         = "k8s-ca-rotation"
secret_replication_automatic = true

k8s_clusters = {
  "k8s-karafra-net" = {
    issuer_uri        = "https://kubernetes.default.svc.cluster.local"
    display_name      = "KarafraNet Kubernetes cluster"
    description       = "Workload Identity Federation for production k8s cluster"
    default_namespace = "default"
    allowed_audiences = [
      "sts.googleapis.com"
    ]
    jwks_json_data = {
      secret_name = "k8s-production-oidc-jwks"
    }
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
  "github-actions-karafrorg" = {
    display_name = "GitHub actions"
    description  = "Workload identity for GitHub Actions workflows"

    providers = {
      "oidc" = {
        display_name = "GitHub OIDC provider"

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
          "attribute.workflow_ref"       = "assertion.workflow_ref"
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
      "infra-gcp" = {
        service_account_email = "github-actions-infra-gcp@karafra-net.iam.gserviceaccount.com"
        attribute_name        = "repository"
        attribute_value       = "KarafrOrg/infra-gcp"
      }
    }
  }
}
