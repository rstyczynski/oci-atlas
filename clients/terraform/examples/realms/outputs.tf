// Scalars
output "last_updated_timestamp" { value = local.last_updated_timestamp }

// Lists (HCL list(string))
output "realm_keys"            { value = local.realm_keys }

// Objects / maps
output "realms"                { value = local.realms }
