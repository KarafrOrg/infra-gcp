module "infra-gcp" {
  source                       = "../../modules/infra-gcp"
  gcp_project_name             = var.gcp_project_name
  gcp_service_service_accounts = var.gcp_service_service_accounts
  k8s_ca_certificate_refs      = var.k8s_ca_certificate_refs
  pub_sub_topic_prefix         = var.pub_sub_topic_prefix
  k8s_clusters                 = var.k8s_clusters
  external_identity_pools      = var.external_identity_pools
  kube_client_ca_cert          = var.kube_client_ca_cert
  kube_client_cert_data        = var.kube_client_cert_data
  kube_client_key_data         = var.kube_client_key_data
  kube_host                    = var.kube_host
  org_policy_config            = var.org_policy_config
  enable_organization_policies = var.enable_organization_policies

  providers = {
    google     = google
    kubernetes = kubernetes
  }
}
