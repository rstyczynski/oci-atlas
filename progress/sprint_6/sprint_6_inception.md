# Sprint 6 - Inception Summary

## What Was Analyzed

Sprint 6 targets `GD-6. Synthetic data sets review`. The analysis covered:

1. Current state of all three JSON data files:
   - `tf_manager/tenancies_v1.json` — two tenants: `acme_prod` (synthetic, `oc19`) and
     `avq3` (real OCI tenancy key, `oc1`, added in Sprint 5)
   - `tf_manager/realms_v1.json` — three realms: `oc1`, `oc19`, `tst01`
   - `tf_manager/regions_v2.json` — ten regions including real `eu-zurich-1` and synthetic
     named regions; six test regions (`tst-region-*`)

2. Sprint 5 implementation: tenancy key auto-discovery fully implemented in CLI, Node.js,
   and Terraform DALs.

3. Existing client implementations in `cli_client/` (Shell/Bash DAL), `node_client/`
   (TypeScript DAL), and `tf_client/` (Terraform module).

## Key Findings

**Data Issues Identified:**

- `avq3` is a real tenancy key hardcoded in `tenancies_v1.json` — makes the demo dataset
  non-portable and leaks real identity.
- Realm inconsistency: `acme_prod` claims realm `oc19` but most of its regions belong to
  realm `oc1` in `regions_v2.json`.
- Missing realm: `tst02` is referenced by four regions in `regions_v2.json` but not defined
  in `realms_v1.json`.

**Required Work:**

- Rationalize JSON data (fix realm consistency, add `tst02` to realms, replace `avq3` with
  synthetic `demo_corp` or similar).
- Create a CLI demo mapping script that:
  - Requires `GDIR_DEMO_MODE=true` to activate
  - Discovers real tenancy key at runtime (Sprint 5)
  - Maps a synthetic template tenant to the real context
  - Limits to N subscribed regions (default 4)

## Open Questions for Product Owner

4 questions identified in the analysis — see
`progress/sprint_6/sprint_6_analysis.md` section "Open Questions".

Key decisions needed:
- Name for replacement synthetic tenant (default: `demo_corp`)
- Node.js scope: CLI-only or also Node.js example
- Fallback behavior when synthetic regions don't overlap with real subscriptions

## Confirmation of Readiness

Awaiting Product Owner answers to open questions. Core analysis is complete; approach is
technically feasible.

## Reference

Full analysis: `progress/sprint_6/sprint_6_analysis.md`

## LLM Tokens Consumed

Input tokens estimated: ~30,000 (reading project data, rules, previous sprint artifacts,
JSON data files). Output: ~3,500 tokens for analysis + inception documents.
