# Sprint 5 - Inception

Status: Complete

## What Was Analyzed

- Active Sprint: **Sprint 5 - Tenancy name is auto-discovered** (`Status: Progress`, `Mode: managed`).
- Backlog Item: **GD-4. Tenancy name is auto-discovered** from `BACKLOG.md`.
- Previous work: Sprints 1–4 establishing the data model (`regions_v2`, `tenancies_v1`, `realms_v1`), versioning, and current DALs/clients for Node, CLI, and Terraform.
- Detailed analysis has been captured in `progress/sprint_5/sprint_5_analysis.md`.

## Key Findings

1. The requirement is to make tenancy name optional and auto-discovered from OCI using the known tenancy OCID, similar to existing region/realm discovery patterns.
2. All three clients (Shell, Node.js, Terraform) already have tenancy DALs (`tenancies_v1`) and examples; the new feature can be implemented by extending these DALs without changing the underlying data model.
3. Auto-discovery will use `oci iam tenancy get` (or equivalent SDK/provider call) and treat `data.name` as the authoritative tenancy name.
4. Backward compatibility is expected: callers that already provide tenancy name should continue to work unchanged.

## Confirmed Work Scope

| Area                   | Scope                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| Tenancy DAL (Node.js)  | Extend `gdir_tenancies_v1` to support optional tenancy name + lookup |
| Tenancy DAL (CLI)      | Extend `gdir_tenancies_v1.sh` functions to lookup name when missing  |
| Tenancy DAL (Terraform)| Extend `gdir_tenancies_v1` module / example to support auto-discovery|
| Examples/Docs          | Update tenancy examples and README to show optional name behavior    |

Full analysis: `progress/sprint_5/sprint_5_analysis.md`

## Readiness

In managed mode, the clarification for OCI API and field has been provided (`oci iam tenancy get` → `data.name`) together with the expectation of **hard failure with a clear error message** when auto-discovery fails. Inception is complete and the Sprint is ready for Elaboration (design).

# Sprint 5 - Inception

Status: In Progress

## What Was Analyzed

- Active Sprint: **Sprint 5 - Tenancy name is auto-discovered** (`Status: Progress`, `Mode: managed`).
- Backlog Item: **GD-4. Tenancy name is auto-discovered** from `BACKLOG.md`.
- Previous work: Sprints 1–4 establishing the data model (`regions_v2`, `tenancies_v1`, `realms_v1`), versioning, and current DALs/clients for Node, CLI, and Terraform.
- Detailed analysis has been captured in `progress/sprint_5/sprint_5_analysis.md`.

## Key Findings

1. The requirement is to make tenancy name optional and auto-discovered from OCI using the known tenancy OCID, similar to existing region/realm discovery patterns.
2. All three clients (Shell, Node.js, Terraform) already have tenancy DALs (`tenancies_v1`) and examples; the new feature can be implemented by extending these DALs without changing the underlying data model.
3. Auto-discovery requires choosing a concrete OCI API/field per technology (e.g. `oci iam tenancy get` and its `name` field, or equivalent in SDK/provider).
4. Backward compatibility is expected: callers that already provide tenancy name should continue to work unchanged.

## Confirmed Work Scope

| Area                   | Scope                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| Tenancy DAL (Node.js)  | Extend `gdir_tenancies_v1` to support optional tenancy name + lookup |
| Tenancy DAL (CLI)      | Extend `gdir_tenancies_v1.sh` functions to lookup name when missing  |
| Tenancy DAL (Terraform)| Extend `gdir_tenancies_v1` module / example to support auto-discovery|
| Examples/Docs          | Update tenancy examples and README to show optional name behavior    |

Full analysis: `progress/sprint_5/sprint_5_analysis.md`

## Readiness

In managed mode, one clarification is requested before proceeding to design:

- **Question:** Which exact OCI API and response field should be treated as the authoritative source of tenancy name for auto-discovery (for CLI, Node SDK, and Terraform provider), and how strict should error handling be if that lookup fails?

Once this is confirmed, Inception can be marked complete and Elaboration can proceed.

