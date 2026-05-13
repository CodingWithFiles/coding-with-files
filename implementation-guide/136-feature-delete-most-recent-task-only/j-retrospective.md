# Delete most-recent task only - Retrospective
**Task**: 136 (feature)

## Task Reference
- **Task ID**: internal-136
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/136-delete-most-recent-task-only
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-13

## Executive Summary
- **Duration**: ~1 working day (estimate: 1-2 days; variance: at or below low end)
- **Scope**: Final scope matched the plan exactly — one helper + one skill + one TaskPath export + hash registration + CLAUDE.md entry. No additions, no removals.
- **Outcome**: Success. `/cwf-delete-task` works, refuses every case it's supposed to refuse, recovers from partial state, and passes integrity validation. One real bug caught in smoke test (self-worktree exclusion); fixed and re-verified before commit.

## Variance Analysis
### Time and Effort
- **Estimated**: 1-2 days end-to-end, low complexity (single concern, refusal-enumeration driven).
- **Actual**: ~1 day across 10 phase commits. The "expensive" phases were design (10 refusal checks needed enumeration) and implementation-exec (smoke-test caught the self-worktree bug). The "cheap" phases were rollout and maintenance (no service to deploy, no monitoring to wire).
- **Variance**: At the optimistic end of the estimate. The refusal-list-driven design paid off — implementation was largely "translate enumeration into code" with no surprises.

### Scope Changes
- **Additions**: None.
- **Removals**: None.
- **Impact**: None — the plan held.

### Quality Metrics
- **Test Coverage**: 28 functional + 2 non-functional cases; one functional case (TC-FR8b) caught a real test-setup bug, not a code defect; root-caused and re-run successfully. All passed.
- **Defect Rate**: 1 implementation defect caught pre-commit (self-worktree exclusion in check 7) by smoke test. 0 defects escaped to commit.
- **Security findings**: 2 pattern-based findings at implementation phase (both safe-here, recorded for audit). 1 false-positive at testing phase (`-CDSL` shebang) rebutted with the actual PerlConventions rule.

## What Went Well
- **Refusal-list-driven design**. Enumerating the 10 checks during c-design-plan made implementation mechanical and made testing exhaustive — every refusal case had an explicit test.
- **Hoisting check 6 (branch-name format) out of cleanup**. Original design put it inside cleanup A; moving it to the pre-cleanup phase means a malformed name cannot trigger partial-state — a one-line code change that meaningfully simplified the cleanup contract.
- **Self-worktree exclusion bug caught in smoke**. The very first end-to-end run inside a disposable worktree refused to delete its own task — exactly the case cleanup step A handles. Caught and fixed before commit; would have shipped otherwise.
- **Idempotent cleanup A–E**. Re-running after partial state completes cleanup. Tested explicitly via TC-CLN1..CLN5. This is the right shape for a destructive CLI: leaning into recovery rather than transactions.
- **Refuting the testing-phase security-review false positive correctly**. Read `PerlConventions.pm` directly, identified the conditional ($PATH_CMDS) the agent missed, recorded the rebuttal in g-testing-exec.md. Did not capitulate to a confidently-worded but wrong finding.

## What Could Be Improved
- **Security-review-changeset helper at implementation phase emitted empty changeset**. The helper diffs `anchor..HEAD` (committed only); my work was uncommitted at step 8. Workaround used (`git add -N` + manual `git diff`) but the helper's contract should make this case visible (warn? exit non-zero?) instead of silently returning empty.
- **TC-FR8b first-pass FAIL was test-setup, not code defect**. The original test setup tripped check 4 (most-recent) before reaching check 10 (stack). The test plan should have called out that "exercise check N" tests need to bypass checks 1..N-1; this is a generic shape worth capturing for future refusal-pipeline tests.
- **The h-rollout and i-maintenance templates contain large vestigial sections** for tools like this (no service, no users, no telemetry). Most lines collapse to "N/A". Worth considering a `chore`/`internal-feature` template variant that drops monitoring/alerting/scaling sections entirely.

