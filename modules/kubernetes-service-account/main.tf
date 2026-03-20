resource "kubernetes_service_account" "k8s_service_accounts" {
  for_each = { for k, v in local.k8s_service_accounts_map : k => v if v.create_k8s_sa }

  metadata {
    name      = each.value.ksa_key
    namespace = each.value.namespace

    annotations = merge(
      each.value.k8s_sa_annotations,
      {
        "iam.gke.io/gcp-service-account" = each.value.gcp_service_account_email
      }
    )

    labels = merge(
      {
        "app.kubernetes.io/managed-by" = "terraform"
        "workload-identity-cluster"    = each.value.cluster_key
      },
      each.value.k8s_sa_labels
    )
  }

  automount_service_account_token = each.value.automount_service_account_token

  depends_on = [
    kubernetes_namespace.namespaces
  ]
}

