module "google_service_account" {
  source           = "../google-service-account"
  service_accounts = var.gcp_service_service_accounts
  gcp_project_name = var.gcp_project_name
}

module "google_secret_manager" {
  source                  = "../google-secret-manager"
  gcp_project_name        = var.gcp_project_name
  k8s_ca_certificate_refs = var.k8s_ca_certificate_refs
  pub_sub_topic_prefix    = var.pub_sub_topic_prefix
}

module "google_workload_identity_federation" {
  source = "../google-workload-identity-federation"

  gcp_project_name        = var.gcp_project_name
  k8s_clusters            = var.k8s_clusters
  external_identity_pools = var.external_identity_pools

  depends_on = [
    module.google_service_account
  ]
}

module "kubernetes_service_account" {
  source = "../kubernetes-service-account"

  k8s_clusters = var.k8s_clusters

  depends_on = [
    module.google_workload_identity_federation
  ]
}
