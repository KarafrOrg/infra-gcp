variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "object_storage" {
  description = "Object storage workloads, buckets, and S3-compatible credentials"
  type = map(object({
    service_account_id = string
    display_name       = string
    description        = string
    secret_id          = string
    location           = string
    storage_class      = optional(string, "STANDARD")
    buckets            = map(string)
    workload_identity = optional(object({
      pool_project_number = string
      pool_id             = string
      namespace           = string
      service_account     = string
    }))
  }))
  default = {}
}
