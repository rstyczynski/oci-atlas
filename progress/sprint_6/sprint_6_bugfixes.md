# Sprint 6 — Bug Fixes

## Status: Fixed

Bug fixes GD-6-1 through GD-6-6 were identified post-implementation and resolved in a
follow-up correction cycle. All bugs are now fixed.

---

## GD-6-1 — OCID Unique-ID Segment Too Short

**Root cause:** Synthetic OCIDs used 14-character unique-ID segments; real Oracle OCIDs use
~60 characters.

**Fix:** Replaced all 6 OCID unique-ID segments in `tf_manager/tenancies_v1.json` with
60-character strings (tenancy-name prefix + zero padding):
- `acme_prod`: `acmeprod` + 52 zeros
- `demo_corp`: `democorp` + 52 zeros

**Files:** `tf_manager/tenancies_v1.json`

**Status:** Fixed

---

## GD-6-2 — Private-CIDR Consistency

**Root cause:** `acme_prod` proxy IPs and observability CIDRs fell outside the tenancy's
declared private VCN CIDR blocks.

**Fix:**

| Region | Private block | Old proxy IP | Fixed | Old obs CIDR | Fixed |
|--------|--------------|-------------|-------|-------------|-------|
| `eu-frankfurt-1` | `10.2.0.0/16` | `10.0.1.100` | `10.2.0.100` | `10.0.10.0/24` | `10.2.10.0/24` |
| `eu-amsterdam-1` | `10.3.0.0/16` | `10.0.2.100` | `10.3.0.100` | `10.0.22.0/24` | `10.3.22.0/24` |

`demo_corp / eu-zurich-1` was already consistent — no change.

**Files:** `tf_manager/tenancies_v1.json`

**Status:** Fixed

---

## GD-6-3 — Realm / Region Consistency

**Root cause:** `acme_prod` declared realm `oc19` (OCI EU Sovereign Cloud) but used
synthetic region names (`af-region-2`, `eu-region-2`). Real realms must pair with real
region names.

**Fix:** Changed `acme_prod` to realm `oc1` with real oc1 regions:

| Old key | New key | Old short key | New | Old realm |New |
|---------|---------|--------------|-----|-----------|-----|
| `af-region-2` | `eu-frankfurt-1` | `AF2` | `FRA` | `oc19` | `oc1` |
| `eu-region-2` | `eu-amsterdam-1` | `EU2` | `AMS` | `oc19` | `oc1` |

Updated endpoint hostnames (`.oraclecloud.eu` → `.oraclecloud.com`), noproxy patterns,
vault endpoints, and loki FQDNs to match.

Also updated `cli_client/test/run_tests.sh` region key and realm assertion for `acme_prod`.

**Files:** `tf_manager/regions_v2.json`, `tf_manager/tenancies_v1.json`,
`cli_client/test/run_tests.sh`

**Status:** Fixed

---

## GD-6-4 — demo_mapping.sh Absent from Quick Start; Stale REGION_KEY

**Root cause:** README Quick Start omitted the `demo_mapping.sh` step before
`bash examples/tenancy.sh`; also referenced stale `REGION_KEY=eu-region-1` in Shell and
Node.js examples.

**Fix:**
- Added `GDIR_DEMO_MODE=true bash demo_mapping.sh` call to Shell Quick Start before
  `bash examples/tenancy.sh`
- Fixed stale `eu-region-1` → `eu-frankfurt-1` in Shell and Node.js Quick Start sections

**Files:** `README.md`

**Status:** Fixed

---

## GD-6-5 — demo_mapping.sh: Auto-Discover Realm + Home Region; Move to bin/

**Root cause:** `cli_client/examples/demo_mapping.sh` existed in `examples/` (illustrative
only) but the use case is an operational utility — discovering real tenancy context and
serving transparent synthetic fallback data for callers whose tenancy is not yet onboarded.

**Fix:**
- Moved `cli_client/examples/demo_mapping.sh` → `cli_client/bin/demo_mapping.sh`
- Rewrote the script to work as a transparent substitute for `examples/tenancy.sh`:
  1. Discovers real tenancy key directly via OCI CLI (bypasses catalog validation since
     tenancy may not be onboarded yet)
  2. Discovers real region key via `_gdir_region_key()`
  3. Checks if tenancy is in catalog: serves real data if found, synthetic template if not
  4. Output is identical in format to `examples/tenancy.sh`
- Updated README to reference `bin/demo_mapping.sh`

**Files:** `cli_client/bin/demo_mapping.sh` (new), `cli_client/examples/demo_mapping.sh`
(removed), `README.md`

**Status:** Fixed

---

## GD-6-6 — demo_mapping.sh Must Inject Data into Bucket

