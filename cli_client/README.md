# cli_client — OCI CLI-based client for the global directory

Mirrors `node_client` using only OCI CLI and `jq`. Source `gdir.sh` to get all `gdir_v1_regions_*` functions.

## Schema versioning

The library is split into two layers:

- **`gdir.sh`** (core) — auth, region discovery from bucket OCID, raw object fetch. Schema-independent.
- **`gdir_regions_v1.sh`** (v1 regions) — parses the raw JSON and exposes `gdir_v1_regions_*` functions tied to the v1 regions schema. Add a `v1/global_directory_services_v1.sh` or a `v2/global_directory_regions_v2.sh` when the scope or schema changes.

Consumers source the versioned file only.

## Prerequisites

- `oci` CLI configured (`~/.oci/config`)
- `jq`

## ENV vars

| Var | Default | Description |
|-----|---------|-------------|
| `GDIR_BUCKET` | `gdir_info` | Object Storage bucket name (core) |
| `GDIR_REGIONS_OBJECT` | `regions/v1` | Object path for regions/v1 data (DAL-level override) |
| `REGION_KEY` | active OCI region from `~/.oci/config` | Region key for single-region functions |

## Functions

| Function | Description |
|----------|-------------|
| `gdir_v1_regions_get_regions` | All regions (JSON) |
| `gdir_v1_regions_get_region_keys` | List of all region keys |
| `gdir_v1_regions_get_region` | One region object (`REGION_KEY` or active OCI region) |
| `gdir_v1_regions_get_region_short_key` | Short region code (e.g. ZRH) |
| `gdir_v1_regions_get_region_realm` | Realm of the region |
| `gdir_v1_regions_get_realms` | All distinct realms |
| `gdir_v1_regions_get_realm_regions <realm>` | All regions in a realm |
| `gdir_v1_regions_get_realm_region_keys <realm>` | Keys of regions in a realm |
| `gdir_v1_regions_get_realm_other_regions` | Regions in the same realm, excluding `REGION_KEY` |
| `gdir_v1_regions_get_realm_other_region_keys` | Keys of the above |
| `gdir_v1_regions_get_region_cidr` | Full CIDR object |
| `gdir_v1_regions_get_region_cidr_public` | Public CIDR entries |
| `gdir_v1_regions_get_region_cidr_internal` | Internal CIDR entries |
| `gdir_v1_regions_get_region_cidr_by_tag <tag>` | CIDR entries matching a tag |
| `gdir_v1_regions_get_region_proxy` | Proxy object |
| `gdir_v1_regions_get_region_proxy_url` | Proxy URL |
| `gdir_v1_regions_get_region_proxy_ip` | Proxy IP |
| `gdir_v1_regions_get_region_proxy_port` | Proxy port |
| `gdir_v1_regions_get_region_proxy_noproxy` | No-proxy list (newline-separated) |
| `gdir_v1_regions_get_region_proxy_noproxy_string` | No-proxy list as `NO_PROXY` string |
| `gdir_v1_regions_get_region_vault` | Full vault object |
| `gdir_v1_regions_get_region_vault_ocid` | Vault OCID |
| `gdir_v1_regions_get_region_vault_crypto_endpoint` | Vault crypto operations endpoint |
| `gdir_v1_regions_get_region_vault_management_endpoint` | Vault management endpoint |
| `gdir_v1_regions_get_region_github` | Full GitHub object |
| `gdir_v1_regions_get_region_github_runner` | GitHub runner object |
| `gdir_v1_regions_get_region_github_runner_labels` | Runner labels (newline-separated) |
| `gdir_v1_regions_get_region_github_runner_image` | Compute image OCID for runner |
| `gdir_v1_regions_get_region_observability` | Full observability object |
| `gdir_v1_regions_get_region_prom_scraping_cidr` | Prometheus scraping CIDR |
| `gdir_v1_regions_get_region_loki_dest_cidr` | Loki destination CIDR |
| `gdir_v1_regions_get_region_loki_fqdn` | Loki FQDN |

## Examples

```bash
# All regions
bash examples/regions.sh

# One region (explicit key)
REGION_KEY=eu-zurich-1 bash examples/region.sh

# One region (auto — uses active OCI region from ~/.oci/config)
bash examples/region.sh

# Use in your own script
source cli_client/gdir_regions_v1.sh
gdir_v1_regions_get_region_proxy_ip                            # proxy IP for current region
REGION_KEY=eu-zurich-1 gdir_v1_regions_get_region_proxy_port  # proxy port for eu-zurich-1
```
