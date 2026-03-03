# Sprint 6 - Analysis

Status: Complete

## Sprint Overview

Sprint 6 delivers backlog item `GD-6. Synthetic data sets review`. The goal is twofold:

1. **Data rationalization**: review and clean up the synthetic demo JSON files
   (`tenancies_v1.json`, `realms_v1.json`, `regions_v2.json`) to produce a coherent,
   portable demo dataset that does not leak real tenancy identifiers.
2. **Demo mode mapping procedure**: create exemplary code (CLI script) that discovers
   the current OCI tenancy key, maps it onto one of the synthetic tenants in the demo
   dataset, and shows the resulting view limited to a configurable number of subscribed
   regions (default 4). This mapping is strictly demo-mode and does not alter stored data.

## Backlog Items Analysis

### GD-6. Synthetic data sets review

**Requirement Summary:**

- Review `tenancies_v1.json`, `realms_v1.json`, and `regions_v2.json` for correctness and
  usefulness as demo data.
- Remove or replace the hardcoded `avq3` real tenancy key from `tenancies_v1.json`.
- Produce a mapping procedure (CLI exemplary code, optionally also Node.js) that:
  - Discovers the active OCI tenancy key at runtime (Sprint 5 mechanism).
  - Takes one synthetic tenant from the dataset as the "demo template".
  - Retrieves the list of subscribed regions for the discovered tenancy and limits to N
    regions (default 4).
  - Returns a merged view where the synthetic template's regions are intersected/overlaid
    with the real subscription list — demo mode only.
- Demo mode must be explicitly activated (env var `GDIR_DEMO_MODE=true` or similar flag);
  real mode always requires proper data from the data owner.

**Issues Found in Current Data:**

The following inconsistencies were identified during analysis:

*tenancies_v1.json:*

- `avq3` is a real tenancy key from the developer's active OCI connection. It must be
  replaced with a purely synthetic tenant (e.g., `demo_corp`) to make the dataset portable
  and avoid leaking real identity in demo data.
- `acme_prod` references realm `oc19` (EU Sovereign Cloud). However three of its four
  regions (`af-region-1`, `eu-region-1`, `eu-region-3`) are mapped to realm `oc1` in
  `regions_v2.json` — a realm-consistency mismatch. Only `eu-zurich-1` is in `oc1`.
  `eu-region-1` and `eu-region-3` use `oc1` realm in `regions_v2.json`, but `acme_prod`
  claims `oc19`. `af-region-1` also uses realm `oc1` in `regions_v2.json`.

*realms_v1.json:*

- Defines `oc1`, `oc19`, and `tst01` realms.
- `tst02` realm is referenced in `regions_v2.json` by `tst-region-3` through
  `tst-region-6` but is **missing** from `realms_v1.json`. This is a referential integrity
  gap.

*regions_v2.json:*

- `tst-region-3` through `tst-region-6` reference `realm: "tst02"` which does not exist in
  `realms_v1.json`.
- `eu-zurich-1` is a real OCI region with accurate public CIDR blocks — this is fine for
  demo purposes as region metadata is public information.

**Technical Approach:**

*Step 1 — Rationalize JSON data files:*

- Remove `avq3` from `tenancies_v1.json`. Add a new synthetic tenant `demo_corp` that
  mirrors the structure of `avq3` (one region, realm `oc1`, `eu-zurich-1`) but with
  clearly fictional names and values.
- Fix realm consistency for `acme_prod`: align its regions to realm `oc19` regions only
  (i.e., regions that have `realm: "oc19"` in `regions_v2.json`). Currently `af-region-2`
  and `eu-region-2` use `oc19` in `regions_v2.json` — these are the correct candidates for
  `acme_prod`.
- Add `tst02` realm to `realms_v1.json` to fix the referential integrity gap.

*Step 2 — Create demo mapping CLI script:*

