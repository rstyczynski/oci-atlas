# Global Directory - Project Analysis

## Purpose
Centralized catalog system for Oracle Cloud Infrastructure (OCI) metadata — region attributes (network, proxy, vault, toolchain, observability) and realm information. Stored in OCI Object Storage with schema validation, versioning, and typed client libraries.

## Technology Stack
- **Data Storage**: OCI Object Storage (versioned bucket)
- **Data Validation**: JSON Schema (draft 2020-12) + ajv-cli 5.x
- **Infrastructure**: Terraform 1.x
- **Node.js Client**: TypeScript 5.4.0, Node.js 18+, OCI SDK 2.125.x
- **Testing**: Jest 30.2.0
- **CLI Client**: Bash + jq + OCI CLI

## Directory Structure
```
global-directory/
├── tf_manager/          # Data source & validation (Terraform provisioning)
├── node_client/         # TypeScript/Node.js client library
│   ├── src/             # gdir.ts (core), gdir_regions_v1.ts, gdir_realms_v1.ts, types.ts
│   ├── examples/        # Usage examples
│   └── test/            # Jest tests (60+ cases, mock data, no OCI required)
├── cli_client/          # Bash client
│   ├── gdir.sh          # Core (caching, region discovery)
│   ├── gdir_regions_v1.sh  # 30+ bash functions
│   └── examples/ test/
└── tf_client/           # Terraform consumer modules
    ├── gdir_regions_v1/
    └── gdir_realms_v1/
```

## Current Domains
- `regions/v1` — per-region network, proxy, vault, toolchain, observability
- `realms/v1` — realm type, geo-region, api_domain

## Key Architectural Patterns

### Layering (identical across all 3 clients)
- **Core layer**: Auth, region auto-discovery from bucket OCID, raw fetch with caching
- **DAL layer**: Schema-specific typed getter methods (extends/wraps core)

### Auto-discovery
- Credentials from `~/.oci/config`
- Region key parsed from bucket OCID: `ocid1.bucket.<realm>.<region>.<hash>` → field [3]
- No hardcoded region/realm/tenancy anywhere

### Naming Convention
- `gdir_<domain>_<version>` for file names, class names, module names
- Examples: `gdir_regions_v1`, `gdir_realms_v1`

### Schema Versioning
- New versions coexist alongside old (`regions/v1` + `regions/v2` simultaneously)
- Consumers migrate at their own pace

### Environment Variable Overrides
- `REGION_KEY`: Explicit region (bypasses auto-discovery)
- `GDIR_BUCKET`: Bucket name (default: `gdir_info`)
- `GDIR_REGIONS_OBJECT`, `GDIR_REALMS_OBJECT`: Object paths
- `REALM_KEY`: Realm key override
- `TEST_DATA_DIR`: Path for Jest test data

## Key Files
| File | Purpose |
|------|---------|
| `node_client/src/gdir.ts` | Core OCI client, lazy init, region discovery |
| `node_client/src/gdir_regions_v1.ts` | 25+ typed async methods for regions |
| `node_client/src/gdir_realms_v1.ts` | Realm-specific typed methods |
| `node_client/test/run_tests.test.ts` | 60+ Jest tests with mock data |
| `cli_client/gdir.sh` | Bash core (caching, region discovery) |
| `cli_client/gdir_regions_v1.sh` | 30+ bash functions for regions |
| `tf_manager/regions_v1.json` | Regions data (~19KB, real OCI CIDR blocks) |
| `tf_manager/regions_v1.schema.json` | JSON Schema strict, draft 2020-12 |
| `tf_manager/validate.sh` | ajv-cli wrapper for pre-upload validation |
| `tf_client/gdir_regions_v1/main.tf` | Terraform DAL module |

## Testing Strategy
- Node.js: Mock subclasses override `fetchObject()` to read local JSON from `tf_manager/`
- No OCI connection required for unit tests
- Linux validation via Podman container (`node:20-slim`)
- CLI tests: `cli_client/test/run_tests.sh`

## Adding a New Domain
Pattern to follow (e.g., `tenancies/v1`):
1. `tf_manager/tenancies_v1.json` + schema + `.tf` provisioning
2. `node_client/src/gdir_tenancies_v1.ts` extending `gdir`
3. `cli_client/gdir_tenancies_v1.sh` with bash functions
4. `tf_client/gdir_tenancies_v1/` Terraform module

## Commands
```bash
# Provision data
cd tf_manager && terraform init && terraform apply -auto-approve

# Node.js
cd node_client && npm install && npm test
npm run example:regions

# CLI
bash cli_client/examples/regions.sh

# Terraform client
cd tf_client/examples/regions && terraform apply -auto-approve

# Linux container tests
bash node_client/test/validate_linux.sh
bash cli_client/test/validate_linux.sh
```
