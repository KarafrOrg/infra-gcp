module "infra-gcp" {
  source                            = "../../modules/infra-gcp"
  gcp_project_name                  = var.gcp_project_name
  gcp_service_service_accounts      = var.gcp_service_service_accounts
  k8s_ca_certificate_refs           = var.k8s_ca_certificate_refs
  pub_sub_topic_prefix              = var.pub_sub_topic_prefix
  k8s_clusters                      = var.k8s_clusters
  external_identity_pools           = var.external_identity_pools
  org_policy_config                 = var.org_policy_config
  enable_organization_policies      = var.enable_organization_policies
  k8s_cluster_certificate_authority = var.k8s_cluster_certificate_authority
  k8s_cluster_client_certificate    = var.k8s_cluster_client_certificate
  k8s_cluster_host                  = var.k8s_cluster_host
  k8s_cluster_token                 = var.k8s_cluster_token

  providers = {
    google     = google
    kubernetes = kubernetes
  }
}
