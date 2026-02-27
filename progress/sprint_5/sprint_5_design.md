# Sprint 5 - Design

## GD-4. Tenancy name is auto-discovered

Status: Accepted

### Requirement Summary

Make tenancy name optional in all clients that consume `tenancies/v1` and automatically discover it from OCI when omitted, using the known tenancy OCID and the existing discovery/auth context. The feature must be implemented consistently across:

- Node.js DAL `gdir_tenancies_v1`
- Shell/CLI helpers in `cli_client/gdir_tenancies_v1.sh`
- Terraform module `tf_client/gdir_tenancies_v1` and its `examples/tenancy` stack

Existing behavior where tenancy name is passed explicitly must remain supported.

### Feasibility Analysis

**API Availability:**

- CLI: `oci iam tenancy get --tenancy-id <ocid>` returns a JSON payload with `.data.name` for the tenancy; this can be called by shell scripts under the same auth used today for Object Storage lookups.
- Node: the official OCI Node SDK exposes IAM clients that can perform the equivalent of `GetTenancy`, returning a structure with `name`; this can be wired through the existing `gdir` core config which already has SDK access.
- Terraform: the OCI provider provides a `oci_identity_tenancy` (or equivalent identity data source) that exposes the tenancy name given a tenancy OCID.

**Technical Constraints:**

- Sprint 5 should not change the data model in `tenancies_v1` JSON; only client-side discovery and configuration are in scope.
- Discovery must **hard-fail with a clear error** when auto-discovery is selected and the underlying OCI call fails, rather than silently falling back to an empty or incorrect name.
- Explicit tenancy name remains a first-class option; discovery should only be used when the user chooses not to provide a name.

**Risk Assessment:**

- Low–Medium: relies on OCI IAM read permissions. In environments without `GetTenancy` permission, discovery will fail fast; users can still provide explicit tenancy name.
- Low: changes are additive to public surfaces (new optional behavior) and do not break existing explicit-name flows.

### Design Overview

The design introduces a **shared pattern** across clients:

1. **Configuration surface:**
   - Tenancy key (logical ID in `tenancies_v1`) remains required for network/security/toolchain/observability lookups.
   - Tenancy *name* becomes optional and, when omitted, is resolved via IAM.
2. **Internal helper per technology:**
   - Shell: `_gdir_v1_tenancies_resolve_tenancy_name` in `cli_client/gdir_tenancies_v1.sh`.
   - Node: `resolveTenancyName()` method on `gdir_tenancies_v1`.
   - Terraform: local `tenancy_name` derived from an `oci_identity_tenancy` (or similar) data source.
3. **Error handling:**
   - If discovery is active and IAM call fails (no permission, network, etc.) → throw/exit with a clear message describing that tenancy-name discovery via IAM failed and suggesting explicit name as a fallback.
4. **Examples and docs:**
   - Update tenancy examples (CLI, Node, Terraform) to show both explicit and auto-discovered tenancy name usage.
   - Update README to describe prerequisites (OCI IAM `GetTenancy` permission) and the new behavior.

### Technical Specification

#### Shell / CLI (`cli_client/gdir_tenancies_v1.sh`)

**APIs Used:**

- `oci iam tenancy get --tenancy-id "$TENANCY_OCID"` (assuming `TENANCY_OCID` is available from existing environment/connection).
- `jq -r '.data.name'` to extract the tenancy name.

**New helper:**

```bash
_gdir_v1_tenancies_resolve_tenancy_name() {
  if [[ -n "${TENANCY_NAME:-}" ]]; then
    echo "$TENANCY_NAME"
    return 0
  fi

  if [[ -z "${TENANCY_OCID:-}" ]]; then
    echo "TENANCY_OCID must be set when TENANCY_NAME is not provided for auto-discovery" >&2
    exit 1
  fi

  local name
  if ! name="$(oci iam tenancy get --tenancy-id "$TENANCY_OCID" 2>/dev/null | jq -r '.data.name' || true)"; then
    echo "Failed to discover tenancy name via 'oci iam tenancy get' (IAM/permission issue?)" >&2
    exit 1
  fi

  if [[ -z "$name" || "$name" == "null" ]]; then
    echo "Tenancy name not returned from 'oci iam tenancy get' — cannot auto-discover" >&2
    exit 1
  fi

  echo "$name"
}
```

**Integration points:**

- Keep `TENANCY_KEY` semantics unchanged for addressing `tenancies_v1` map.
- Wherever examples/tests currently assume a tenancy name, add an example that:
  - Leaves `TENANCY_NAME` unset.
  - Sets `TENANCY_OCID`.
  - Calls a wrapper script that prints both tenancy key and discovered name.

**Error Handling:**

- On any failure of `oci iam tenancy get` or missing `TENANCY_OCID`, exit 1 with a clear diagnostic message (hard fail).

#### Node.js (`node_client/src/gdir_tenancies_v1.ts`)

**APIs Used:**

- OCI Node SDK IAM client equivalent of `GetTenancy(tenancyId)` to obtain `.name` (exact import/type will be wired during implementation).

**New configuration:**

- Extend `gdir_tenancies_config` with an optional `tenancyOcid?: string` and (optionally) `tenancyName?: string`:

```ts
export interface gdir_tenancies_config extends gdir_config {
  tenancyKey?: string;
  tenancyName?: string;
  tenancyOcid?: string;
}
```

