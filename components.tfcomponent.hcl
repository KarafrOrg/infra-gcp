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

component "google-secret-manager" {
  source = "./modules/google-secret-manager"

  providers = {
    google = provider.google.main
  }

  inputs = {
    gcp_project_name        = var.gcp_project_name
    k8s_ca_certificate_refs = var.k8s_ca_certificate_refs
    pub_sub_topic_prefix    = var.pub_sub_topic_prefix
  }
}

component "google-workload-identity-federation" {
  source = "./modules/google-workload-identity-federation"

  providers = {
    google = provider.google.main
  }

  inputs = {
    gcp_project_name        = var.gcp_project_name
    k8s_clusters            = var.k8s_clusters
    external_identity_pools = var.external_identity_pools
  }

  depends_on = [
    component.google-service-account
  ]
}

component "kubernetes-service-account" {
  source = "./modules/kubernetes-service-account"

  providers = {
    kubernetes = provider.kubernetes.k8s
  }

  inputs = {
    k8s_clusters = var.k8s_clusters
  }

  depends_on = [
    component.google-workload-identity-federation
  ]
}

