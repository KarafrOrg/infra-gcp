# ============================================================
# GCP Service Accounts
# ============================================================

component "google-service-account" {
  source = "./modules/google-service-account"

  providers = {
    google = provider.google.main
  }

  inputs = {
    service_accounts = var.gcp_service_service_accounts
    gcp_project_name = var.gcp_project_name
  }
}

# ============================================================
# Secret Manager - K3s CA Certificate Pub/Sub Topics
# ============================================================

component "google-secret-manager" {
  source = "./modules/google-secret-manager"

  providers = {
    google = provider.google.main
  }

  inputs = {
    gcp_project_name        = var.gcp_project_name
    k3s_ca_certificate_refs = var.k3s_ca_certificate_refs
    pub_sub_topic_prefix    = var.pub_sub_topic_prefix
  }
}

# ============================================================
# Workload Identity Federation
# ============================================================

component "google-workload-identity-federation" {
  source = "./modules/google-workload-identity-federation"

  providers = {
    google = provider.google.main
  }

  inputs = {
    gcp_project_name = var.gcp_project_name
    k3s_clusters     = var.k3s_clusters
  }

  depends_on = [
    component.google-service-account
  ]
}

# ============================================================
# Kubernetes Service Accounts
# ============================================================

component "kubernetes-service-account" {
  source = "./modules/kubernetes-service-account"

  providers = {
    kubernetes = provider.kubernetes.k3s
  }

  inputs = {
    k3s_clusters = var.k3s_clusters
  }

  depends_on = [
    component.google-workload-identity-federation
  ]
}
