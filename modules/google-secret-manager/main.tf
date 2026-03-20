terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.7"
    }
  }
}

# Note: CA certificates must be managed externally (manually or via CI/CD)
# This module only manages Pub/Sub topics for rotation notifications

# ============================================================
# Pub/Sub Topics for Secret Rotation Notifications
# ============================================================

resource "google_pubsub_topic" "secret_rotation" {
  for_each = { for k, v in var.k3s_ca_certificate_refs : k => v if v.enable_pub_sub }

  name    = "${var.pub_sub_topic_prefix}-${each.key}"
  project = var.gcp_project_name

  labels = merge(
    {
      cluster = each.key
      purpose = "ca-cert-rotation"
    },
    try(each.value.labels, {})
  )
}

# ============================================================
# IAM for Pub/Sub Topic Access
# ============================================================

resource "google_pubsub_topic_iam_member" "secret_manager_publisher" {
  for_each = { for k, v in var.k3s_ca_certificate_refs : k => v if v.enable_pub_sub }

  project = var.gcp_project_name
  topic   = google_pubsub_topic.secret_rotation[each.key].name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-secretmanager.iam.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.gcp_project_name
}

