locals {
  buckets = merge([
    for service, config in var.object_storage : {
      for bucket, name in config.buckets :
      "${service}-${bucket}" => {
        service       = service
        name          = name
        location      = config.location
        storage_class = config.storage_class
      }
    }
  ]...)
}

resource "google_service_account" "object_storage" {
  for_each     = var.object_storage
  project      = var.gcp_project_name
  account_id   = each.value.service_account_id
  display_name = each.value.display_name
  description  = each.value.description
}

resource "google_service_account_iam_member" "workload_identity" {
  for_each = {
    for service, config in var.object_storage : service => config.workload_identity
    if config.workload_identity != null
  }

  service_account_id = google_service_account.object_storage[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${each.value.pool_project_number}/locations/global/workloadIdentityPools/${each.value.pool_id}/subject/system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
}

resource "google_storage_bucket" "object_storage" {
  for_each                    = local.buckets
  project                     = var.gcp_project_name
  name                        = each.value.name
  location                    = each.value.location
  storage_class               = each.value.storage_class
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket_iam_member" "object_admin" {
  for_each = local.buckets
  bucket   = google_storage_bucket.object_storage[each.key].name
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${google_service_account.object_storage[each.value.service].email}"
}

resource "google_storage_bucket_iam_member" "bucket_reader" {
  for_each = local.buckets
  bucket   = google_storage_bucket.object_storage[each.key].name
  role     = "roles/storage.legacyBucketReader"
  member   = "serviceAccount:${google_service_account.object_storage[each.value.service].email}"
}

resource "google_storage_hmac_key" "object_storage" {
  for_each              = var.object_storage
  project               = var.gcp_project_name
  service_account_email = google_service_account.object_storage[each.key].email
}

resource "google_secret_manager_secret" "object_storage" {
  for_each  = var.object_storage
  project   = var.gcp_project_name
  secret_id = each.value.secret_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "object_storage" {
  for_each = var.object_storage
  secret   = google_secret_manager_secret.object_storage[each.key].id
  secret_data = jsonencode({
    access_key = google_storage_hmac_key.object_storage[each.key].access_id
    secret_key = google_storage_hmac_key.object_storage[each.key].secret
  })
}
