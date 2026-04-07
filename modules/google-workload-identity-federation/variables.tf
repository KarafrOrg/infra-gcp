variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "k8s_clusters" {
  description = "Map of k8s cluster configurations for workload identity federation"
  type = map(object({
    issuer_uri        = string
    display_name      = optional(string)
    description       = optional(string)
    default_namespace = optional(string, "default")
    allowed_audiences = optional(list(string), ["sts.googleapis.com"])
    kubernetes_service_accounts = map(object({
      namespace                 = optional(string)
      gcp_service_account_email = string
    }))
    jwks_json_data = optional(string)
  }))
  default = {}
}

variable "external_identity_pools" {
  description = "Map of external identity pool configurations (GitHub Actions, GitLab CI, AWS, etc.)"
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    disabled     = optional(bool, false)

    providers = map(object({
      display_name        = optional(string)
      description         = optional(string)
      disabled            = optional(bool, false)
      attribute_mapping   = optional(map(string))
      attribute_condition = optional(string)

      # OIDC provider configuration (GitHub, GitLab, custom)
      oidc = optional(object({
        issuer_uri        = string
        allowed_audiences = optional(list(string))
        jwks_json         = optional(string)
      }))

      # AWS provider configuration
      aws = optional(object({
        account_id = string
      }))

      # SAML provider configuration
      saml = optional(object({
        idp_metadata_xml = string
      }))
    }))

    # Service account bindings for this pool
    service_account_bindings = optional(map(object({
      service_account_email = string
      role                  = optional(string, "roles/iam.workloadIdentityUser")
      # Attribute-based access control
      attribute_name  = string
      attribute_value = string
    })), {})
  }))
  default = {}
}
