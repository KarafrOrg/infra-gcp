locals {
  k8s_service_accounts = flatten([
    for cluster_key, cluster_value in var.k8s_clusters : [
      for ksa_key, ksa_value in cluster_value.kubernetes_service_accounts : {
        cluster_key                     = cluster_key
        ksa_key                         = ksa_key
        namespace                       = coalesce(ksa_value.namespace, cluster_value.default_namespace)
        create_k8s_sa                   = ksa_value.create_k8s_sa
        gcp_service_account_email       = ksa_value.gcp_service_account_email
        k8s_sa_annotations              = ksa_value.k8s_sa_annotations
        k8s_sa_labels                   = ksa_value.k8s_sa_labels
        automount_service_account_token = ksa_value.automount_service_account_token
      }
    ]
  ])

  k8s_service_accounts_map = {
    for item in local.k8s_service_accounts :
    "${item["cluster_key"]}-${item["namespace"]}-${item["ksa_key"]}" => item
  }
}
