variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "k3s_ca_certificate_refs" {
  description = "Map of K3s cluster CA certificate references for Pub/Sub topic creation (certificates must be managed externally)"
  type = map(object({
    enable_pub_sub = optional(bool, true)
    labels         = optional(map(string), {})
  }))
  default = {}
}

variable "pub_sub_topic_prefix" {
  description = "Prefix for Pub/Sub topic names for secret rotation notifications"
  type        = string
  default     = "k3s-ca-rotation"
}
