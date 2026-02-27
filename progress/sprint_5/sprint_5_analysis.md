# Sprint 5 - Analysis

Status: Complete

## Sprint Overview

Sprint 5 delivers backlog item `GD-4. Tenancy name is auto-discovered`. The goal is to make the tenancy name optional in the tenancy client and automatically resolve it from OCI APIs using the already known tenancy OCID, mirroring the existing auto-discovery patterns (for example region from bucket OCID). The change must be implemented consistently across all three clients (Shell/CLI, Node.js, Terraform) and reflected in examples and README documentation.

## Backlog Items Analysis

### GD-4. Tenancy name is auto-discovered

**Requirement Summary:**

- Make tenancy name optional in the tenancy Data Access Layer (DAL) and clients.
- When tenancy name is not provided, discover it from OCI API using the known tenancy OCID under the current security context.
- Keep behavior compatible with the existing discovery model used for region and realm where possible.
- Update examples and documentation to show tenancy name auto-discovery and clarify when explicit tenancy name is still allowed.

**Technical Approach:**

- Identify where tenancy name is currently required/passed in each client:
  - Node: tenancy DAL class in `node_client/src/gdir_tenancies_v1.ts` and its example scripts/tests.
  - CLI: tenancy helper functions in `cli_client/gdir_tenancies_v1.sh` and tenancy examples/tests.
  - Terraform: tenancy module `tf_client/gdir_tenancies_v1/` and `tf_client/examples/tenancy`.
- Introduce an internal helper that:
  - Accepts an optional tenancy name and a required tenancy OCID.
  - If name is omitted, calls OCI APIs to fetch tenancy metadata and extracts the tenancy name.
  - Caches or reuses the discovered name within the DAL instance / shell process / Terraform data source, so it is not fetched repeatedly.
- Keep external contracts stable where possible:
  - Existing parameters that accept tenancy name remain supported.
  - New behavior: if parameter is omitted or empty, auto-discovery is triggered.
- Ensure the auto-discovery logic is encapsulated so that changes to APIs or tenancy model are localized in one place per technology.

**Dependencies:**

- Sprint 1: foundational data model (`regions_v2`, `tenancies_v1`, `realms_v1`) and OCI-centric discovery pattern.
- Sprint 3–4: versioned DALs and refactored clients (Node, CLI, Terraform) already consuming `tenancies_v1`.
- OCI authentication and configuration: OCI CLI/SDK credentials (`~/.oci/config`, instance principal, and similar) must be present for live discovery.

**Testing Strategy:**

- Node:
  - Extend or add tests in `node_client` that:
    - Call tenancy DAL with explicit tenancy name (regression).
    - Call tenancy DAL with name omitted; assert that a non-empty name is returned from OCI and used consistently.
  - Run `npm --prefix node_client test -- --runInBand`.
- CLI:
  - Add or update tests in `cli_client/test/run_tests.sh` and examples so that:
    - `TENANCY_KEY` remains supported when explicitly set.
    - When `TENANCY_KEY` is unset but tenancy OCID is known, scripts still resolve and display tenancy name.
- Terraform:
  - Extend `tf_client/examples/tenancy`:
    - One example using explicit tenancy name variable.
    - One example omitting the name so that the data source/module discovers it.
  - Run `terraform init` and `terraform validate` for the tenancy example.
- Cross-cutting:
  - README and example snippets updated to describe optional tenancy name and emphasize prerequisites (OCI config, tenancy OCID availability).

**Risks/Concerns:**

- OCI API shape / permission requirements: the chosen OCI call to fetch tenancy name must be available under the same auth context as existing discovery calls; insufficient permissions could cause failures in environments with restricted IAM policies.
- Performance: repeated OCI metadata calls for tenancy name in tight loops could add latency; mitigated by simple in-process caching.
- Backward compatibility: need to ensure existing paths that always pass tenancy name continue to work unchanged.

**Compatibility Notes:**

- The feature is backward-compatible for existing callers that always supply tenancy name.
- New auto-discovery behavior is additive; failures in discovery should be surfaced clearly while preserving the ability to set tenancy name explicitly.

## Overall Sprint Assessment

**Feasibility:** High — leverages existing OCI connectivity and discovery patterns; primarily DAL and client-layer changes plus tests/docs.

**Estimated Complexity:** Moderate — touches three client stacks (Shell, Node.js, Terraform) and their tests/examples, but each change is localized to tenancy DAL and supporting scripts/modules.

**Prerequisites Met:** Yes — previous sprints established the data domains and versioned DALs; OCI auth/config is assumed available for live tests.

**Open Questions:**

- RESOLVED: Use `oci iam tenancy get` and read `data.name` as the authoritative tenancy name. Node/Terraform implementations should use the provider/SDK equivalent of this call and the same field.

## Recommended Design Focus Areas

- Precisely define the OCI calls and response fields used to discover tenancy name for each technology (`oci iam tenancy get` → `data.name` in CLI, equivalent in Node SDK and Terraform).
- Decide on error-handling strategy when auto-discovery fails (in this sprint: hard fail with a clear error, while still allowing explicit tenancy name as an alternative code path).
- Ensure a consistent configuration surface across clients (environment variables / variables / constructor params) for opting into or out of auto-discovery.

## Readiness for Design Phase

Confirmed Ready — clarification about the OCI API and field has been provided; Elaboration can proceed using `oci iam tenancy get` → `data.name` and hard-fail semantics on discovery errors.

