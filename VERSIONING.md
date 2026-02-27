# Versioning Strategy

This document defines how semantic versioning (semver) applies across all artefacts in the Global Directory project: data objects, the Data Access Layer, client library distribution, and Object Storage paths.

---

## Semver Semantics for Data

All version numbers follow `MAJOR.MINOR.PATCH` (e.g., `1.2.3`).

| Version part | Change | Example |
| ------------ | ------ | ------- |
| MAJOR | Breaking — field removed, renamed, or type changed | Remove `realm` from `regions_v2` |
| MINOR | Backward-compatible addition — new schema field, or new catalog entry (e.g. new region added) | Add `api_endpoint` field to schema; add `eu-paris-1` to `regions_v2.json` |
| PATCH | Bug fix — wrong data value corrected, wrong schema constraint fixed | Fix a wrong CIDR block; fix a wrong regex pattern in schema |

---

## Area 1: Data Objects

### `schema_version` field

Every JSON data object carries a top-level `schema_version` field alongside `last_updated_timestamp`:

```json
{
  "last_updated_timestamp": "2026-02-25T12:00:00Z",
  "schema_version": "1.0.0",
  ...
}
```

**Format:** Full semver string `"MAJOR.MINOR.PATCH"` (e.g., `"1.0.0"`, `"2.1.3"`).

**Placement:** Top-level, next to `last_updated_timestamp`. Not inside individual entries.

**Purpose:** Consumers can detect stale cached data without a separate Object Storage API call. All three parts are meaningful:
- MAJOR bump signals the consumer must update its code before parsing the object.
- MINOR bump signals new fields or new entries are available, but existing code still works.
- PATCH bump signals a silent data correction; no consumer code change needed.

### Current versions

| Data object | Current `schema_version` |
| ----------- | ------------------------ |
| `tf_manager/regions_v1.json` | `1.0.0` |
| `tf_manager/realms_v1.json` | `1.0.0` |
| `tf_manager/regions_v2.json` | `2.0.0` |
| `tf_manager/tenancies_v1.json` | `1.0.0` |

### Schema files

Each JSON Schema file defines `schema_version` in its top-level `properties`:

```json
"schema_version": {
  "type": "string",
  "description": "Semver version of this data object, format MAJOR.MINOR.PATCH (e.g. \"1.0.0\")"
}
```

`schema_version` is not in `required` — it is optional at the schema level to allow incremental adoption.

---

## Area 2: Data Access Layer

### File naming

DAL files carry the MAJOR version in their filename:

```
gdir_regions_v1.ts      ← Node.js DAL for regions/v1
gdir_regions_v2.ts      ← Node.js DAL for regions/v2
gdir_regions_v1.sh      ← Shell DAL for regions/v1
```

Pattern: `gdir_<domain>_v<MAJOR>.<ext>`

**Rationale:** MAJOR bumps introduce breaking changes requiring updated consumer code. Embedding MAJOR in the filename makes the breaking change explicit and allows old and new versions to coexist during transition.

### Version-neutral alias (advisory)

An optional version-neutral alias file may be provided per domain:

- TypeScript: `gdir_regions.ts` — thin re-export: `export * from './gdir_regions_v2'`
- Shell: `gdir_regions.sh` — source redirect: `source "$(dirname "$0")/gdir_regions_v1.sh"`

The alias always points to the current default MAJOR version. Consumers using the alias get the current version without changing their import path on a MINOR/PATCH update.

**Note:** Alias files are advisory. The canonical import remains the versioned file.

### Maintenance branches

Old MAJOR versions that require bug fixes are maintained on branches named `maint/v<MAJOR>` (e.g., `maint/v1`). The `main` branch always tracks the current active version.

---

## Area 3: Client Library Distribution

### Node.js (npm git-source install)

The Node.js client is distributed via npm git-source install from a tagged commit:

```json
"global-directory-node-client": "git+https://github.com/your-org/global-directory.git#v1.0.0"
```

Tags follow `v<MAJOR>.<MINOR>.<PATCH>` (e.g., `v1.0.0`, `v1.1.0`, `v2.0.0`).

The `node_client/package.json` must include a `prepare` script so that `tsc` runs automatically on `npm install` from git source:

```json
"scripts": {
  "build": "tsc",
  "prepare": "npm run build"
}
```

Without `prepare`, a git-source consumer receives only TypeScript source files — not the compiled `dist/` output.

### Shell and Terraform

Shell scripts and Terraform modules are sourced by path or git URL. Versioning is tracked by git tag; consumers reference the tag in their checkout or submodule configuration.

---

## Area 4: Object Storage Paths

### Target convention

```
<domain>/<MAJOR>/<domain>-<MAJOR>.<MINOR>.json
<domain>/<MAJOR>/<domain>-latest.json
```

**Examples:**

```
regions/2/regions-2.0.json        ← MAJOR=2, MINOR=0
regions/2/regions-2.1.json        ← MAJOR=2, MINOR=1 (after adding new region)
regions/2/regions-latest.json     ← copy/alias of current latest MINOR
tenancies/1/tenancies-1.0.json
tenancies/1/tenancies-latest.json
```

**Rules:**

- No `v` prefix in numeric path components — aligns with semver (`2`, `2.0`, not `v2`, `v2.0`)
- MAJOR appears in the directory segment
- MINOR appears in the filename
- PATCH: applied in-place on the same object; tracked by Object Storage native object versioning, not in the path
- `-latest.json` is always updated to point to the most recent MINOR within the current MAJOR

### Current state

Existing paths (`regions/v1`, `regions/v2`) use the legacy `v`-prefixed convention from before this strategy was established. These paths will be replaced when `tf_manager` upload logic is updated (GD-3 scope). No migration period is needed — the project is in early phase with no locked production consumers.

---

## Version history

| Domain | Version | Notes |
| ------ | ------- | ----- |
| `regions` | `v1` → `1.0.0` | Legacy path `regions/v1`; combined physical + tenancy data |
| `regions` | `v2` → `2.0.0` | Physical region data only; tenancy data moved to `tenancies/v1` |
| `tenancies` | `v1` → `1.0.0` | New domain; tenancy + per-region subscription data |
| `realms` | `v1` → `1.0.0` | Realm attributes; unchanged from inception |
