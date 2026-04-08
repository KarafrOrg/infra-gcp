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

resource "google_iam_workload_identity_pool_provider" "external_providers" {
  for_each = local.external_providers_map

  project                            = var.gcp_project_name
  workload_identity_pool_id          = google_iam_workload_identity_pool.external_pools[each.value["pool_key"]].workload_identity_pool_id
  workload_identity_pool_provider_id = each.value["provider_key"]
  display_name                       = try(each.value["provider"]["display_name"], each.value["provider_key"])
  description                        = try(each.value["provider"]["description"], "Identity provider ${each.value["provider_key"]}")
  disabled                           = try(each.value["provider"]["disabled"], false)

  attribute_mapping   = each.value["provider"]["attribute_mapping"]
  attribute_condition = try(each.value["provider"]["attribute_condition"], null)

  dynamic "oidc" {
    for_each = try(each.value["provider"]["oidc"], null) != null ? [each.value["provider"]["oidc"]] : []
    content {
      issuer_uri        = oidc.value["issuer_uri"]
      allowed_audiences = try(oidc.value["allowed_audiences"], null)
      jwks_json         = try(oidc.value["jwks_json"], null)
    }
  }

  dynamic "aws" {
    for_each = try(each.value["provider"]["aws"], null) != null ? [each.value["provider"]["aws"]] : []
    content {
      account_id = aws.value["account_id"]
    }
  }

  dynamic "saml" {
    for_each = try(each.value["provider"]["saml"], null) != null ? [each.value["provider"]["saml"]] : []
    content {
      idp_metadata_xml = saml.value["idp_metadata_xml"]
    }
  }
}

resource "google_service_account_iam_member" "k8s_workload_identity_bindings" {
  for_each = local.k8s_service_accounts_map

  service_account_id = "projects/${var.gcp_project_name}/serviceAccounts/${each.value["gcp_service_account_email"]}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.k8s_clusters[each.value["cluster_key"]].name}/attribute.namespace/${each.value["namespace"]}/attribute.service_account/${each.value["ksa_key"]}"

  depends_on = [
    google_iam_workload_identity_pool.k8s_clusters,
    google_iam_workload_identity_pool_provider.k8s_oidc
  ]
}

resource "google_service_account_iam_member" "external_workload_identity_bindings" {
  for_each = local.external_bindings_map

  service_account_id = "projects/${var.gcp_project_name}/serviceAccounts/${each.value["service_account_email"]}"
  role               = each.value["role"]
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.external_pools[each.value["pool_key"]].name}/attribute.${each.value["attribute_name"]}/${each.value["attribute_value"]}"

  depends_on = [
    google_iam_workload_identity_pool.external_pools,
    google_iam_workload_identity_pool_provider.external_providers
  ]
}

