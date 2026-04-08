variable "k8s_clusters" {
  description = "Map of k8s cluster configurations for Kubernetes service account creation"
  type = map(object({
    default_namespace = optional(string, "default")
    kubernetes_service_accounts = map(object({
      namespace                       = optional(string) # If not specified, uses default_namespace
      gcp_service_account_email       = string           # Email of the GCP service account
      create_k8s_sa                   = optional(bool, true)
      k8s_sa_annotations              = optional(map(string), {})
      k8s_sa_labels                   = optional(map(string), {})
      automount_service_account_token = optional(bool, true)
    }))
  }))
  default = {}
}
