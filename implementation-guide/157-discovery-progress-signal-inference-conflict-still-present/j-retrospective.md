# Progress-signal inference conflict still present - Retrospective
**Task**: 157 (discovery)

## Task Reference
- **Task ID**: internal-157
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/157-progress-signal-inference-conflict-still-present
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-23

## Executive Summary
- **Duration**: single session (estimated <1 day, Low complexity). On estimate.
- **Scope**: Unchanged. Bounded to the specific backlog claim about `_score_progress`; no broader inference-system review.
- **Outcome**: Question answered conclusively. The reported conflict does **not** reproduce on current code. The backlog premise is a **misread**: `_score_progress` receives post-cliff work potential, not raw completion, so a correctly-finished task scores 0 and is filtered out before candidate selection. Backlog item retired; a Low clarity-only chore filed for the misleading naming that invited the misread.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day total (discovery; phases a–g + j).
- **Actual**: single session, on estimate. No phase materially over- or under-ran.
- **Variance**: None significant.

### Scope Changes
- **Additions**: None to the discovery itself. One unrelated Very High backlog item (cwf-manage records a ref instead of a resolved semver in `cwf_version`) was filed mid-task from a user log and folded into the f-phase commit — orthogonal to this investigation.
- **Removals**: None.
- **Impact**: None on timeline.

### Quality Metrics
- **Test Coverage**: TC-1..TC-6 all PASS; three of four `state_achievable` branches exercised (CLIFF, FRESH, ACTIVE); DORMANT/BLOCKED out of scope (not load-bearing for a *finished*-task question).
- **Defect Rate**: N/A (no behaviour change). The "defect" under investigation was found not to exist on current code.
- **Performance**: N/A.

## What Went Well
- **Two-level evidence caught the right thing.** The static trace proved the exclusion deductively; the executable probe (calling the real `state_achievable` / `_score_progress` / `_get_progress_signal`) confirmed it empirically against a synthetic tree. The integration level is the only one that exhibits the reported symptom (candidate-list assembly + `top`), and it showed the finished task absent.
- **The parse-success guard earned its place.** Asserting `state_done(201)==100` before trusting the candidate list ruled out a false-confirm where a malformed fixture (missing `## Status` heading → "Unknown" → empty statuses → 0) would have excluded `201` for the wrong reason. Without it, the verdict would have rested on an ambiguous signal.
- **Determinism check was cheap and conclusive.** Re-running the probe byte-identically settled NFR5 in one command.
- **Plan review corrected a real error before exec.** The design initially cited `find_git_root()` and a "chdir → defaults fallback" that cannot fire (process-lifetime config cache); reviewers caught both. The corrected reasoning (outcomes are config-source-independent because real config is byte-identical to defaults for the keys used) is what made the empirical step trustworthy.

## What Could Be Improved
- **The original report conflated a label with a computed value.** "Task 103 (100%/Finished)" was taken as "computed completion 100%". The two diverge precisely when a task is mislabelled Finished while a step is non-terminal — which is the system's purpose-#2 diagnostic, not noise. The retrospective records this distinction so it is not re-filed.
- **Stale comment + misleading parameter name invited the misread.** `$percentage` (`TaskContextInference.pm:447`) actually carries post-cliff work potential, and the `:410` "bell curve, peak at 50%" comment describes an algorithm that isn't there. Source that misdescribes itself is a latent bug-report generator. Filed as a clarity chore.

## Key Learnings
### Technical Insights
- **`{code} != {purpose}.** The scoring chain's intent is "momentum among live tasks, abstain when unsure", and `inconclusive` is *diagnostic* (it can mean a prior task was left in an incorrect state), not mere abstention. Reading `_score_progress` in isolation — without the upstream cliff (`TaskState.pm:150`) and the downstream zero-filter (`TaskContextInference.pm:418`) — produces exactly the wrong conclusion the backlog item reached.
- **The cliff + zero-filter are the real guarantee.** A correctly-finished task (all steps terminal → `state_done` 100) is forced to work potential 0 and dropped before candidate assembly. It cannot be `top`, cannot dissent, cannot drive an inconclusive. A "finished" task that *does* surface is therefore evidence it is not correctly finished — the alarm working as designed.
- **Why the original Task 104 observation could occur yet not reproduce now**: either it predates the current cliff implementation, or Task 103 was not in fact fully closed (a non-terminal step kept it live and legitimately a candidate). Both are consistent with current code excluding correctly-finished tasks; the discovery's question ("does it still reproduce?") is answered: no.

### Process Learnings
- **For a discovery, the deliverable is falsifiable evidence.** Defining up front what output *would* have shown the premise to hold (the finished task surviving as a candidate) and showing it did not occur is stronger than asserting "the code looks right".
- **Read-only discipline held.** No `.cwf/**` file was touched; all artefacts stayed in the project-namespaced scratch dir. Any clarity fix is a separate task with an in-commit hash refresh.

### Risk Mitigation Strategies
- Driving the real functions against a fixture (rather than reasoning only from source) mitigated the "premise true at a boundary" risk identified in a-task-plan; the boundary cases (FRESH, ACTIVE) were observed directly.

## Recommendations
### Process Improvements
- When triaging a "scoring favours X" bug, trace the *input* to the scoring function before trusting its body — the misleading value here entered two subs upstream.

### Tool and Technique Recommendations
- The parse-success guard pattern (assert the fixture parsed as intended before trusting a downstream observation) is worth reusing in any fixture-driven probe where a parse failure could masquerade as the expected result.

### Future Work
- **Clarity-only chore (filed, Low)**: rename `$percentage` → a work-potential name in `_score_progress` (`TaskContextInference.pm:447`) and delete the stale "bell curve, peak at 50%" comment (`:410`). No behaviour change. `TaskContextInference.pm` is hash-tracked, so the fix carries a same-commit `script-hashes.json` refresh.
- **Unrelated, already filed (Very High)**: cwf-manage records a ref in `cwf_version` instead of the resolved semver.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-23
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning/design/evidence: `a-task-plan.md` … `g-testing-exec.md` in this task directory.
- Scratch fixture + probe (throwaway): `/tmp/-home-matt-repo-coding-with-files-task-157/` (`probe.pl`, `probe.out`).
- Commits: f-phase `dbb3b90`, g-phase `5ebe54c` (pre-squash).
