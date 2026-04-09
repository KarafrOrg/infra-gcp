output "applied_policies" {
  description = "List of organization policies that have been applied"
  value = concat(
    var.enforce_uniform_bucket_level_access ? ["storage.uniformBucketLevelAccess"] : [],
    var.restrict_public_ip_cloud_sql ? ["sql.restrictPublicIp"] : [],
    var.require_os_login ? ["compute.requireOsLogin"] : [],
    var.restrict_vpc_peering ? ["compute.restrictVpcPeering"] : [],
    var.disable_service_account_key_creation ? ["iam.disableServiceAccountKeyCreation"] : [],
    var.restrict_protocol_forwarding ? ["compute.restrictProtocolForwardingCreationForTypes"] : [],
    var.enforce_detailed_audit_logging ? ["gcp.detailedAuditLoggingMode"] : [],
    var.disable_default_network_creation ? ["compute.skipDefaultNetworkCreation"] : [],
    var.enforce_automatic_iam_grants_for_default_sa ? ["iam.automaticIamGrantsForDefaultServiceAccounts"] : [],
    var.require_shielded_vm ? ["compute.requireShieldedVm"] : [],
    var.restrict_vm_external_ip ? ["compute.vmExternalIpAccess"] : [],
    length(var.allowed_locations) > 0 ? ["gcp.resourceLocations"] : [],
    length(var.allowed_policy_member_domains) > 0 ? ["iam.allowedPolicyMemberDomains"] : [],
    length(var.allowed_ingress_settings) > 0 ? ["cloudfunctions.allowedIngressSettings"] : [],
    keys(var.custom_policies)
  )
}

output "policy_summary" {
  description = "Summary of organization policy enforcement"
  value = {
    security = {
      uniform_bucket_access            = var.enforce_uniform_bucket_level_access
      restrict_cloud_sql_public_ip     = var.restrict_public_ip_cloud_sql
      require_os_login                 = var.require_os_login
      disable_sa_key_creation          = var.disable_service_account_key_creation
      require_shielded_vm              = var.require_shielded_vm
      disable_default_sa_iam_grants    = var.enforce_automatic_iam_grants_for_default_sa
    }
    network = {
      restrict_vpc_peering        = var.restrict_vpc_peering
      restrict_protocol_forwarding = var.restrict_protocol_forwarding
      skip_default_network        = var.disable_default_network_creation
      restrict_vm_external_ip     = var.restrict_vm_external_ip
    }
    compliance = {
      allowed_locations               = var.allowed_locations
      allowed_policy_member_domains   = var.allowed_policy_member_domains
      detailed_audit_logging          = var.enforce_detailed_audit_logging
    }
    custom_policies_count = length(var.custom_policies)
  }
}

