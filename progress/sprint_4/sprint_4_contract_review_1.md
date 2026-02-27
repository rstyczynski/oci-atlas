# Sprint 4 - Contracting

Status: Complete

## Contracting Note

Contracting was completed in Sprint 3 of this session. All project rules, cooperation protocols, and technology constraints remain unchanged. This file references the Sprint 3 contracting artefact rather than repeating the review.

**Reference:** `progress/sprint_3/sprint_3_contract_review_1.md`

## Sprint 4 Scope Confirmation

- **Sprint:** Sprint 4 — Apply versioning strategy for data and access layer
- **Mode:** managed (explicit approvals required)
- **Backlog Item:** GD-4

**GD-4 summary from BACKLOG.md:**
Apply the versioning strategy documented in `VERSIONING.md` (Sprint 3 product) to the actual project artefacts. Note: get rid of old versions, and start from the latest ones.

## Rules in Effect

All rules from Sprint 3 contracting apply unchanged:
- `AGENTS.md` — status tokens, FSM, PROGRESS_BOARD protocol
- `rules/generic/GENERAL_RULES.md` — general cooperation
- `rules/generic/PRODUCT_OWNER_GUIDE.md` — managed mode workflow
- `rules/generic/GIT_RULES.md` — semantic commits, branch rules
- No technology-specific rule directories apply (JSON/shell/npm work; no GitHub Actions or Ansible)

## Technology Constraints for GD-4

- JSON Schema draft 2020-12 (unchanged)
- `additionalProperties: false` on all schema objects (must add new fields to `properties`)
- `ajv-cli@5` available via `npx` for schema validation
- `jq` available for JSON field extraction
- Node.js / npm available for `node_client/` build

## Open Questions

None — scope is clear. VERSIONING.md provides the authoritative specification.

## Status

Contracting Complete — Ready for Inception
