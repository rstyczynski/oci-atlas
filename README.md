# Global directory

Catalog of OCI region attributes (proxy, network, realm membership, etc.), realm (domain, type, geo-region, etc.), stored as JSON in an OCI Object Storage bucket. Provides versioned data with associated Node.js, CLI, and Terraform clients for reading the data. The catalog is provisioned and maintained by a Terraform manager module supplied with data file validation.

Global directory is the equivalent of `jq data.json` — except the data file lives centrally in OCI Object Storage, is schema-validated before every upload, versioned by domain, and consumed through structured data access layers in Node.js, CLI, and Terraform instead of ad-hoc one-off queries.

## Contents

- [Quick start](#quick-start)
- [Repository structure](#repository-structure)
- [Data domains](#data-domains)
  - [Object path convention](#object-path-convention)
  - [Data definition](#data-definition)
  - [Auto-discovery](#auto-discovery)
  - [Data Access Layer (DAL)](#data-access-layer-dal)
- [Data structures](#data-structures)
  - [`realms/v1` schema](#realmsv1-schema)
  - [`regions/v1` schema](#regionsv1-schema)
- [Client libraries](#client-libraries)
  - [Shell (CLI)](#shell-cli)
  - [Node.js](#nodejs)
  - [Terraform](#terraform)
- [Testing](#testing)
- [References](#referenes)

## Quick start

**Data** — edit `tf_manager/regions_v2.json`, `tf_manager/tenancies_v1.json`, and/or `tf_manager/realms_v1.json`, then provision.

**Provision:**

```bash
cd tf_manager
terraform init
terraform apply -auto-approve 
cd ..
```

**Read — Shell:**

```bash
cd cli_client
REGION_KEY=eu-zurich-1 bash examples/region.sh       # region-only (v2)
bash examples/regions.sh                             # list regions/realms (v2)
TENANCY_KEY=acme_prod REGION_KEY=eu-zurich-1 bash examples/tenancy.sh
REALM_KEY=oc1 bash examples/realms.sh
# override bucket if not default:
# GDIR_BUCKET=my_other_bucket REGION_KEY=... bash examples/region.sh
cd ..
```

**Read — Node:**

```bash
cd node_client
npm install
REGION_KEY=eu-zurich-1 npm run example:region
npm run example:regions
TENANCY_KEY=acme_prod REGION_KEY=eu-zurich-1 npm run example:tenancy
REALM_KEY=oc1 npm run example:realm
cd ..
```

**Read — Terraform:**

```bash
cd tf_client/examples

cd regions
terraform init
terraform apply -auto-approve 
terraform output
cd ..

cd region
terraform init
terraform apply -auto-approve
terraform output

rm -f terraform.tfstate terraform.tfstate.backup
TF_VAR_region_key=tst-region-3 terraform apply -auto-approve
terraform output
cd ..

cd tenancy
terraform init
terraform apply -auto-approve
terraform output
cd ..
cd ..

cd realms
terraform init
terraform apply -auto-approve
terraform output
cd ..

cd realm
terraform init
terraform apply -auto-approve
terraform output

TF_VAR_realm_key=oc19 terraform apply -auto-approve
terraform output
cd ..

cd ../..
```

### Online vs offline data for examples/tests

- Online (live bucket): leave `TEST_DATA_DIR` unset; set `GDIR_BUCKET` if not `gdir_info`; ensure OCI CLI/SDK auth works (instance principal, config profile, etc.).
- Offline (local fixtures): set `TEST_DATA_DIR=$PWD/tf_manager` to force CLI scripts to read local JSON files instead of Object Storage.

Common environment knobs:

| Var | Purpose | Default (all clients) |
| --- | ------- | ------- |
| `GDIR_BUCKET` | Bucket containing catalog objects | `gdir_info` — baked into every DAL (CLI core `gdir.sh`, Node `DEFAULT_BUCKET`, Terraform `bucket_name` default) |
| `REGION_KEY`  | Region key for region/tenancy lookups | auto-resolved from bucket OCID |
| `TENANCY_KEY` | Tenancy key for tenancy examples/tests | none (must set for tenancy flows) |
| `REALM_KEY`   | Realm key for realm example | auto-resolved via regions unless set |
| `TEST_DATA_DIR` | Path to local JSON fixtures (CLI tests/examples) | unset (use OCI) |

## Repository structure

| Module | Technology | Description |
|--------|------------|-------------|
| `tf_manager/` | Terraform | Provisions and maintains the catalog |
| `tf_client/` | Terraform | Reads the catalog |
| `node_client/` | Node.js | Reads the catalog |
| `cli_client/` | Shell | Reads the catalog |

## Data domains

The catalog is organised into **data domains** — independent datasets stored as separate JSON objects in the bucket. Each domain has its own schema,data validator program, evolves independently, and is accessed through a dedicated **Data Access Layer (DAL)** in  client libraries provided for node.js, shell, and terraform.

### Object path convention

```
<domain>/<version>
```

| Domain | Current version | Object path | Description |
|--------|----------------|-------------|-------------|
| `regions` | `v2` | `regions/v2` | Physical region attributes — realm, public CIDRs |
| `tenancies` | `v1` | `tenancies/v1` | Tenancy-scoped attributes per region — private CIDRs, proxy, vault, toolchain, observability |
| `realms` | `v1` | `realms/v1` | Realm-level attributes — name, geo-region, API domain |

Additional domains (e.g. `tenancies`, `residents`) follow the same pattern.

>Note Default location of data is `gdir_info` bucket located in root compartment. The master module may be configured with compartment and bucket name to private compartments to serve resident level data. The resident level scoping is based on externally defined iam policies.

### Data definition

Each domain ships four co-located artefacts in `tf_manager/`:

| Artefact | Naming | Purpose |
|----------|--------|---------|
| Data | `<domain>_<version>.json` | The actual data, edited by operators |
| Schema | `<domain>_<version>.schema.json` | JSON Schema (draft 2020-12), machine-readable source of truth |
| Validator | `<domain>_<version>.schema.json` + `validate.sh` | Thin shell wrapper around `ajv-cli` (JSON Schema draft 2020-12); run by Terraform before upload; also runnable standalone: `bash validate.sh <schema> <data>` |
| Provisioning | `<domain>_<version>.tf` | Uploads the data object; depends on validator passing |

The schema in README is derived from the `.schema.json` file.

### Auto-discovery

The catalog avoids requiring hardcoded identifiers by deriving them from the active OCI connection:

| What | How | Override |
|------|-----|----------|
| **Tenancy / compartment** (`tf_manager`) | `oci os ns get-metadata` returns the tenancy root compartment OCID | `var.compartment_id` / `TF_VAR_compartment_id` |
| **Region key** (all clients) | Bucket OCID encodes the region: `ocid1.bucket.<realm>.<region>.<hash>` → field `[3]` | `TF_VAR_region_key` · `REGION_KEY` env · `regionKey` constructor config |
| **Realm key** (`tf_client/examples/realm`) | Active region is resolved first, then its `realm` field is read from `regions/v2` | `TF_VAR_realm_key` |

All three discoveries cascade from a single source: the OCI SDK credentials in `~/.oci/config`. No region, realm, or tenancy identifier needs to be hardcoded anywhere.

### Data Access Layer (DAL)

Each domain+version pair has a dedicated DAL in every client library. The DAL encodes the exact field structure of that schema version and is never shared between versions or domains.

The canonical DAL name for a domain+version is **`gdir_<domain>_<version>`**. Every client uses this name directly — as a class name, file name, or module name.

| Client | DAL for `regions/v2` | DAL for `tenancies/v1` | DAL for `realms/v1` |
|--------|----------------------|------------------------|---------------------|
| Node.js | class `gdir_regions_v2` in `node_client/src/gdir_regions_v2.ts` | class `gdir_tenancies_v1` in `node_client/src/gdir_tenancies_v1.ts` | class `gdir_realms_v1` in `node_client/src/gdir_realms_v1.ts` |
| CLI | `cli_client/gdir_regions_v2.sh`, functions `gdir_v2_regions_*` | `cli_client/gdir_tenancies_v1.sh`, functions `gdir_v1_tenancies_*` | `cli_client/gdir_realms_v1.sh`, functions `gdir_v1_realms_*` |
| Terraform | module `tf_client/gdir_regions_v2/` | module `tf_client/gdir_tenancies_v1/` | module `tf_client/gdir_realms_v1/` |

When a schema changes incompatibly, a new version (`v2`) is introduced alongside the existing one. Consumers migrate at their own pace; both versions can be live simultaneously.

When a new domain is added (e.g. `realms`), a parallel set of DAL artefacts is created — `gdir_realms_v1` class, `gdir_realms_v1.sh`, `tf_client/gdir_realms_v1/` — without touching any existing code.

## Data structures


## Client libraries

Each client ships a DAL per domain/version:
- CLI: bash scripts under `cli_client/` (`gdir_regions_v2.sh`, `gdir_tenancies_v1.sh`, `gdir_realms_v1.sh`).
- Node: TypeScript classes in `node_client/src/` (`gdir_regions_v2.ts`, `gdir_tenancies_v1.ts`, `gdir_realms_v1.ts`).
- Terraform: modules in `tf_client/` (`gdir_regions_v2`, `gdir_tenancies_v1`, `gdir_realms_v1`).

## Testing

- Node: `npm --prefix node_client test -- --runInBand`
- CLI: `TEST_DATA_DIR=$PWD/tf_manager bash cli_client/test/run_tests.sh`
- Terraform: `terraform init && terraform validate` in `tf_client/examples/{region,regions,tenancy,realm,realms}`


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

Top-level keys are region identifiers (e.g. `eu-zurich-1`). Each entry includes realm and public CIDRs; tenancy-scoped data is in `tenancies/v1`. Metadata is top-level and removed by DALs before returning maps.

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

Top-level keys are tenancy identifiers (e.g. `acme_prod`). Each tenancy has per-region attributes: private CIDRs, proxy, vault, toolchain, observability. Metadata is top-level.

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


## References

Oracle public cloud CIDR informaton, (https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json)[https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json]