## Key Learnings
### Technical Insights
- **Per-worktree exclusion**: `git worktree list --porcelain` emits the current worktree alongside others. For "refuse if checked out elsewhere" semantics, compare each entry's `abs_path` against the helper's own `git rev-parse --show-toplevel` to skip self.
- **`File::Path::remove_tree` with `safe => 1`**: refuses to follow symlinks and refuses to delete files we don't own. The right primitive for symlink-bearing template trees.
- **NUL-separated `git log -z --format='%H%x00%s'`**: clean way to pair commit SHAs and subjects without subject-collision risk. `split /\0/` then walk in pairs.
- **`branch_exists` check before `git branch -D`**: cheap and makes step idempotency trivial.
- **Hoisting validation out of destructive blocks**: the check-6 lesson — anything that could refuse should refuse *before* any cleanup state mutation, not inside it.

### Process Learnings
- **Refusal pipelines benefit from enumeration in design**. Writing the 10 checks as a list (with rationale per check) made implementation mechanical and made the test matrix obvious.
- **Smoke-test before commit catches the "design-correct, implementation-wrong" class** — the self-worktree exclusion was correct in design but missed in code until a real `delete` was attempted from inside the worktree it was meant to handle. Smoke tests are cheap insurance.
- **A confidently-worded agent finding is not authoritative**. The testing-phase agent flagged `-CDSL` as a "non-negotiable" violation; the actual rule in `PerlConventions.pm` is conditional. Always read the validator source when disputed.

### Risk Mitigation Strategies
- **Idempotent cleanup converts a "partial-state" risk into "re-run the same command"**. This was identified in design and held up under tests.
- **`--force` for unmerged-work-loss only** (not FR3/4/5/7/8). Bounding `--force`'s scope tightly is what makes it safe; an over-broad `--force` would defeat the refusal pipeline.
- **Hand-recorded baseline SHA in `a-task-plan.md` (FR6)**. The anchor for "what counts as new work" lives in a file the user owns, not a heuristic in the helper. If the user wants the helper to refuse, they damage the anchor; if they want it to allow, they ensure the anchor is correct. Refuse-on-malformed is conservative-default-correct.

## Recommendations
### Process Improvements
- When designing test cases for a refusal pipeline, explicitly note which earlier checks each case must bypass. Add this as a template note in e-testing-plan.md for future refusal-heavy tasks.
- Consider a "smoke-test before checkpoint commit" step in f-implementation-exec for any task whose primary deliverable is a destructive CLI helper.

### Tool and Technique Recommendations
- **`security-review-changeset --phase=...`**: improve behaviour when changeset is empty due to uncommitted work — at minimum, log a hint pointing to `git add -N` + manual diff workaround.

### Future Work
- Consider an `internal-feature` template variant with collapsed h-rollout/i-maintenance sections, for tasks whose deliverable is a local CLI helper with no service surface.
- Consider letting `/cwf-delete-task` accept the topmost-stack entry as a synonym for "most-recent" (so `cwf-delete-task` with no args = "delete what's currently on top"). Not in this task's scope — would need its own FR set.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None
**Completion Date**: 2026-05-13
**Sign-off**: Maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Implementation: `.cwf/scripts/command-helpers/task-workflow.d/delete` (~340 lines)
- Skill: `.claude/skills/cwf-delete-task/SKILL.md`
- Wiring: `.cwf/scripts/command-helpers/task-workflow` (dispatcher), `.cwf/lib/CWF/TaskPath.pm` (added `version_compare` export)
- Integrity: `.cwf/security/script-hashes.json` (new entry for `task-workflow.d/delete`; refreshed entries for `task-workflow` and `CWF/TaskPath.pm`)
- Documentation: `CLAUDE.md` Core Skills list
- Checkpoints: `feature/136-delete-most-recent-task-only-checkpoints` (created at Step 10)
