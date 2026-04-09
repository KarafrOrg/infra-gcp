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
