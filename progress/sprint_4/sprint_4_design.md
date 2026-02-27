# Sprint 4 - Design

## GD-4. Apply versioning strategy for data and access layer

Status: Proposed

### Requirement Summary

Apply the versioning strategy from `VERSIONING.md` to all project artefacts:
1. Add `schema_version` field to the 3 active schema files
2. Add `schema_version` (and `last_updated_timestamp`) to the 3 active data files
3. Add `prepare` script to `node_client/package.json`
4. Remove the superseded `regions_v1` stack (data + schema + DAL + tests)

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

**Affected schema files:**

| File | Change |
| ---- | ------ |
| `tf_manager/realms_v1.schema.json` | Add `schema_version` to top-level `properties` |
| `tf_manager/regions_v2.schema.json` | Add `schema_version` to top-level `properties` |
| `tf_manager/tenancies_v1.schema.json` | Add `schema_version` to top-level `properties` |

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

---

### Implementation Approach

**Step 1:** Add `schema_version` to `realms_v1.schema.json`, `regions_v2.schema.json`, `tenancies_v1.schema.json`.

**Step 2:** Add `schema_version` (and `last_updated_timestamp`) to `realms_v1.json`, `regions_v2.json`, `tenancies_v1.json`.

**Step 3:** Add `"prepare": "npm run build"` to `node_client/package.json`.

**Step 4:** Delete `regions_v1.json`, `regions_v1.schema.json`, `gdir_regions_v1.ts`.

**Step 5:** Update `index.ts` — remove `gdir_regions_v1` export.

**Step 6:** Update `run_tests.test.ts` — remove `regions_v1` test cases.

**Step 7:** Run `npm run build` in `node_client/` to verify compilation.

### Testing Strategy

**Functional Tests:**

1. Each active schema passes `ajv compile --spec=draft2020` — 3 tests
2. Each active data file passes `ajv validate` against its schema — 3 tests
3. `jq .schema_version` returns correct value for each data file — 3 tests
4. `jq .last_updated_timestamp` returns value for `realms_v1.json` — 1 test
5. `npm run build` succeeds — 1 test
6. `regions_v1.json` no longer exists — 1 test
7. `gdir_regions_v1.ts` no longer exists — 1 test

**Success Criteria:** All 13 tests pass.

### Integration Notes

**Dependencies:** Sprint 1 (schema + data files) and Sprint 3 (`VERSIONING.md`) artefacts.

**Compatibility:** Removing `regions_v1` from the Node.js library is a breaking API change. Per VERSIONING.md this constitutes a MAJOR bump — the git tag after this sprint will be `v2.0.0` (not `v1.x.x`).

**Future sprints:** GD-6 (Top Level DAL) will add new DAL files for `regions_v2` and `tenancies_v1` — those are not in scope here.

### Design Decisions

**Decision 1:** `schema_version` field is NOT added to `required` — it is optional to allow incremental adoption.
**Rationale:** Consistent with VERSIONING.md specification.

**Decision 2:** `regions_v1` removal includes all associated artefacts (data, schema, DAL, exports, tests).
**Rationale:** "Get rid of old versions" note in BACKLOG.md. Keeping dead code creates confusion.

**Decision 3:** No new DAL files for `regions_v2` or `tenancies_v1` in this sprint.
**Rationale:** DAL implementation is GD-6 scope. This sprint focuses on versioning artefacts, not feature implementation.

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

Awaiting Review
