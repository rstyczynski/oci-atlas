# Sprint 5 - Functional Tests

## Test Environment Setup

### Prerequisites

- OCI CLI configured for active connection (`~/.oci/config` or equivalent auth).
- Bucket contains current `tenancies/v1` object with discovered key present (`avq3` in this run).
- Terraform example initialized in `tf_client/examples/tenancy`.

## GD-5 Tests

### Test 1: CLI vanilla discovery

**Purpose:** Verify CLI resolves `TENANCY_KEY` from active OCI connection when unset.

**Command:**

```bash
cd cli_client
bash examples/tenancy.sh
```

**Expected Outcome:** Non-empty tenancy output with realm/region/network/proxy/vault/toolchain/observability fields.

**Status:** PASS

### Test 2: Terraform vanilla discovery

**Purpose:** Verify Terraform module resolves `tenancy_key` from active OCI connection when `TF_VAR_tenancy_key` is unset.

**Command:**

```bash
cd tf_client/examples/tenancy
terraform apply -auto-approve -input=false
terraform output tenancy_realm
```

**Expected Outcome:** Tenancy outputs returned from discovered key path; `tenancy_realm` matches dataset for discovered key.

**Status:** PASS (`tenancy_realm = "oc1"` in latest run)

### Test 3: Node vanilla discovery

**Purpose:** Verify Node client resolves tenancy key from active OCI connection when `TENANCY_KEY` is unset.

**Command:**

```bash
cd node_client
npm run example:tenancy
```

**Expected Outcome:** Example prints tenancy realm and region-scoped attributes without requiring `TENANCY_KEY`.

**Status:** PASS (`tenancy realm = oc1` in latest run)

## Test Summary

| Backlog Item | Total Tests | Passed | Failed | Status |
|--------------|-------------|--------|--------|--------|
| GD-5         | 3           | 3      | 0      | tested |

## Overall Result

- Total Tests: 3
- Passed: 3
- Failed: 0
- Sprint 5 validation: PASS

