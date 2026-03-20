output "kubernetes_service_accounts" {
  description = "Map of created Kubernetes service accounts"
  value = {
    for k, v in kubernetes_service_account.k8s_service_accounts :
    k => {
      name        = v.metadata[0].name
      namespace   = v.metadata[0].namespace
      annotations = v.metadata[0].annotations
      labels      = v.metadata[0].labels
    }
  }
}