- New file: `cli_client/examples/demo_mapping.sh`
- Logic:
  1. Check `GDIR_DEMO_MODE=true` (fail if not set — demo must be explicit).
  2. Discover real tenancy key via Sprint 5 mechanism (`_gdir_v1_tenancies_resolved_key`).
  3. Select a synthetic "template" tenant from the dataset (default `acme_prod`, or set via
     `GDIR_DEMO_TENANT`).
  4. Get subscribed regions for real tenancy from OCI:
     `oci iam region-subscription list --tenancy-id <ocid> --query 'data[*]."region-name"'`
  5. Intersect with template tenant's region list; take first `GDIR_DEMO_MAX_REGIONS`
     (default 4).
  6. Output a JSON snippet showing the mapping: real tenancy key → template tenant data
     with overlaid region list.
- No stored data is modified; output is ephemeral.

*Step 3 — Node.js equivalent (optional, scope TBD by PO):*

- If confirmed, add `demoMapping()` utility in `node_client/src/` that encapsulates the
  same logic and expose an example script in `node_client/examples/demo_mapping.ts`.

**Dependencies:**

- Sprint 5: tenancy key auto-discovery already implemented in CLI and Node.js DALs.
- OCI CLI available with `iam` and `os` permissions for the active connection.
- `jq` for JSON processing in the CLI script.

**Testing Strategy:**

- Validate rationalized JSON files against their schemas using `validate.sh` in `tf_manager/`.
- CLI demo mapping script: test with `GDIR_DEMO_MODE=true` and real OCI connection.
- Negative tests: missing `GDIR_DEMO_MODE` should print clear error; OCI unavailable should
  print clear error.
- Node.js tests (if in scope): Jest tests with mocked OCI calls.

**Risks/Concerns:**

- Region subscription list from OCI may return regions not present in `regions_v2.json`
  (e.g., real OCI regions vs. synthetic keys) — intersection may be empty. Mitigation: if
  intersection is empty, fall back to template tenant's own region list up to the limit.
- Schema validation: changes to JSON data files must pass schema validation.
- `avq3` removal impacts Sprint 5 test data — `avq3` was added to `tenancies_v1.json` in
  Sprint 5 specifically for the tenancy key discovery test. Removing it may break existing
  tests that check for `avq3`. Mitigation: replace `avq3` with `demo_corp` and update
  tests accordingly.

**Compatibility Notes:**

- Removing `avq3` is a data-layer change. Any test or example relying on `avq3` as a fixed
  key must be updated to use `demo_corp` (or the dynamically discovered key).
- Clients (Node, CLI, Terraform) do not change their DAL interfaces; only the underlying
  JSON data and one new example script change.

## Overall Sprint Assessment

**Feasibility:** High — primarily JSON data cleanup plus a new shell example; leverages
existing Sprint 5 discovery infrastructure.

**Estimated Complexity:** Simple to Moderate — data rationalization is straightforward; demo
mapping script requires careful handling of the real/synthetic boundary.

**Prerequisites Met:** Yes — Sprint 5 tenancy key auto-discovery is in place.

**Open Questions:**

1. Should `demo_corp` be added as the replacement synthetic tenant for `avq3`, or is a
   different name / structure preferred?
2. Should the demo mapping also be implemented in Node.js (in addition to the CLI example),
   or is CLI-only sufficient for Sprint 6?
3. Should the `avq3` data entry be completely removed, or renamed to a synthetic key to
   preserve the data structure (network, security, toolchain, observability fields)?
4. For region intersection: if the active OCI connection's subscribed regions don't overlap
   with the synthetic template's region keys, should the script fall back to the template's
   own regions (up to the limit), or fail with an informative message?

## Recommended Design Focus Areas

- Define the exact JSON structure changes needed and ensure schema compliance after edits.
- Specify the demo mapping script interface (env vars, output format) clearly before
  implementation.
- Decide on Node.js scope to keep the sprint focused.

## Readiness for Design Phase

Awaiting Product Owner clarification on the four open questions above before proceeding to
Elaboration. Core approach is clear; open questions refine scope and edge case handling.
