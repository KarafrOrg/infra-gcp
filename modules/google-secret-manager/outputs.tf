output "k8s_ca_secrets" {
  description = "Map of K3s CA certificate secrets"
  value = {
    for k, v in google_secret_manager_secret.k8s_ca_cert :
    k => {
      secret_id      = v.secret_id
      secret_name    = v.name
      secret_version = google_secret_manager_secret_version.k8s_ca_cert[k].name
      project        = v.project
    }
  }
}

output "rotation_pub_sub_topics" {
  description = "Map of Pub/Sub topics for secret rotation notifications"
  value = {
    for k, v in google_pubsub_topic.secret_rotation :
    k => {
      name = v.name
      id   = v.id
    }
  }
}
