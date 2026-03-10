# Sprint 8 - Implementation

## GD-18: Remove last_updated_timestamp field

Status: Implemented

### Changes Implemented

**Group 1: JSON data files (3 files)**

Removed `"last_updated_timestamp": "..."` from:
- `manager/realms_v1.json`
- `manager/regions_v2.json`
- `manager/tenancies_v1.json`

**Group 2: Schema files (3 files)**

Removed `last_updated_timestamp` property block (3 lines) from:
- `manager/realms_v1.schema.json`
- `manager/regions_v2.schema.json`
- `manager/tenancies_v1.schema.json`

**Group 3: Manager TF files (3 files)**

Replaced `jsonencode(merge(jsondecode(file("...")), { last_updated_timestamp = timestamp() }))` with `file("...")` in:
- `manager/realms_v1.tf`
- `manager/regions_v2.tf`
- `manager/tenancies_v1.tf` (used `file(local.tenancies_data_file)` — local var preserved)

**Group 4: Manager demo_mapping.sh**

Removed `last_updated_timestamp: $ts,` jq expression and `now`/`$ts` variable from `manager/demo_mapping.sh`.

**Group 5: Shell DAL files (3 files)**

For each of `gdir_regions_v2.sh`, `gdir_tenancies_v1.sh`, `gdir_realms_v1.sh`:
- Removed `*_get_last_updated_timestamp()` function
- Updated `del(.last_updated_timestamp, .schema_version)` → `del(.schema_version)`
- Updated header comment
- `gdir_realms_v1.sh`: updated `select(. != "last_updated_timestamp" and . != "schema_version")` → `select(. != "schema_version")`

**Group 6: Shell test file**

Removed 3 `get_last_updated_timestamp` test lines from `clients/shell/test/run_tests.sh`.

**Group 7: Shell examples**

Removed `_ts` variable, `echo "=== Data last updated ==="`, and timestamp echo from `clients/shell/examples/realms.sh`.

**Group 8: Shell README**

Removed `get_last_updated_timestamp` rows and updated `del()` descriptions in `clients/shell/README.md`.

**Group 9: Node TS DAL files (3 files)**

For each of `gdir_regions_v2.ts`, `gdir_tenancies_v1.ts`, `gdir_realms_v1.ts`:
- Removed `getLastUpdatedTimestamp()` method
- Updated destructuring: `const { last_updated_timestamp, schema_version, ...X }` → `const { schema_version, ...X }`

**Group 10: Node test file**

Removed 3 `getLastUpdatedTimestamp` test cases. Retained `not.toHaveProperty("last_updated_timestamp")` regression guards.

**Group 11: Node README**

Removed `getLastUpdatedTimestamp()` rows from all 3 function lists.

**Group 12: Terraform DAL files (3 modules)**

For each of `gdir_regions_v2`, `gdir_tenancies_v1`, `gdir_realms_v1`:
- `main.tf`: removed `last_updated_timestamp = try(...)` from locals; updated filter to only exclude `schema_version`
- `outputs.tf`: removed `output "last_updated_timestamp"` block

**Group 13: Terraform example files**

- `examples/realm/main.tf`: removed `last_updated_timestamp` from locals
- `examples/realm/outputs.tf`: removed output
- `examples/realms/main.tf`: removed `last_updated_timestamp` from locals
- `examples/realms/outputs.tf`: removed output block

**Group 14: Terraform README**

Removed 3 `last_updated_timestamp` output rows from `clients/terraform/README.md`.

**Group 15: Root docs**

- `README.md`: removed from all 3 schema examples, updated metadata description
- `VERSIONING.md`: removed from JSON example and description text

### Commit

`refactor: (sprint-8) remove last_updated_timestamp field — GD-18`

35 files changed, 23 insertions(+), 119 deletions(-)
