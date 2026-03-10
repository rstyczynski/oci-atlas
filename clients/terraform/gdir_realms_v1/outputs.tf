// Scalars
output "realm_type"             { value = local.realm_type }
output "realm_name"             { value = local.realm_name }
output "realm_description"      { value = local.realm_description }
output "realm_geo_region"       { value = local.realm_geo_region }
output "realm_api_domain"       { value = local.realm_api_domain }

// Lists (HCL list(string))
output "realm_keys"             { value = keys(local.realms) }

// Objects / maps
output "realms"                 { value = local.realms }
output "realm"                  { value = local.realm }
