variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "k8s_clusters" {
  description = "Map of k8s cluster configurations for workload identity federation"
  type = map(object({
    issuer_uri          = string
    display_name        = optional(string)
    description         = optional(string)
    default_namespace   = optional(string, "default")
    allowed_audiences   = optional(list(string), ["sts.googleapis.com"])
    kubernetes_service_accounts = map(object({
      namespace              = optional(string) # If not specified, uses default_namespace
      gcp_service_account_email = string         # Email of the GCP service account
    }))
  }))
  default = {}
}

