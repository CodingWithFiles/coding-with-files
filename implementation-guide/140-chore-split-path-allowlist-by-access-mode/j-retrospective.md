# Split path-allowlist by access mode - Retrospective
**Task**: 140 (chore)

## Task Reference
- **Task ID**: internal-140
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/140-split-path-allowlist-by-access-mode
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-16

## Executive Summary
- **Duration**: ~0.5 day (single session, estimate matched)
- **Scope**: As planned, with one explicit deferral decided at d-plan time (temp variant) and two minor exec-time deviations (test placement, hash-update mechanism) — both documented in f-implementation-exec.md.
- **Outcome**: The two-function split shipped. `backlog-manager --body-file` now accepts any readable path; the prior allowlist friction (which had already pushed Task 136 to bypass the helper) is gone. The write-side semantics for `cwf-apply-artefacts` and `cwf-claude-settings-merge` are byte-identical to the prior behaviour — verified by verbatim function-body copy plus full regression green.

## Variance Analysis

### Time and Effort
- **Estimated** (a-task-plan.md): 0.5 day, Low complexity.
- **Actual**: 0.5 day (single session, six phase commits + one source-code commit).
- **Variance**: ~0%. The scope was well-bounded by the BACKLOG entry; no expansion during exec.

### Scope Changes
- **Removals (planned)**: `validate_temp_path_allowlist` deferred at d-plan time. Confirmed during plan-review by grepping the two candidate callers (`cwf-checkpoint-commit`, `security-review-changeset`) — neither writes Perl-side temp files today. Adding the function with zero callers would be dead code. The original BACKLOG entry stays open; if a future caller materialises, the function can be added on the same `CWF::ArtefactHelpers` pattern.
- **Removals (exec-time)**: None.
- **Additions (exec-time)**:
  - Help-text update at `backlog-manager:131` (was "repo-relative path; outside-repo paths rejected"). Caught by the plan-review subagent — would have shipped stale otherwise.
  - Removal of the redundant `-f $path` follow-up in `backlog-manager` after the new validator already enforces it. Listed in d-plan after plan-review, executed in f-exec.

### Quality Metrics
- **Test count**: 472/472 passing (full `prove t/`). 16 new test assertions across `t/artefacthelpers.t` (write × 6, read × 5) and `t/backlog-manager.t` (4 new subtests). The total stayed at 472 because the old `validate_path_allowlist` test block (7 assertions) was removed in the same change.
- **Defect rate**: 0 — no test failures, no rework loops.
- **Orphan-symbol guard**: `grep -rn validate_path_allowlist .cwf/ t/ docs/ .claude/` → 0 hits.
- **Manifest integrity**: `cwf-manage validate` → OK after hand-updated SHAs.
- **Manual smoke**: `add` then `delete` against live BACKLOG using a `/tmp/...` body file — `BACKLOG.md` restored byte-for-byte.

## What Went Well
- **Verbatim function-body copy** for `validate_write_path_allowlist`. The risk of "did we accidentally weaken the write-side checks?" was eliminated by copying line-for-line, not rewriting. This let the security review focus on the *new* read validator without re-litigating the old one.
- **Plan review caught two real defects** the LLM-written plan had missed: the stale `--body-file` help text, and the implicit removal of the `-f $path` follow-up. Both would have shipped silently. Map/reduce plan review continues to earn its keep on plans this small as well as the larger ones.
- **Inline test placement decision**. The d-plan said "extract to shared module on rule-of-three; otherwise copy". At exec time the count was 2 sites; the cleanest move was neither — add subtests to the file that already has the helpers. f-exec recorded the deviation with rationale.
- **Hash-update friction working as designed**. `fix-security` refused to rewrite SHAs (Task-135 anti-smoothing policy). The friction did what it was supposed to: forced me to think about *why* the hashes had drifted and copy the four computed values by hand. The memory note `feedback_surface_security_dont_smooth.md` was exactly the right context to recall.

