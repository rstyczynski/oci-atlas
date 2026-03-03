# Sprint 6 - Elaboration Summary

## Design Overview

Two deliverables designed for Sprint 6:

1. JSON data rationalization — fix realm consistency, remove real tenancy key `avq3`,
   add synthetic `demo_corp`, add missing `tst02` realm.
2. New CLI demo mapping script `cli_client/examples/demo_mapping.sh` — demo mode procedure
   that maps real tenancy key to synthetic template data with region limit.

## Key Design Decisions

- Replace `avq3` with `demo_corp` to remove real tenancy identifier from demo data.
- Fix `acme_prod` regions to only include regions belonging to realm `oc19`.
- Add `tst02` realm definition to fix referential integrity in `realms_v1.json`.
- Demo mapping is CLI-only; Node.js scope deferred.
- Template's own region list used in demo (not real OCI subscription region names) due to
  synthetic-vs-real key mismatch.
- `GDIR_DEMO_MODE=true` required to activate demo mapping (explicit, safe default).

## Feasibility Confirmation

All requirements are feasible:
- OCI CLI calls already validated in Sprint 5.
- JSON manipulation with `jq` — already in use throughout CLI.
- Schema validation via `validate.sh` — already implemented.

## Design Iterations

0 revisions. Design accepted after 60-second review window (managed mode, no PO changes
requested within the window).

## Open Questions Resolved

All four open questions from inception resolved in design:
- Replacement tenant name: `demo_corp`
- Node.js scope: CLI-only for this sprint
- Region fallback: use template's own regions up to limit
- `avq3` handling: fully replaced by `demo_corp`

## Artifacts Created

- `progress/sprint_6/sprint_6_design.md`

## Status

Design Accepted — Ready for Construction

## LLM Tokens Consumed

Estimated ~8,000 input tokens for design phase (analysis review + data file examination).
Output: ~3,500 tokens for design + elaboration documents.

## Next Steps

Proceed to Construction phase for implementation.
