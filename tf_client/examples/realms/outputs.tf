output "last_updated_timestamp" {
  description = "Timestamp when the data was last uploaded by tf_manager"
  value       = local.last_updated_timestamp
}

output "realms" {
  description = "All realms (v1 schema)"
  value       = local.realms
}

output "realm_keys" {
  description = "All realm keys (v1 schema)"
  value       = local.realm_keys
}
