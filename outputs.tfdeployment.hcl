publish_output "gcp_service_accounts" {
  description = "Created GCP service accounts"
  value       = component.google-service-account.service_accounts
}

publish_output "rotation_pub_sub_topics" {
  description = "Pub/Sub topics for CA certificate rotation notifications"
  value       = component.google-secret-manager.rotation_pub_sub_topics
}

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

publish_output "kubernetes_service_accounts" {
  description = "Created Kubernetes service accounts"
  value       = component.kubernetes-service-account.kubernetes_service_accounts
}
