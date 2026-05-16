# security-review-changeset blind to uncommitted - Implementation Execution
**Task**: 141 (bugfix)

## Task Reference
- **Task ID**: internal-141
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/141-security-review-changeset-blind-to-uncommitted
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Actual Results

### Step 1: Baseline confirmation
- **Planned**: `prove t/security-review-changeset.t` green on `f833bbf`; 19 tests.
- **Actual**: Green. **Count correction**: the file has **13** subtests, not 19 as the d-plan stated. Plan number was wrong; functional outcome (baseline green) unaffected.

### Step 2 + Step 3: Restructure summary emission and add the dirty-check
- **Planned**: refactor the empty-changeset and non-empty summary sites to interpolate a `$dirty_suffix` computed once near the top; add `git_check('diff', '--quiet', 'HEAD')` for dirty detection with fail-quiet-and-degrade on rc ≥ 2.
- **Actual**: applied exactly per the d-plan "After" code block. Single intermediate `$dirty_suffix` reused at both summary sites; comment block above documents the rc semantics inline. `prove t/security-review-changeset.t` still 13 PASS — committed-state behaviour unchanged.

### Step 4: Drop `..HEAD` from both diff specs + comment updates
- **Planned**: edit lines 168 + 341; update `list_changed_files` block comment; update the file-header stderr-contract comment to advertise the new suffix.
- **Actual**: all three edits applied. The two `..HEAD` mentions remaining in the source are inside historical-context comments (line 33: `not just anchor..HEAD`, line 343: `Task 141: dropped \`..HEAD\``), both deliberate. `prove t/security-review-changeset.t` still 13 PASS.

### Step 5: Add `TC-Task141-uncommitted` regression test
- **Planned**: two distinct new files in the test (`staged-script` via `git add`, `unstaged-script` without `git add`); assert both paths appear in the diff.
- **Actual — DEVIATION**: first attempt followed the plan literally and **the working-tree-only file (`unstaged-script`) was not picked up** — assertion 3 failed. **Root cause**: my own c-design plan said it explicitly ("Untracked files: `git diff` does not list them by design") and the d-plan still conflated "unstaged" (= tracked-but-modified) with "untracked" (= never `git add`-ed). For `git diff <anchor>` to show working-tree changes to a file, the file must be tracked.
  - **Fix**: restructured the test to commit a `baseline-script` on the task branch *first*, then modify it without `git add` (working-tree-only change to a *tracked* file). The new file `staged-script` remains as the index-side proof. Added an inline comment in the test referencing the c-design "Behavioural notes" section so a future reader sees the constraint.
  - **Restructured test**: 4 assertions now (added `like($out, qr{UNSTAGED_MOD_141})` to prove the unstaged-modification *content* appears, not just the file path). Now PASSES.
  - **Plan defect to note in retro**: the d-plan and the c-design were *consistent* with each other on the underlying constraint but *inconsistent* on the test setup. Plan-review subagents on both phases missed this. The bug self-revealed at first test run — caught early, low cost.

### Step 6: Regenerate script hash
- **Planned**: `cwf-manage fix-security` to surface the new SHA; hand-update `script-hashes.json`.
- **Actual**: applied as planned. New SHA for `security-review-changeset`: `826abd8d…09e5cbe8`. `last_updated` bumped to 2026-05-17.
- `cwf-manage validate` → OK.

### Step 7: Validation gate
- **Planned**: full `prove t/` → 473 PASS; canonical smoke; `..HEAD` orphan-literal guard.
- **Actual**:
  - `prove t/` → 42 files, **473 tests, all PASS**.
  - **Canonical end-to-end smoke** (THE PROOF):
    ```
    $ .cwf/scripts/command-helpers/security-review-changeset --phase=implementation
    [stdout: 121-line diff of security-review-changeset + t/security-review-changeset.t]
    [stderr]: reviewed 2 files, 121 lines, anchor=f833bbf, includes uncommitted
    ```
    Run against the bare working tree, *before* any 141 checkpoint commits. Previous behaviour would have shown `reviewed 0 files, 0 lines, anchor=f833bbf` (the workaround that bit Tasks 137/138/139/140). The disclosure suffix lands on the summary line as designed. **The fix works on first try.**
  - `grep -rn '\.\.HEAD' .cwf/scripts/command-helpers/security-review-changeset` → 2 hits, both in historical-context comments. No orphan code refs.

## Blockers Encountered
None. The Step 5 deviation was caught by the first test run (~30 seconds of feedback), restructured, and shipped in the same step.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed.
- [x] All success criteria from a-task-plan.md met (verified below).
- [x] Design guidance in c-design-plan.md followed.
- [x] No planned work deferred.

## Success-criteria roll-up (from a-task-plan.md)
- [x] Invoking the helper on a branch with uncommitted changes emits a non-empty diff — *proven by the smoke* (`reviewed 2 files, 121 lines, ..., includes uncommitted`).
- [x] Existing tests for committed-state branches unchanged — 13 existing subtests + 1 new = 14 in the helper test file, all PASS.
- [x] Exec-phase skills no longer need the commit-first workaround — this very review ran successfully on uncommitted state, which is itself the proof.
- [x] No new permission surface — `git_check('diff', '--quiet', 'HEAD')` is list-form spawn (same pattern as existing trunk-name validation).
- [x] BACKLOG entry to be retired in j-retrospective; `cwf-manage validate` + `prove t/` green now.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 141
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: error

error: subagent emitted substantive analysis with a body-level "no findings" verdict, but failed sentinel-first formatting on the first attempt — same pattern as Tasks 139, 140 (both phases each). Per the three-tier rule: tier-1 fails (first non-blank line is "Now let me analyze the changeset…"); tier-2 fails (body uses bold-bullet `**Threat (a) — …**` markdown, not the `^\s*\d+[.)]\s` numbered-list form the fallback regex matches, and contains no "actionable finding" phrase); tier-3 conservative default → `error`.

This is now the **fifth consecutive exec-phase security review** to hit the sentinel-formatting failure (139-f, 139-g, 140-f, 140-g, 141-f). The two BACKLOG items bumped to Medium in Task 140's retro ("Enforce sentinel-first output…" + "Tighten security-subagent prompt…") have not been touched. Their priority bump was justified; the prompt-engineering work itself still needs doing.

Substantive verdict (verbatim, closing lines of subagent output):

```
no findings

The changeset correctly implements the widened diff window for uncommitted work visibility, with proper disclosure ("includes uncommitted"), safe git command patterns, and comprehensive regression testing. All threat categories (a)–(e) are clear.
```

Per-category notes from the body (paraphrased for compactness; full output is in the subagent transcript and was not preserved verbatim due to length):
- **(a) Bash injection**: list-form `git_check()` and `capture_git()` — no shell exposure.
- **(b) Git output handling**: `list_changed_files` uses `--name-only -z` + `split /\0/`; widening the diff range doesn't affect NUL-separation.
- **(c) Prompt injection**: no LLM-bound strings introduced; `, includes uncommitted` is a fixed literal.
- **(d) Env vars**: no new env-var refs.
- **(e) Pattern-based**: the widened window is safe at this callsite (helper's purpose is emitting all potentially-relevant changes for review); the change is documented in the comments; no callsite invariant dependency.

Human-review summary: no code action required from this review. The fix is the security review subagent's first opportunity to review uncommitted work on the helper itself — and it did so successfully. Counts as both the bug fix and its own validation.

## Lessons Learned
*To be captured during retrospective*