# Sprint 5 - Analysis

Status: Complete

## Sprint Overview

Sprint 5 delivers backlog item `GD-4. Tenancy name is auto-discovered`. The goal is to make the tenancy name optional in the tenancy client and automatically resolve it from OCI APIs using the already known tenancy OCID, mirroring the existing auto-discovery patterns (e.g. region from bucket OCID). The change must be implemented consistently across all three clients (Shell/CLI, Node.js, Terraform) and reflected in examples and README documentation.

## Backlog Items Analysis

### GD-4. Tenancy name is auto-discovered

**Requirement Summary:**

- Make tenancy name optional in the tenancy Data Access Layer (DAL) and clients.
- When tenancy name is not provided, discover it from OCI API using the known tenancy OCID under the current security context.
- Keep behavior compatible with the existing discovery model used for region and realm where possible.
- Update examples and documentation to show tenancy name auto-discovery and clarify when explicit tenancy name is still allowed.

**Technical Approach:**

- Identify where tenancy name is currently required/passed in each client:
  - Node: tenancy DAL class in `node_client/src/gdir_tenancies_v1.ts` and its example scripts/tests.
  - CLI: tenancy helper functions in `cli_client/gdir_tenancies_v1.sh` and tenancy examples/tests.
  - Terraform: tenancy module `tf_client/gdir_tenancies_v1/` and `tf_client/examples/tenancy`.
- Introduce an internal helper that:
  - Accepts an optional tenancy name and a required tenancy OCID.
  - If name is omitted, calls OCI APIs to fetch tenancy metadata (e.g. via `oci iam tenancy get` or equivalent SDK call) and extracts the tenancy name.
  - Caches or reuses the discovered name within the DAL instance / shell process / Terraform data source, so it is not fetched repeatedly.
- Keep external contracts stable where possible:
  - Existing parameters that accept tenancy name remain supported.
  - New behavior: if parameter is omitted or empty, auto-discovery is triggered.
- Ensure the auto-discovery logic is encapsulated so that changes to APIs or tenancy model are localized in one place per technology.

**Dependencies:**

- Sprint 1: foundational data model (`regions_v2`, `tenancies_v1`, `realms_v1`) and OCI-centric discovery pattern.
- Sprint 3–4: versioned DALs and refactored clients (Node, CLI, Terraform) already consuming `tenancies_v1`.
- OCI authentication and configuration: OCI CLI/SDK credentials (`~/.oci/config`, instance principal, etc.) must be present for live discovery.

**Testing Strategy:**

- Node:
  - Extend or add tests in `node_client` that:
    - Call tenancy DAL with explicit tenancy name (regression).
    - Call tenancy DAL with name omitted; assert that a non-empty name is returned from OCI and used consistently.
  - Run `npm --prefix node_client test -- --runInBand`.
- CLI:
  - Add or update tests in `cli_client/test/run_tests.sh` and examples so that:
    - `TENANCY_KEY` remains supported when explicitly set.
    - When `TENANCY_KEY` is unset but tenancy OCID is known, scripts still resolve and display tenancy name.
- Terraform:
  - Extend `tf_client/examples/tenancy`:
    - One example using explicit tenancy name variable.
    - One example omitting the name so that the data source/module discovers it.
  - Run `terraform init` and `terraform validate` for tenancy example.
- Cross-cutting:
  - README and example snippets updated to describe optional tenancy name and emphasize prerequisites (OCI config, tenancy OCID availability).

**Risks/Concerns:**

- OCI API shape / permission requirements: the chosen OCI call to fetch tenancy name must be available under the same auth context as existing discovery calls; insufficient permissions could cause failures in environments with restricted IAM policies.
- Performance: repeated OCI metadata calls for tenancy name in tight loops could add latency; mitigated by simple in-process caching.
- Backward compatibility: need to ensure existing paths that always pass tenancy name continue to work unchanged.

**Compatibility Notes:**

- The feature is backward-compatible for existing callers that always supply tenancy name.
- New auto-discovery behavior is additive; failures in discovery should be surfaced clearly while preserving the ability to set tenancy name explicitly.

## Overall Sprint Assessment

**Feasibility:** High — leverages existing OCI connectivity and discovery patterns; primarily DAL and client-layer changes plus tests/docs.

**Estimated Complexity:** Moderate — touches three client stacks (Shell, Node.js, Terraform) and their tests/examples, but each change is localized to tenancy DAL and supporting scripts/modules.

**Prerequisites Met:** Yes — previous sprints established the data domains and versioned DALs; OCI auth/config is assumed available for live tests.

**Open Questions:**

- Which exact OCI API should be used to fetch tenancy name in each client (CLI vs Node SDK vs Terraform provider)? The default assumption is `oci iam tenancy get` or provider-equivalent, but this should be confirmed by the Product Owner if a different endpoint or field is preferred.

## Recommended Design Focus Areas

- Precisely define the OCI calls and response fields used to discover tenancy name for each technology.
- Decide on error-handling strategy when auto-discovery fails (e.g. fall back to explicit tenancy name only, or hard-fail with clear error).
- Ensure a consistent configuration surface across clients (environment variables / variables / constructor params) for opting into or out of auto-discovery.

## Readiness for Design Phase

Awaiting Clarification — ready for Elaboration once the Product Owner confirms or adjusts the preferred OCI API/field for tenancy name discovery and any specific error-handling expectations.

