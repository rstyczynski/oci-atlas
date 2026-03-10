# clients/terraform — Terraform clients for OCI Atlas

Terraform modules for reading OCI Atlas global directory data from OCI Object Storage.

## Architecture

- `gdir_regions_v2`: reads `regions/v2` and exposes region/realm attributes.
- `gdir_tenancies_v1`: reads `tenancies/v1` and exposes tenancy + tenancy/region-scoped attributes.
- `gdir_realms_v1`: reads `realms/v1` and exposes realm attributes.

Each module:

- Fetches its own object from Object Storage (`bucket_name`, `object_name`).
- Uses provider data sources (and where needed an `external` data source) for auto-discovery.
- Exposes strongly-typed outputs for the relevant domain and version.

## Prerequisites

- Terraform installed (and the OCI provider configured).
- Access to the OCI tenancy and bucket that host the catalog data.
- For tenancy auto-discovery in `gdir_tenancies_v1`, `oci` CLI must be available in the execution environment (used via the `external` data source).

## Example usage

From a Terraform configuration:

```hcl
module "gdir_core" {
  source      = "./clients/terraform"
  bucket_name = "gdir_info"
}

module "gdir_regions" {
  source      = "./clients/terraform/gdir_regions_v2"
  bucket_name = module.gdir_core.bucket_name
  object_name = "regions/v2"
  region_key  = module.gdir_core.region_key
}

module "gdir_tenancies" {
  source      = "./clients/terraform/gdir_tenancies_v1"
  bucket_name = module.gdir_core.bucket_name
  object_name = "tenancies/v1"
  tenancy_key = null        # discover from OCI, or set explicitly
  region_key  = module.gdir_core.region_key
}
```

Run the Terraform examples from the repo root:

```bash
cd clients/terraform/examples

# Regions (all regions) — same data as clients/shell: region keys, realms
cd regions
terraform init
terraform apply -auto-approve
terraform output region_keys
terraform output realms
cd ..

# Region (single) — same data as clients/shell: scalar region_short_key, list of scalars region_cidr_public
cd region
terraform init
TF_VAR_region_key=tst-region-1 terraform apply -auto-approve >/dev/null
terraform output region_short_key
terraform output region_cidr_public
cd ..

cd tenancy
terraform init
TF_VAR_tenancy_key=demo_corp TF_VAR_region_key=tst-region-1 terraform apply -auto-approve >/dev/null
terraform output tenancy_region_proxy_url
terraform output tenancy_region_vault_ocid
terraform output tenancy_region_cidr_private
terraform output tenancy_region_proxy_noproxy
terraform output tenancy_region_proxy_noproxy_string
cd ..

# Realms (all) — same data as clients/shell: realm keys, full realms
cd realms
terraform init
terraform apply -auto-approve >/dev/null
terraform output realm_keys
cd ..

# Realm (single) — same data as clients/shell: REALM_KEY=oc1 → scalar realm_api_domain
cd realm
terraform init
TF_VAR_realm_key=oc1 terraform apply -auto-approve >/dev/null
terraform output realm_api_domain
cd ..
```

## Arguments

Variable names and defaults match the CLI client where applicable: `REGION_KEY` → `TF_VAR_region_key`, `TENANCY_KEY` → `TF_VAR_tenancy_key`, `REALM_KEY` → `TF_VAR_realm_key`, `GDIR_BUCKET` → `bucket_name` (`gdir_info`). Example values in this README use the same as in `clients/shell` (e.g. `eu-zurich-1`, `demo_corp`, `tst-region-1`, `oc1`).

Top-level `clients/terraform` module (region discovery + bucket wiring):

| Var | Default | Description |
| --- | --- | --- |
| `bucket_name` | `gdir_info` | Object Storage bucket name |
| `region_key` | `null` | Region key override; if `null`, derived from bucket OCID |

### SDK level

All DAL modules share common inputs:

| Input | Default | Description |
| --- | --- | --- |
| `bucket_name` | `gdir_info` | Object Storage bucket containing catalog objects |
| `object_name` | domain-specific | Object path (`regions/v2`, `tenancies/v1`, `realms/v1`) |

Additional per-module inputs are described below.

## Functions

Data objects are exposed through module outputs. Each module returns:

1. Scalar values (strings, numbers).
2. Lists (HCL lists of strings or objects).
3. Nested objects (maps) representing domains.

### Discovery behavior

- **Region key discovery** (regions and tenancies modules):
  - If `region_key` is unset (`null`), it is derived from the bucket OCID.
  - OCI bucket OCID format: `ocid1.bucket.<realm>.<region>.<hash>`; the module splits on `.` and takes field `3` as region key.

- **Tenancy key discovery** (tenancies module):
  - If `tenancy_key` is unset (`null`), it is derived from the active tenancy context:
    1. `oci os ns get-metadata` returns the default S3 compartment OCID.
    2. `oci iam tenancy get` returns the tenancy name for that OCID.
    3. That name is used as `tenancy_key`.
  - The catalog object (`tenancies/v1`) must contain a top-level key equal to this name; otherwise `tenancy` and all tenancy-scoped outputs are `null`.

In all modules, if a resolved key does not exist in the catalog data, downstream outputs become `null`. The tenancy example surfaces the resolved keys to make debugging easy.

### Regions (`gdir_regions_v2`)

### Inputs

- `bucket_name` — Object Storage bucket (default `gdir_info`).
- `object_name` — object path (default `regions/v2`).
- `region_key` — region key; if `null`, auto-discovered from bucket OCID.
- `cidr_tag_filter` — tag used to filter CIDR entries (default `public`).

