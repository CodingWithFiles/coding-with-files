# cwf-init runs security check - Implementation Execution
**Task**: 120 (bugfix)

## Task Reference
- **Task ID**: internal-120
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/120-cwf-init-runs-security-check
- **Template Version**: 2.1

## Goal
Execute the implementation per d-implementation-plan.md: add `cwf-manage fix-security`, refresh hash, edit `/cwf-init` SKILL.md, add regression test.

## Implementation Steps (executed)

### Step 1: Setup and pattern review
- **Planned**: Re-read insertion points, baseline test count, existing test conventions.
- **Actual**: Baseline `prove t/`: 26 files, 246 tests, all pass. Confirmed `template-copier-slug-validation.t` and `cwf-manage-check-clean-tree.t` test patterns. Confirmed `cwf-manage` is hash-tracked (`script-hashes.json:70-74`). Confirmed `context-manager` is **not** hash-tracked (TC-4/TC-5 retargeted to `task-stack`).
- **Deviation**: None significant.

### Step 2: Write the regression test first (TDD)
- **Planned**: `t/cwf-manage-fix-security.t` with TC-test-1 through TC-test-7, subprocess invocation against temp `.cwf/` fixture.
- **Actual**: Created `t/cwf-manage-fix-security.t`. Initial run failed with "Unknown command: fix-security" (expected pre-implementation).
- **Deviations from plan**:
  - **Fixture creation**: switched to `cp -rp` (preserve perms). Without `-p`, the user's umask (077) drops 0755 source files to 0700 in the fixture, producing false-positive `permissions` violations during TC-1 (clean install).
  - **TC-3 target**: original plan tampered `cwf-manage` itself, but the test runs `cwf-manage` to detect the tamper — circular. Switched to tampering `cwf-set-status` (a tracked, non-bootstrap script).
  - **TC-4/TC-5 target**: original plan deleted/tampered `command-helpers/context-manager`, but that file is not hash-tracked. Switched to `command-helpers/task-stack` (hash-tracked).
  - **Subprocess invocation**: tests use `perl -I.cwf/lib .cwf/scripts/cwf-manage <subcommand>` (not direct script invocation). Necessary because TC-2/TC-7 strip the script's own exec bits in the fixture, so direct invocation would fail to exec. The bootstrap surface (the SKILL) uses the same `perl -I` invocation for the same reason.

### Step 3: Implement `cmd_fix_security` in `cwf-manage`
- **Planned**: New sub near `cmd_validate`, dispatch entry, help-text line.
- **Actual**: Added `cmd_fix_security($git_root)` after `cmd_validate` in `.cwf/scripts/cwf-manage`. The sub:
  - Reads `.cwf/security/script-hashes.json` directly (decode_json).
  - Walks every section that looks like a file map (`for $section ... if has values with {path,...}`).
  - Per entry: classifies as `existence`/`sha256` unfixable, or `permissions` fixable (chmod to recorded perms when sha matches).
  - Emits per-fix lines and per-unfixable blocks (with `field`/`actual`/`expected`/`Recovery:` lines keyed by field).
  - Exit 1 with summary if any unfixable; exit 0 (`return`) with `repaired N file(s); validate: OK` summary otherwise.
  - Recovery hints stored in package-level `%FIX_SECURITY_RECOVERY` keyed by violation field.
- Registered `'fix-security' => sub { cmd_fix_security($git_root) }` in `%dispatch`.
- Added help-text line between `validate` and `help` in `cmd_help`.
- **Deviation**: Loaded `Digest::SHA` and `JSON::PP` via `require` (lazy) inside `cmd_fix_security` instead of `use` at the top, since other subcommands don't need them. Minor; aligns with not perturbing existing module-load behaviour.

### Step 4: Refresh the script hash
- **Planned**: Compute new sha256, update `script-hashes.json`.
- **Actual**: `sha256sum` → `b45c03b5c343e2d30b6f7d4ef07823c8e40670c5ab2989672795c4fdd0a20e65`. Edited `cwf-manage` entry in `script-hashes.json`. `cwf-manage validate` → `OK`.

### Step 5: Edit the SKILL.md
- **Planned**: Insert section `### 1a. Verify and Repair CWF Install` between current sections 1 and 2; add success-criterion line.
- **Actual**: Inserted the section verbatim per the plan. Added `- [ ] Install integrity verified via \`cwf-manage fix-security\` (exit 0)` to the Success Criteria list (between `Directory structure created` and `Project configuration generated`).

### Step 6: Run tests + global validation
- **Planned**: `prove t/cwf-manage-fix-security.t` all pass; `prove t/` no new failures; `cwf-manage validate` OK; `cwf-manage fix-security` no-op on dev repo.
- **Actual**:
  - `prove t/cwf-manage-fix-security.t` → 7/7 pass
  - `prove t/` → Files=27, Tests=253, all pass (was 246 baseline → 7 new tests added, no regressions)
  - `.cwf/scripts/cwf-manage validate` → `[CWF] validate: OK`
  - `.cwf/scripts/cwf-manage fix-security` → `[CWF] fix-security: repaired 0 file(s); validate: OK`

### Step 7: Manual smoke verification
- **Planned**: Deferred to g-testing-exec (LLM-driven SKILL exec requires a separate Claude Code session in a scratch checkout).
- **Actual**: Deferred per plan.

## Files Modified
- `.cwf/scripts/cwf-manage` — added `cmd_fix_security`, dispatch entry, help text, recovery-hint table (~150 new lines)
- `.cwf/security/script-hashes.json` — refreshed `cwf-manage` sha256
- `.claude/skills/cwf-init/SKILL.md` — new section `### 1a. Verify and Repair CWF Install`; one new success-criterion line
- `t/cwf-manage-fix-security.t` (new) — 7 subtests covering classification table

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] No requirements phase for bugfix workflow
- [x] All design decisions in c-design-plan.md implemented
- [x] No work deferred (the manual smoke is part of g-testing-exec, not f-implementation-exec)

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 120
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
