# Sprint 3 - Analysis

Status: Complete

## Sprint Overview

Establish a concrete versioning strategy for data objects, the Data Access Layer, client library distribution, and Object Storage paths. The sprint produces decisions + a lightweight set of concrete artefacts that implement the core decision (adding `schema_version` to data objects). Object Storage path restructure is deferred to GD-3.

## Backlog Items Analysis

### GD-2. Establish versioning strategy for data and access layer

**Requirement Summary:**

Define and document how semantic versioning applies to:

1. Data objects — JSON data files and their schemas
2. Data Access Layer — DAL file naming, version embedding, default alias
3. Client library distribution — how consumers install and pin the Node.js library
4. Object Storage paths — how MAJOR, MINOR, PATCH map to bucket object paths

**Current State Assessment:**

| Area | Current Convention | Gap |
|------|--------------------|-----|
| Schema `$id` | `regions/v2`, `tenancies/v1` | MAJOR only; no MINOR/PATCH; `v` prefix |
| Object Storage path | `regions/v1`, `regions/v2` | MAJOR only in path; no MINOR in path |
| Data files (local) | `regions_v2.json`, `tenancies_v1.json` | MAJOR only; no `schema_version` field in data |
| DAL files | `gdir_regions_v1.ts`, `gdir_regions_v1.sh` | MAJOR only; no default alias/symlink |
| Node.js package | `global-directory-node-client` v1.0.0 in package.json | Not tagged in git; no `prepare` script for git-source install |
| Git branches | Only `main` | No maintenance branch convention established |

**`schema_version` field — current state:** Not present in any data file (`regions_v2.json`, `tenancies_v1.json`, `regions_v1.json`, `realms_v1.json`). The data objects have `last_updated_timestamp` but no machine-readable schema version.

**Technical Approach:**

This sprint resolves four areas:

**Area 1 — Data objects:** Add a `schema_version` field to all data schemas (4 files) and example data files (4 files). The field format must be decided in design.

**Area 2 — DAL:** Decide whether to add a version-neutral alias (`gdir_regions.ts` → symlink or re-export pointing to the current version) alongside the versioned file. The versioned filename stays; the alias is optional.

**Area 3 — Client library distribution:** Confirm npm git-source install as the distribution strategy; add a `prepare` script to `node_client/package.json` so `tsc` runs on git install.

**Area 4 — Object Storage paths:** Define the MINOR/PATCH convention for Object Storage. Current `regions/v1` path encodes MAJOR only. Decide if MINOR is added to the path, or tracked only in the data file via `schema_version`.

**Dependencies:**

Depends on Sprint 1 (GD-1) schemas and data files being in their current state — confirmed. GD-3 ("tf_manager handles upload of latest version") logically follows from GD-2 decisions on Object Storage paths.

**Testing Strategy:**

1. All 4 schema files pass `ajv compile --spec=draft2020` after `schema_version` field is added
2. All 4 data files pass `ajv validate` against their updated schemas
3. `npm run build` succeeds in `node_client/` (validates `prepare` script works)
4. `jq .schema_version` on each data file returns the expected version string

**Risks/Concerns:**

1. **Object Storage path format conflict**: Current convention uses `v`-prefixed MAJOR (`v1`). Semver uses numeric only (`1.0.0`). GD-2 must decide which convention wins and whether a migration of existing paths is needed (likely out of scope for this sprint).
2. **Breaking change scope**: Adding `schema_version` to `required` in existing schemas would break any existing data files that don't have it. Strategy: add to `properties` but not `required` (or add to all existing data files simultaneously — which this sprint does).
3. **DAL alias complexity**: A TypeScript re-export file `gdir_regions.ts → gdir_regions_v1.ts` is trivial; a shell symlink is OS-dependent. This should remain optional/advisory.

**Compatibility Notes:**

- `schema_version` field addition is additive to schemas — existing consumers reading data files do not break if they don't use the new field.
- If added to `required`, all existing data files must be updated simultaneously (which this sprint does for the example files).
- No DAL code changes required for `schema_version` — it is a data-layer field, not a DAL concern.

## Overall Sprint Assessment

**Feasibility:** High — all changes are to JSON files and documentation; no runtime system dependency.

**Estimated Complexity:** Simple — JSON Schema edits + data file edits + one `package.json` script addition + documentation.

**Prerequisites Met:** Yes — Sprint 1 artifacts are complete and in their expected state.

**Open Questions:**

1. **`schema_version` field format** — should the value be `"1.0"`, `"1.0.0"`, `"v1"`, or just `1`? The format determines how consumers parse and compare versions.
2. **`schema_version` field placement** — top-level alongside `last_updated_timestamp`, or inside each entry? Top-level is consistent with `last_updated_timestamp` convention.
3. **Object Storage path for MINOR** — does MINOR go into the path (`regions/1/regions-1.1.json`) or only in the `schema_version` field? If in the path, the current `regions/v1` object becomes `regions/1/regions-1.0.json`, which requires a migration. If not in the path, MINOR changes are transparent to Object Storage and only traceable via the `schema_version` field.
4. **DAL alias** — is a version-neutral alias (`gdir_regions.ts`) required as a deliverable of this sprint, or advisory only?

## Recommended Design Focus Areas

- `schema_version` field: format, location, required or optional
- Object Storage path convention: whether MINOR appears in path or only in data field — this determines GD-3 scope
- `prepare` script in `node_client/package.json` — confirm if already present (it is not — `build` exists but `prepare` does not)

## Readiness for Design Phase

Confirmed Ready — all four areas identified, scope bounded, open questions documented for design resolution.
