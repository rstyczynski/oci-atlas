# Sprint 3 - Implementation

Status: Complete

## GD-2. Establish versioning strategy for data and access layer

### Deliverable

**`VERSIONING.md`** — project-root versioning strategy document.

The construction phase produces a single artefact: `VERSIONING.md` at the repository root. This document is the authoritative reference for how semver applies across the project.

### Scope adjustment from design

The approved design listed concrete implementation artefacts including `schema_version` field additions to schema and data files, and a `prepare` script in `node_client/package.json`. These changes are **deferred to a downstream sprint** alongside the actual versioning workflow. The construction deliverable for GD-2 is the strategy document that governs those future changes.

### Files created

| File | Description |
| ---- | ----------- |
| `VERSIONING.md` | Project-root versioning strategy document covering all four areas |

### Content summary

`VERSIONING.md` documents:

1. **Semver semantics** — MAJOR/MINOR/PATCH definitions with data-specific examples
2. **Data objects** — `schema_version` field format, placement, purpose, and current version table
3. **Data Access Layer** — `_v<MAJOR>` filename convention, version-neutral alias pattern, maintenance branch naming
4. **Client library distribution** — npm git-source install, git tag convention, `prepare` script requirement
5. **Object Storage paths** — target convention `<domain>/<MAJOR>/<domain>-<MAJOR>.<MINOR>.json`, no `v` prefix, `-latest.json` alias, PATCH in-place rule

### Design fidelity

All four areas from the approved design (`sprint_3_design.md`) are represented in `VERSIONING.md`. No design decisions were changed during implementation.