**Root cause:** Demo mode mapping only existed at the query layer (`cli_client/bin/`). For
all three clients (Shell, Node.js, Terraform) to see the synthetic data transparently, the
mapping must be injected into the OCI Object Storage bucket.

**Fix:** Introduced a provisioning-side demo mapping flow:

1. **`tf_manager/demo_mapping.sh`** (new): Generates `tenancies_v1.demo.json` with real
   tenancy key and real region key mapped to synthetic template data. Two modes:
   - Demo mode (`GDIR_DEMO_MODE=true`): discovers real tenancy key (via OCI IAM) and real
     region key (from bucket OCID), remaps first template region's data to the real region
     key
   - Normal mode: copies `tenancies_v1.json` → `tenancies_v1.demo.json` unchanged

2. **`tf_manager/tenancies_v1.tf`**: Uses `fileexists()` to prefer
   `tenancies_v1.demo.json` over `tenancies_v1.json` when present

3. **`.gitignore`**: Added `tf_manager/*.demo.json` (non-tracked working copy)

4. **README.md**: Added demo mode provisioning block with correct `GDIR_DEMO_MODE=true`

**Files:** `tf_manager/demo_mapping.sh` (new), `tf_manager/tenancies_v1.tf`,
`.gitignore`, `README.md`

**Status:** Fixed

---

## Additional Bugs Found During GD-6-6 Implementation

### Region Key Mismatch — All Data Returns null

**Root cause:** `tf_manager/demo_mapping.sh` initially wrote the entire template data
(with template region keys `eu-frankfurt-1`, `eu-amsterdam-1`) under the real tenancy
key. But the CLI client auto-discovers region from the bucket OCID (e.g., `eu-zurich-1`)
which didn't exist as a key in the tenancy data → all fields returned `null`.

**Symptom:**
```
=== Tenancy keys ===        avq3         ← correct (real key mapped)
=== Tenancy realm ===       oc1          ← correct
=== Region keys for tenancy ===
eu-amsterdam-1              ← template keys (wrong)
eu-frankfurt-1              ← template keys (wrong)
=== Network (private CIDRs) ===
null                        ← null because eu-zurich-1 not found
```

**Fix:** Added region discovery to `tf_manager/demo_mapping.sh`:
- Discover real region key from bucket OCID (`oci os bucket get --bucket-name gdir_info
  --query 'data.id'` → parse field `[3]`)
- Pick first template region's data
- Write live.json as: `{ real_tenancy_key: { realm, regions: { real_region_key: template_data } } }`

**Status:** Fixed

---

### README Demo Provisioning Used GDIR_DEMO_MODE=false

**Root cause:** The README demo mode provisioning block contained `GDIR_DEMO_MODE=false`
(typo). Users following the Quick Start ran provisioning in normal mode (copying static
data without real tenancy key), so `bash examples/tenancy.sh` auto-discovery then failed
because the real tenancy key was absent from the bucket.

**Fix:** `GDIR_DEMO_MODE=false` → `GDIR_DEMO_MODE=true` in README provisioning block.

**Files:** `README.md`

**Status:** Fixed

---

### tenancies_v1.live.json Renamed to tenancies_v1.demo.json

**Rationale:** `demo.json` better reflects the file's purpose (demo mode working copy).

**Files affected (updated consistently):** `tf_manager/demo_mapping.sh`,
`tf_manager/tenancies_v1.tf`, `.gitignore`, `README.md`

**Status:** Fixed

---

## Fix Summary

| Bug | Description | Files Changed | Status |
|-----|-------------|---------------|--------|
| GD-6-1 | OCID unique-ID length 14 → 60 chars | `tenancies_v1.json` | Fixed |
| GD-6-2 | Proxy IPs / obs CIDRs outside tenancy CIDR | `tenancies_v1.json` | Fixed |
| GD-6-3 | acme_prod: realm oc19 + synthetic regions → oc1 + real regions | `regions_v2.json`, `tenancies_v1.json`, `run_tests.sh` | Fixed |
| GD-6-4 | demo_mapping.sh missing from Quick Start; stale eu-region-1 | `README.md` | Fixed |
| GD-6-5 | demo_mapping.sh → bin/; auto-discover tenancy + region + realm | `cli_client/bin/demo_mapping.sh` | Fixed |
| GD-6-6 | demo_mapping.sh injects into bucket; tenancies_v1.demo.json | `tf_manager/demo_mapping.sh`, `tenancies_v1.tf`, `.gitignore`, `README.md` | Fixed |
| — | Region key mismatch → all data null | `tf_manager/demo_mapping.sh` | Fixed |
| — | README GDIR_DEMO_MODE=false typo | `README.md` | Fixed |
| — | live.json → demo.json rename | `demo_mapping.sh`, `tenancies_v1.tf`, `.gitignore`, `README.md` | Fixed |
