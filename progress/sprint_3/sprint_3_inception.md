# Sprint 3 - Inception

## What Was Analyzed

GD-2: Establish versioning strategy for data and access layer.

Current state of all four areas assessed against the Sprint 1 artefacts (`regions_v2.json`, `tenancies_v1.json`, `regions_v1.json`, `realms_v1.json`, all `.schema.json` files, `node_client/package.json`, DAL source files).

## Key Findings

- No `schema_version` field exists in any data file or schema — the version is only implicit in the Object Storage path and local filename.
- Object Storage path convention currently uses `v`-prefixed MAJOR only (`regions/v1`, `regions/v2`). Semver uses numeric without prefix (`1.0.0`). These must be reconciled in design.
- The Node.js package has a `build` script but no `prepare` script — git-source install would not auto-compile.
- DAL files embed MAJOR version (`_v1`) but have no version-neutral alias. Whether to add one is an open design question.
- GD-3 ("tf_manager handles upload of latest version") is a downstream dependency of this sprint's Object Storage path decision.

## Confirmation of Readiness

Ready to proceed to Elaboration. Four open questions carried into design for resolution:

1. `schema_version` field format (`"1.0"` / `"1.0.0"` / `"v1"` / integer)
2. `schema_version` field placement (top-level vs per-entry)
3. Object Storage path for MINOR (in path vs in data field only)
4. DAL alias — required deliverable or advisory only

## Reference

Full analysis: `progress/sprint_3/sprint_3_analysis.md`

## Status

Inception phase complete — ready for Elaboration.
