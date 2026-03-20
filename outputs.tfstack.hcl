# ============================================================
# GCP Service Accounts Outputs
# ============================================================

output "gcp_service_accounts" {
  description = "Created GCP service accounts"
  value       = component.google-service-account.service_accounts
  type = map(object({
    email        = string
    display_name = string
    description  = string
    roles        = list(string)
  }))
}

# ============================================================
# Secret Manager Outputs
# ============================================================

output "k8s_ca_secrets" {
  description = "K3s CA certificate secrets"
  value       = component.google-secret-manager.k8s_ca_secrets
  type = map(object({
    secret_id      = string
    secret_name    = string
    secret_version = string
    project        = string
  }))
  sensitive = true
}

output "rotation_pub_sub_topics" {
  description = "Pub/Sub topics for CA certificate rotation notifications"
  value       = component.google-secret-manager.rotation_pub_sub_topics
  type = map(object({
    name = string
    id   = string
  }))
}

# ============================================================
# Workload Identity Federation Outputs
# ============================================================

output "workload_identity_pools" {
  description = "Workload Identity pools"
  value       = component.google-workload-identity-federation.workload_identity_pools
  type = map(object({
    name         = string
    pool_id      = string
    display_name = string
    state        = string
  }))
}

output "workload_identity_providers" {
  description = "Workload Identity providers"
  value       = component.google-workload-identity-federation.workload_identity_providers
  type = map(object({
    name        = string
    provider_id = string
    issuer_uri  = string
    state       = string
  }))
}

output "service_account_bindings" {
  description = "List of service account IAM bindings for workload identity"
  value       = component.google-workload-identity-federation.service_account_bindings
  type = list(object({
    binding_id         = string
    service_account_id = string
    role               = string
    member             = string
  }))
}

# ============================================================
# Kubernetes Service Accounts Outputs
# ============================================================

output "kubernetes_service_accounts" {
  description = "Created Kubernetes service accounts"
  value       = component.kubernetes-service-account.kubernetes_service_accounts
  type = map(object({
    name        = string
    namespace   = string
    annotations = map(string)
    labels      = map(string)
  }))
}

output "kubernetes_namespaces" {
  description = "Created Kubernetes namespaces"
  value       = component.kubernetes-service-account.kubernetes_namespaces
  type = map(object({
    name = string
  }))
}

# ============================================================
# Summary Output
# ============================================================

output "deployment_summary" {
  description = "Summary of the K3s Workload Identity Federation deployment"
  value = {
    gcp_project = var.gcp_project_name
    region      = var.gcp_region

    service_accounts_count = length(component.google-service-account.service_accounts)
    ca_certificates_count  = length(component.google-secret-manager.k8s_ca_secrets)
    wif_pools_count        = length(component.google-workload-identity-federation.workload_identity_pools)
    k8s_namespaces_count   = length(component.kubernetes-service-account.kubernetes_namespaces)
    k8s_service_accounts_count = length(component.kubernetes-service-account.kubernetes_service_accounts)

    rotation_topics = [
      for topic in component.google-secret-manager.rotation_pub_sub_topics : topic.name
    ]
  }
}

