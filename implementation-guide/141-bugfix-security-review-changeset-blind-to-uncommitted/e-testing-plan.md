# security-review-changeset blind to uncommitted - Testing Plan
**Task**: 141 (bugfix)

## Task Reference
- **Task ID**: internal-141
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/141-security-review-changeset-blind-to-uncommitted
- **Template Version**: 2.1

## Goal
Validate the c-design / d-implementation fix at three levels: the new regression test demonstrating the bug is gone; the full regression suite proving committed-state behaviour is unchanged; and an end-to-end smoke during f-implementation-exec proving the fix works on the canonical "agent invokes helper before checkpoint" scenario.

## Test Strategy

### Test Levels
- **Unit**: not applicable — the helper has no internal pure-function surface worth pinning at unit level; its behaviour is end-to-end against a synthetic git repo.
- **Integration**: existing `t/security-review-changeset.t` scaffolding (`make_synthetic_repo`, `run_helper`, `git_in`, `git_capture`) drives the helper as a subprocess against fixture repos. One new subtest added (`TC-Task141-uncommitted`).
- **Regression**: full `prove t/` must stay green. Existing committed-state subtests verify the new behaviour is a strict superset (when working tree == HEAD, the two diff shapes return identical output).
- **End-to-end smoke**: run the helper mid-exec on this very task, against the actual repo working tree, before committing. The fix succeeds iff this works on first try.

### Test Coverage Targets
- **Bug-fix-specific regression**: one positive case (`TC-Task141-uncommitted`) covering both index-side and working-tree-side changes via distinct file paths (per c-design's two-file proof model).
- **Committed-state regression**: the existing 19 subtests in `t/security-review-changeset.t` must all pass without modification.
- **Error path**: the `git diff --quiet HEAD` dirty-check's rc ≥ 2 branch (git error → skip disclosure) is fail-quiet by design; no test forces it. Acceptable risk: this branch is only reachable from corrupted-repo states, which the primary `git diff` would have failed on first.
- **Summary-line shape**: `TC-Task141-uncommitted`'s Assert 3 uses an anchored regex on the summary line specifically (not a loose substring match) to prove the disclosure suffix lands on the right line.

## Test Cases

### Functional Test Cases — `t/security-review-changeset.t`

- **TC-Task141-uncommitted**: helper sees both staged and working-tree-only changes
  - **Given**: a synthetic CWF-layout repo on a task branch with recorded baseline = main's tip, and two separate new files on the task branch:
    - `.cwf/scripts/staged-script` (`#!/usr/bin/perl\nprint "STAGED_141";\n`), `git add`ed, not committed.
    - `.cwf/scripts/unstaged-script` (`#!/usr/bin/perl\nprint "UNSTAGED_141";\n`), not `git add`ed.
  - **When**: `run_helper($repo)` invokes the helper with default args (no flags).
  - **Then**:
    1. exit code 0.
    2. stdout diff includes the path `staged-script` (proves index-side changes scanned).
    3. stdout diff includes the path `unstaged-script` (proves working-tree-only changes scanned).
    4. stderr summary matches `qr{^reviewed 2 files,.+anchor=[0-9a-f]{7}, includes uncommitted$}m` — anchored to summary line, count is 2 (both files), disclosure suffix present.

### Regression Test Cases — must remain green without modification
- **TC-F1** through **TC-F7**: file-classification cases. All commit before invoking; working tree clean at helper call → new behaviour reduces to old behaviour → unchanged output.
- **TC-NF1** through **TC-NF5**: non-functional cases (anchor resolution, malformed inputs, etc.). Same reasoning.

### Non-Functional Test Cases
- **Security**: `security-review-changeset --phase=testing` invoked on this task's own diff (which now legitimately picks up the working-tree edits) — recorded in g-testing-exec.md § "Security Review". The fix removes the need for the workaround of commit-first-then-re-run.
- **Maintainability**: source-level grep `grep -rn '\.\.HEAD' .cwf/scripts/command-helpers/security-review-changeset` returns 0 hits. The `..HEAD` literal should be fully removed from the helper.
- **Reliability**: `cwf-manage validate` is OK after hash regen. `prove t/` reaches the target 473 (was 472 + 1).
- **Performance**: not measured — change is one extra `git diff --quiet HEAD` per helper invocation (cheap, sub-100ms). Helper itself runs once per exec-phase invocation, so ~10s of invocations per day in active development. Negligible delta.

### End-to-End Smoke (executed during g-testing-exec, after the helper edit lands locally but before any 141 checkpoint commits)
- **Setup**: be on the task branch with both source edits to `.cwf/scripts/command-helpers/security-review-changeset` and the new test in `t/security-review-changeset.t` uncommitted (i.e. the natural state mid-f-exec).
- **Action**: run `.cwf/scripts/command-helpers/security-review-changeset --phase=implementation`.
- **Expected**:
  - exit 0.
  - stdout non-empty, containing the diff of the helper's own modifications plus the test additions.
  - stderr line matches `qr{reviewed [12] files,.+, includes uncommitted}` (count is 1 or 2 depending on whether the test file also gets picked up — verify which).
- **This is the canonical proof.** Record the verbatim stderr line in g-testing-exec.md.

## Test Environment

### Setup Requirements
- Standard repo checkout. No external services, no databases, no fixtures beyond what `t/security-review-changeset.t` already builds.
- `File::Temp`, `File::Path` (core). `git` available on `$PATH` (already required by every other helper test).
- POSIX-only.

### Automation
- All cases run under `prove t/` via the existing harness.
- No CI integration changes needed.
- End-to-end smoke is a one-shot manual invocation in g-testing-exec.

## Validation Criteria
- [ ] `TC-Task141-uncommitted` passes (all 4 assertions).
- [ ] TC-F1..F7 and TC-NF1..NF5 pass unchanged.
- [ ] `prove t/` → 473 tests PASS.
- [ ] End-to-end smoke shows non-empty diff and the `includes uncommitted` suffix in stderr — both observed first try.
- [ ] `grep -rn '\.\.HEAD' .cwf/scripts/command-helpers/security-review-changeset` returns 0 hits (orphan-literal guard).
- [ ] `cwf-manage validate` is OK after script-hash regen.
- [ ] Security review subagent invoked on the now-real diff returns substantive analysis (sentinel compliance permitting).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 141
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
