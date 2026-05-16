# security-review-changeset blind to uncommitted - Retrospective
**Task**: 141 (bugfix)

## Task Reference
- **Task ID**: internal-141
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/141-security-review-changeset-blind-to-uncommitted
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-17

## Executive Summary
- **Duration**: ~0.5 day (single session, on-target with the 0.5-day estimate).
- **Scope**: As planned. One option chosen from three; one test-setup deviation caught at first run; one bonus discovery about subagent prompt engineering.
- **Outcome**: The bug is gone, *and* the very act of fixing it produced its own proof — the implementation-phase security review ran on a non-empty diff before the checkpoint commit, which was structurally impossible under the old behaviour. The four-task workaround pattern ("commit code first, then re-run security-review") that bit Tasks 137, 138, 139, and 140 is now obsolete.

## Variance Analysis

### Time and Effort
- **Estimated** (a-task-plan.md): 0.5 day, Low complexity.
- **Actual**: 0.5 day, single session, seven phase commits + the source-code change folded into the f-phase checkpoint.
- **Variance**: ~0%.

### Scope Changes
- **Additions (exec-time)**:
  - File-header comment update (stderr contract) and `list_changed_files` block comment update — both planned in d-plan after plan-review caught the missing documentation.
  - Inline test comment explaining the "untracked vs unstaged" constraint — added during exec when the deviation was caught.
- **Removals**: None.
- **Re-scopes (exec-time)**:
  - **TC-Task141-uncommitted test setup restructured at first run.** Initial setup (per d-plan) created two new files: one `git add`-ed (staged), one not. `git diff <anchor>` doesn't list untracked files — exactly what my own c-design plan said in "Behavioural notes on the widened diff window." The d-plan and e-plan both inherited the same blind spot from each other; plan-review subagents on both phases missed it.
  - **Fix**: restructured to commit a `baseline-script` first (creating a tracked-on-branch file), then modify it without `git add` for the working-tree-side proof. The `staged-script` remained as the index-side proof. 4 assertions instead of 3 (added a content-level assertion on `UNSTAGED_MOD_141`).

### Quality Metrics
- **Test count**: 473/473 passing (was 472 + 1 new = 473). One new subtest, zero existing modified.
- **Defect rate**: 1 test-design defect, caught at first run (~30s feedback), restructured in-place, zero rework after.
- **Manifest integrity**: `cwf-manage validate` → OK throughout. Hand-update of the `security-review-changeset` SHA per the Task-135 surface-don't-smooth policy worked first try.
- **Orphan-literal guard**: `grep -rn '\.\.HEAD' .cwf/scripts/command-helpers/security-review-changeset` returns 2 hits, both in deliberate historical-context comments documenting the Task 141 change. No live code references to the old shape.

## What Went Well
- **Self-validating fix.** The implementation-phase security review ran successfully on a non-empty diff *before* the checkpoint commit — this is structurally impossible under the old `anchor..HEAD` behaviour. The review's *running* is the proof, independent of the unit test. The two-state observation in g-testing-exec (dirty tree → suffix shown + diff non-empty; clean tree → suffix omitted + diff still non-empty via working-tree anchor) leaves no daylight.
- **Plan-review catching documentation drift.** The d-plan review subagents caught two missing comment updates that the bare implementation step list would have left as stale strings (the file-header stderr contract and the `list_changed_files` block comment). Both updates landed in the same f-phase commit alongside the code change.
- **Fast-feedback test design.** The TC-Task141-uncommitted defect surfaced in the first 30 seconds of test execution. Caught early, restructured in-place, zero rework propagated. Adding a content-level assertion (`UNSTAGED_MOD_141`) made the test stronger as a side-effect of the fix.
- **Sentinel-first prompt engineering breakthrough.** After five consecutive exec-phase security reviews failing sentinel-first formatting (Tasks 139-f, 139-g, 140-f, 140-g, 141-f), the testing-phase review (141-g) succeeded on first attempt. The prompt that worked: open with "Your VERY FIRST CHARACTER of response must be the letter `n`, `f`, or `e`" and explicitly enumerate unacceptable openers ("Now", "Let me", "I'll", "Looking at..."). **Character-level instructions worked where sentence-level instructions did not.** This is a concrete prompt template to fold into `.cwf/docs/skills/security-review.md` when the two BACKLOG items about sentinel compliance get picked up.
- **Fold-into-active-workflow worked for the surprise BACKLOG addition.** The "Default task-workflow `--baseline-commit` to HEAD" entry that came up mid-task-creation was added on this branch and folded into the a-phase checkpoint. Clean — no orphan commit on main.

