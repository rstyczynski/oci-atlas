# Sprint 3 - Design

## GD-2. Establish versioning strategy for data and access layer

Status: Proposed

### Requirement Summary

Define and implement a versioning strategy across four areas: data objects (JSON schema + data files), the Data Access Layer (file naming convention), client library distribution (Node.js npm), and Object Storage paths (MAJOR/MINOR/PATCH mapping). Deliver concrete artefacts where the strategy requires immediate implementation.

### Feasibility Analysis

**API Availability:**

No external API required. All changes are to local JSON files, schema files, and `package.json`. `ajv-cli` (already available via `npx ajv-cli@5`) validates schema and data changes.

**Technical Constraints:**

- JSON Schema draft 2020-12 (existing standard, unchanged)
- `additionalProperties: false` convention must be maintained — any new field must be added to `properties` in each schema
- `node_client/package.json` `prepare` script must run `tsc` to enable git-source npm install
- Existing consumers of `regions/v1` and `realms/v1` (legacy paths) must not break — these objects stay as-is

**Risk Assessment:**

- Low: Adding `schema_version` to `properties` is additive; adding to `required` requires simultaneous update of all data files (this sprint does both)
- Low: `prepare` script addition is non-breaking for existing `npm install` workflows
- Medium: Object Storage path convention change (removing `v` prefix, adding MINOR) requires migration of existing objects — **deferred to GD-3**, this sprint only documents the target convention

### Design Overview — Four Areas

---

#### Area 1: Data Objects — `schema_version` field

**Decision:** Add `schema_version` as a top-level field in all data objects, alongside `last_updated_timestamp`. Format: `"MAJOR.MINOR"` string (e.g., `"1.0"`). PATCH is not tracked in the field — PATCH changes are transparent (bug fixes only; data structure unchanged).

**Rationale:** Top-level placement mirrors `last_updated_timestamp` convention. String `"MAJOR.MINOR"` is human-readable and machine-parsable without a semver library. PATCH omitted because it is applied to the data value, not the structure, and is tracked by Object Storage native versioning.

**Schema change (all 4 schema files):** Add to top-level `properties`:

```json
"schema_version": {
  "type": "string",
  "description": "Schema version this data object conforms to, format MAJOR.MINOR (e.g. \"1.0\")"
}
```

Add `"schema_version"` to the top-level implicit required list. Since the root object uses `additionalProperties` to define entries, `schema_version` must appear in `properties` at the top level alongside `last_updated_timestamp`. Both `last_updated_timestamp` and `schema_version` are top-level reserved keys.

**Data file change (all 4 data files):** Add `"schema_version": "1.0"` after `last_updated_timestamp`.

**Affected files:**

| File | Change |
| ---- | ------ |
| `tf_manager/regions_v1.schema.json` | Add `schema_version` to top-level properties |
| `tf_manager/realms_v1.schema.json` | Add `schema_version` to top-level properties |
| `tf_manager/regions_v2.schema.json` | Add `schema_version` to top-level properties |
| `tf_manager/tenancies_v1.schema.json` | Add `schema_version` to top-level properties |
| `tf_manager/regions_v1.json` | Add `"schema_version": "1.0"` |
| `tf_manager/realms_v1.json` | Add `"schema_version": "1.0"` |
| `tf_manager/regions_v2.json` | Add `"schema_version": "2.0"` |
| `tf_manager/tenancies_v1.json` | Add `"schema_version": "1.0"` |

---

#### Area 2: Data Access Layer — File Naming Convention

**Decision:** Keep the current `gdir_<domain>_v<MAJOR>` naming convention (e.g., `gdir_regions_v1.ts`). Add an **advisory** version-neutral alias file per domain (e.g., `gdir_regions.ts`) as a re-export pointing to the current MAJOR version. The alias is not a symlink (OS-dependent) but a thin TypeScript re-export and a thin shell source-redirect.

**This sprint scope:** Document the convention. The alias files themselves are not a deliverable of this sprint — they are a deliverable of the DAL implementation sprint (future).

**Version maintenance:** Old MAJOR versions are maintained on git branches named `maint/v<MAJOR>` (e.g., `maint/v1`). The `main` branch always tracks the current version.

---

#### Area 3: Client Library Distribution

**Decision:** npm git-source install from a tagged commit. Consumers add to their `package.json`:

```json
"global-directory-node-client": "git+https://github.com/your-org/global-directory.git#v1.0.0"
```

Tags follow `v<MAJOR>.<MINOR>.<PATCH>` (e.g., `v1.0.0`).

