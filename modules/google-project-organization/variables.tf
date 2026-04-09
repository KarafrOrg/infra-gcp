variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "enforce_uniform_bucket_level_access" {
  description = "Enforce uniform bucket-level access for Cloud Storage"
  type        = bool
  default     = true
}

variable "restrict_public_ip_cloud_sql" {
  description = "Restrict public IP addresses on Cloud SQL instances"
  type        = bool
  default     = true
}

variable "require_os_login" {
  description = "Require OS Login for SSH access to VMs"
  type        = bool
  default     = true
}

variable "restrict_vpc_peering" {
  description = "Restrict VPC peering to authorized networks"
  type        = bool
  default     = true
}

variable "disable_service_account_key_creation" {
  description = "Disable creation of service account keys (use Workload Identity instead)"
  type        = bool
  default     = true
}

variable "restrict_protocol_forwarding" {
  description = "Restrict protocol forwarding on VMs"
  type        = bool
  default     = true
}

variable "enforce_detailed_audit_logging" {
  description = "Enforce detailed audit logging mode"
  type        = bool
  default     = true
}

variable "restrict_shared_vpc_subnetworks" {
  description = "Restrict which Shared VPC subnetworks can be used"
  type        = bool
  default     = false
}

variable "disable_default_network_creation" {
  description = "Skip default network creation for new projects"
  type        = bool
  default     = true
}

variable "enforce_automatic_iam_grants_for_default_sa" {
  description = "Disable automatic IAM grants for default service accounts"
  type        = bool
  default     = true
}

variable "allowed_policy_member_domains" {
  description = "List of allowed customer IDs for IAM policy members (empty = allow all)"
  type        = list(string)
  default     = []
}

variable "allowed_ingress_settings" {
  description = "Allowed ingress settings for Cloud Functions"
  type        = list(string)
  default     = ["ALLOW_INTERNAL_ONLY", "ALLOW_INTERNAL_AND_GCLB"]
}

variable "require_shielded_vm" {
  description = "Require Shielded VM for Compute Engine instances"
  type        = bool
  default     = true
}

variable "restrict_vm_external_ip" {
  description = "Restrict external IP addresses on VM instances"
  type        = bool
  default     = false
}

variable "allowed_locations" {
  description = "List of allowed resource locations (regions/zones)"
  type        = list(string)
  default = [
    "in:us-locations",
    "in:eu-locations"
  ]
}

variable "custom_policies" {
  description = "Map of custom organization policies"
  type = map(object({
    constraint  = string
    policy_type = string # "boolean" or "list"
    enforce     = optional(bool)
    allow       = optional(list(string))
    deny        = optional(list(string))
    allow_all   = optional(bool)
    deny_all    = optional(bool)
  }))
  default = {}
}
