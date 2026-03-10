# clients/shell — OCI CLI/jq client

Shell client for OCI Atlas global directory data in Object Storage.

## Architecture

- `gdir.sh` (core): OCI auth, object fetch, region auto-discovery.
- `gdir_regions_v2.sh`: region DAL (`regions/v2`).
- `gdir_tenancies_v1.sh`: tenancy DAL (`tenancies/v1`).
- `gdir_realms_v1.sh`: realm DAL (`realms/v1`).

## Prerequisites

- OCI CLI configured (`~/.oci/config` or instance principal).
- `jq`.
- POSIX-style utilities: `awk`, `tr`, `cat`, `head`, `wc`.

>>**Note** DAL scripts validate that both `oci` and `jq` are available on `PATH`. If either is missing, sourcing fails with a clear error message and the `gdir_*` functions are not registered.

## Example usage

```bash
# Region-level calls
source clients/shell/gdir_regions_v2.sh
export REGION_KEY=tst-region-1
gdir_v2_regions_get_region_short_key
gdir_v2_regions_get_region_cidr_public

# Tenancy-level calls
source clients/shell/gdir_tenancies_v1.sh
export TENANCY_KEY=demo_corp 
export REGION_KEY=tst-region-1 
gdir_v1_tenancies_get_tenancy_region_proxy_url
gdir_v1_tenancies_get_tenancy_region_vault_ocid
gdir_v1_tenancies_get_tenancy_region_cidr_private
gdir_v1_tenancies_get_tenancy_region_proxy_noproxy
gdir_v1_tenancies_get_tenancy_region_proxy_noproxy_string

# Realm-level calls
source clients/shell/gdir_realms_v1.sh
export REALM_KEY=oc1
gdir_v1_realms_get_realm_api_domain
```

## Arguments

| Var | Default | Description |
| --- | --- | --- |
| `REGION_KEY` | auto-discovered from bucket OCID | Region key override |
| `TENANCY_KEY` | auto-discovered from tenancy context | Tenancy key override |
| `REALM_KEY` | none | Realm key for single-realm queries |

### SDK level

| Var | Default | Description |
| --- | --- | --- |
| `GDIR_BUCKET` | `gdir_info` | Object Storage bucket name |
| `GDIR_REGIONS_OBJECT` | `regions/v2` | Regions object path override |
| `GDIR_TENANCIES_OBJECT` | `tenancies/v1` | Tenancies object path override |
| `GDIR_REALMS_OBJECT` | `realms/v1` | Realms object path override |
| `GDIR_DATA_DIR` | unset | Offline JSON fixture directory (for tests/examples) |

## Functions

Data object is accessible trough helper access functions, that returns:

1. scalar values
2. arrays in a form of scalars separated by new lines
3. JSON objects

### Regions (`gdir_v2_regions_*`)

#### Raw scalars (regions)

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v2_regions_get_region_short_key` | raw scalar (text) | `.[REGION_KEY].key` | Region short key |
| `gdir_v2_regions_get_region_realm` | raw scalar (text) | `.[REGION_KEY].realm` | Region realm |

#### Raw lines (regions)

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v2_regions_get_region_keys` | raw lines (text) | `keys[]` over regions map | Region keys |
| `gdir_v2_regions_get_realms` | raw lines (text) | `to_entries \| map(.value.realm) \| unique \| .[]` | Distinct realm keys |
| `gdir_v2_regions_get_realm_region_keys` | raw lines (text) | `keys[]` over realm regions | Keys in current realm |
| `gdir_v2_regions_get_realm_other_region_keys` | raw lines (text) | `keys[]?` over realm-other regions | Keys of peer regions |
| `gdir_v2_regions_get_region_cidr_public` | raw lines (text) | `.network.public[]?.cidr` | Public CIDR list |
| `gdir_v2_regions_get_region_cidr_by_tag <tag>` | raw lines (text) | `(.network.public // []) \| map(select(.tags[]? == $tag))[]?.cidr` | Public CIDRs filtered by tag |

#### JSON objects / arrays (regions)

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v2_regions_get_regions` | JSON object | `del(.schema_version)` | Full regions map |
| `gdir_v2_regions_get_region` | JSON object | `.[REGION_KEY]` | Current/selected region object |
| `gdir_v2_regions_get_realm_regions` | JSON object | `select(.value.realm == current_realm)` | Regions in current realm |
| `gdir_v2_regions_get_realm_other_regions` | JSON object | `del(.[$self])` over realm regions | Same-realm regions except current |

SDK level functions

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v2_regions_get_schema_version` | raw scalar (text) | `.schema_version` | Data schema version |

### Tenancies (`gdir_v1_tenancies_*`)

