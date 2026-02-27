# Sprint 4 - Design

## GD-4. Apply versioning strategy for data and access layer

Status: Accepted

### Requirement Summary

Apply the versioning strategy from `VERSIONING.md` to all project artefacts:
1. Add mandatory `schema_version` field to all active schema files (top-level `properties` **and** `required`)
2. Add `schema_version` (and `last_updated_timestamp`) to all active data files
3. Add `prepare` script to `node_client/package.json`
4. Replace the superseded `regions_v1` stack across all clients (Node, Bash CLI, Terraform):
   - Remove regions_v1 data + schema + DAL + tests
   - Add/enable DALs for `regions_v2` and `tenancies_v1`; update exports, examples, and tests

### Feasibility Analysis

**API Availability:**

No external API required. All changes are local file edits and deletions. `ajv-cli@5` (via `npx`) validates schema + data. `npm run build` validates the `prepare` script.

**Technical Constraints:**

- `additionalProperties: false` on all schema objects — `schema_version` must be added to `properties`, not `required` (optional field)
- `regions_v1` DAL is imported by `node_client/test/run_tests.test.ts` — removing it requires updating the test file
- No new DAL files for `regions_v2` or `tenancies_v1` in this sprint (DAL is GD-6 scope)

**Risk Assessment:**

- Low: Adding `schema_version` is additive
- Low: `prepare` script is non-breaking
- Medium: Removing `regions_v1` + updating tests is destructive/irreversible — covered by git history

### Design Overview

The sprint has two independent parts:

**Part A — Add `schema_version`:** Additive, low-risk. Three schema files + three data files + `package.json`.

**Part B — Remove `regions_v1`:** Destructive, irreversible. Remove data file, schema file, DAL file, and update the test file and `index.ts` to remove all references.

---

### Part A: Add `schema_version` (and `last_updated_timestamp`)

#### Schema files — add `schema_version` to top-level `properties`

All three active schemas get the same addition after `last_updated_timestamp`:

```json
"schema_version": {
  "type": "string",
  "description": "Semver version of this data object, format MAJOR.MINOR.PATCH (e.g. \"1.0.0\")"
}
```

**Affected schema files (schema_version REQUIRED):**

| File | Change |
| ---- | ------ |
| `tf_manager/realms_v1.schema.json` | Add `schema_version` to top-level `properties` and `required` |
| `tf_manager/regions_v2.schema.json` | Add `schema_version` to top-level `properties` and `required` |
| `tf_manager/tenancies_v1.schema.json` | Add `schema_version` to top-level `properties` and `required` |

#### Data files — add `schema_version` (and `last_updated_timestamp` for `realms_v1.json`)

| File | Change | Value |
| ---- | ------ | ----- |
| `tf_manager/realms_v1.json` | Add `last_updated_timestamp` + `schema_version` | `"2026-02-25T12:00:00Z"` + `"1.0.0"` |
| `tf_manager/regions_v2.json` | Add `schema_version` after `last_updated_timestamp` | `"2.0.0"` |
| `tf_manager/tenancies_v1.json` | Add `schema_version` after `last_updated_timestamp` | `"1.0.0"` |

#### `node_client/package.json` — add `prepare` script

```json
"scripts": {
  "build": "tsc",
  "prepare": "npm run build",
  ...
}
```

---

### Part B: Remove `regions_v1` stack

#### Files to delete

| File | Reason |
| ---- | ------ |
| `tf_manager/regions_v1.json` | Old combined model — superseded by `regions_v2 + tenancies_v1` |
| `tf_manager/regions_v1.schema.json` | Schema for deleted data file |
| `node_client/src/gdir_regions_v1.ts` | DAL for deleted domain |

#### Files to update

**`node_client/src/index.ts`** — remove the `gdir_regions_v1` export line:

```typescript
// REMOVE this line:
export { gdir_regions_v1 } from "./gdir_regions_v1";
```

**`node_client/test/run_tests.test.ts`** — remove all `regions_v1`-related test cases:
- Remove `import { gdir_regions_v1 }` import
- Remove `MockRegions` class
- Remove all test cases that use `MockRegions` or reference `regions_v1.json`
- Keep all `realms_v1` tests unchanged (those stay)

**Bash CLI** — remove `cli_client/gdir_regions_v1.sh`; add scripts for `gdir_regions_v2.sh` and `gdir_tenancies_v1.sh`; update examples (`examples/region.sh`, `examples/regions.sh`) and test runner to use new scripts only.

**Terraform modules** — remove `tf_client/gdir_regions_v1/`; add `tf_client/gdir_regions_v2/` and `tf_client/gdir_tenancies_v1/`; update example stacks and outputs to consume the new modules; remove `tf_manager/regions_v1.tf` and add `regions_v2.tf` + `tenancies_v1.tf`.

---

