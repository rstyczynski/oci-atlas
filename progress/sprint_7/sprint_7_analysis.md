# Sprint 7 - Analysis

Status: Complete

## Sprint Overview

Rename four top-level directories to a cleaner grouped layout. Pure filesystem restructure with no logic changes.

## Backlog Items Analysis

### GD-10: Restructure client directories

**Requirement Summary:**

- `cli_client/` → `clients/shell/`
- `node_client/` → `clients/node/`
- `tf_client/` → `clients/terraform/`
- `tf_manager/` → `manager/`
- Update relative path references in 4 script files
- Update README.md and VERSIONING.md
- Historical sprint docs NOT updated (per backlog spec)

**Technical Approach:**

1. `git mv` each directory to new path
2. Update path references in affected files:
   - `clients/shell/test/run_tests.sh` — `GDIR_DATA_DIR` relative path `../tf_manager` → `../../manager`
   - `clients/shell/test/validate_linux.sh` — two occurrences of `cli_client/` and `tf_manager`
   - `manager/demo_mapping.sh` — self-references to `tf_manager/` in comments
   - `clients/shell/bin/demo_mapping.sh` — comment reference to `../tf_manager`
3. Update README.md — all `cli_client/`, `node_client/`, `tf_client/`, `tf_manager/` refs → new paths
4. Update VERSIONING.md — `tf_manager/` refs in version table and code examples → `manager/`

**Dependencies:** None (standalone restructure)

**Testing Strategy:**

- Verify `git mv` completed with no leftovers
- Run shell tests: `GDIR_DATA_DIR=$PWD/manager bash clients/shell/test/run_tests.sh`
- Run node tests: `npm --prefix clients/node test -- --runInBand`
- Verify `GDIR_DATA_DIR=$PWD/manager` still works for all clients

**Risks/Concerns:**

- `tf_manager/.terraform/` and `node_client/node_modules/` are large — `git mv` handles them but they must not be tracked in git (should already be in `.gitignore`)
- terraform.tfstate files should also be gitignored

**Compatibility Notes:**

All existing paths are self-contained within the repo. No external consumers are locked to these paths (early-phase project per VERSIONING.md). VERSIONING.md examples reference `tf_manager/` — must be updated.

## YOLO Mode Decisions

### Assumption 1: VERSIONING.md examples updated

**Issue**: Backlog spec says "update README.md and VERSIONING.md" but only mentions 4 script files for path references.
**Assumption Made**: VERSIONING.md version table and git example commands referencing `tf_manager/` are also updated to `manager/`.
**Rationale**: Document accuracy; stale paths in docs are misleading.
**Risk**: Low

### Assumption 2: Comments in scripts updated

**Issue**: Script comments are not "relative path references" strictly, but they document usage from project root.
**Assumption Made**: Comments referencing old paths updated to new paths.
**Rationale**: Usability; copy-paste examples in comments must work.
**Risk**: Low

### Assumption 3: cli_client/README.md references to cli_client

**Issue**: `cli_client/README.md` contains `source cli_client/gdir_*.sh` examples.
**Assumption Made**: After `git mv`, those references need to change to `clients/shell/`.
**Rationale**: Copy-paste correctness.
**Risk**: Low

## Overall Sprint Assessment

**Feasibility:** High — pure `git mv` + text substitution

**Estimated Complexity:** Simple

**Prerequisites Met:** Yes — all previous sprints done

**Open Questions:** None

## Recommended Design Focus Areas

- Identify ALL path references exhaustively before executing (one-shot `git mv` is cleaner)
- Check `.gitignore` has entries for `node_modules/`, `.terraform/`, `terraform.tfstate*`

## Readiness for Design Phase

Confirmed Ready
