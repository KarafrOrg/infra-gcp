resource "google_project_organization_policy" "uniform_bucket_level_access" {
  count   = var.enforce_uniform_bucket_level_access ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/storage.uniformBucketLevelAccess"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "restrict_public_ip_cloud_sql" {
  count   = var.restrict_public_ip_cloud_sql ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/sql.restrictPublicIp"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "require_os_login" {
  count   = var.require_os_login ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/compute.requireOsLogin"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "require_shielded_vm" {
  count   = var.require_shielded_vm ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/compute.requireShieldedVm"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "disable_service_account_key_creation" {
  count   = var.disable_service_account_key_creation ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/iam.disableServiceAccountKeyCreation"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "disable_automatic_iam_grants" {
  count   = var.enforce_automatic_iam_grants_for_default_sa ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/iam.automaticIamGrantsForDefaultServiceAccounts"

  boolean_policy {
    enforced = false
  }
}

resource "google_project_organization_policy" "restrict_vpc_peering" {
  count   = var.restrict_vpc_peering ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/compute.restrictVpcPeering"

  list_policy {
    allow {
      all = true
    }
  }
}

resource "google_project_organization_policy" "restrict_protocol_forwarding" {
  count   = var.restrict_protocol_forwarding ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/compute.restrictProtocolForwardingCreationForTypes"

  list_policy {
    deny {
      all = true
    }
  }
}

resource "google_project_organization_policy" "skip_default_network" {
  count   = var.disable_default_network_creation ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/compute.skipDefaultNetworkCreation"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "restrict_vm_external_ip" {
  count   = var.restrict_vm_external_ip ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/compute.vmExternalIpAccess"

  list_policy {
    deny {
      all = true
    }
  }
}

resource "google_project_organization_policy" "allowed_locations" {
  count   = length(var.allowed_locations) > 0 ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/gcp.resourceLocations"

  list_policy {
    allow {
      values = var.allowed_locations
    }
  }
}

resource "google_project_organization_policy" "allowed_policy_member_domains" {
  count   = length(var.allowed_policy_member_domains) > 0 ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/iam.allowedPolicyMemberDomains"

  list_policy {
    allow {
      values = var.allowed_policy_member_domains
    }
  }
}

resource "google_project_organization_policy" "cloud_function_ingress" {
  count   = length(var.allowed_ingress_settings) > 0 ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/cloudfunctions.allowedIngressSettings"

  list_policy {
    allow {
      values = var.allowed_ingress_settings
    }
  }
}

resource "google_project_organization_policy" "detailed_audit_logging" {
  count   = var.enforce_detailed_audit_logging ? 1 : 0
  project = var.gcp_project_name

  constraint = "constraints/gcp.detailedAuditLoggingMode"

  boolean_policy {
    enforced = true
  }
}

resource "google_project_organization_policy" "custom_boolean" {
  for_each = {
    for k, v in var.custom_policies : k => v
    if v.policy_type == "boolean"
  }

  project    = var.gcp_project_name
  constraint = each.value.constraint

  boolean_policy {
    enforced = each.value.enforce
  }
}

resource "google_project_organization_policy" "custom_list" {
  for_each = {
    for k, v in var.custom_policies : k => v
    if v.policy_type == "list"
  }

  project    = var.gcp_project_name
  constraint = each.value.constraint

  list_policy {
    dynamic "allow" {
      for_each = each.value.allow_all == true ? [1] : []
      content {
        all = true
      }
    }

    dynamic "allow" {
      for_each = each.value.allow != null && each.value.allow_all != true ? [1] : []
      content {
        values = each.value.allow
      }
    }

    dynamic "deny" {
      for_each = each.value.deny_all == true ? [1] : []
      content {
        all = true
      }
    }

    dynamic "deny" {
      for_each = each.value.deny != null && each.value.deny_all != true ? [1] : []
      content {
        values = each.value.deny
      }
    }
  }
}
