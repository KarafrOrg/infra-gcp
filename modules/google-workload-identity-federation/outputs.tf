output "workload_identity_pools" {
  description = "Map of workload identity pools"
  value = merge(
    {
      for k, v in google_iam_workload_identity_pool.k8s_clusters :
      k => {
        name         = v.name
        pool_id      = v.workload_identity_pool_id
        display_name = v.display_name
        state        = v.state
        type         = "kubernetes"
      }
    },
    {
      for k, v in google_iam_workload_identity_pool.external_pools :
      k => {
        name         = v.name
        pool_id      = v.workload_identity_pool_id
        display_name = v.display_name
        state        = v.state
        disabled     = v.disabled
        type         = "external"
      }
    }
  )
}

output "workload_identity_providers" {
  description = "Map of workload identity providers"
  value = merge(
    {
      for k, v in google_iam_workload_identity_pool_provider.k8s_oidc :
      k => {
        name        = v.name
        provider_id = v.workload_identity_pool_provider_id
        issuer_uri  = v.oidc[0].issuer_uri
        state       = v.state
        type        = "kubernetes"
      }
    },
    {
      for k, v in google_iam_workload_identity_pool_provider.external_providers :
      k => {
        name        = v.name
        provider_id = v.workload_identity_pool_provider_id
        state       = v.state
        type        = "external"
      }
    }
  )
}

output "service_account_bindings" {
  description = "List of service account IAM bindings for workload identity"
  value = concat(
    [
      for k, v in google_service_account_iam_member.k8s_workload_identity_bindings :
      {
        binding_id         = k
        service_account_id = v.service_account_id
        role               = v.role
        member             = v.member
        type               = "kubernetes"
      }
    ],
    [
      for k, v in google_service_account_iam_member.external_workload_identity_bindings :
      {
        binding_id         = k
        service_account_id = v.service_account_id
        role               = v.role
        member             = v.member
        type               = "external"
      }
    ]
  )
}

output "external_provider_names" {
  description = "Map of external provider names for use in CI/CD authentication"
  value = {
    for k, v in google_iam_workload_identity_pool_provider.external_providers :
    k => v.name
  }
}
