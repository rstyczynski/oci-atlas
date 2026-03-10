// Scalars
output "schema_version"         { value = local.schema_version }
output "region_short_key"       { value = local.region_short_key }

// Lists (HCL list(string))
output "region_keys"            { value = keys(local.regions) }
output "realms"                 { value = local.realms }
output "region_cidr_public"     { value = local.region_cidr_public }
output "region_cidr_by_tag"     { value = local.region_cidr_by_tag }

// Objects / maps
output "regions"                { value = local.regions }
output "region"                 { value = local.region }
output "realm"                  { value = local.realm }
output "realm_regions"          { value = local.realm_regions }
output "realm_region_keys"      { value = local.realm_region_keys }
output "realm_other_regions"    { value = local.realm_other_regions }
output "realm_other_region_keys"{ value = local.realm_other_region_keys }
