locals {
  k8s_service_accounts = flatten([
    for cluster_key, cluster_value in var.k8s_clusters : [
      for ksa_key, ksa_value in cluster_value.kubernetes_service_accounts : {
        cluster_key               = cluster_key
        ksa_key                   = ksa_key
        namespace                 = coalesce(ksa_value.namespace, cluster_value.default_namespace)
        gcp_service_account_email = ksa_value.gcp_service_account_email
      }
    ]
  ])

  k8s_service_accounts_map = {
    for item in local.k8s_service_accounts :
    "${item["cluster_key"]}-${item["namespace"]}-${item["ksa_key"]}" => item
  }

  external_bindings = flatten([
    for pool_key, pool_value in var.external_identity_pools : [
      for binding_key, binding_value in try(pool_value.service_account_bindings, {}) : {
        pool_key              = pool_key
        binding_key           = binding_key
        service_account_email = binding_value.service_account_email
        role                  = try(binding_value.role, "roles/iam.workloadIdentityUser")
        attribute_name        = binding_value.attribute_name
        attribute_value       = binding_value.attribute_value
      }
    ]
  ])

  external_bindings_map = {
    for item in local.external_bindings :
    "${item["pool_key"]}-${item["binding_key"]}" => item
  }

  external_providers = flatten([
    for pool_key, pool_value in var.external_identity_pools : [
      for provider_key, provider_value in pool_value.providers : {
        pool_key     = pool_key
        provider_key = provider_key
        provider     = provider_value
      }
    ]
  ])

  external_providers_map = {
    for item in local.external_providers :
    "${item["pool_key"]}-${item["provider_key"]}" => item
  }
}