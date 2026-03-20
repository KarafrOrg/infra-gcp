output "workload_identity_pools" {
  description = "Map of workload identity pools"
  value = {
    for k, v in google_iam_workload_identity_pool.k8s_clusters :
    k => {
      name         = v.name
      pool_id      = v.workload_identity_pool_id
      display_name = v.display_name
      state        = v.state
    }
  }
}

output "workload_identity_providers" {
  description = "Map of workload identity providers"
  value = {
    for k, v in google_iam_workload_identity_pool_provider.k8s_oidc :
    k => {
      name         = v.name
      provider_id  = v.workload_identity_pool_provider_id
      issuer_uri   = v.oidc[0].issuer_uri
      state        = v.state
    }
  }
}

output "service_account_bindings" {
  description = "List of service account IAM bindings for workload identity"
  value = [
    for k, v in google_service_account_iam_member.workload_identity_bindings :
    {
      binding_id            = k
      service_account_id    = v.service_account_id
      role                  = v.role
      member                = v.member
    }
  ]
}