## What Could Be Improved
- **Plan-review didn't catch the test-setup blind spot.** Three of four d-plan reviewers and four of four c-design reviewers ran on the plan. The "untracked vs unstaged" semantic distinction was *explicit in c-design* but not propagated to the test setup in d-plan. Plan-review subagents look for consistency *within* a plan, not consistency *across* sibling plans in the same task. Worth a process note: when one plan documents a constraint, a later plan in the same task that references the constrained behaviour should re-state it inline rather than assume cross-document inheritance.
- **Cwf-checkpoint-commit perm-drift false positive after Task 140's squash.** When I checkpointed the a-task-plan, `cwf-manage validate` flagged `ArtefactHelpers.pm` as `permissions: 0600` vs expected `0444`. The cause: Task 140's soft-reset during squash restored content but not the file's recorded mode bits (umask creates 0600 for new files). `fix-security` repaired it in one call. Not a Task 141 bug, but worth recording as a known shape — any squash-via-soft-reset will leak the working umask onto whatever files git stages, and the next validate run after will surface drift on permission-tracked files.
- **The two sentinel-format BACKLOG items remain open and still un-picked-up.** Bumped to Medium during Task 140's retro on a 5-task-streak; Task 141 was the 6th, and exec-phase reviews still failed 1-of-2 on this task. The streak is now broken (141-g succeeded), but the *prompt change* that made it succeed is not yet folded into the canonical security-review.md template. The BACKLOG items need to be picked up to ship the fix before more agents discover the same workaround independently.

## Key Learnings

### Technical Insights
- **A bug-fix can be its own proof of correctness when the fix unblocks a previously-unrunnable test.** Task 141's fix made the implementation-phase security review functional for the first time on uncommitted state. The review's *running successfully* is structurally impossible under the old behaviour, which makes the run itself a sharper test than any unit test. Look for this pattern when fixing infrastructure bugs that gate other workflows.
- **`git diff <anchor>` excludes untracked files; `git diff <anchor>..HEAD` does the same for completely different reasons.** Both shapes ignore untracked files because `git diff` ignores them by design. The old `..HEAD` shape *also* excluded staged-but-uncommitted changes, which the new `<anchor>` shape now includes. The disclosure suffix (`, includes uncommitted`) makes this widening visible to the reviewer; without it the change would be silent.
- **`-r _` (chained file-test) saves one stat call after `-f`.** Not Task 141, but the same idiom I used in Task 140's `validate_read_path_allowlist`. Two-touch pattern worth keeping in the Perl toolkit.

### Process Learnings
- **Map/reduce plan review is a per-plan check, not a cross-plan check.** Each plan-review subagent sees the plan it was given; it doesn't read sibling plans in the same task directory. To benefit from cross-plan consistency, either: (a) include the relevant sibling-plan excerpts in the plan being reviewed, or (b) accept that constraints documented in one plan need to be re-stated in any plan that references the same code surface. Option (b) is cheaper and what this retro lands on.
- **Prompt engineering at character level beats sentence level for sentinel discipline.** Six consecutive subagent reviews failed sentence-level "start with the sentinel" instructions. The seventh — character-level "your very first character must be `n`, `f`, or `e`" plus explicit unacceptable-opener list — succeeded. The working prompt should be ported into the canonical template the next time the sentinel-compliance BACKLOG items are picked up.
- **Folding adjacent housekeeping into an active phase's checkpoint commit works cleanly.** The "Default task-workflow --baseline-commit to HEAD" BACKLOG addition (made mid-task-creation, before any a-phase work on Task 141) was folded into Task 141's a-phase checkpoint. The commit's name still names the task; the BACKLOG.md addition rides along. This pattern is preferable to: standalone non-task commit, branch-switch detour to main, or carrying the change forward to the retrospective.

### Risk Mitigation Strategies
- **Test "the change does what I claim" before "the change passes other tests".** TC-Task141-uncommitted was the first test added in this task because it directly proves the bug is gone. Existing tests pass because the new behaviour reduces to the old behaviour when the working tree is clean — they're regression backstops, not proofs of the fix. Ordering matters.

## Recommendations

### Process Improvements
- **Pick up the sentinel-compliance BACKLOG items soon.** With this task's 141-g prompt as a working starting point, the work is now mostly "rephrase the existing template using the character-level pattern, retest on a synthetic changeset." Likely <2 hours. The two BACKLOG entries ("Enforce sentinel-first…" + "Tighten security-subagent…") should probably consolidate into one task.
- **When a plan documents a constraint, restate it in the next plan that touches the same code surface.** Or include the relevant excerpt as an explicit reference. Don't assume plan-review subagents read sibling plans — they don't.

### Tool and Technique Recommendations
- No new tools. Continue existing patterns.

### Future Work
- The two sentinel-format BACKLOG items are the natural follow-on. The bumped priority (Medium, from Task 140's retro) plus this task's working prompt template should make them quick to ship.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-17
**Sign-off**: Task 141 — security-review-changeset blind to uncommitted

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- `implementation-guide/141-bugfix-security-review-changeset-blind-to-uncommitted/a-task-plan.md`
- `implementation-guide/141-bugfix-security-review-changeset-blind-to-uncommitted/c-design-plan.md`
- `implementation-guide/141-bugfix-security-review-changeset-blind-to-uncommitted/d-implementation-plan.md`
- `implementation-guide/141-bugfix-security-review-changeset-blind-to-uncommitted/e-testing-plan.md`
- `implementation-guide/141-bugfix-security-review-changeset-blind-to-uncommitted/f-implementation-exec.md`
- `implementation-guide/141-bugfix-security-review-changeset-blind-to-uncommitted/g-testing-exec.md`
- Source-code change: in commit `df9f1c2` (Task 141 f-phase checkpoint).
- Test coverage: `prove t/` 473/473 (post-task), see g-testing-exec.md.
