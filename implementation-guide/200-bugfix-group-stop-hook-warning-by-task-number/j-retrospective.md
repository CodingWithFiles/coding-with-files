# Group Stop-hook warning by task number - Retrospective
**Task**: 200 (bugfix)

## Task Reference
- **Task ID**: internal-200
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/200-group-stop-hook-warning-by-task-number
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-13

## Executive Summary
- **Duration**: <1 day (estimated: <1 day, variance: ~0%)
- **Scope**: Delivered exactly as planned — grouped Stop-hook warning by owning
  task number, number elided when a single task is dirty, per-group overflow cap.
  No additions, no removals.
- **Outcome**: Success. The operator now sees which task each uncommitted wf file
  belongs to; the single-task path stays byte-identical to the prior output.

## Variance Analysis
### Time and Effort
Bugfix path (a, c, d, e, f, g, j). Estimate <1 day; actual <1 day. No phase ran
materially over. The only unplanned work was a doc correction (git sort order)
and clamping a pre-existing permission drift — both absorbed within the phase.

### Scope Changes
- **Additions**: None.
- **Removals**: None. Generic JSON-escaping of basenames remains out of scope
  (pre-existing baseline property, design-disclosed in D3).
- **Impact**: None on timeline or quality.

### Quality Metrics
- **Test Coverage**: New `t/stop-uncommitted-changes-warning.t` — 7 cases / 20
  assertions, all PASS. Full suite 782 tests green; `cwf-manage validate` clean.
- **Defect Rate**: No defects found post-implementation. One *plan* inaccuracy
  (git status ordering) caught and corrected during testing-exec.
- **Performance**: N/A (single git query per stop, unchanged from baseline).

## What Went Well
- Reusing `CWF::TaskPath::parse_dirname` over a fourth inline regex kept the
  change single-source and let the design lean on the sibling hook's established
  lib-loading pattern.
- The real-subprocess test harness (throwaway git repo per case) surfaced the
  git-sort-order assumption that a mocked-output test would have silently encoded.
- Fix-on-sight handling of the unrelated permission drift kept `validate` green
  for the checkpoint instead of leaving a latent integrity failure.
- Both exec-phase security reviews returned "no findings"; the pre-existing
  unescaped-JSON property was disclosed at design time, so review read it as
  inherited, not regressed.

## What Could Be Improved
- The testing plan asserted "file-plant order controls git-status order" — an
  unverified assumption about a tool's output. It cost a correction pass in
  testing-exec. Plan-time claims about a tool's output ordering should be
  verified against the tool, not assumed.

## Key Learnings
### Technical Insights
- `git status --porcelain` emits records sorted lexicographically by pathname,
  independent of working-tree mutation order. Any test asserting on its order
  must expect git's sort (e.g. `199` before `30`, `28` before `30`).
- Git pathspec `*` matches across `/`, so the single-`*` glob
  `implementation-guide/*/[a-j]-*.md` reaches two-deep nested-subtask files —
  the `28.1` grouping case is live, not dead.

### Process Learnings
- Driving a leaf script as a real subprocess against a throwaway git tree is the
  cheapest way to catch tool-behaviour assumptions; prefer it over mocking the
  tool's output for hooks whose behaviour depends on that output.

### Risk Mitigation Strategies
- The top design risk (overflow dropping a whole task's group) was retired by
  choosing a per-group cap and writing TC-5 specifically to assert the second
  group survives the first group's overflow.

## Recommendations
### Process Improvements
- When a plan states an assumption about an external tool's output (ordering,
  format, exit semantics), verify it against the tool during planning rather
  than deferring discovery to execution.

### Tool and Technique Recommendations
- The throwaway-git-repo subprocess harness in `t/stop-uncommitted-changes-warning.t`
  is a reusable shape for testing other cwd-sensitive leaf hooks.

### Future Work
- None required. Generic JSON-escaping of interpolated basenames remains a
  pre-existing, bounded baseline property; revisit only if the `[a-j]-*.md`
  pathspec ever widens to admit non-repo-authored filenames.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-13
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning/design/impl/test docs: `a-task-plan.md`, `c-design-plan.md`,
  `d-implementation-plan.md`, `e-testing-plan.md` (this task directory).
- Exec records: `f-implementation-exec.md`, `g-testing-exec.md` (incl. verbatim
  security reviews).
- Implementation: `.cwf/scripts/hooks/stop-uncommitted-changes-warning`,
  `t/stop-uncommitted-changes-warning.t`.
