output "last_updated_timestamp" {
  description = "Timestamp when the data was last uploaded by tf_manager"
  value       = local.last_updated_timestamp
}

output "realm_key" {
  description = "Effective realm key (auto-discovered or overridden via TF_VAR_realm_key)"
  value       = local.realm_key
}

output "realm_type" {
  description = "Deployment model: public | government | sovereign | drcc | alloy | airgapped (v1 schema)"
  value       = local.realm_type
}

output "realm_name" {
  description = "Realm name (v1 schema)"
  value       = local.realm_name
}

output "realm_description" {
  description = "Realm description (v1 schema)"
  value       = local.realm_description
}

output "realm_geo_region" {
  description = "Geographic region (v1 schema)"
  value       = local.realm_geo_region
}

output "realm_api_domain" {
  description = "Base API domain URL (v1 schema)"
  value       = local.realm_api_domain
}