**Class changes:**

- Add private fields:

```ts
private tenancyName?: string;
private tenancyOcid?: string;
private cachedTenancyName?: string;
```

- In constructor, wire from config/env:

```ts
this.tenancyName = config.tenancyName ?? process.env.TENANCY_NAME;
this.tenancyOcid = config.tenancyOcid ?? process.env.TENANCY_OCID;
```

**New helper method:**

```ts
private async resolveTenancyName(): Promise<string> {
  if (this.tenancyName) return this.tenancyName;
  if (this.cachedTenancyName) return this.cachedTenancyName;

  const tenancyOcid = this.tenancyOcid ?? process.env.TENANCY_OCID;
  if (!tenancyOcid) {
    throw new Error("TENANCY_OCID must be set when tenancyName is not provided for auto-discovery");
  }

  const name = await this.fetchTenancyNameFromIam(tenancyOcid);
  if (!name) {
    throw new Error("Failed to discover tenancy name via OCI IAM GetTenancy; no name returned");
  }

  this.cachedTenancyName = name;
  return name;
}
```

**IAM call wrapper:**

- Implement `private async fetchTenancyNameFromIam(tenancyOcid: string): Promise<string | undefined>` using the OCI Node SDK IAM client configured similarly to existing `gdir` SDK usage (details validated during implementation).
- On any SDK error, propagate a descriptive `Error` mentioning that IAM access failed and that callers can supply `tenancyName` explicitly instead.

**Usage in public API:**

- Existing methods (`getTenancy`, `getTenancyRealm`, etc.) **do not change signature**.
- Expose a new method `getTenancyName(): Promise<string>` that calls `resolveTenancyName()` and returns the discovered or explicit tenancy name; examples/tests can then assert its behavior.

#### Terraform (`tf_client/gdir_tenancies_v1`)

**APIs Used:**

- OCI Terraform provider data source (conceptual):

```hcl
data "oci_identity_tenancy" "this" {
  tenancy_id = var.tenancy_ocid
}
```

**Module changes (conceptual):**

- Add a new input variable `tenancy_ocid` (optional) and optional `tenancy_name`:
  - If `var.tenancy_name` is set, use it directly.
  - Else if `var.tenancy_ocid` is set, use `data.oci_identity_tenancy.this.name`.
  - Else, module consumers must provide tenancy name explicitly (no silent discovery without OCID).

**Locals:**

```hcl
locals {
  tenancy_name_explicit = var.tenancy_name
  tenancy_name_discovered = try(data.oci_identity_tenancy.this.name, null)
  tenancy_name = coalesce(local.tenancy_name_explicit, local.tenancy_name_discovered)
}
```

**Error handling:**

- If `local.tenancy_name` is null when the user expected discovery (for example `var.tenancy_ocid` set but IAM restricted), emit a clear error using `validation` blocks on variables or by documenting that Terraform plan/apply will fail with the provider error and that users should either grant IAM permission or set `tenancy_name` explicitly.

**Outputs / examples:**

- Extend `tf_client/examples/tenancy`:
  - Existing example: uses explicit `tenancy_name`.
  - New example: uses `tenancy_ocid` and shows the discovered `tenancy_name` in outputs.

### Testing Strategy

**CLI:**

- Add tests that:
  - Run existing flows with `TENANCY_NAME` set (regression).
  - Run flows with `TENANCY_NAME` unset and `TENANCY_OCID` set, asserting a non-empty tenancy name is printed.
  - Verify that missing `TENANCY_OCID` in discovery mode leads to a clear failure message.

**Node.js:**

- Extend Jest tests to:
  - Verify `getTenancyName()` returns the provided `tenancyName` when set.
  - Verify `getTenancyName()` calls IAM to resolve name when `tenancyName` is omitted (stub/mock IAM client).
  - Verify errors thrown when `TENANCY_OCID` is missing or IAM lookup fails.

**Terraform:**

- Validate both examples:
  - `terraform -chdir=tf_client/examples/tenancy validate` with explicit name.
  - Repeat with discovery example once the new input variables are defined (subject to live IAM permissions).

### Documentation Requirements

- README:
  - Describe tenancy name auto-discovery, including:
    - Required IAM permission (`oci iam tenancy get`).
    - Environment variables/config knobs: `TENANCY_NAME`, `TENANCY_OCID`, module variables, and Node constructor config.
    - Behavior on failures (hard fail with clear message).
- Examples:
  - Update CLI, Node, and Terraform tenancy examples to include:
    - A “classic” explicit tenancy-name example.
    - An auto-discovery example using tenancy OCID only.

### Design Decisions

**Decision 1:** Use `oci iam tenancy get` and `data.name` (and equivalent in SDK/provider) as the authoritative tenancy name source.  
**Rationale:** Simple, stable IAM API; directly exposes the display name we need.

**Decision 2:** Hard-fail on discovery errors instead of silently falling back.  
**Rationale:** Prevents confusing behavior and makes IAM permission issues obvious; callers can always pass `tenancyName` explicitly.

**Decision 3:** Keep existing explicit-name flows fully supported and additive-only changes to public APIs.  
**Rationale:** Avoid breaking current consumers; feature is a convenience extension, not a breaking change.

### Open Design Questions

None — all required API choices and error-handling behaviors are defined. Design is ready for Product Owner review.

