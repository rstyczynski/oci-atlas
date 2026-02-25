# Sprint 1 - Elaboration

## Design Overview

Two new JSON Schema files (draft 2020-12) modelling the v2 data layer:

- `tf_manager/regions_v2.schema.json` — physical region attributes only (`key`, `realm`, `network.public`)
- `tf_manager/tenancies_v1.schema.json` — tenancy realm membership + per-region subscription sub-map (`network.private`, `network.proxy`, `security.vault`, `toolchain.github`, `observability`)

`realms/v1` unchanged. No data files, no provisioning, no DAL in scope.

## Key Design Decisions

- All tenancy-specific attributes (proxy, vault, toolchain, observability including prometheus) moved to `tenancies/v1`
- `regions/v2` contains only physical public CIDRs
- Tenancy keyed by short name; region sub-map keyed by OCI region identifier (`eu-zurich-1` format)
- `propertyNames` pattern enforces region key format; cross-file referential integrity is a data governance convention
- `cidr_entry` `$defs` pattern reused from `regions_v1`

## Feasibility Confirmation

All requirements feasible — JSON Schema authoring only, no external dependencies.

## Design Iterations

One revision: added `propertyNames` pattern and DAL implications note following Product Owner feedback on cross-document association and DAL architecture.

## Open Questions Resolved

All four open questions answered during Inception and Elaboration. GD-2 proposed for future DAL sprint.

## Artifacts Created

- `progress/sprint_1/sprint_1_design.md`
- `progress/sprint_1/sprint_1_proposedchanges.md`

## Status

Design Accepted - Ready for Construction

## LLM Tokens consumed

Phase: Elaboration
Model: claude-sonnet-4-6
Estimated tokens this phase: ~6,000 (schema design + two revision cycles)

## Next Steps

Proceed to Construction phase — create schema files in `tf_manager/`
