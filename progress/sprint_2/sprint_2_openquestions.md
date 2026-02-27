# Sprint 2 - Feedback / Decisions

## GD-1-fix1 Rejected — realm must remain in tenancies/v1

Status: Rejected

Decision: Product Owner rejected the removal of `realm` from `tenancies/v1` during construction phase. The `realm` field must be kept in the tenancy-level model.

Rationale (PO): "realm must be in tenancy" — the tenancy-level `realm` field carries semantic meaning independent of the subscribed regions. It should not be removed.

Impact:
- `tenancies_v1.schema.json` — no change (restored to Sprint 1 state)
- `tenancies_v1.json` — no change (restored to Sprint 1 state)

Next steps: GD-1-fix1 is closed as Rejected. No further work required for Sprint 2.