**Concrete deliverable this sprint:** Add `"prepare": "npm run build"` to `node_client/package.json` scripts. This ensures `tsc` runs automatically when the package is installed via git source. Without `prepare`, a git-source consumer gets only source files, not compiled `dist/`.

**Shell and Terraform modules:** Sourced by path or git URL — no package manager. Versioning is tracked by git tag; consumers reference the tag in their checkout.

---

#### Area 4: Object Storage Paths

**Decision (target convention):**

- `<domain>/<MAJOR>/<domain>-<MAJOR>.<MINOR>.json` — full MINOR in filename
- `<domain>/<MAJOR>/<domain>-latest.json` — symlink/copy to latest MINOR for clients that always want current
- PATCH: applied in-place; tracked by Object Storage native object versioning (not in path)
- No `v` prefix in numeric parts (aligns with semver: `1`, `1.0`, not `v1`, `v1.0`)

**Example:**

```text
regions/2/regions-2.0.json    ← current regions/v2 content under new convention
regions/2/regions-latest.json ← latest minor (same as 2.0 today)
```

**Early-phase note:** The project is in early phase with no production consumers locked to existing paths. All paths will adopt the new convention immediately — no migration period, no legacy path maintenance. GD-3 implements tf_manager upload logic using this convention from scratch.

**This sprint scope:** Document the target convention. No Object Storage changes are made in this sprint — that is GD-3 scope.

---

### Implementation Approach

**Step 1:** Add `schema_version` to top-level `properties` in all 4 schema files.

**Step 2:** Add `"schema_version": "X.0"` to all 4 data files.

**Step 3:** Add `"prepare": "npm run build"` to `node_client/package.json` scripts.

**Step 4:** Validate all 4 schema+data pairs with `ajv validate`.

**Step 5:** Validate `npm run build` still succeeds in `node_client/`.

### Testing Strategy

**Functional Tests:**

1. Each schema passes `ajv compile --spec=draft2020` — 4 tests
2. Each data file passes `ajv validate` against its schema — 4 tests
3. `jq .schema_version` on each data file returns the correct version string — 4 tests
4. `node_client/` builds cleanly (`npm run build`) — 1 test

**Success Criteria:**

All 13 tests pass. `schema_version` field present and validated in all 4 data files.

### Integration Notes

**Dependencies:** Sprint 1 artefacts (schema + data files) are the base for all edits.

**Compatibility:** Additive changes only to schemas and data files. Existing consumers that do not read `schema_version` are unaffected.

**GD-3 dependency:** Object Storage path convention defined here; GD-3 implements tf_manager upload logic using that convention.

### Design Decisions

**Decision 1:** `schema_version` format `"MAJOR.MINOR"` string
**Rationale:** Human-readable, parsable with simple string split. PATCH excluded as it doesn't change schema structure.
**Alternatives Considered:** `"MAJOR.MINOR.PATCH"` full semver — rejected (PATCH is infrastructure concern, not schema concern); integer MAJOR only — rejected (MINOR changes need consumer visibility).

**Decision 2:** Object Storage drops `v` prefix in new convention
**Rationale:** Aligns with semver standard (`1.0` not `v1.0`). Existing `v`-prefixed paths remain untouched.
**Alternatives Considered:** Keep `v` prefix — rejected for new paths (inconsistent with semver).

**Decision 3:** `prepare` script added to `node_client/package.json`
**Rationale:** npm git-source install runs `prepare` automatically; without it consumers get uncompiled TypeScript.
**Alternatives Considered:** Commit compiled `dist/` to repo — rejected (unnecessary binary in git).

### Open Design Questions

None — all four areas resolved. PO approval requested.

---

## Design Summary

## Overall Architecture

Four-area versioning strategy established:

- **Data**: `schema_version` field (`"MAJOR.MINOR"`) in all data objects
- **DAL**: `_v<MAJOR>` filename convention retained; version-neutral alias deferred to DAL sprint
- **Distribution**: npm git-source with `prepare` script; git tags `v<MAJOR>.<MINOR>.<PATCH>`
- **Object Storage**: Target convention `<domain>/<MAJOR>/<domain>-<MAJOR>.<MINOR>.json`; migration in GD-3

## Shared Components

`schema_version` field definition is identical across all 4 schema files.

## Design Risks

Low — all changes are additive JSON edits and one `package.json` script addition.

## Resource Requirements

- `ajv-cli` (available via `npx ajv-cli@5`)
- `jq` (already installed)
- Node.js + npm (already installed for `node_client/`)

## Design Approval Status

Awaiting Review
