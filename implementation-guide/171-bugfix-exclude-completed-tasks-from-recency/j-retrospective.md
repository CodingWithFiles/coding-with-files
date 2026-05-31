# exclude-completed-tasks-from-recency - Retrospective
**Task**: 171 (bugfix)

## Task Reference
- **Task ID**: internal-171
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/171-exclude-completed-tasks-from-recency
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-31

## Executive Summary
- **Duration**: ~1 day (estimated <1 day; on target)
- **Scope**: Unchanged from plan — single guard line in `_get_recency_signal`
  plus two regression tests. No additions, no descopes.
- **Outcome**: Success. The `recency` task-candidate signal now passes its
  candidates through the existing `CWF::TaskState` work-potential framework, so
  completed (100%) tasks can no longer be nominated as the current task. This
  removes the reported false `uncorrelated` / `candidates: 2` results where a
  recently-touched finished task disagreed with `branch`/`progress`.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day (Planning/Design/Impl/Testing all small).
- **Actual**: ~1 day. Plan phases (a/c/d/e) drafted and reviewed first, then a
  single exec pass (f/g). No phase overran.
- **Variance**: None material. The design phase absorbed the only real thinking
  (predicate choice), which is where a bugfix of this shape should spend it.

### Scope Changes
- **Additions**: None.
- **Removals**: None. The d-plan deliberately reduced the change from the
  a-plan's "add `state_achievable` to the import" to a single fully-qualified
  `state_done` call with no import edit — a reduction in blast radius, not a
  scope cut.
- **Impact**: One-line production diff; smaller than the original framing.

### Quality Metrics
- **Test Coverage**: TC-9 (regression, completed task excluded) + TC-10
  (boundary, live/fresh task retained). Inference file 19→21 subtests; full
  suite 634→636 tests, all green.
- **Defect Rate**: Zero defects found post-implementation. TC-9 was proven
  load-bearing (fails on the unpatched module, returning the completed task
  `'41'`; passes patched).
- **Performance**: One extra `state_done` call per task dir — the same per-dir
  cost the adjacent `progress` signal already pays. Negligible.

## What Went Well
- **Reuse over invention**: the user's prompt ("don't we have a work-potential
  framework?") steered the fix straight to `CWF::TaskState`. `recency` was the
  one task-candidate signal not already gated through it; closing that gap fixed
  the root cause rather than papering over a symptom.
- **Design-time predicate analysis caught a latent test break**: reading the
  existing TC-8a/TC-8b fixtures during design revealed that the intuitive
  `state_achievable == 0` predicate would over-filter (those fixtures have no
  status markers → `state_achievable == 0` → every dir filtered). Switching to
  `state_done >= 100` — which returns 0 for no-status dirs — preserved them.
- **Plan reviews earned their keep**: the misalignment reviewer flagged the
  module's existing fully-qualified `TaskState` call precedent (`:519`),
  collapsing the change to one line with no import edit; the robustness reviewer
  flagged that a naive copy-paste fixture (bare `"x"` files) would pass without
  the fix, which became the load-bearing `_write_status` requirement.
- **Pre-fix failure verification**: temporarily removing the guard and watching
  TC-9 turn `not ok` proved the test reproduces the defect, not just the fix.

## What Could Be Improved
- **a-plan / c-plan predicate drift**: the a-task-plan was written around
  `state_achievable == 0` before the design phase corrected it to
  `state_done >= 100`. The a-plan's success criteria still name the old
  predicate. Acceptable as workflow archaeology (plans are point-in-time), but a
  reader skimming a-plan in isolation could be misled. The c/d/e/f/g files and
  this retrospective carry the authoritative predicate.
- The c-design-plan's Interface section still says "add `state_done` to the
  import"; superseded by the d-plan's no-import-edit decision. Noted here rather
  than rewritten, consistent with the point-in-time nature of phase files.

## Key Learnings
### Technical Insights
- `state_done` and `state_achievable` are not interchangeable as completion
  gates: `state_done >= 100` means *finished*; `state_achievable == 0` means
  *finished OR no parseable status OR dormant-truncated-to-zero*. For "exclude
  finished work", the completion measure is the precise match and the
  work-potential measure over-filters.
- `state_done`'s 0-on-missing-status default is the correct fail-open direction
  for an inference heuristic: a task that cannot be *proven* complete stays a
  candidate. Both security reviews independently flagged this as safe-here and
  worth auditing only if the predicate is ever reused as a gate on an
  irreversible action.

### Process Learnings
- For signal/scoring bugs, the highest-leverage diagnostic is "which signals
  consult the shared framework and which don't" — the odd-one-out is usually the
  defect. Here `branch` and `progress` agreed; `recency` was the only
  task-candidate signal bypassing the work-potential framework.
- Reading the *test fixtures* (not just the source) during design is what
  surfaced the over-filter risk before any code was written.

### Risk Mitigation Strategies
- The a-plan's "Over-filtering" medium risk was real and materialised in
  analysis — mitigated at design time by predicate choice plus the TC-10
  boundary test, exactly as the risk's mitigation line anticipated.

## Recommendations
### Process Improvements
- When a bugfix's a-plan predicate/approach is later refined in design, it is
  acceptable to leave the a-plan as-authored (archaeology) but the retrospective
  should explicitly name the authoritative version — done here.

### Tool and Technique Recommendations
- Keep the "prove the regression test fails pre-fix" step as a standard part of
  bugfix testing-exec; it is cheap and converts a plausible test into a verified
  one.

### Future Work
- None required. The category-(e) security note (audit `state_done`'s
  0-on-missing default if ever reused as a gate on an irreversible action) is
  forward-looking signal, not an actionable item for this task.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-31
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan commits: a `d4d825f`, c `421639b`, d `8db74a1`, e `87b0116`
- Exec commits: f `eb139c5` (guard + hash refresh), g `630add4` (TC-9/TC-10)
- Production change: `.cwf/lib/CWF/TaskContextInference.pm` `_get_recency_signal`
- Tests: `t/taskcontextinference.t` TC-9, TC-10, `_write_status` helper
