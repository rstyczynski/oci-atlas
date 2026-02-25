# Sprint 1 - Functional Tests

## Test Environment Setup

### Prerequisites

- `jq` installed (`jq --version`)
- `npx` available (Node.js 18+)
- Working directory: `tf_manager/`

```bash
cd /path/to/global-directory/tf_manager
```

## GD-1. Build foundation data model

### Test 1: regions_v2 schema is valid JSON

**Purpose:** Confirm the schema file is well-formed JSON.

**Expected Outcome:** `jq` exits 0, no error output.

**Test Sequence:**

```bash
jq . regions_v2.schema.json > /dev/null && echo "PASS: valid JSON"
```

Expected output:

```text
PASS: valid JSON
```

**Status:** PASS

---

### Test 2: tenancies_v1 schema is valid JSON

**Purpose:** Confirm the schema file is well-formed JSON.

**Expected Outcome:** `jq` exits 0, no error output.

**Test Sequence:**

```bash
jq . tenancies_v1.schema.json > /dev/null && echo "PASS: valid JSON"
```

Expected output:

```text
PASS: valid JSON
```

**Status:** PASS

---

### Test 3: regions_v2 compiles as valid JSON Schema (draft 2020-12)

**Purpose:** Confirm the schema is structurally valid per the JSON Schema specification.

**Expected Outcome:** `ajv compile` exits 0 with "schema ... is valid".

**Test Sequence:**

```bash
npx ajv-cli@5 compile --spec=draft2020 -s regions_v2.schema.json
```

Expected output:

```text
schema regions_v2.schema.json is valid
```

**Status:** PASS

---

### Test 4: tenancies_v1 compiles as valid JSON Schema (draft 2020-12)

**Purpose:** Confirm the schema is structurally valid per the JSON Schema specification.

**Expected Outcome:** `ajv compile` exits 0 with "schema ... is valid".

**Test Sequence:**

```bash
npx ajv-cli@5 compile --spec=draft2020 -s tenancies_v1.schema.json
```

Expected output:

```text
schema tenancies_v1.schema.json is valid
```

**Status:** PASS

---

### Test 5: regions_v2 rejects entry missing required field

**Purpose:** Confirm `required` constraint catches missing `key` property.

**Expected Outcome:** Validation exits 1 with error citing missing `key` property.

**Test Sequence:**

```bash
echo '{"eu-zurich-1": {"realm": "oc1", "network": {"public": []}}}' \
  > /tmp/t_missing_key.json
npx ajv-cli@5 validate --spec=draft2020 \
  -s regions_v2.schema.json -d /tmp/t_missing_key.json
echo "exit code: $?"
rm /tmp/t_missing_key.json
```

Expected output:

```text
/tmp/t_missing_key.json invalid
[{ message: "must have required property 'key'", ... }]
exit code: 1
```

**Status:** PASS

---

### Test 6: regions_v2 rejects entry with forbidden additional property

**Purpose:** Confirm `additionalProperties: false` blocks extra fields.

**Expected Outcome:** Validation exits 1 citing `additionalProperties`.

**Test Sequence:**

```bash
echo '{"eu-zurich-1": {"key":"ZRH","realm":"oc1","network":{"public":[]},"proxy":"http://x"}}' \
  > /tmp/t_extra_field.json
npx ajv-cli@5 validate --spec=draft2020 \
  -s regions_v2.schema.json -d /tmp/t_extra_field.json
echo "exit code: $?"
rm /tmp/t_extra_field.json
```

Expected output:

```text
/tmp/t_extra_field.json invalid
[{ message: "must NOT have additional properties", ... }]
exit code: 1
```

**Status:** PASS

---

### Test 7: tenancies_v1 rejects short region key format

**Purpose:** Confirm `propertyNames` pattern blocks `ZRH`-style keys (must be `eu-zurich-1` style).

**Expected Outcome:** Validation exits 1 citing `propertyNames` pattern mismatch.

**Test Sequence:**

```bash
cat > /tmp/t_bad_region_key.json << 'ENDJSON'
{"acme_prod": {"realm": "oc1", "regions": {"ZRH": {
  "network": {"private": [], "proxy": {"url":"","ip":"","port":"","noproxy":[]}},
  "security": {"vault": {"ocid":"","crypto_endpoint":"","management_endpoint":""}},
  "toolchain": {"github": {"runner": {"labels": ["x"], "image": "y"}}},
  "observability": {"prometheus_scraping_cidr":"","loki_destination_cidr":"","loki_fqdn":""}
}}}}
ENDJSON
npx ajv-cli@5 validate --spec=draft2020 \
  -s tenancies_v1.schema.json -d /tmp/t_bad_region_key.json
echo "exit code: $?"
rm /tmp/t_bad_region_key.json
```