#### Raw scalars (tenancies)

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v1_tenancies_get_tenancy_realm` | raw scalar (text) | `.[TENANCY_KEY].realm` | Tenancy realm |
| `gdir_v1_tenancies_get_tenancy_region_proxy_url` | raw scalar (text) | `.network.proxy.url` | Proxy URL |
| `gdir_v1_tenancies_get_tenancy_region_proxy_ip` | raw scalar (text) | `.network.proxy.ip` | Proxy IP |
| `gdir_v1_tenancies_get_tenancy_region_proxy_port` | raw scalar (text/number) | `.network.proxy.port` | Proxy port |
| `gdir_v1_tenancies_get_tenancy_region_proxy_noproxy_string` | raw scalar (text) | `.network.proxy.noproxy \| join(",")` | No-proxy list as `NO_PROXY` value |
| `gdir_v1_tenancies_get_tenancy_region_vault_ocid` | raw scalar (text) | `.security.vault.ocid` | Vault OCID |
| `gdir_v1_tenancies_get_tenancy_region_vault_crypto_endpoint` | raw scalar (text) | `.security.vault.crypto_endpoint` | Vault crypto endpoint |
| `gdir_v1_tenancies_get_tenancy_region_vault_management_endpoint` | raw scalar (text) | `.security.vault.management_endpoint` | Vault management endpoint |
| `gdir_v1_tenancies_get_tenancy_region_github_runner_image` | raw scalar (text) | `.toolchain.github.runner.image` | Runner image OCID |
| `gdir_v1_tenancies_get_tenancy_region_prom_scraping_cidr` | raw scalar (text) | `.observability.prometheus_scraping_cidr` | Prometheus scraping CIDR |
| `gdir_v1_tenancies_get_tenancy_region_loki_dest_cidr` | raw scalar (text) | `.observability.loki_destination_cidr` | Loki destination CIDR |
| `gdir_v1_tenancies_get_tenancy_region_loki_fqdn` | raw scalar (text) | `.observability.loki_fqdn` | Loki FQDN |

SDK level functions

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v1_tenancies_get_schema_version` | raw scalar (text) | `.schema_version` | Data schema version |

#### Raw lines (tenancies)

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v1_tenancies_get_tenancy_keys` | raw lines (text) | `keys[]` over tenancies map | Tenancy keys |
| `gdir_v1_tenancies_get_tenancy_region_keys` | raw lines (text) | `.[TENANCY_KEY].regions \| keys[]` | Region keys for tenancy |
| `gdir_v1_tenancies_get_tenancy_region_cidr_private` | raw lines (text) | `.network.private[]?.cidr` | Private CIDR list |
| `gdir_v1_tenancies_get_tenancy_region_cidr_private_by_tag <tag>` | raw lines (text) | `.network.private \| map(select(.tags[]? == $tag))[]?.cidr` | Private CIDRs by tag |
| `gdir_v1_tenancies_get_tenancy_region_proxy_noproxy` | raw lines (text) | `.network.proxy.noproxy[]?` | No-proxy entries |
| `gdir_v1_tenancies_get_tenancy_region_github_runner_labels` | raw lines (text) | `.toolchain.github.runner.labels[]?` | Runner labels |

#### JSON objects / arrays

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v1_tenancies_get_tenancies` | JSON object | `del(.schema_version)` | Full tenancies map |
| `gdir_v1_tenancies_get_tenancy` | JSON object | `.[TENANCY_KEY]` | Selected tenancy object (explicit or auto-discovered key) |
| `gdir_v1_tenancies_get_tenancy_region` | JSON object | `.[TENANCY_KEY].regions[REGION_KEY]` | Selected tenancy region object |
| `gdir_v1_tenancies_get_tenancy_region_network` | JSON object | `.network` | Region network section |
| `gdir_v1_tenancies_get_tenancy_region_proxy` | JSON object | `.network.proxy` | Proxy section |
| `gdir_v1_tenancies_get_tenancy_region_vault` | JSON object | `.security.vault` | Vault section |
| `gdir_v1_tenancies_get_tenancy_region_github` | JSON object | `.toolchain.github` | GitHub section |
| `gdir_v1_tenancies_get_tenancy_region_github_runner` | JSON object | `.toolchain.github.runner` | GitHub runner section |
| `gdir_v1_tenancies_get_tenancy_region_observability` | JSON object | `.observability` | Observability section |

### Realms (`gdir_v1_realms_*`)

#### Raw scalars (realms)

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v1_realms_get_realm_type` | raw scalar (text) | `.[REALM_KEY].type` | Deployment model |
| `gdir_v1_realms_get_realm_name` | raw scalar (text) | `.[REALM_KEY].name` | Realm name |
| `gdir_v1_realms_get_realm_description` | raw scalar (text) | `.[REALM_KEY].description` | Realm description |
| `gdir_v1_realms_get_realm_geo_region` | raw scalar (text) | `.[REALM_KEY]["geo-region"]` | Realm geo region |
| `gdir_v1_realms_get_realm_api_domain` | raw scalar (text) | `.[REALM_KEY].api_domain` | Base API domain |

SDK level functions

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v1_realms_get_schema_version` | raw scalar (text) | `.schema_version` | Data schema version |

#### Raw lines (realms)

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v1_realms_get_realm_keys` | raw lines (text) | `keys[]` excluding metadata keys | Realm keys |

#### JSON objects / arrays (realms)

| Function | Returns | JSON path / expression | Description |
| --- | --- | --- | --- |
| `gdir_v1_realms_get_realms` | JSON object | `del(.schema_version)` | Full realms map |
| `gdir_v1_realms_get_realm` | JSON object | `.[REALM_KEY]` | Selected realm object |
