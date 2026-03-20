variable "workload_identity_federations" {
  type = map(object({
    issuer_uri                = string
    namespace                 = string
    ksa_name                  = string
    gcp_service_account_email = string
    display_name              = optional(string)
    description               = optional(string)
  }))
  default = {}
}

variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}
