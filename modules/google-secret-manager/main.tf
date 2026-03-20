resource "google_project_service" "secretmanager" {
  project = var.gcp_project_name
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "serviceusage" {
  project = var.gcp_project_name
  service = "serviceusage.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service_identity" "secretmanager_agent" {
  provider = google-beta
  project  = var.gcp_project_name
  service  = "secretmanager.googleapis.com"

  depends_on = [
    google_project_service.secretmanager,
    google_project_service.serviceusage
  ]
}

resource "google_pubsub_topic" "secret_rotation" {
  for_each = { for k, v in var.k8s_ca_certificate_refs : k => v if v.enable_pub_sub }

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

resource "google_pubsub_topic_iam_member" "secret_manager_publisher" {
  for_each = { for k, v in var.k8s_ca_certificate_refs : k => v if v.enable_pub_sub }

  project = var.gcp_project_name
  topic   = google_pubsub_topic.secret_rotation[each.key].name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_project_service_identity.secretmanager_agent.email}"

  depends_on = [
    google_project_service_identity.secretmanager_agent
  ]
}

data "google_project" "project" {
  project_id = var.gcp_project_name
}
