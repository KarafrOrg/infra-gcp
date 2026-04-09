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

module "google_org_policy" {
  count  = var.enable_organization_policies
  source = "../google-project-organization"

  gcp_project_name = var.gcp_project_name

  enforce_uniform_bucket_level_access         = try(var.org_policy_config.enforce_uniform_bucket_level_access, true)
  restrict_public_ip_cloud_sql                = try(var.org_policy_config.restrict_public_ip_cloud_sql, true)
  require_os_login                            = try(var.org_policy_config.require_os_login, true)
  restrict_vpc_peering                        = try(var.org_policy_config.restrict_vpc_peering, true)
  disable_service_account_key_creation        = try(var.org_policy_config.disable_service_account_key_creation, true)
  restrict_protocol_forwarding                = try(var.org_policy_config.restrict_protocol_forwarding, true)
  enforce_detailed_audit_logging              = try(var.org_policy_config.enforce_detailed_audit_logging, true)
  disable_default_network_creation            = try(var.org_policy_config.disable_default_network_creation, true)
  enforce_automatic_iam_grants_for_default_sa = try(var.org_policy_config.enforce_automatic_iam_grants_for_default_sa, true)
  require_shielded_vm                         = try(var.org_policy_config.require_shielded_vm, true)
  restrict_vm_external_ip                     = try(var.org_policy_config.restrict_vm_external_ip, false)
  allowed_locations                           = try(var.org_policy_config.allowed_locations, [])
  allowed_policy_member_domains               = try(var.org_policy_config.allowed_policy_member_domains, [])
  allowed_ingress_settings                    = try(var.org_policy_config.allowed_ingress_settings, ["ALLOW_INTERNAL_ONLY", "ALLOW_INTERNAL_AND_GCLB"])
  custom_policies                             = try(var.org_policy_config.custom_policies, {})
}
