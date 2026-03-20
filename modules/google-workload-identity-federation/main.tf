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
    jwks_json         = try(each.value.jwks_json, null)
  }

  attribute_mapping = {
    "google.subject"                = "assertion.sub"
    "attribute.namespace"           = "assertion['kubernetes.io/serviceaccount/namespace']"
    "attribute.service_account"     = "assertion['kubernetes.io/serviceaccount/service-account.name']"
    "attribute.service_account_uid" = "assertion['kubernetes.io/serviceaccount/uid']"
  }
}

locals {
  # Flatten K8s service accounts to create IAM bindings
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
}

resource "google_service_account_iam_member" "workload_identity_bindings" {
  for_each = local.k8s_service_accounts_map

  service_account_id = "projects/${var.gcp_project_name}/serviceAccounts/${each.value.gcp_service_account_email}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.k8s_clusters[each.value.cluster_key].name}/attribute.namespace/${each.value.namespace}/attribute.service_account/${each.value.ksa_key}"

  depends_on = [
    google_iam_workload_identity_pool.k8s_clusters,
    google_iam_workload_identity_pool_provider.k8s_oidc
  ]
}