## What Could Be Improved
- **Security-review subagent failed sentinel-first formatting on both exec phases**. f-exec and g-exec each got an explicit, escalating warning that the first line must be a sentinel; both subagents emitted preamble first and the verdict last. Both were classified `error` per the conservative-default tier rather than letting tier-2 numbered-list detection mis-flag them as `findings`. This is the third+ task to hit this; the existing BACKLOG entries "Enforce sentinel-first output in security-review subagent prompt" and "Tighten security-subagent prompt for sentinel-line compliance" are *not* speculative — they are confirmed prompt-engineering defects with a 100% miss rate on this task. Recommend bumping their priority.
- **`security-review-changeset` blind to uncommitted work bit again** (Task 137, 138, 139 retros also flagged this). The recovery — commit code first under a non-checkpoint message, then re-run the helper, then do the checkpoint commit with only the wf file — works but it's a two-commits-per-phase shape that doesn't compose well with the squash flow. The BACKLOG entry "security-review-changeset blind to uncommitted work" needs to be resolved; this is now the fourth task in a row to trip on it.
- **No deviation from "every step must be checkpoint-committed immediately"**, but I notice the temptation to batch when phases are mostly Edit calls. Worth keeping the immediate-commit reminder loaded.

## Key Learnings

### Technical Insights
- **The "split a multi-purpose helper" pattern reduces ceremony at the call site and clarifies the threat model.** `validate_read_path_allowlist($path)` is one argument instead of two, the call site needs no inline prefix list, and the function's docblock now states the threat model it actually defends against (rather than the union of all callers' threat models, which is what the original function implicitly carried).
- **`-r _` (chained file-test against the cached stat) avoids a second `stat(2)` after `-f $path`**. Small, but the implementation plan and the plan-review subagent both caught this and the resulting function uses one `stat` call.
- **The d-plan deferral mechanism (move scope to a follow-up BACKLOG entry instead of force-fitting) avoided dead code**. Grep-against-candidate-callers is cheaper than "design the function and hope someone uses it later."

### Process Learnings
- **Plan-review value scales down well**. Even on a one-day chore, the four-subagent map/reduce found two concrete plan defects. Both fixed in <60 seconds. Continue running plan-review on chores.
- **Memory recall on day-one of the conversation paid off twice**: (1) `feedback_surface_security_dont_smooth.md` immediately framed the `fix-security` refusal as "the friction is the feature, not a tooling bug" — no time lost looking for a recompute flag. (2) `feedback_avoid_merge_commits.md` plus the checkpoint-commit-then-re-run-security pattern from Task 139 retro put the security-review chicken-and-egg on rails.

### Risk Mitigation Strategies
- **Verbatim copy as a security-equivalence proof**. When refactoring a security-relevant function, copying the body byte-for-byte under a new name is a stronger guarantee than reviewing the diff. Then the diff a reviewer must check is "is the new caller's threat model the one the function defends?" — a much narrower question than "did the refactor preserve every defensive check?"

## Recommendations

### Process Improvements
- **Bump priority on the two sentinel-format BACKLOG items** ("Enforce sentinel-first output in security-review subagent prompt" + "Tighten security-subagent prompt for sentinel-line compliance"). At least one of them should move from Low to Medium given the 100% miss rate on this task across both exec phases. Possibly consolidate them into one task.
- **The "security-review-changeset blind to uncommitted work" BACKLOG item is now blocking smooth exec on a fourth consecutive task** (137, 138, 139, 140). Bump from Low to High and pick it up before another retrospective records the same complaint.

### Tool and Technique Recommendations
- None new. Continue the existing patterns.

### Future Work
- `validate_temp_path_allowlist` remains on the BACKLOG. When a Perl-side temp-file caller appears (most likely candidate: a future refactor of `security-review-changeset` to emit a temp file rather than stdout), revisit and add the function then. No action required now.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-16
**Sign-off**: Task 140 — split-path-allowlist-by-access-mode

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- `implementation-guide/140-chore-split-path-allowlist-by-access-mode/a-task-plan.md`
- `implementation-guide/140-chore-split-path-allowlist-by-access-mode/d-implementation-plan.md`
- `implementation-guide/140-chore-split-path-allowlist-by-access-mode/e-testing-plan.md`
- `implementation-guide/140-chore-split-path-allowlist-by-access-mode/f-implementation-exec.md`
- `implementation-guide/140-chore-split-path-allowlist-by-access-mode/g-testing-exec.md`
- Source-code commit: `bad1e77` ("Task 140: Split path-allowlist into write/read variants")
- Test coverage: `prove t/` 472/472 (post-task), see g-testing-exec.md
