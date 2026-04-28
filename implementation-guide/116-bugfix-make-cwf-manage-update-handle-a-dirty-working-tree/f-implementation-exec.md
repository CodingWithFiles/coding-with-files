# Make cwf-manage update handle a dirty working tree - Implementation Execution
**Task**: 116 (bugfix)

## Task Reference
- **Task ID**: internal-116
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/116-make-cwf-manage-update-handle-a-dirty-working-tree
- **Template Version**: 2.1

## Goal
Execute the implementation following d-implementation-plan.md (post-`/simplify` shape) and verify integration end-to-end.

## Files Changed
- `.cwf/scripts/cwf-manage` — added `check_clean_tree($git_root)` helper (~25 lines including the section divider) in its own `# --- Working-tree safety ---` block; one new line in `cmd_update` (`check_clean_tree($git_root);`); `Notes:` subsection added to `cmd_help` heredoc between `Environment:` and `Examples:`.
- `.cwf/security/script-hashes.json` — `cwf-manage` `sha256` updated `97d4bfe1…` → `e3b5628d…`.
- `t/cwf-manage-check-clean-tree.t` — new file. Three subtests (TC-1..TC-3): clean / dirty (tracked + untracked) / git-status-failure.

## Actual Results

### Step 1: Setup
- **Planned**: Confirm task branch checked out, clean working tree (untracked workflow templates expected).
- **Actual**: On `bugfix/116-...`, three untracked workflow templates (`f-`, `g-`, `j-`) from `/cwf-new-task` scaffold present. Otherwise clean.

### Step 2: Test first (TDD)
- **Planned**: Write `t/cwf-manage-check-clean-tree.t` with 3 subtests; run; expect undefined-subroutine red.
- **Actual**: Wrote the test file using the Task 115 prologue verbatim (including the `*main::die_msg` symbol-table override under `no warnings 'redefine', 'once';`). Ran `prove t/cwf-manage-check-clean-tree.t`:
  ```
  Failed 3/3 subtests
  Undefined subroutine &main::check_clean_tree
  ```
  Red as expected.

### Step 3: Add the `check_clean_tree` helper
- **Planned**: Insert after `resolve_source` per d-impl Step 3 skeleton.
- **Actual**: Inserted verbatim per the post-`/simplify` skeleton (one block, calls `die_msg` directly with the full message — header + file list + recipe — via heredoc). No deviation. Re-ran the test file:
  ```
  t/cwf-manage-check-clean-tree.t .. ok
  All tests successful.
  Files=1, Tests=3
  ```
  3/3 green.

### Step 4: Wire into `cmd_update`
- **Planned**: One new line `check_clean_tree($git_root);` between `resolve_source` and `log_msg("Updating CWF...")`.
- **Actual**: Done verbatim. `cmd_rollback` (unchanged at lines 257–263) inherits the check via delegation — confirmed by reading.

### Step 5: Update `cmd_help` heredoc
- **Planned**: Add `Notes:` block between `Environment:` and `Examples:`. No file-header duplicate.
- **Actual**: Done verbatim. Verified: `cwf-manage help` output includes the new block.

### Step 7: Re-hash and validate
- **Planned**: Update `.cwf/security/script-hashes.json` `cwf-manage` sha256 to match modified script.
- **Actual**: Initial `cwf-manage validate` failed with the expected hash mismatch (actual: `e3b5628d…`, expected: `97d4bfe1…`). Updated `.cwf/security/script-hashes.json:72` with the new hash. Re-ran — `validate: OK`.

### Step 8: Smoke tests
- **Planned**: Full `prove t/` (expect 238/238); manual end-to-end smokes for Scenarios A/B/C.
- **Actual**:
  - **Full `prove t/`**: 25 files, **238 tests, all PASS** (235 baseline + 3 new). No regressions.
  - **`cwf-manage help`**: `Notes:` block present, exact wording matches d-impl Step 5.
  - **Scenario B (dirty `.cwf/`, env override — load-bearing)**: built tempdir fixture per Task 115's TC-10 pattern; `echo dirt > .cwf/foo.txt; CWF_SOURCE=file:///tmp/cwf-nonexistent cwf-manage update` produced exact expected output:
    ```
    [CWF] ERROR: Working tree has uncommitted changes under .cwf, .cwf-skills:
      ?? .cwf/foo.txt
    Stash or commit them, then re-run:
      git stash
      cwf-manage update [ref]
      git stash pop
    ```
    Exit code 1. **No `Cloning CWF source...` log** — confirms the check fires before the clone.
  - Scenarios A and C are deferred to g-testing-exec (smoke responsibility belongs there).

### Step 9: Validation
- All d-impl-plan checklist items met. No deviations.

## Deviations from Plan
None. The post-`/simplify` plan executed verbatim. Helper, call site, heredoc edit, hash bump, and test file all landed exactly as specified.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed.
- [x] All a-task-plan.md success criteria met (full smoke verification in g).
- [x] No design deviations.
- [x] No follow-up tasks needed beyond what's already in BACKLOG.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 116
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
