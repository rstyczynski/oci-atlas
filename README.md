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

**Data** — edit `tf_manager/regions_v1.json` and/or `tf_manager/realms_v1.json`, then provision.

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
GDIR_BUCKET=gdir_info REGION_KEY=eu-zurich-1 bash examples/region.sh       # region-only (v2)
GDIR_BUCKET=gdir_info bash examples/regions.sh                             # list regions/realms (v2)
GDIR_BUCKET=gdir_info TENANCY_KEY=acme_prod REGION_KEY=eu-zurich-1 bash examples/tenancy.sh
GDIR_BUCKET=gdir_info REALM_KEY=oc1 bash examples/realms.sh
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
| `GDIR_BUCKET` | Bucket containing catalog objects | `gdir_info` (CLI `gdir.sh`, Node `DEFAULT_BUCKET`, Terraform `bucket_name` variable) |
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
| `regions` | `v1` | `regions/v1` | OCI region attributes — network, proxy, vault, toolchain, observability |
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
| **Realm key** (`tf_client/examples/realm`) | Active region is resolved first, then its `realm` field is read from `regions/v1` | `TF_VAR_realm_key` |

All three discoveries cascade from a single source: the OCI SDK credentials in `~/.oci/config`. No region, realm, or tenancy identifier needs to be hardcoded anywhere.

### Data Access Layer (DAL)

Each domain+version pair has a dedicated DAL in every client library. The DAL encodes the exact field structure of that schema version and is never shared between versions or domains.

The canonical DAL name for a domain+version is **`gdir_<domain>_<version>`**. Every client uses this name directly — as a class name, file name, or module name.

| Client | DAL for `regions/v1` | DAL for `realms/v1` |
|--------|----------------------|---------------------|
| Node.js | class `gdir_regions_v1` in `node_client/src/gdir_regions_v1.ts` | class `gdir_realms_v1` in `node_client/src/gdir_realms_v1.ts` |
| CLI | `cli_client/gdir_regions_v1.sh`, functions `gdir_v1_regions_*` | `cli_client/gdir_realms_v1.sh`, functions `gdir_v1_realms_*` |
| Terraform | module `tf_client/gdir_regions_v1/` | module `tf_client/gdir_realms_v1/` |

When a schema changes incompatibly, a new version (`v2`) is introduced alongside the existing one. Consumers migrate at their own pace; both versions can be live simultaneously.

When a new domain is added (e.g. `realms`), a parallel set of DAL artefacts is created — `gdir_realms_v1` class, `gdir_realms_v1.sh`, `tf_client/gdir_realms_v1/` — without touching any existing code.

## Data structures

### `realms/v1` schema

Top-level keys are realm identifiers (e.g. `oc1`, `tst01`). Each entry carries the realm's display name, geographic scope, and base API domain.

