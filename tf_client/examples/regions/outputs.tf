output "last_updated_timestamp" {
  description = "Timestamp when the data was last uploaded by tf_manager"
  value       = local.last_updated_timestamp
}

output "regions" {
  description = "All regions (v1 schema)"
  value       = local.regions
}

output "region_keys" {
  description = "All region keys (v1 schema)"
  value       = local.region_keys
}

output "realms" {
  description = "All distinct realms (v1 schema)"
  value       = local.realms
}
