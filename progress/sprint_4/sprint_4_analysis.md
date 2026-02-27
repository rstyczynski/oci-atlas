# Sprint 4 - Analysis

Status: Complete

## Sprint Overview

Apply the versioning strategy documented in `VERSIONING.md` (Sprint 3 product) to all project artefacts. "Get rid of old versions, and start from the latest ones." The sprint produces concrete artefact changes: `schema_version` field in schemas + data files, `prepare` script in `node_client/package.json`, and removal of superseded `regions_v1` artefacts.

## Backlog Items Analysis

### GD-4. Apply versioning strategy for data and access layer

**Requirement Summary:**

Implement VERSIONING.md across all relevant artefacts:
1. Add `schema_version` field to all JSON Schema files (in top-level `properties`)
2. Add `schema_version` value to all JSON data files
3. Add `prepare: npm run build` to `node_client/package.json`
4. Remove old-version artefacts (`regions_v1`) per the "get rid of old versions" note

**Current State Assessment:**

| Artefact | Current State | Required Change |
| -------- | ------------- | --------------- |
| `tf_manager/regions_v1.schema.json` | No `schema_version` in properties | Add `schema_version` property — OR remove (see below) |
| `tf_manager/realms_v1.schema.json` | No `schema_version` in properties | Add `schema_version` property |
| `tf_manager/regions_v2.schema.json` | No `schema_version` in properties | Add `schema_version` property |
| `tf_manager/tenancies_v1.schema.json` | No `schema_version` in properties | Add `schema_version` property |
| `tf_manager/regions_v1.json` | No `schema_version`, no `last_updated_timestamp` | Remove OR add both fields |
| `tf_manager/realms_v1.json` | No `schema_version`, no `last_updated_timestamp` | Add both fields |
| `tf_manager/regions_v2.json` | Has `last_updated_timestamp`, no `schema_version` | Add `schema_version: "2.0.0"` |
| `tf_manager/tenancies_v1.json` | Has `last_updated_timestamp`, no `schema_version` | Add `schema_version: "1.0.0"` |
| `node_client/package.json` | Has `build: tsc`, no `prepare` | Add `"prepare": "npm run build"` |
| `node_client/src/gdir_regions_v1.ts` | DAL for the old `regions/v1` domain | Remove — OR keep for backward compat |

**`regions_v1` removal analysis:**

`regions_v1` is the original data model that mixed physical region + tenancy-specific attributes. Sprint 1 (GD-1) replaced it with `regions_v2` (physical only) + `tenancies_v1` (tenancy-specific). The BACKLOG.md GD-4 note says "get rid of old versions, and start from the latest ones."

Removing `regions_v1` means:
- Delete `tf_manager/regions_v1.json`
- Delete `tf_manager/regions_v1.schema.json`
- Delete `node_client/src/gdir_regions_v1.ts` (DAL is useless without the data)
- Update `node_client/src/index.ts` to remove the `gdir_regions_v1` export

**`last_updated_timestamp` gap:** `regions_v1.json` and `realms_v1.json` lack this field. Since these files were created before the convention was established, and `realms_v1.json` stays (it's the current realms version), `last_updated_timestamp` should be added to `realms_v1.json`.

**Technical Approach:**

1. Remove `regions_v1` data + schema + DAL (if PO confirms removal)
2. Add `schema_version` to remaining 3 schema files
3. Add `schema_version` + `last_updated_timestamp` to `realms_v1.json`
4. Add `schema_version` to `regions_v2.json` and `tenancies_v1.json`
5. Add `prepare` script to `node_client/package.json`
6. Update `node_client/src/index.ts` if `gdir_regions_v1.ts` is removed

**Dependencies:**

- Sprint 1 artefacts (`regions_v2.json`, `tenancies_v1.json`, `realms_v1.json`) — confirmed present
- Sprint 3 `VERSIONING.md` — the reference spec for this sprint

**Testing Strategy:**

1. All remaining schema files pass `ajv compile --spec=draft2020` — 3 tests (or 4 if regions_v1 kept)
2. All remaining data files pass `ajv validate` against their schemas — 3 tests
3. `jq .schema_version` on each data file returns correct version string — 3 tests
4. `npm run build` succeeds in `node_client/` — 1 test

**Risks/Concerns:**

1. **Removing `regions_v1`**: Irreversible deletion. Since this is early phase with no production consumers, risk is low. But this is a destructive action that requires PO confirmation in managed mode.
2. **`index.ts` update**: Removing `gdir_regions_v1` export may break any test that imports it. Current test file should be checked.
3. **`last_updated_timestamp` in `realms_v1.json`**: This field should be set to a real timestamp value.

**Compatibility Notes:**

- Removing `regions_v1` from exports is a breaking change to the Node.js library — consistent with the "get rid of old versions" directive and will be a MAJOR bump.
- Adding `schema_version` to schemas + data is additive — backward-compatible for any consumer that ignores the new field.

## Overall Sprint Assessment

**Feasibility:** High — JSON edits + file deletions + one TypeScript file update.

**Estimated Complexity:** Simple to Moderate — the deletion of `regions_v1` requires careful clean-up of the DAL and index exports.

**Prerequisites Met:** Yes — Sprint 1 and Sprint 3 artefacts are complete.

**Open Questions:**

1. **Remove `regions_v1` entirely?** BACKLOG.md says "get rid of old versions" — this implies yes, but confirmation needed in managed mode before destructive action.
2. **What timestamp value for `realms_v1.json` `last_updated_timestamp`?** Suggest using the same value as the other files: `"2026-02-25T12:00:00Z"`.

## Recommended Design Focus Areas

- Confirm scope of `regions_v1` removal (data + schema + DAL + export)
- Define exact `schema_version` values: `realms/v1 → 1.0.0`, `regions/v2 → 2.0.0`, `tenancies/v1 → 1.0.0`
- Check `node_client/src/index.ts` and test files for `gdir_regions_v1` dependencies

## Readiness for Design Phase

Confirmed Ready — scope bounded, open questions documented for design resolution.
