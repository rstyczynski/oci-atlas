output "region_keys" { value = module.regions_v2.region_keys }
output "realms"      { value = module.regions_v2.realm_region_keys }
output "tenancy_keys" { value = module.tenancies_v1.tenancy_region_keys }
