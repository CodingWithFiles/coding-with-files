# Fix normalise wrapped-field stranding - Retrospective
**Task**: 208 (bugfix)

## Task Reference
- **Task ID**: internal-208
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/208-fix-normalise-wrapped-field-stranding
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-17

## Executive Summary
- **Duration**: ~28 min wall-clock across one session (estimated: <1 day; within estimate).
- **Scope**: Delivered the core fold fix and regression coverage as planned. The AC5d
  byte-guard tightening (SC#2) was dropped mid-design under KD4 (user-approved) once it
  was shown to be a no-op for the bug class; the regression fixture is the real safety net.
- **Outcome**: Success. `normalise` now folds hard-wrapped legacy `**Field**:` continuation
  lines into a single canonical heading; 869-test suite green; `validate` OK.

## Variance Analysis
### Time and Effort
- **Estimated**: <1 day total (Original Estimate, a-task-plan).
- **Actual** (commit timestamps, all 2026-06-17):
  - Planning (a): 21:13
  - Design (c): 21:19 (~6 min)
  - Implementation plan (d): 21:22 (~3 min)
  - Testing plan (e): 21:23 (~1 min)
  - Implementation exec (f): 21:38 (~15 min — code + fixture + hash refresh + reviews)
  - Testing exec (g): 21:41 (~3 min)
- **Variance**: Well within the sub-day estimate. The bulk of effort sat in f (the fold
  edit, the four-terminator fixture matrix, the same-commit hash refresh, and the
  out-of-band permission-drift fix), consistent with a localised bugfix.

### Scope Changes
- **Removals**: SC#2 / the proposed AC5d "metadata-value byte" guard was dropped (KD4,
  user-approved). Rationale: pre-normalise legacy fields live in `body_raw` with an empty
  `metadata` array, so a pre/post metadata-byte comparison is always 0→N and can never
  trip — it would have been dead code masquerading as a guard. The regression fixture
  (AC18d/e/f) is the genuine safety net for the misplace-not-delete class.
- **Additions**: None.
- **Impact**: Net simplification — one fewer moving part, no loss of protection. Aligns
  with "the best part is no part".

### Quality Metrics
- **Test Coverage**: Each fold terminator (next field / blank / `---` / EOF) plus the
  seed-empty edge has a dedicated fixture row (KD3 matrix); single-line legacy path
  regression-guarded by AC18f. New: 48 tests in `backlog-manager.t`.
- **Defect Rate**: 0 defects found in testing; 0 regressions (full suite 869 tests green).
- **Performance**: N/A — deterministic in-memory fold, no measurable surface.

## What Went Well
- The index-walk rewrite landed verbatim from the d-plan "After"; no design churn at exec.
- KD4 was caught at design time, not after writing a useless guard — measure-twice paid off.
- The same-commit hash refresh convention was followed without prompting; `validate` clean.
- Both changeset review rounds (f and g), security and best-practice, returned no findings.
- The pre-existing 0400 permission drift on two agent files was fixed on sight rather than
  deferred, keeping the full suite green.

## What Could Be Improved
- The best-practice reviewer matched only out-of-domain corpora (`golang`/`postgres`) for a
  Perl-only changeset — wasted two agent rounds producing "not applicable". CWF's own
  Perl-helper tasks would benefit from a narrower `active-tags` set so `best-practice-resolve`
  returns 0 and skips the reviewer. Captured as a backlog candidate.
- The AC5d guard was specified in the plan before its no-op nature was understood; a quick
  check of how legacy fields populate `metadata` at task-plan time would have pre-empted SC#2.

## Key Learnings
### Technical Insights
- A per-physical-line walk cannot fold continuation lines — the terminator-driven index walk
  (look-ahead for next field / blank / `---` / EOF) is the correct shape for "field value may
  hard-wrap" parsing.
- Byte-budget gates (AC5d) conserve total bytes and so are blind to misplace-not-delete
  corruption; structural fixtures, not byte accounting, catch content landing in the wrong place.
- The fold trims but does not escape the assembled value — safe only because the sink is an
  inert `### Field: value` heading. The "value is inert display text" invariant is load-bearing
  for any future sink that feeds a shell/path/exec or LLM tool-selection.

### Process Learnings
- Dropping a planned acceptance criterion is legitimate when it is shown to be a no-op — record
  it as a deviation (KD4) rather than implementing dead code to satisfy the checklist.
- Permission drift surfacing in an unrelated test file is a fix-on-sight runtime repair; read-bit
  perms are not version-tracked (git mode `100644`), so the chmod correctly leaves no commit trace.

### Risk Mitigation Strategies
- The High-priority "continuation-fold boundary errors" risk was retired exactly as the a-plan
  mitigation specified: an explicit terminator set with one fixture per boundary plus an
  idempotency re-run (TC-6) asserting no drift.

## Recommendations
### Process Improvements
- Validate that a proposed guard can actually fire (against the real data shape) before writing
  it into success criteria.

### Tool and Technique Recommendations
- Narrow `active-tags` for CWF's own Perl-helper tasks so the best-practice reviewer is skipped
  when no applicable corpus exists (backlog candidate below).

### Future Work
- BACKLOG: scope a narrower best-practice tag set (or a per-task tag override) for CWF's internal
  Perl/Markdown tasks so `best-practice-resolve` returns 0 instead of matching out-of-domain
  corpora.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-17
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning/design/exec docs: this task directory (a/c/d/e/f/g).
- Commits: 7cc78a9 (a), 7ac2ccf (c), fd32a77 (d), 5ce4b6c (e), 2ed4309 (f), 79e20a6 (g).
- Test results: `t/backlog-manager.t` (48 tests); full suite 869 tests, 0 failures.
