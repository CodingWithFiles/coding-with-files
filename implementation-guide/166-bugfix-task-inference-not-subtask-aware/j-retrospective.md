# task inference not subtask-aware - Retrospective
**Task**: 166 (bugfix)

## Task Reference
- **Task ID**: internal-166
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/166-task-inference-not-subtask-aware
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-28

## Executive Summary
- **Duration**: single session (estimate ~1 day, Medium complexity). On estimate.
- **Scope**: Full D1+D2+D3 — delegate task-path parsing to `CWF::TaskPath` (D1); recency/progress signals enumerate `{T} ∪ find_descendants(T)` (D2); `correlate_signals` gains the deterministic 8-step ancestry-collapse predicate (D3). D4 items (worktree-regex extension, subtask branch convention, `CWF::Backlog` directory-scan refactor, state-signal refactor, performance) deliberately out of scope. No descope.
- **Outcome**: Success. The canonical `{branch: 28, recency: 28.2, progress: 28.2}` signal set now collapses to `correlated, chosen_task: 28.2` rather than emitting `inconclusive, task_nums: 28,20`. Test suite grows from 11 to 19 subtests (the 8 new are bound 1-to-1 to c-design-plan §Validation bullets); full `prove -r t/` runs 618 tests, all pass. `cwf-manage validate` clean. Hash refresh landed in the same commit as the source edit per [[hash-updates]].

## Variance Analysis
### Time and Effort
- **Estimated**: ~1 day, Medium complexity. Phase-level estimates not broken out in a-task-plan.
- **Actual**: one continuous session across a–j. Planning (a,c,d,e) was the larger share — the map/reduce design and implementation reviews materially reshaped the plans (8-step D3 predicate, pure correlator, `resolve_branch` adoption, deferred enumerator promotion). Exec (f,g) was mechanical: bottom-up edits in the order the implementation plan listed, ~10 Edit calls, then a clean test pass on first run.
- **Variance**: within estimate. Front-loaded plan-review investment is again the reason exec had near-zero rework.

### Scope Changes
- **Additions**: none beyond the plans.
- **Removals**: none. D4 items were never in scope; their out-of-scope status is recorded in c-design-plan and not revisited.
- **Impact**: the security-review changeset (543 lines) exceeded the 500-line cap, as it would on any change carrying its own test suite. Maintainer authorised invoking the reviewer anyway; verdict was `no findings`. Surfaced a follow-up Medium-priority backlog item: cap should weight production code, not test scaffolding.

