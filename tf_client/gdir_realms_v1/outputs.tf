output "last_updated_timestamp" {
  description = "Timestamp when the data was last uploaded by tf_manager"
  value       = local.last_updated_timestamp
}

output "realms" {
  description = "All realms (v1 schema)"
  value       = local.realms
}

output "realm_keys" {
  description = "List of realm keys (v1 schema)"
  value       = keys(local.realms)
}

output "realm" {
  description = "Single realm object for the configured realm key (v1 schema)"
  value       = local.realm
}

output "realm_type" {
  description = "Deployment model: public | government | sovereign | drcc | alloy | airgapped (v1 schema)"
  value       = local.realm_type
}

output "realm_name" {
  description = "Realm name, e.g. OCI Public (v1 schema)"
  value       = local.realm_name
}

output "realm_description" {
  description = "Human-readable realm description (v1 schema)"
  value       = local.realm_description
}

output "realm_geo_region" {
  description = "Geographic region, e.g. global, eu (v1 schema)"
  value       = local.realm_geo_region
}

output "realm_api_domain" {
  description = "Base API domain URL for the realm (v1 schema)"
  value       = local.realm_api_domain
}
