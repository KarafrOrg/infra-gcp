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
}

variable "gcp_service_account_email" {
  type = string
}
# endregion

# region Service accounts
variable google_service_service_accounts {
  description = "Map of service account configurations"
  type = map(object({
    display_name = optional(string)
    description = optional(string)
    roles = optional(list(string))
  }))
  default = {}
}
# endregion
