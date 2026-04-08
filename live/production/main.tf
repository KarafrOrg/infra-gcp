module "infra-gcp" {
  source                       = "../../modules/infra-gcp"
  gcp_project_name             = var.gcp_project_name
  gcp_service_service_accounts = var.gcp_service_service_accounts
  k8s_ca_certificate_refs      = var.k8s_ca_certificate_refs
  pub_sub_topic_prefix         = var.pub_sub_topic_prefix
  k8s_clusters                 = var.k8s_clusters
  external_identity_pools      = var.external_identity_pools
  gcp_audience                 = var.gcp_audience
  gcp_identity_token           = var.gcp_identity_token
  gcp_region                   = var.gcp_region
  gcp_service_account_email    = var.gcp_service_account_email
  gcp_zone                     = var.gcp_zone
  kube_client_ca_cert          = var.kube_client_ca_cert
  kube_client_cert_data        = var.kube_client_cert_data
  kube_client_key_data         = var.kube_client_key_data
  kube_host                    = var.kube_host

  providers = {
    google     = google
    kubernetes = kubernetes
  }
}
