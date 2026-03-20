variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "k8s_ca_certificates" {
  description = "Map of K3s cluster CA certificates to store in Secret Manager"
  type = map(object({
    ca_certificate      = string           # PEM-encoded CA certificate
    display_name        = optional(string)
    description         = optional(string)
    rotation_period     = optional(string, "2592000s") # 30 days default
    enable_pub_sub      = optional(bool, true)
    labels              = optional(map(string), {})
  }))
  default = {}
}

variable "secret_replication_automatic" {
  description = "Whether to use automatic replication for secrets"
  type        = bool
  default     = true
}

variable "pub_sub_topic_prefix" {
  description = "Prefix for Pub/Sub topic names for secret rotation notifications"
  type        = string
  default     = "secret-rotation"
}