Expected output:

```text
/tmp/t_bad_region_key.json invalid
[{ message: "must match pattern ...", propertyName: "ZRH", ... }]
exit code: 1
```

**Status:** PASS

---

### Test 8: valid regions_v2 document is accepted

**Purpose:** Confirm a correctly structured document passes validation.

**Expected Outcome:** Validation exits 0.

**Test Sequence:**

```bash
cat > /tmp/t_valid_regions.json << 'ENDJSON'
{
  "last_updated_timestamp": "2026-02-25T12:00:00Z",
  "eu-zurich-1": {
    "key": "ZRH",
    "realm": "oc1",
    "network": {
      "public": [
        { "cidr": "130.61.0.0/16", "description": "OCI ZRH public", "tags": ["oci"] }
      ]
    }
  }
}
ENDJSON
npx ajv-cli@5 validate --spec=draft2020 \
  -s regions_v2.schema.json -d /tmp/t_valid_regions.json
echo "exit code: $?"
rm /tmp/t_valid_regions.json
```

Expected output:

```text
/tmp/t_valid_regions.json valid
exit code: 0
```

**Status:** PASS

---

### Test 9: valid tenancies_v1 document is accepted

**Purpose:** Confirm a correctly structured tenancy document passes validation.

**Expected Outcome:** Validation exits 0.

**Test Sequence:**

```bash
cat > /tmp/t_valid_tenancies.json << 'ENDJSON'
{
  "last_updated_timestamp": "2026-02-25T12:00:00Z",
  "acme_prod": {
    "realm": "oc1",
    "regions": {
      "eu-zurich-1": {
        "network": {
          "private": [
            { "cidr": "10.0.0.0/8", "description": "private", "tags": ["internal"] }
          ],
          "proxy": {
            "url": "http://proxy.acme.example.com:8080",
            "ip": "10.1.2.3",
            "port": "8080",
            "noproxy": ["localhost", "169.254.0.0/16"]
          }
        },
        "security": {
          "vault": {
            "ocid": "ocid1.vault.oc1.eu-zurich-1.example",
            "crypto_endpoint": "https://crypto.vault.example.com",
            "management_endpoint": "https://mgmt.vault.example.com"
          }
        },
        "toolchain": {
          "github": {
            "runner": {
              "labels": ["self-hosted", "zrh"],
              "image": "oracle-linux-8"
            }
          }
        },
        "observability": {
          "prometheus_scraping_cidr": "10.2.0.0/24",
          "loki_destination_cidr": "10.3.0.0/24",
          "loki_fqdn": "loki.acme.example.com"
        }
      }
    }
  }
}
ENDJSON
npx ajv-cli@5 validate --spec=draft2020 \
  -s tenancies_v1.schema.json -d /tmp/t_valid_tenancies.json
echo "exit code: $?"
rm /tmp/t_valid_tenancies.json
```

Expected output:

```text
/tmp/t_valid_tenancies.json valid
exit code: 0
```

**Status:** PASS

---

### Test 10: regions_v2.json example data is valid

**Purpose:** Confirm the bundled example data file for regions/v2 passes schema validation.

**Expected Outcome:** Validation exits 0.

**Test Sequence:**

```bash
npx ajv-cli@5 validate --spec=draft2020 \
  -s regions_v2.schema.json -d regions_v2.json
echo "exit code: $?"
```

Expected output:

```text
regions_v2.json valid
exit code: 0
```

**Status:** PASS

---

### Test 11: tenancies_v1.json example data is valid

**Purpose:** Confirm the bundled example data file for tenancies/v1 passes schema validation.

**Expected Outcome:** Validation exits 0.

**Test Sequence:**

```bash
npx ajv-cli@5 validate --spec=draft2020 \
  -s tenancies_v1.schema.json -d tenancies_v1.json
echo "exit code: $?"
```

Expected output:

```text
tenancies_v1.json valid
exit code: 0
```

**Status:** PASS

---

## Test Summary

| Backlog Item | Total Tests | Passed | Failed | Status |
| ------------ | ----------- | ------ | ------ | ------ |
| GD-1         | 11          | 11     | 0      | tested |

## Overall Test Results

**Total Tests:** 11
**Passed:** 11
**Failed:** 0
**Success Rate:** 100%

## Test Execution Notes

- `ajv-cli@5` does not support stdin (`-d -`); temp files required for inline JSON tests
- `propertyNames` with `pattern` correctly enforces OCI region identifier format
- `additionalProperties: false` enforces strict schema structure as intended
- Example data files (`regions_v2.json`, `tenancies_v1.json`) derived from `regions_v1.json` — `acme_prod` tenancy covers 4 oc1 regions; `network.internal` renamed to `network.private` per v2 model
