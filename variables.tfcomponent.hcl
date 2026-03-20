# Region GCP provider variables
variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
}

variable "gcp_identity_token" {
  type        = string
  ephemeral   = true
  description = "JWT identity token"
}

variable "gcp_audience" {
  type        = string
  description = "The fully qualified GCP identity provider name, e.g. '//iam.googleapis.com/projects/123456789/locations/global/workloadIdentityPools/my-tfc-pool/providers/the-tfc-provider'. This is the same audience value as you've configured in the identity_token block. Google requires this audience value to be set in the service account file itself as well as the token claim."
  sensitive   = true
  ephemeral   = true
}

variable "gcp_service_account_email" {
  type      = string
  sensitive = true
  ephemeral = true
}
# endregion

# region Kubernetes provider variables
variable "kube_client_cert_data" {
  description = "Base64 encoded client certificate data for Kubernetes provider"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "kube_client_key_data" {
  description = "Base64 encoded client key data for Kubernetes provider"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "kube_client_ca_cert" {
  description = "Base64 encoded cluster CA certificate data for Kubernetes provider"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "kube_host" {
  description = "Kubernetes API server host URL for Kubernetes provider"
  type        = string
  ephemeral   = true
}
# endregion

# region Kubernetes provider variables
variable "k8s_kubeconfig_path" {
  description = "Path to kubeconfig file for k8s cluster"
  type        = string
  default     = "~/.kube/config"
}

variable "k8s_context_name" {
  description = "Kubernetes context name for k8s cluster"
  type        = string
}
# endregion

# region Service accounts
variable gcp_service_service_accounts {
  description = "Map of service account configurations"
  type = map(object({
    display_name = optional(string)
    description = optional(string)
    roles = optional(list(string))
  }))
  default = {}
}
# endregion

# region k8s CA Certificate References (managed externally in Secret Manager)
variable "k8s_ca_certificate_refs" {
  description = "Map of k8s clusters for Pub/Sub topic creation (CA certificates must be managed externally)"
  type = map(object({
    enable_pub_sub = optional(bool, true)
    labels = optional(map(string), {})
  }))
  default = {}
}

variable "pub_sub_topic_prefix" {
  description = "Prefix for Pub/Sub topic names for secret rotation notifications"
  type        = string
  default     = "k8s-ca-rotation"
}

variable "secret_replication_automatic" {
  description = "Whether to use automatic replication for secrets (true) or user-managed replication (false)"
  type        = bool
  default     = true
}
# endregion

# region k8s Workload Identity Federation
variable "k8s_clusters" {
  description = "Map of k8s cluster configurations for workload identity federation"
  type = map(object({
    issuer_uri = string
    display_name = optional(string)
    description = optional(string)
    default_namespace = optional(string, "default")
    allowed_audiences = optional(list(string), ["sts.googleapis.com"])
    kubernetes_service_accounts = map(object({
      namespace = optional(string)
      gcp_service_account_email = string
      create_k8s_sa = optional(bool, true)
      k8s_sa_annotations = optional(map(string), {})
      k8s_sa_labels = optional(map(string), {})
      automount_service_account_token = optional(bool, true)
    }))
  }))
  default = {}
}
# endregion