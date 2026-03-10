# Global directory

>**Note:** Work in progress. Project is in DRAFT mode.

An OCI tenancy is described by many attributes that hosted systems use as configuration inputs: tenancy id, internal network properties (for example internal subnet CIDRs), proxy settings (URL, IP, port), and certificate-related metadata. Some lower-level procedures also require region short keys, realm API domains, and public network ranges.

Some of these attributes are OCI-native, while others are customer-defined. Collecting them manually and keeping them configured across systems is time-consuming.

Global Directory provides a catalog of OCI realm, region, and tenancy attributes as JSON documents with strict schemas and semantic versioning.

The JSON data is available in this Git repository and in an OCI Object Storage bucket. To simplify lookups, Global Directory provides Data Access Layer (DAL) clients for Shell (CLI), Node.js, Terraform, and Ansible. You can either consume raw JSON directly or use the client libraries.

In practice, Global Directory is a managed equivalent of `jq data.json`: the data is centralized, schema-validated before upload, versioned, and exposed through client APIs instead of ad-hoc one-off queries.

## Contents

- [Quick start](#quick-start)
- [Repository structure](#repository-structure)
- [Data domains](#data-domains)
  - [Object path convention](#object-path-convention)
  - [Data definition](#data-definition)
  - [Auto-discovery](#auto-discovery)
  - [Data Access Layer (DAL)](#data-access-layer-dal)
- [Client libraries](#client-libraries)
  - [Shell (CLI)](#shell-cli)
  - [Node.js](#nodejs)
  - [Terraform](#terraform)
- [Testing](#testing)
- [Data structures](#data-structures)
  - [`realms/v1` schema](#realmsv1-schema)
  - [`regions/v2` schema](#regionsv2-schema)
  - [`tenancies/v1` schema](#tenanciesv1-schema)
- [References](#references)

## Quick start

To start you need IAM privileges to compartment where data bucket will be created. If not set, tenancy level is used. Make sure you have required privileges to the target tenancy.

```bash
export TV_VAR_compartment_id=
```

### Provisioning data by a terraform manager

Data files are owned by Terraform module, which validates json data files against defined schema and uploads to an object storage bucket.

>>The package comes with demo datasets. To demonstrate automatic detection of tenancy key demo data is prepared for your tenancy It's done by demo_mapping.sh script.

```bash
cd tf_manager
GDIR_DEMO_MODE=true bash demo_mapping.sh     
terraform init
terraform apply -auto-approve
cd ..
```

### Shell client

```bash
# Region-level calls
source cli_client/gdir_regions_v2.sh
export REGION_KEY=tst-region-1
gdir_v2_regions_get_region_short_key
gdir_v2_regions_get_region_cidr_public

# Tenancy-level calls
source cli_client/gdir_tenancies_v1.sh
export TENANCY_KEY=demo_corp
export REGION_KEY=tst-region-1
gdir_v1_tenancies_get_tenancy_region_proxy_url
gdir_v1_tenancies_get_tenancy_region_vault_ocid
gdir_v1_tenancies_get_tenancy_region_cidr_private

# Realm-level calls
source cli_client/gdir_realms_v1.sh
export REALM_KEY=oc1
gdir_v1_realms_get_realm_api_domain
```

### Terraform client

```bash
cd tf_client/examples/tenancy
terraform init
TF_VAR_tenancy_key=demo_corp TF_VAR_region_key=tst-region-1 terraform apply -auto-approve >/dev/null
terraform output tenancy_region_proxy_url
terraform output tenancy_region_vault_ocid
terraform output tenancy_region_cidr_private
cd ../../..
```

### Node.js client

```bash
cd node_client
npm install
npm run example:region
REGION_KEY=tst-region-1 npm run example:region
npm run example:regions

npm run example:tenancy
TENANCY_KEY=demo_corp REGION_KEY=tst-region-1 npm run example:tenancy

npm run example:realms
REALM_KEY=oc1 npm run example:realm
cd ..
```

## Repository structure

| Module | Technology | Description |
|--------|------------|-------------|
| `tf_manager/` | Terraform | Provisions and maintains the catalog |
| `tf_client/` | Terraform | Reads the catalog |
| `node_client/` | Node.js | Reads the catalog |
| `cli_client/` | Shell | Reads the catalog |

## Data domains

The catalog is organized into data domains — independent datasets stored as separate JSON objects in the bucket. Each domain has its own json schema document, evolves independently, and is accessed through a dedicated Data Access Layer (DAL) in client libraries provided for Shell, Terraform, and Node.js.

### Object path convention

To maintain backward compatibility data files are stored in directories following `<domain>/<version>` scheme. As semantic versioning is applied to both data files and access layers this approach guarantees servicing older clients during evolution of the data.

| Domain | Current version | Object path | Description |
|--------|----------------|-------------|-------------|
| `regions` | `v2` | `regions/v2` | Physical region attributes — realm, public CIDRs |
| `tenancies` | `v1` | `tenancies/v1` | Tenancy-scoped attributes per region — private CIDRs, proxy, vault, toolchain, observability |
| `realms` | `v1` | `realms/v1` | Realm-level attributes — name, geo-region, API domain |

Additional domains (e.g. `residents`) follow the same pattern.

>Note Default location of data is `gdir_info` bucket located in root compartment. The master module may be configured with compartment and bucket name to private compartments to serve resident level data. The resident level scoping is based on externally defined iam policies.

### Data definition

Each domain ships four co-located artifacts in `tf_manager/`:

| Artefact | Naming | Purpose |
|----------|--------|---------|
| Data | `<domain>_<version>.json` | The actual data, edited by operators |
| Schema | `<domain>_<version>.schema.json` | JSON Schema (draft 2020-12), machine-readable source of truth |
| Validator | `<domain>_<version>.schema.json` + `validate.sh` | Thin shell wrapper around `ajv-cli` (JSON Schema draft 2020-12); run by Terraform before upload; also runnable standalone: `bash validate.sh <schema> <data>` |
| Provisioning | `<domain>_<version>.tf` | Uploads the data object; depends on validator passing |

The schema in this README is derived from the `.schema.json` file.

### Tenancy auto-detection

To avoid configuration when not specified tenancy parameters are auto detected using CLI and default connection profile.

| What | How | Override |
|------|-----|----------|
| **Tenancy / compartment** (`tf_manager`) | `oci os ns get-metadata` returns the tenancy root compartment OCID | `var.compartment_id` / `TF_VAR_compartment_id` |
| **Region key** (all clients) | Bucket OCID encodes the region: `ocid1.bucket.<realm>.<region>.<hash>` → field `[3]` | `TF_VAR_region_key` · `REGION_KEY` env · `regionKey` constructor config |
| **Realm key** (`tf_client/examples/realm`) | Active region is resolved first, then its `realm` field is read from `regions/v2` | `TF_VAR_realm_key` |
| **Tenancy key** (`tenancies/v1` clients) | Derived from OCI tenancy context (for example using `oci os ns get-metadata --query 'data.\"default-s3-compartment-id\"'` or SDK/provider equivalent) when `TENANCY_KEY` is unset | `TENANCY_KEY` env · per-client config fields |

All discoveries cascade from the OCI SDK/CLI credentials in `~/.oci/config` (or instance principal). No region, realm, or tenancy identifier needs to be hardcoded anywhere; tenancy key and region key can always be overridden explicitly when needed.

### Data Access Layer (DAL)

Directory data is stored in JSON files with specified schema. Data is available at well known `gdir_info` bucket, so it easy to get the data and query it. Toi make this process even easier, global directory comes with data access layer (DAL) libraries for Shell, Terraform, and Node.js.

Refer to individual README documents for each client to get full details and API reference:

1. [Shell client (`cli_client/README.md`)](cli_client/README.md) — OCI CLI + `jq`
2. [Terraform client (`tf_client/README.md`)](tf_client/README.md) — Terraform modules
3. [Node.js client (`node_client/README.md`)](node_client/README.md) — Node.js/TypeScript client

## Testing

### Node (OCI)

```bash
npm --prefix node_client test -- --runInBand
```

### Node (offline fixtures)

```bash
GDIR_DATA_DIR=$PWD/tf_manager npm --prefix node_client test -- --runInBand
```

### CLI (OCI)

```bash
bash cli_client/test/run_tests.sh
```

### CLI (offline fixtures)

```bash
GDIR_DATA_DIR=$PWD/tf_manager bash cli_client/test/run_tests.sh
```

### Terraform

Test for tf_client are not provided.

## Data structures

### `realms/v1` schema

Top-level keys are realm identifiers (e.g. `oc1`, `tst01`). Metadata fields (`schema_version`, `last_updated_timestamp`) are top-level; DALs strip them from the realm map.

```json
{
  "schema_version": "1.0.0",
  "last_updated_timestamp": "<ISO-8601-UTC>",
  "<realm-key>": {
    "type": "public | government | sovereign | drcc | alloy | airgapped",
    "geo-region": "<geo>",
    "name": "<display-name>",
    "description": "<description>",
    "api_domain": "<second-level-domain>"
  }
}
```

### `regions/v2` schema

Top-level keys are region identifiers (e.g. `tst-region-1`). Each entry includes realm and public CIDRs; tenancy-scoped data is in `tenancies/v1`. Metadata is top-level and removed by DALs before returning maps.

```json
{
  "schema_version": "1.0.0",
  "last_updated_timestamp": "<ISO-8601-UTC>",
  "<region-key>": {
    "key": "<short-key>",
    "realm": "<realm-key>",
    "network": {
      "public": [
        { "cidr": "<CIDR>", "description": "<desc>", "tags": ["OCI"] }
      ]
    }
  }
}
```

### `tenancies/v1` schema

Top-level keys are tenancy identifiers (e.g. `demo_corp`). Each tenancy has per-region attributes: private CIDRs, proxy, vault, toolchain, observability. Metadata is top-level.

```json
{
  "schema_version": "1.0.0",
  "last_updated_timestamp": "<ISO-8601-UTC>",
  "<tenancy-key>": {
    "realm": "<realm-key>",
    "regions": {
      "<region-key>": {
        "network": {
          "private": [
            { "cidr": "<CIDR>", "description": "<desc>", "tags": ["vcn"] }
          ],
          "proxy": {
            "url": "<http://proxy>",
            "ip": "<ip>",
            "port": "<port>",
            "noproxy": ["<cidr-or-host>", "..."]
          }
        },
        "security": {
          "vault": {
            "ocid": "<ocid1.vault...>",
            "crypto_endpoint": "<url>",
            "management_endpoint": "<url>"
          }
        },
        "toolchain": {
          "github": {
            "runner": {
              "labels": ["<label>"],
              "image": "<ocid1.image...>"
            }
          }
        },
        "observability": {
          "prometheus_scraping_cidr": "<CIDR>",
          "loki_destination_cidr": "<CIDR>",
          "loki_fqdn": "<fqdn>"
        }
      }
    }
  }
}
```

## Recent Updates

### Sprint 6 - Synthetic Data Sets Review

**Status:** implemented

**Backlog Items Implemented:**

- **GD-6**: Synthetic data sets review — tested

**Key Features Added:**

- Rationalized demo data: removed real tenancy key `avq3`, replaced with synthetic `demo_corp`
- Fixed realm consistency: `acme_prod` now uses real `oc1`-realm regions (`eu-frankfurt-1`, `eu-amsterdam-1`)
- Fixed referential integrity: added missing `tst02` realm to `realms_v1.json`
- New demo mapping script: `cli_client/bin/demo_mapping.sh` maps auto-discovered real tenancy key, region, and realm to synthetic template data in demo mode

**Demo Mode Usage:**

```bash
# Map real tenancy key to synthetic template data (offline, local fixtures)
TEST_DATA_DIR=tf_manager GDIR_DEMO_MODE=true TENANCY_KEY=demo_corp REGION_KEY=tst-region-1 \
  bash cli_client/bin/demo_mapping.sh

# Custom template and region limit
TEST_DATA_DIR=tf_manager GDIR_DEMO_MODE=true TENANCY_KEY=demo_corp REGION_KEY=tst-region-1 \
  GDIR_DEMO_TENANT=acme_prod GDIR_DEMO_MAX_REGIONS=2 \
  bash cli_client/bin/demo_mapping.sh
```

**Documentation:**

- Implementation: `progress/sprint_6/sprint_6_implementation.md`
- Tests: `progress/sprint_6/sprint_6_tests.md`
- Design: `progress/sprint_6/sprint_6_design.md`


## Online vs offline data for examples/tests

- Online (live bucket): leave `GDIR_DATA_DIR` unset; set `GDIR_BUCKET` if not `gdir_info`; ensure OCI CLI/SDK auth works (instance principal, config profile, etc.).
- Offline (local fixtures): set `GDIR_DATA_DIR=$PWD/tf_manager` to force CLI scripts to read local JSON files instead of Object Storage.

Common environment knobs:

| Var | Purpose | Default (all clients) |
| --- | ------- | ------- |
| `GDIR_BUCKET`  | Bucket containing catalog objects | `gdir_info` — baked into every DAL (CLI core `gdir.sh`, Node `DEFAULT_BUCKET`, Terraform `bucket_name` default) |
| `REGION_KEY`   | Region key for region/tenancy lookups | auto-resolved from bucket OCID |
| `TENANCY_KEY`  | Tenancy key for tenancy examples/tests | none (must set for tenancy flows) |
| `REALM_KEY`    | Realm key for realm example | auto-resolved via regions unless set |
| `GDIR_DATA_DIR`| Path to local JSON fixtures (CLI tests/examples) | unset (use OCI) |


## References

Oracle public cloud CIDR information: [public_ip_ranges.json](https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json)