### Outputs (selected)

- Metadata:
  - `schema_version`
- Catalog:
  - `regions` — full regions map (without metadata).
  - `region_keys` — list of all region keys.
  - `region` — selected region object (by `region_key`).
  - `realm` — realm of selected region.
  - `realm_regions`, `realm_region_keys`, `realm_other_regions`, `realm_other_region_keys`.
- Network:
  - `region_cidr_public` — public CIDR entries for the region.
  - `region_cidr_by_tag` — public CIDRs filtered by `cidr_tag_filter`.

### Tenancies (`gdir_tenancies_v1`)

#### Tenancy inputs

- `bucket_name` — Object Storage bucket (default `gdir_info`).
- `object_name` — object path (default `tenancies/v1`).
- `tenancy_key` — tenancy key; if `null`, auto-discovered from active tenancy (IAM tenancy name).
- `region_key` — region key; if `null`, auto-discovered from bucket OCID.
- `cidr_tag_filter` — tag used to filter private CIDRs (default `vcn`).

#### Tenancy outputs (selected)

- Metadata:
  - `schema_version`
  - `tenancies` — full tenancies map (without metadata).
  - `tenancy` — selected tenancy object (by `tenancy_key`).
  - `tenancy_realm` — realm of selected tenancy.
  - `tenancy_key` — effective tenancy key used (explicit or discovered).
  - `region_key` — effective region key used (explicit or discovered).
- Region scoping:
  - `tenancy_region` — selected region object under the tenancy.
  - `tenancy_region_keys` — all region keys for the tenancy.
- Network:
  - `tenancy_region_network`
  - `tenancy_region_cidr_private`
  - `tenancy_region_cidr_by_tag`
- Proxy:
  - `tenancy_region_proxy`
  - `tenancy_region_proxy_url`
  - `tenancy_region_proxy_ip`
  - `tenancy_region_proxy_port`
  - `tenancy_region_proxy_noproxy`
  - `tenancy_region_proxy_noproxy_string`
- Vault:
  - `tenancy_region_vault`
  - `tenancy_region_vault_ocid`
  - `tenancy_region_vault_crypto_endpoint`
  - `tenancy_region_vault_management_endpoint`
- Toolchain:
  - `tenancy_region_github`
  - `tenancy_region_github_runner`
  - `tenancy_region_github_runner_labels`
  - `tenancy_region_github_runner_image`
- Observability:
  - `tenancy_region_observability`
  - `tenancy_region_prometheus_scraping_cidr`
  - `tenancy_region_loki_destination_cidr`
  - `tenancy_region_loki_fqdn`

### Realms (`gdir_realms_v1`)

#### Realm inputs

- `bucket_name` — Object Storage bucket (default `gdir_info`).
- `object_name` — object path (default `realms/v1`).
- `realm_key` — realm key (e.g. `oc1`, `tst01`); if `null`, only `realms` / `realm_keys` are useful.

#### Realm outputs (selected)

- Metadata:
  - `schema_version`
- Catalog:
  - `realms` — full realms map (without metadata).
  - `realm_keys` — all realm keys.
  - `realm` — selected realm object.
- Fields:
  - `realm_type`
  - `realm_name`
  - `realm_description`
  - `realm_geo_region`
  - `realm_api_domain`

## Example Commands

Use the ready-made examples under `clients/terraform/examples`. Each block shows the same data as the corresponding CLI example (`clients/shell/examples/*.sh`):

```bash
cd clients/terraform/examples

# Regions — same as bash examples/regions.sh
cd regions && terraform init && terraform apply -auto-approve && terraform output region_keys && terraform output realms && cd ..

# Region — same as bash examples/region.sh (scalar region_short_key, list region_cidr_public)
cd region && terraform init && terraform apply -auto-approve && terraform output region_short_key && terraform output region_cidr_public && cd ..

# Tenancy — same as CLI: TENANCY_KEY=demo_corp REGION_KEY=tst-region-1, same data (proxy_url, vault_ocid, cidr_private, proxy_noproxy, proxy_noproxy_string)
cd tenancy && terraform init && TF_VAR_tenancy_key=demo_corp TF_VAR_region_key=tst-region-1 terraform apply -auto-approve && terraform output tenancy_region_proxy_url && terraform output tenancy_region_vault_ocid && terraform output tenancy_region_cidr_private && terraform output tenancy_region_proxy_noproxy && terraform output tenancy_region_proxy_noproxy_string && cd ..

# Realms — same as bash examples/realms.sh (all realms)
cd realms && terraform init && terraform apply -auto-approve && terraform output realm_keys && terraform output realms && cd ..

# Realm — same as REALM_KEY=oc1 bash examples/realms.sh (single realm: scalar realm_api_domain)
cd realm && terraform init && TF_VAR_realm_key=oc1 terraform apply -auto-approve && terraform output realm_api_domain && cd ..
```

Same variables as CLI (`TENANCY_KEY=demo_corp`, `REGION_KEY=tst-region-1`). Same data — run:

```bash
cd clients/terraform/examples/tenancy
terraform init
TF_VAR_tenancy_key=demo_corp TF_VAR_region_key=tst-region-1 terraform apply -auto-approve
terraform output tenancy_region_proxy_url
terraform output tenancy_region_vault_ocid
terraform output tenancy_region_cidr_private
terraform output tenancy_region_proxy_noproxy
terraform output tenancy_region_proxy_noproxy_string
```
