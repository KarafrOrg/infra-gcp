variable "service_accounts" {
  description = "Map of service account configurations"
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    roles        = optional(list(string))
  }))
  default = {}
}
