# Sprint 8 - Design

## GD-18: Remove last_updated_timestamp field

Status: Proposed

### Requirement Summary

Remove `last_updated_timestamp` from data JSON, schemas, manager TF injection, all DAL code, tests, and docs.

### Feasibility Analysis

**API Availability:** N/A — text deletion only.

**Technical Constraints:**

- `del(.last_updated_timestamp, .schema_version)` in shell DALs → must become `del(.schema_version)`
- `{ for k, v in local._raw : k => v if !(k == "last_updated_timestamp" || k == "schema_version") }` in TF DALs → simplify to only exclude `schema_version`
- Terraform `merge(..., { last_updated_timestamp = timestamp() })` → becomes plain `jsonencode(jsondecode(file(...)))` or just read the file content directly
- Node destructuring `const { last_updated_timestamp, schema_version, ...X } = doc` → remove `last_updated_timestamp`

**Risk Assessment:** Low — field removal only.

### Technical Specification — File-by-file changes

**Group 1: JSON data files (3 files)**

Remove `"last_updated_timestamp": "..."` line from:
- `manager/realms_v1.json`
- `manager/regions_v2.json`
- `manager/tenancies_v1.json`

**Group 2: Schema files (3 files)**

Remove `last_updated_timestamp` property block (3 lines each) from:
- `manager/realms_v1.schema.json`
- `manager/regions_v2.schema.json`
- `manager/tenancies_v1.schema.json`

**Group 3: Manager TF files (3 files)**

Replace `jsonencode(merge(jsondecode(file("...")), { last_updated_timestamp = timestamp() }))` with `file("...")` (read directly) in:
- `manager/realms_v1.tf`
- `manager/regions_v2.tf`
- `manager/tenancies_v1.tf`

**Group 4: Manager demo_mapping.sh**

Remove `last_updated_timestamp: $ts,` jq expression line from `manager/demo_mapping.sh`.

**Group 5: Shell DAL files (3 files)**

For each of `gdir_regions_v2.sh`, `gdir_tenancies_v1.sh`, `gdir_realms_v1.sh`:
- Remove `*_get_last_updated_timestamp()` function
- Update `del(.last_updated_timestamp, .schema_version)` → `del(.schema_version)`
- Update header comment removing `last_updated_timestamp?`
- `gdir_realms_v1.sh` only: update `select(. != "last_updated_timestamp" and . != "schema_version")` → `select(. != "schema_version")`

**Group 6: Shell test file**

Remove 3 `get_last_updated_timestamp` test lines from `clients/shell/test/run_tests.sh`.

**Group 7: Shell examples**

Remove `_ts` variable and echo lines from `clients/shell/examples/realms.sh`.

**Group 8: Shell README**

Remove `get_last_updated_timestamp` rows and update `del()` descriptions in `clients/shell/README.md`.

**Group 9: Node TS DAL files (3 files)**

For each of `gdir_regions_v2.ts`, `gdir_tenancies_v1.ts`, `gdir_realms_v1.ts`:
- Remove `getLastUpdatedTimestamp()` method
- Update destructuring: `const { last_updated_timestamp, schema_version, ...X }` → `const { schema_version, ...X }`

**Group 10: Node test file**

Remove test cases that call `getLastUpdatedTimestamp()`. Keep `not.toHaveProperty` / `not.toContain` assertions.

**Group 11: Node README**

Remove `getLastUpdatedTimestamp()` lines from function lists.

**Group 12: Terraform DAL files (3 modules)**

For each of `gdir_regions_v2`, `gdir_realms_v1`, `gdir_tenancies_v1`:
- `main.tf`: remove `last_updated_timestamp = try(...)` from locals; update filter expression to only exclude `schema_version`
- `outputs.tf`: remove `output "last_updated_timestamp"` block

**Group 13: Terraform example files**

`examples/realm/main.tf`: remove `last_updated_timestamp` from locals
`examples/realm/outputs.tf`: remove output
`examples/realms/main.tf`: remove `last_updated_timestamp` from locals
`examples/realms/outputs.tf`: remove output

**Group 14: Terraform README**

Remove 3 `last_updated_timestamp` output rows from `clients/terraform/README.md`.

**Group 15: Root docs**

`README.md`: remove from schema examples, update metadata description
`VERSIONING.md`: remove from JSON example and description text

### Testing Strategy

- Shell tests: 3 timestamp tests removed → expect 18 passed
- Node tests: timestamp `getLastUpdatedTimestamp` cases removed → verify count
- `not.toHaveProperty("last_updated_timestamp")` assertions retained (regression guards)

### YOLO Mode Decisions

#### Decision 1: Manager TF content handling

**Context**: `jsonencode(merge(jsondecode(file("...")), { last_updated_timestamp = timestamp() }))` — after removing the merge, what to use?
**Decision Made**: Use `file("${path.module}/xxx.json")` directly — reads raw JSON without re-encoding. This is cleaner.
**Alternatives**: Could use `jsonencode(jsondecode(file(...)))` but unnecessary round-trip.
**Risk**: Low — Terraform `file()` for `content` is valid.

#### Decision 2: Tenancies TF uses local var

**Context**: Tenancies TF uses `local.tenancies_data_file` (not a literal path) — must read the actual TF to handle correctly.
**Decision Made**: Read the file before editing.
**Risk**: Low

### Open Design Questions

None

---

# Design Summary

## Overall Architecture

Field removal across 18 files in 6 client areas. No new logic introduced.

## Design Approval Status

Proposed
