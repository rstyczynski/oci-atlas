// Scalars
output "tenancy_region_proxy_url" { value = module.tenancies_v1.tenancy_region_proxy_url }
output "tenancy_region_vault_ocid" { value = module.tenancies_v1.tenancy_region_vault_ocid }
output "tenancy_region_proxy_noproxy_string" { value = module.tenancies_v1.tenancy_region_proxy_noproxy_string }
output "tenancy_key" { value = module.tenancies_v1.tenancy_key }
output "region_key"  { value = module.tenancies_v1.region_key }

// Lists (HCL list(string))
output "tenancy_region_cidr_private" { value = module.tenancies_v1.tenancy_region_cidr_private }
output "tenancy_region_proxy_noproxy" { value = module.tenancies_v1.tenancy_region_proxy_noproxy }
