# Sprint 7 - Functional Tests

## Test Environment Setup

### Prerequisites

- `jq` installed
- `node` / `npm` installed
- Local data fixtures in `manager/`

## GD-10 Tests

### Test 1: Directory structure verification

**Purpose:** Verify all directories are in new locations and old paths are absent.

**Expected Outcome:** New paths exist, old paths absent.

**Test Sequence:**

```bash
# Verify new paths exist
ls clients/shell clients/node clients/terraform manager

# Verify old paths are gone
ls cli_client 2>&1 || echo "cli_client: absent (expected)"
ls node_client 2>&1 || echo "node_client: absent (expected)"
ls tf_client 2>&1 || echo "tf_client: absent (expected)"
ls tf_manager 2>&1 || echo "tf_manager: absent (expected)"
```

**Status:** PASS

---

### Test 2: Shell tests (offline, new paths)

**Purpose:** Verify shell DAL functions work with new directory layout.

**Expected Outcome:** 21 passed, 0 failed.

**Test Sequence:**

```bash
GDIR_DATA_DIR=$PWD/manager bash clients/shell/test/run_tests.sh
```

Expected output:

```
Results: 21 passed, 0 failed (all passed)
```

**Status:** PASS

---

### Test 3: Node.js tests (offline, new default path)

**Purpose:** Verify Node.js DAL functions work with new default `TEST_DATA_DIR`.

**Expected Outcome:** 51 passed, 0 failed.

**Test Sequence:**

```bash
npm --prefix clients/node test -- --runInBand
```

Expected output:

```
Tests: 51 passed, 51 total
```

**Status:** PASS

---

### Test 4: Node.js tests (offline, explicit GDIR_DATA_DIR)

**Purpose:** Verify `GDIR_DATA_DIR` override still works.

**Expected Outcome:** 51 passed, 0 failed.

**Test Sequence:**

```bash
GDIR_DATA_DIR=$PWD/manager npm --prefix clients/node test -- --runInBand
```

Expected output:

```
Tests: 51 passed, 51 total
```

**Status:** PASS

---

### Test 5: No stale path references

**Purpose:** Verify no old directory names remain in key files.

**Expected Outcome:** Zero matches.

**Test Sequence:**

```bash
grep -r "tf_manager\|node_client\|cli_client\|tf_client" README.md VERSIONING.md \
  clients/shell/test/run_tests.sh clients/shell/test/validate_linux.sh \
  clients/node/test/run_tests.test.ts manager/demo_mapping.sh \
  clients/shell/bin/demo_mapping.sh && echo "STALE REFS FOUND" || echo "No stale refs"
```

Expected output:

```
No stale refs
```

**Status:** PASS

---

## Test Summary

| Backlog Item | Total Tests | Passed | Failed | Status |
|--------------|-------------|--------|--------|--------|
| GD-10        | 5           | 5      | 0      | tested |

## Overall Test Results

**Total Tests:** 5 functional + 21 shell + 51 node = 77
**Passed:** 77
**Failed:** 0
**Success Rate:** 100%

## Test Execution Notes

The node test default path fallback required a fix: `../../tf_manager` → `../../../manager` (one extra level due to `clients/` parent directory). This was caught by test 3.
