terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.7"
    }
  }
}

# ============================================================
# Pub/Sub Topics for Secret Rotation Notifications
# ============================================================

resource "google_pubsub_topic" "secret_rotation" {
  for_each = { for k, v in var.k8s_ca_certificates : k => v if v.enable_pub_sub }

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
# Secret Manager - K3s CA Certificates
# ============================================================

resource "google_secret_manager_secret" "k8s_ca_cert" {
  for_each  = var.k8s_ca_certificates
  secret_id = "${each.key}-ca-certificate"
  project   = var.gcp_project_name

  replication {
    dynamic "auto" {
      for_each = var.secret_replication_automatic ? [1] : []
      content {}
    }
  }

  rotation {
    rotation_period = each.value.rotation_period
  }

  dynamic "topics" {
    for_each = each.value.enable_pub_sub ? [1] : []
    content {
      name = google_pubsub_topic.secret_rotation[each.key].id
    }
  }

  labels = merge(
    {
      cluster = each.key
      type    = "k8s-ca-cert"
    },
    try(each.value.labels, {})
  )
}

resource "google_secret_manager_secret_version" "k8s_ca_cert" {
  for_each    = var.k8s_ca_certificates
  secret      = google_secret_manager_secret.k8s_ca_cert[each.key].id
  secret_data = each.value.ca_certificate
}

# ============================================================
# IAM for Pub/Sub Topic Access
# ============================================================

resource "google_pubsub_topic_iam_member" "secret_manager_publisher" {
  for_each = { for k, v in var.k8s_ca_certificates : k => v if v.enable_pub_sub }

  project = var.gcp_project_name
  topic   = google_pubsub_topic.secret_rotation[each.key].name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-secretmanager.iam.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.gcp_project_name
}

