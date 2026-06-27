# classify auto-discover review outputs - Retrospective
**Task**: 214 (chore)

## Task Reference
- **Task ID**: internal-214
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/214-classify-auto-discover-outputs
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-27

## Executive Summary
- **Duration**: ~0.5 day (estimated: ~0.5 day, variance: ~0%)
- **Scope**: Delivered exactly as planned — additive `--dir`/`--phase` discovery mode on `security-review-classify`, with the stdin contract byte-identical. No scope creep, no descope.
- **Outcome**: Success. The exec skills now classify all reviewer outputs in one allowlist-matching invocation, removing the per-file shell loop whose `$var` redirect triggered a blocking permission prompt on every exec run. The feature was dogfooded in this very task's f- and g-phase reviews with no prompt.

## Variance Analysis
### Time and Effort
- **Estimated**: Implementation ~0.3 day, Testing ~0.2 day (chore — no requirements/design/rollout).
- **Actual**: Close to estimate. One helper edit, two SKILL edits, two doc edits, a hash refresh, and seven new test cases — all single-session.
- **Variance**: Negligible. Low complexity as scoped; the additive-only design kept blast radius small.

### Scope Changes
- **Additions**: None beyond plan. The unknown-flag regression test (TC-D6c) was already anticipated in the plan as pinning a previously-uncovered rejection.
- **Removals**: None.
- **Impact**: None.

### Quality Metrics
- **Test Coverage**: Both modes' success paths and every named edge case pinned — stdin regression (TC-C1..C14), discovery happy-path/order, phase scoping (incl. `-changeset-` exclusion), zero-match, symlink/non-regular skip, per-file open failure, all arg errors. 30 assertions in the helper suite; 931 across `t/`.
- **Defect Rate**: 0. The only transient red was the four integrity tests before the same-commit hash refresh — expected behaviour, not a defect.
- **Performance**: N/A (single readdir + per-file slurp; trivial).

## What Went Well
- **Single-parser invariant held cleanly.** Extracting the block-walk verbatim into `classify_text()` let both modes share one parser — the Task-162 "no drift" guarantee survived unchanged, and the security/robustness reviewers both confirmed it.
- **Byte-identical stdin path.** The SubagentStop guard hook and single-file callers needed no change; the regression cases prove it.
- **Dogfooding caught nothing because nothing was wrong — but proved the point.** Both exec phases used the new discovery mode for their own Step-8 classification under the live allowlist with no permission prompt, which is the strongest possible acceptance evidence for the task's core motivation.
- **Plan review paid off.** The pre-exec d-phase review had already surfaced the `-f && ! -l` symlink subtlety and the single-pass capture; exec just executed them.

## What Could Be Improved
- **Interface symmetry with the sibling helper.** Two exec reviewers (improvements, misalignment) independently flagged that the new `--dir`/`--phase` interface diverges from its matched-pair sibling `security-review-changeset`, which takes `--wf-step` (validated against the canonical step allowlist) and derives the scratch dir itself via `CWF::Common::scratch_dir()`. The divergence is deliberate and documented (read-only helper, single literal argv for the allowlist), and the user accepted it to proceed — but it is a genuine inconsistency worth a conscious follow-up rather than silent acceptance. Captured as a backlog item below.

## Key Learnings
### Technical Insights
- A consumer that reads a producer's output files is a natural place to reuse the producer's path-derivation abstraction (`scratch_dir()`). Choosing a caller-supplied `--dir` instead keeps the helper read-only and SKILL-driven, but pushes path derivation into SKILL prose — a real maintainability trade, not a free choice.
- `\Q$phase\E` quoting in the discovery regex is load-bearing, not incidental: it keeps the match safe even if a future caller passes a less-constrained phase string.

### Process Learnings
- The same-commit hash refresh produces a transient four-test integrity failure if the full suite is run before the refresh. Refresh the hash immediately after the hashed-file edit, in the same step, to avoid a misleading red.
- Recording each reviewer's verbatim output to its `<reviewer>-review-output-<phase>.out` and classifying the whole directory in one call is materially smoother than the per-file loop — both for the permission surface and for the launched-vs-classified cross-check.

### Risk Mitigation Strategies
- The additive-only design (stdin default unchanged, discovery strictly opt-in via flags) made the backward-compatibility risk (Risk 1) a non-event — the regression assertions are the proof.

## Recommendations
### Process Improvements
- When editing a hash-tracked file, do the hash refresh in the same edit batch before running the full suite, so integrity tests never flash red mid-task.

### Tool and Technique Recommendations
- Continue the "write each reviewer output to a phase-scoped `.out`, classify the directory in one invocation" pattern; it is now the standard exec Step-8 shape for both implementation-exec and testing-exec.

### Future Work
- **Optional alignment follow-up**: a `--task-num` form of discovery mode that reuses `CWF::Common::scratch_dir()` and shares the sibling's `--wf-step` parameter name, letting the helper (not SKILL prose) own the scratch path and validate the step against the canonical allowlist. Deliberately deferred; see BACKLOG.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-27
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan: a-task-plan.md, d-implementation-plan.md, e-testing-plan.md
- Execution: f-implementation-exec.md, g-testing-exec.md
- Commits: `3481a69` (f), `81a898e` (g); checkpoints branch preserves per-phase history.
- Tests: `t/security-review-classify.t` (30 assertions), full suite 931.
