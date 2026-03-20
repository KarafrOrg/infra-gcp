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
}

provider "kubernetes" {
  client_certificate     = var.KUBE_CLIENT_CERT_DATA
  client_key             = var.KUBE_CLIENT_KEY_DATA
  cluster_ca_certificate = var.KUBE_CLUSTER_CA_CERT_DATA
  host                   = var.KUBE_HOST
}
