// Scalars
output "region_short_key"   { value = module.regions_v2.region_short_key }

// Lists (HCL list(string))
output "region_cidr_public" { value = module.regions_v2.region_cidr_public }

// Objects / maps
output "region"             { value = module.regions_v2.region }
