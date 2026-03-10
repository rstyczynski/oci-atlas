# Sprint 7 - Design

## GD-10: Restructure client directories

Status: Proposed

### Requirement Summary

Rename four top-level directories to a cleaner grouped layout. Update all path references in affected files. Update README.md and VERSIONING.md.

### Feasibility Analysis

**API Availability:** N/A — pure filesystem and text operations.

**Technical Constraints:**

- `git mv` preserves history; must be used (not `mv`)
- `terraform.tfstate`, `node_modules/`, `.terraform/` are large but handled by `.gitignore`
- No consumers are locked to old paths (early-phase project)

**Risk Assessment:**

- Low: straightforward rename + text substitution
- Medium: relative path `$ROOT/../tf_manager` in `run_tests.sh` changes depth — must verify

### Design Overview

**Directory mapping:**

| Old path | New path |
|----------|----------|
| `cli_client/` | `clients/shell/` |
| `node_client/` | `clients/node/` |
| `tf_client/` | `clients/terraform/` |
| `tf_manager/` | `manager/` |

**New structure:**

```
clients/
  shell/       (was cli_client/)
  node/        (was node_client/)
  terraform/   (was tf_client/)
manager/       (was tf_manager/)
```

### Technical Specification — File-by-file changes

**Step 1: git mv directories**

```bash
mkdir -p clients
git mv cli_client clients/shell
git mv node_client clients/node
git mv tf_client clients/terraform
git mv tf_manager manager
```

**Step 2: Path reference updates (post-mv)**

| File | Old string | New string |
|------|-----------|------------|
| `clients/shell/test/run_tests.sh:6` | `$ROOT/../tf_manager` | `$ROOT/../../manager` |
| `clients/shell/test/validate_linux.sh:6` | `cli_client/test/validate_linux.sh` | `clients/shell/test/validate_linux.sh` |
| `clients/shell/test/validate_linux.sh:7` | `cli_client/test/validate_linux.sh` | `clients/shell/test/validate_linux.sh` |
| `clients/shell/test/validate_linux.sh:38` | `/workspace/tf_manager` | `/workspace/manager` |
| `clients/shell/test/validate_linux.sh:41` | `cli_client/test/run_tests.sh` | `clients/shell/test/run_tests.sh` |
| `clients/shell/bin/demo_mapping.sh:16` | `../tf_manager` | `../../manager` |
| `clients/shell/README.md` | `cli_client` (title + source examples) | `clients/shell` |
| `clients/node/README.md` | `node_client` | `clients/node` |
| `clients/terraform/README.md` | `tf_client` | `clients/terraform` |
| `clients/terraform/README.md` | `cli_client` (cross-ref descriptions) | `clients/shell` |
| `manager/demo_mapping.sh` | `tf_manager/` (in comments) | `manager/` |
| `manager/demo_mapping.sh` | `cd tf_manager` | `cd manager` |
| `README.md` | all 4 old paths | new paths |
| `VERSIONING.md` | `tf_manager/` | `manager/` |
| `VERSIONING.md` | `node_client/` | `clients/node/` |

### Testing Strategy

**Functional Tests:**

1. Directory structure: verify `ls clients/shell clients/node clients/terraform manager` shows expected files
2. Shell tests: `GDIR_DATA_DIR=$PWD/manager bash clients/shell/test/run_tests.sh`
3. Node tests: `npm --prefix clients/node test -- --runInBand`
4. Relative path: verify `$ROOT/../../manager` resolves correctly from `clients/shell/test/`

**Success Criteria:**

- All directories in new locations; old paths absent
- Shell and node tests pass
- No broken references in READMEs

### YOLO Mode Decisions

#### Decision 1: `clients/shell/examples/realms.sh` comment

**Context**: Comment `# Mirrors node_client/examples/client_realms.ts` — informational cross-ref.
**Decision Made**: Update to `clients/node/examples/client_realms.ts`.
**Rationale**: Accuracy.
**Risk**: Low

#### Decision 2: `clients/shell/gdir_realms_v1.sh` comment

**Context**: Comment `# ISO 8601 timestamp injected by tf_manager at upload time` — refers to tool name, not path.
**Decision Made**: Update to `manager`.
**Rationale**: Accuracy.
**Risk**: Low

#### Decision 3: VERSIONING.md git example paths

**Context**: VERSIONING.md has `git add tf_manager/regions_v2.json` etc. in example git commands.
**Decision Made**: Update to `manager/regions_v2.json`.
**Rationale**: Examples must be accurate copy-paste.
**Risk**: Low

### Open Design Questions

None

---

# Design Summary

## Overall Architecture

Single-phase operation: `git mv` + text substitution in ~8 files.

## Design Risks

Low overall. Only risk is missing a path reference — mitigated by exhaustive grep before implementation.

## Design Approval Status

Proposed
