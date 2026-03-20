# ============================================================
# GCP Service Accounts Outputs
# ============================================================

publish_output "gcp_service_accounts" {
  description = "Created GCP service accounts"
  value       = component.google-service-account.service_accounts
}

# ============================================================
# Secret Manager Outputs
# ============================================================

publish_output "rotation_pub_sub_topics" {
  description = "Pub/Sub topics for CA certificate rotation notifications"
  value       = component.google-secret-manager.rotation_pub_sub_topics
}

# ============================================================
# Workload Identity Federation Outputs
# ============================================================

publish_output "workload_identity_pools" {
  description = "Workload Identity pools"
  value       = component.google-workload-identity-federation.workload_identity_pools
}

publish_output "workload_identity_providers" {
  description = "Workload Identity providers"
  value       = component.google-workload-identity-federation.workload_identity_providers
}

publish_output "service_account_bindings" {
  description = "List of service account IAM bindings for workload identity"
  value       = component.google-workload-identity-federation.service_account_bindings
}

# ============================================================
# Kubernetes Service Accounts Outputs
# ============================================================

publish_output "kubernetes_service_accounts" {
  description = "Created Kubernetes service accounts"
  value       = component.kubernetes-service-account.kubernetes_service_accounts
}

publish_output "kubernetes_namespaces" {
  description = "Created Kubernetes namespaces"
  value       = component.kubernetes-service-account.kubernetes_namespaces
}

# ============================================================
# Summary Output
# ============================================================

publish_output "deployment_summary" {
  description = "Summary of the K3s Workload Identity Federation deployment"
  value = {
    gcp_project = var.gcp_project_name
    region      = var.gcp_region

    service_accounts_count     = length(component.google-service-account.service_accounts)
    rotation_topics_count      = length(component.google-secret-manager.rotation_pub_sub_topics)
    wif_pools_count            = length(component.google-workload-identity-federation.workload_identity_pools)
    k8s_namespaces_count       = length(component.kubernetes-service-account.kubernetes_namespaces)
    k8s_service_accounts_count = length(component.kubernetes-service-account.kubernetes_service_accounts)

    rotation_topics = [
      for topic in component.google-secret-manager.rotation_pub_sub_topics : topic.name
    ]
  }
}