### Quality Metrics
- **Test Coverage**: 8 new subtests (TC-1..TC-6, TC-8a, TC-8b) added to `t/taskcontextinference.t`; TC-7 covered by the existing top-level baseline subtest. 19/19 subtests pass focused; 618/618 full suite passes. Every c-design-plan §Validation bullet is bound to a concrete subtest in e-testing-plan and exercised in g-testing-exec.
- **Defect Rate**: zero rework in exec. The Step 5 grep description in d-implementation-plan was slightly inaccurate (claimed state-file regex matches `(\d+)` literally — it doesn't; the worktree line matches instead, which is deliberately preserved per D4). Substantive scope contract upheld. Documented as a deviation note in f-implementation-exec.md.
- **Performance**: not benchmarked. The enumeration widening (was ~150 top-level scan; now ~150 + descendants × depth) is bounded by recursive `glob` calls in `find_descendants`. No observable change in `prove -r t/` wall-clock (~30s).

## What Went Well
- **Reuse over duplication, all the way down.** Once the c-design-plan review confirmed that `CWF::TaskPath` already implements every needed primitive (`parse_branch`, `resolve_num`, `find_descendants`, `find_ancestors`, `get_depth`), the implementation pivoted from "fix the regexes in TaskContextInference" to "delete the regexes and delegate." Net code reduction; `_get_task_dir` and `_get_task_slug` both gone outright.
- **The branch-signal "bug" turned out to be correct.** Verified Assumption 1 (subtasks share parent's branch — `/cwf-new-subtask` creates a directory only, never `git checkout -b`) reframed the defect. The branch signal returning `28` for active `28.2` is *consistent with* the subtask being active, not in conflict with it. The fix moved from regex-loosening to ancestry-collapse in the correlator, which is the right shape.
- **The 8-step D3 predicate is mechanical.** Spelling out the algorithm exhaustively in c-design-plan (steps 1–8 with explicit edge cases for ties, stale references, orphaned subtasks) meant the Perl implementation was a transliteration. Each of TC-1..TC-6 binds to one D3 step (or one edge case), so failures would localise to a single rule.
- **Plan review pruned drift.** Drafts proposed broader changes (worktree-regex extension, `chosen_resolved` field on correlator return, double-resolve of task num in `_infer_workflow_step`); the map/reduce reviews removed all of them. The correlator stays pure (no return-shape change); the worktree regex stays untouched (D4); `_infer_workflow_step` now takes `$task_dir` directly.

## What Could Be Improved
- **The 500-line security-review cap weighs the wrong thing.** A change carrying its own tests will routinely exceed 500 lines of diff even when the substantive code is well under 200. Maintainer override worked but felt like working around the tool rather than with it. Captured as a Medium-priority backlog chore.
- **Plan-time grep descriptions can drift from reality.** d-implementation-plan Step 5 claimed `git grep -nE '\(\\d\+\)'` should match the state-file line; in reality the state-file regex is `(\d+(?:\.\d+)*)` and doesn't match the literal `(\d+)` pattern — the grep flagged the worktree line instead (deliberately preserved per D4). The grep was a safety net, not the contract; the substantive constraint ("no bare `\d+` in the branch signal") held. Still: when a plan asserts "this grep will return only X", verify the grep against reality before recording.

## Key Learnings
### Technical Insights
- A correlator over candidate sets should be *pure*. Resolution and disk-state queries happen at the caller boundary; the correlator's signature is `\@signals → \%result` and stays that way. This kept the new D3 predicate composable with the existing test fixtures (string-equality assertions on top tasks) without forcing a return-shape change.
- `find_ancestors` gating on `task_exists` (TaskPath.pm:447-459) is exactly the right shape for the orphaned-subtask edge case. A subtask whose parent dir is missing produces an empty ancestor set, which causes D3 step 7 to fail and the result falls to uncorrelated — graceful degradation, not an exception.
- Tempdir + cwd discipline in tests: capture cwd *before* the `eval`, `chdir` back unconditionally, do it inside the subtest (not in an END block). `File::Temp::tempdir(CLEANUP => 1)` registers a destructor that `rmtree`s the dir; if cwd is still inside it at scope exit, some platforms surface ENOENT. All 8 new subtests follow this shape.

### Process Learnings
- For a one-defect-one-fix task, the security-review cap will trip on the unified-diff line count even when the change is genuinely cohesive (single commit by D5). The right response is to surface, not split — the cap is informational on changes of this shape, not a gate.
- "Plan grep" descriptions are heuristic verifications, not contracts. Treat the substantive scope statement (e.g. "no bare `\d+` parsing in the branch signal") as authoritative; if the grep flags a different line, prove the substantive contract holds and record the deviation. Don't rewrite the grep to match what you want it to say.

### Risk Mitigation Strategies
- D1+D2+D3 sequenced as a single commit (per D5) keeps the change atomic. None of the three is independently shippable (D2 without D3 just trades one inconclusive case for another; D1 without D2/D3 changes nothing observable). The single-commit constraint is the design's response to that interdependence.
- Hash refresh in the same commit as the source edit ([[hash-updates]]) is the standard discipline. Documented inline in d-implementation-plan; executed in f-implementation-exec; verified by `cwf-manage validate` post-checkpoint.

## Recommendations
### Process Improvements
- When a task asserts a plan-time grep result, derive it by running the grep against the current code, not by inspection. The d-implementation-plan grep was a small process leak that didn't bite — but on a more sensitive contract it could.

### Tool and Technique Recommendations
- Backlog item submitted (Medium chore): *security-review-changeset cap should weight production code, not test scaffolding*. Identified in this task's f-implementation-exec surfacing.

### Future Work
- **Promote `_enumerate_all_tasks` into `CWF::TaskPath`**: the existing Low-priority backlog item *Unify implementation-guide directory-scan helpers across `CWF::Backlog` and `CWF::TaskContextInference`* now has a clearer landing point — fold the top-level loop here in with the identical loop in `CWF::TaskPath::find_siblings` and `CWF::Backlog`. This task partially executed the convergence for `TaskContextInference`; the full sweep remains separate.
- **Reconsider the `task[_-]?(\d+)` worktree regex** if/when a decimal-worktree convention emerges (D4 placeholder).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-28
**Sign-off**: Task 166 (CWF maintainer)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, c-design-plan.md, d-implementation-plan.md, e-testing-plan.md
- Execution: f-implementation-exec.md (security-review verdict embedded), g-testing-exec.md
- Checkpoint commits preserved on the task's checkpoints branch (see Step 10)
- Tests: `t/taskcontextinference.t` (8 new subtests appended; full file 19 subtests)
