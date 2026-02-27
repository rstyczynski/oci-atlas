# Sprint 3 - Contract Review 1

## Summary

Contracting review for Sprint 3. All foundation documents read: BACKLOG.md, PLAN.md, AGENTS.md, rules/generic (GENERAL_RULES.md, GIT_RULES.md, PRODUCT_OWNER_GUIDE.md). No technology-specific rules apply (no GitHub Actions, no Ansible; project uses JSON Schema, Node.js/TypeScript, Bash, Terraform — no dedicated rules files exist for these in the rules directory).

Prior Sprint context reviewed: Sprint 1 (GD-1, done), Sprint 2 (GD-1-fix1, rejected). Sprint 1 delivered `regions/v2`, `tenancies/v1` schemas and example data files. Sprint 2 rolled back cleanly.

## Understanding Confirmed

- **Project scope**: Centralized OCI metadata catalog with JSON data in OCI Object Storage, typed clients (Node.js, Bash, Terraform). Understood.
- **Implementation plan**: Sprint 3 active (`Status: Progress`, `Mode: managed`). Single backlog item: GD-2 — Establish versioning strategy for data and access layer.
- **General rules**: Implementor implements only what is in the active Sprint. Proposals go to `proposedchanges.md`, questions to `openquestions.md`. Design must be approved before construction starts. `PLAN.md` and `BACKLOG.md` are read-only for agents.
- **Git rules**: Semantic commit format `type: (sprint-N) description` — parenthetical sprint prefix AFTER the colon, not before. Push after every commit.
- **Product Owner guide**: Managed mode — wait for design approval, stop for unclear requirements, confirm before major decisions.

## Responsibilities Enumerated

**Allowed to edit:**

- `progress/sprint_3/` documents (analysis, design, implementation, tests, documentation)
- `PROGRESS_BOARD.md` — update at phase transitions
- `PLAN.md` — update Status from `Progress` to `Done` or `Failed` when construction completes

**Must never modify:**

- `PLAN.md` (except status token as allowed above)
- `BACKLOG.md`
- Status tokens in phase documents (owned by Product Owner)
- Documents from prior sprints

**Communication:**

- Proposals → `sprint_3_proposedchanges.md`
- Questions → `sprint_3_openquestions.md`
- Design: set Status to `Proposed`, wait for PO to change to `Accepted`

## Constraints

- Construction must not start until design Status = `Accepted`
- Test sequences must be copy-paste-able, no `exit` commands
- Keep implementation as simple as possible — no over-engineering

## Sprint 3 Scope Understood

GD-2 is an analysis/strategy backlog item. Its deliverable is a **versioning strategy decision document** covering:

1. Data objects — semantic versioning, `schema_version` field in JSON data objects
2. DAL — whether version belongs in filenames, aggregation DAL for multi-domain access
3. Client library distribution — npm git source install as the distribution mechanism
4. Object Storage path structure — MAJOR/MINOR/PATCH directory/file convention

The GD-2 backlog item explicitly lists "Areas for analysis" not "Areas for implementation", which means the sprint product is a strategy + possibly lightweight proof-of-concept artefacts (e.g., adding a `schema_version` field to existing schemas). The exact construction scope depends on what the design proposes and the PO accepts.

## Open Questions

None — GD-2 is sufficiently described for analysis and design to begin. Scope of construction artefacts will be resolved in the design phase.

## Status

Contracting phase complete — ready for Inception.

## Artifacts Created

- `progress/sprint_3/sprint_3_contract_review_1.md`

## Next Phase

Inception Phase