```json
{
  "last_updated_timestamp": "<ISO-8601-UTC>",
  "<realm-key>": {
    "type": "<realm-type>",
    "geo-region": "<geo>",
    "name": "<display-name>",
    "description": "<description>",
    "api_domain": "<second-level-domain>"
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `last_updated_timestamp` | string | ISO 8601 UTC timestamp injected by `tf_manager` at upload time |
| `<realm-key>` | string (map key) | Unique realm identifier, e.g. `oc1`, `tst01` |
| `type` | enum | Deployment model — `public` · `government` · `sovereign` · `drcc` · `alloy` · `airgapped` |
| `geo-region` | string | Geographic scope, e.g. `global`, `eu` |
| `name` | string | Human-readable realm name, e.g. `OCI Public` |
| `description` | string | Longer description of the realm |
| `api_domain` | string | Second-level domain for OCI API endpoints in this realm, e.g. `oraclecloud.com`, `oraclecloud.eu` |

**Type reference (based on OCI TypeScript SDK realm registry):**

| Type | Oracle product | Example realms |
|------|---------------|----------------|
| `public` | OCI Commercial | OC1 (`oraclecloud.com`) |
| `government` | OCI Government Cloud | OC2/OC3 (`oraclegovcloud.com`), OC4 (`oraclegovcloud.uk`) |
| `sovereign` | OCI Sovereign Cloud | OC19 (`oraclecloud.eu` — EU Sovereign) |
| `drcc` | Dedicated Region Cloud@Customer | OC8–OC15, OC23–OC35 |
| `alloy` | Oracle Alloy (partner-operated) | OC20, OC21, OC42 |
| `airgapped` | Air-gapped Dedicated Region | fully isolated customer DC deployments |

### `regions/v1` schema

Top-level keys are OCI region identifiers. Each entry carries realm membership, network ranges, proxy settings, vault coordinates, toolchain config, and observability endpoints.

```json
{
  "last_updated_timestamp": "<ISO-8601-UTC>",
  "<region-key>": {
    "key": "<short-code>",
    "realm": "<realm-id>",
    "network": {
      "public": [
        {
          "cidr": "<cidr-block>",
          "description": "<description>",
          "tags": ["<tag>"]
        }
      ],
      "internal": [
        {
          "cidr": "<cidr-block>",
          "description": "<description>",
          "tags": ["<tag>"]
        }
      ],
      "proxy": {
        "url": "<scheme>://<host>:<port>",
        "ip": "<proxy-ip>",
        "port": "<port>",
        "noproxy": ["<ip>", "<fqdn>"]
      }
    },
    "security": {
      "vault": {
        "ocid": "<ocid>",
        "crypto_endpoint": "https://<host>:<port>",
        "management_endpoint": "https://<host>:<port>"
      }
    },
    "toolchain": {
      "github": {
        "runner": {
          "labels": ["<label>"],
          "image": "<ocid>"
        }
      }
    },
    "observability": {
      "prometheus_scraping_cidr": "<cidr-block>",
      "loki_destination_cidr": "<cidr-block>",
      "loki_fqdn": "<fqdn>"
    }
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `last_updated_timestamp` | string | ISO 8601 UTC timestamp injected by `tf_manager` at upload time |
| `<region-key>` | string (map key) | Unique region identifier, e.g. `eu-zurich-1` |
| `key` | string | Short region code, e.g. `ZRH`, `FRA` |
| `realm` | string | Realm the region belongs to, e.g. `oc1`, `tst01` |
| `network.public` | `{cidr, description, tags[]}[]` | Public-facing CIDR blocks |
| `network.internal` | `{cidr, description, tags[]}[]` | Internal/private CIDR blocks |
| `network.proxy.url` | string | Full proxy URL |
| `network.proxy.ip` | string | Proxy IP address |
| `network.proxy.port` | string | Proxy port |
| `network.proxy.noproxy` | string[] | IPs/FQDNs that bypass the proxy |
| `security.vault.ocid` | string | OCI Vault OCID |
| `security.vault.crypto_endpoint` | string | Vault cryptographic operations endpoint |
| `security.vault.management_endpoint` | string | Vault management endpoint |
| `toolchain.github.runner.labels` | string[] | GitHub Actions runner labels for this region |
| `toolchain.github.runner.image` | string | Compute image OCID used for GitHub runner instances |
| `observability.prometheus_scraping_cidr` | string | CIDR allowed to scrape Prometheus |
| `observability.loki_destination_cidr` | string | CIDR of the Loki destination |
| `observability.loki_fqdn` | string | FQDN of the Loki endpoint |

## Client libraries

Each client library contains a dedicated **Data Access Layer (DAL)** per domain and schema version. The DAL encodes the field structure of a specific schema version, exposes typed getter methods, and handles all OCI Object Storage interaction — callers never parse raw JSON directly.

All three libraries share the same DAL naming convention (`gdir_<domain>_<version>`) and the same auto-discovery chain (region → realm → tenancy from the active OCI connection). They are fully independent and can be used individually.

### Shell (CLI)

Bash functions sourced from `cli_client/gdir_<domain>_<version>.sh`. No compilation step; requires only `bash`, `jq`, and the OCI CLI.

→ See [`cli_client/README.md`](cli_client/README.md) for function reference, env-var overrides, and usage examples.

### Node.js

TypeScript classes in `node_client/src/gdir_<domain>_<version>.ts`, compiled with `tsc` and consumed via the package entry point. Async getter methods return typed interfaces defined in `types.ts`.

→ See [`node_client/README.md`](node_client/README.md) for API reference, constructor config, and example scripts.

### Terraform

Reusable modules under `tf_client/gdir_<domain>_<version>/`. Each module exposes typed `output` blocks and is consumed by example configurations under `tf_client/examples/`.

→ See [`tf_client/README.md`](tf_client/README.md) for module inputs, outputs, and example usage.

## Testing

Client logic (JSON parsing, field access, DAL methods) is validated without any OCI connection. Tests override the data-fetch layer to read from the local JSON files in `tf_manager/` instead of calling OCI Object Storage. Both test suites can be run on macOS or inside a Linux container via Podman.

**Shell client:**
```bash
# macOS
bash cli_client/test/run_tests.sh

# Linux via Podman (Ubuntu 24.04 default; override with IMAGE=oraclelinux:8)
bash cli_client/test/validate_linux.sh
```

**Node.js client (Jest):**
```bash
# macOS
cd node_client
npm test
cd ..

# Linux via Podman (node:20-slim)
bash node_client/test/validate_linux.sh
```

Tests use `ts-jest` with value-level assertions (`expect(...).toBe`, `toContain`, `toHaveProperty`, etc.) grouped in `describe` blocks. Both client test suites exit non-zero on any failure, making them suitable for CI pipelines.

## Recent Updates

### Sprint 2 - Sprint 1 Bug Fix

**Status:** failed

**Backlog Items:**

- **GD-1-fix1**: Remove `realm` attribute from tenancies json data file — **Rejected** (Product Owner decision: `realm` must remain in `tenancies/v1`)

**Outcome:** GD-1-fix1 was analyzed, designed, and partially implemented, then rolled back upon explicit Product Owner rejection during construction. No net change to any production file.

**Documentation:**

- Design: `progress/sprint_2/sprint_2_design.md`
- Decision log: `progress/sprint_2/sprint_2_openquestions.md`

---

### Sprint 1 - Foundation Data Model

**Status:** done

**Backlog Items Implemented:**

- **GD-1**: Build foundation data model — done

**Key Features Added:**

- `regions/v2` schema (`tf_manager/regions_v2.schema.json`) — physical region attributes only (public CIDRs)
- `tenancies/v1` schema (`tf_manager/tenancies_v1.schema.json`) — tenancy realm membership + per-region attributes (network, proxy, vault, toolchain, observability)
- Example data files: `regions_v2.json`, `tenancies_v1.json`

**Documentation:**

- Implementation: `progress/sprint_1/sprint_1_implementation.md`
- Tests: `progress/sprint_1/sprint_1_tests.md`
- Design: `progress/sprint_1/sprint_1_design.md`

---

## References

Oracle public cloud CIDR informaton, (https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json)[https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json]