### Part C: New DALs across clients

- **Node**: add `gdir_regions_v2.ts`, `gdir_tenancies_v1.ts`, update `types.ts`, `index.ts`, and Jest tests to cover new DALs; remove `gdir_regions_v1.ts`.
- **Bash CLI**: add `gdir_regions_v2.sh`, `gdir_tenancies_v1.sh` mirroring Node capabilities; update examples and test suite; remove `gdir_regions_v1.sh`.
- **Terraform**: add modules `gdir_regions_v2` and `gdir_tenancies_v1` plus manager tf files; update example stacks; remove regions_v1 module/manager file.

### Implementation Approach

**Step 1:** Add `schema_version` to `realms_v1.schema.json`, `regions_v2.schema.json`, `tenancies_v1.schema.json`.

**Step 2:** Add `schema_version` (and `last_updated_timestamp`) to `realms_v1.json`, `regions_v2.json`, `tenancies_v1.json`.

**Step 3:** Add `"prepare": "npm run build"` to `node_client/package.json`.

**Step 4:** Delete `regions_v1.json`, `regions_v1.schema.json`, `gdir_regions_v1.ts`, `cli_client/gdir_regions_v1.sh`, `tf_client/gdir_regions_v1/`, and `tf_manager/regions_v1.tf`.

**Step 5:** Update `index.ts` — remove `gdir_regions_v1` export; add exports for new DALs.

**Step 6:** Add new types to `types.ts`.

**Step 7:** Create `gdir_regions_v2.ts` and `gdir_tenancies_v1.ts`.

**Step 8:** Update `run_tests.test.ts` — replace `regions_v1` tests with `regions_v2` and `tenancies_v1` tests; add `getSchemaVersion()` test for `realms_v1`.

**Step 9:** Bash CLI — add v2/v1 scripts, update examples and test runner.

**Step 10:** Terraform — add regions_v2/tenancies_v1 modules and example stacks; remove v1 modules.

**Step 11:** Run `npm run build` + `npm test` and `bash cli_client/test/run_tests.sh` + `terraform` validations — iterate until all tests pass.

### Testing Strategy

**Functional Tests:**

Node / data validation
1. `ajv compile` on `realms_v1.schema.json`, `regions_v2.schema.json`, `tenancies_v1.schema.json`
2. `ajv validate` each data file against its schema
3. `jq .schema_version` returns correct value for each data file
4. `jq .last_updated_timestamp` present in `realms_v1.json`
5. `regions_v1.json` + `gdir_regions_v1.ts` absent
6. `gdir_realms_v1.getSchemaVersion()` returns `"1.0.0"`

Node client build/tests
7. `npm run build`
8. `npm test` — Jest suite covers regions_v2, tenancies_v1, realms_v1

Bash CLI
9. `bash cli_client/test/run_tests.sh` — covers regions_v2 and tenancies_v1 commands; asserts regions_v1 script absent

Terraform
10. `terraform -chdir=tf_client/examples/region validate`
11. `terraform -chdir=tf_client/examples/regions validate`
12. Confirm absence of `tf_client/gdir_regions_v1` and `tf_manager/regions_v1.tf`

**Success Criteria:** All 18 tests pass.

### Integration Notes

**Dependencies:** Sprint 1 (schema + data files) and Sprint 3 (`VERSIONING.md`) artefacts.

**Compatibility:** Removing `regions_v1` from the Node.js library is a breaking API change. Per VERSIONING.md this constitutes a MAJOR bump — the git tag after this sprint will be `v2.0.0` (not `v1.x.x`).

**Future sprints:** GD-6 (Top Level DAL) will add new DAL files for `regions_v2` and `tenancies_v1` — those are not in scope here.

### Design Decisions

**Decision 1:** `schema_version` field is mandatory — added to `properties` and `required` in all active schemas.
**Rationale:** PO directive; ensures future data cannot omit version metadata.

**Decision 2:** `regions_v1` removal includes all associated artefacts (data, schema, DAL, exports, tests).
**Rationale:** "Get rid of old versions" note in BACKLOG.md. Keeping dead code creates confusion.

**Decision 3:** New DALs for `regions_v2` and `tenancies_v1` are in-scope for this sprint across Node, Bash CLI, and Terraform.
**Rationale:** PO directive to update access layers alongside data versioning and to retire regions_v1 everywhere.

### Open Design Questions

None — all areas resolved. PO approval requested.

---

## Design Summary

## Overall Architecture

Two-part change: additive (`schema_version` + `prepare` script) + destructive (`regions_v1` stack removal).

## Design Risks

Medium — `regions_v1` removal is irreversible; covered by git history.

## Resource Requirements

- `ajv-cli` via `npx ajv-cli@5`
- `jq` for field extraction tests
- Node.js/npm for build test

## Design Approval Status

Accepted
