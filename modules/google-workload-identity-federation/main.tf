# Kubernetes Workload Identity Pools
resource "google_iam_workload_identity_pool" "k8s_clusters" {
  for_each                  = var.k8s_clusters
  workload_identity_pool_id = each.key
  display_name              = try(each.value.display_name, each.key)
  description               = try(each.value.description, "Workload Identity Pool for k8s cluster ${each.key}")
  project                   = var.gcp_project_name
}

resource "google_iam_workload_identity_pool_provider" "k8s_oidc" {
  for_each = var.k8s_clusters

  project                            = var.gcp_project_name
  workload_identity_pool_id          = google_iam_workload_identity_pool.k8s_clusters[each.key].workload_identity_pool_id
  workload_identity_pool_provider_id = "oidc-provider"

  oidc {
    issuer_uri        = each.value.issuer_uri
    allowed_audiences = each.value.allowed_audiences
    jwks_json         = try(each.value.jwks_json_data, null) != null ? base64decode(each.value.jwks_json_data) : null
  }

  attribute_mapping = {
    "google.subject"                = "assertion.sub"
    "attribute.namespace"           = "assertion['kubernetes.io/serviceaccount/namespace']"
    "attribute.service_account"     = "assertion['kubernetes.io/serviceaccount/service-account.name']"
    "attribute.service_account_uid" = "assertion['kubernetes.io/serviceaccount/uid']"
  }
}

# Generic Workload Identity Pools (GitHub, GitLab, AWS, etc.)
resource "google_iam_workload_identity_pool" "external_pools" {
  for_each = var.external_identity_pools

  project                   = var.gcp_project_name
  workload_identity_pool_id = each.key
  display_name              = try(each.value.display_name, each.key)
  description               = try(each.value.description, "Workload Identity Pool for ${each.key}")
  disabled                  = try(each.value.disabled, false)
}

locals {
  # Flatten external providers from all pools
  external_providers = flatten([
    for pool_key, pool_value in var.external_identity_pools : [
      for provider_key, provider_value in pool_value.providers : {
        pool_key      = pool_key
        provider_key  = provider_key
        provider      = provider_value
      }
    ]
  ])

  external_providers_map = {
    for item in local.external_providers :
    "${item.pool_key}-${item.provider_key}" => item
  }
}

resource "google_iam_workload_identity_pool_provider" "external_providers" {
  for_each = local.external_providers_map

  project                            = var.gcp_project_name
  workload_identity_pool_id          = google_iam_workload_identity_pool.external_pools[each.value.pool_key].workload_identity_pool_id
  workload_identity_pool_provider_id = each.value.provider_key
  display_name                       = try(each.value.provider.display_name, each.value.provider_key)
  description                        = try(each.value.provider.description, "Identity provider ${each.value.provider_key}")
  disabled                           = try(each.value.provider.disabled, false)

  attribute_mapping   = each.value.provider.attribute_mapping
  attribute_condition = try(each.value.provider.attribute_condition, null)

  # OIDC provider (GitHub, GitLab, custom)
  dynamic "oidc" {
    for_each = try(each.value.provider.oidc, null) != null ? [each.value.provider.oidc] : []
    content {
      issuer_uri        = oidc.value.issuer_uri
      allowed_audiences = try(oidc.value.allowed_audiences, null)
      jwks_json         = try(oidc.value.jwks_json, null)
    }
  }

  # AWS provider
  dynamic "aws" {
    for_each = try(each.value.provider.aws, null) != null ? [each.value.provider.aws] : []
    content {
      account_id = aws.value.account_id
    }
  }

  # SAML provider
  dynamic "saml" {
    for_each = try(each.value.provider.saml, null) != null ? [each.value.provider.saml] : []
    content {
      idp_metadata_xml = saml.value.idp_metadata_xml
    }
  }
}

locals {
  # K8s service accounts
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
    "${item.cluster_key}-${item.namespace}-${item.ksa_key}" => item
  }

  # External service account bindings
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
    "${item.pool_key}-${item.binding_key}" => item
  }
}

# K8s workload identity bindings
resource "google_service_account_iam_member" "k8s_workload_identity_bindings" {
  for_each = local.k8s_service_accounts_map

  service_account_id = "projects/${var.gcp_project_name}/serviceAccounts/${each.value.gcp_service_account_email}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.k8s_clusters[each.value.cluster_key].name}/attribute.namespace/${each.value.namespace}/attribute.service_account/${each.value.ksa_key}"

  depends_on = [
    google_iam_workload_identity_pool.k8s_clusters,
    google_iam_workload_identity_pool_provider.k8s_oidc
  ]
}

# External workload identity bindings (GitHub, GitLab, etc.)
resource "google_service_account_iam_member" "external_workload_identity_bindings" {
  for_each = local.external_bindings_map

  service_account_id = "projects/${var.gcp_project_name}/serviceAccounts/${each.value.service_account_email}"
  role               = each.value.role
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.external_pools[each.value.pool_key].name}/attribute.${each.value.attribute_name}/${each.value.attribute_value}"

  depends_on = [
    google_iam_workload_identity_pool.external_pools,
    google_iam_workload_identity_pool_provider.external_providers
  ]
}

