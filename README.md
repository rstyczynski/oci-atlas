# Global directory

Catalog of OCI region attributes (proxy, network, realm membership, etc.), realm (domain, type, geo-region, etc.), stored as JSON in an OCI Object Storage bucket. Provides versioned data with associated Node.js, CLI, and Terraform clients for reading the data. The catalog is provisioned and maintained by a Terraform manager module supplied with data file validation.

Global directory is the equivalent of `jq data.json` — except the data file lives centrally in OCI Object Storage, is schema-validated before every upload, versioned by domain, and consumed through structured data access layers in Node.js, CLI, and Terraform instead of ad-hoc one-off queries.

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
bash examples/regions.sh
REGION_KEY=tst-region-1 bash examples/region.sh

bash examples/realms.sh
REALM_KEY=oc1 bash examples/realms.sh
cd ..
```

**Read — Node:**

```bash
cd node_client
npm install
npm run example:regions
npm run example:region
REGION_KEY=tst-region-2 npm run example:region

npm run example:realms
npm run example:realm
REALM_KEY=oc19 npm run example:realm
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
