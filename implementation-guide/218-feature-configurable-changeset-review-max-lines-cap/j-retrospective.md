# Configurable changeset-review max-lines cap - Retrospective
**Task**: 218 (feature)

## Task Reference
- **Task ID**: internal-218
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/218-configurable-changeset-review-max-lines-cap
- **Template Version**: 2.1
- **Retrospective Date**: 2026-07-05

## Executive Summary
- **Duration**: one session (estimated `<1 day`, Low complexity — on estimate).
- **Scope**: delivered as scoped — a `security.review.max-lines` config key read by
  `security-review-changeset`, precedence `--max-lines` > config > built-in 500, this
  repo's cap raised to 1000. No scope creep, no descope.
- **Outcome**: success. All five a-plan success criteria met; 7 clean changeset
  reviews (5 at f, 2 at g); full suite 947 tests pass; `cwf-manage validate` clean.

## Variance Analysis
### Time and Effort
- **Estimated**: `<1 day` total (Low complexity, single-unit task, no per-phase split).
- **Actual**: one working session across all ten phases.
- **Variance**: none material. The shape mirrored the existing
  `max_lines_exclude_paths` config reader, so the implementation was a known pattern.

### Scope Changes
- **Additions**: none.
- **Removals**: none.
- **Impact**: n/a — final scope equals planned scope.

### Quality Metrics
- **Test Coverage**: precedence matrix (CLI/config/default + explicit-500-vs-config
  edge) 100%; every invalid-config equivalence class (non-integer, boolean, array,
  zero, negative, leading-zero, missing, null, numeric-string) covered by
  TC-CONFIGCAP1–10. CLI-fatal/config-degrade asymmetry pinned.
- **Defect Rate**: zero defects in the shipped code. One incidental regression
  surfaced (see below) from an unrelated fix-on-sight action, resolved in-phase.
- **Performance**: n/a (a config read on an already-running helper).

## What Went Well
- Reusing the sibling config-reader pattern (`max_lines_exclude_paths`) kept the
  concern count at one and held the estimate.
- Fail-safe framing up front (ambiguity → stricter 500, never fail-open-large) made
  the test matrix fall straight out of the requirements.
- The single-sourced `$DEFAULT_MAX_LINES` constant kept the two live-code sites and
  the POD consistent; only the non-interpolating `#` banner needs a manual dual-write.
- Plan Step 1's pre-refresh hash verification (`git log <lasthash>..HEAD` empty + live
  digest match) meant the sha256 refresh signed a known-clean baseline.

## What Could Be Improved
- **Test-ID collision**: the e-plan numbered new cases TC-CAP7–16, colliding with
  existing TC-CAP7/8/9. Caught at exec, renamed TC-CONFIGCAP1–10. Plan-time ID
  numbering should check the existing suite first.
- **Fixture-size vs signal**: e-plan's TC-CAP14 used a 600-line diff to test the
  silent-missing-key default, but 600 > 500 would exit 2 and mask the signal. Reduced
  to <500 at exec. A "silent default" fixture must sit under that default.
- **Fix-on-sight over-clamp**: a fix-on-sight `cwf-manage fix-security` on two
  Task-217 files clamped 0600 → 0400, under the recorded 0444 floor, breaking TC-8.
  `fix-security` only strips excess bits; a recorded-floor file needs
  `chmod <recorded>`. Now in memory.

## Key Learnings
### Technical Insights
- `cwf-manage fix-security` is clamp-only (clears excess bits, never raises); for a
  recorded-**floor** file it under-clamps. Use `chmod <recorded>` directly.
- `validate` tolerates under-permissive files, so a floor violation reads clean there
  — only an exact-floor test (TC-8) catches it. The full suite is the real gate.

### Process Learnings
- Estimation was accurate because the task reused a proven pattern; "mirrors an
  existing sibling" is a reliable low-variance signal.
- Plan-time test IDs and fixture sizes both need a reality check against the existing
  suite and against the very default under test.

### Risk Mitigation Strategies
- The a-plan's two named risks (silent wrong cap, hashed-file drift) were both
  mitigated exactly as planned — fail-safe degrade + same-commit hash refresh — and
  verified by tests and `validate`. No surprise risks materialised from the code.

## Recommendations
### Process Improvements
- When a plan enumerates new test IDs, grep the target test file for the range first.
- For fix-on-sight on a hashed file, check whether the recorded permission is a floor
  before reaching for `fix-security`.

### Tool and Technique Recommendations
- Keep single-sourcing defaults in one constant; flag any literal-only surface (the
  `#` banner) as a manual dual-write in the maintenance doc (done).

### Future Work
- None required. If a future task ever reads `security.review.max-lines` from an
  out-of-tree source (env override, user-global config), re-audit the self-referential
  trust boundary (b-requirements NFR4 / c-design D3) before merging.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-07-05
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning → retrospective: `a-` through `j-` in this task directory.
- Implementation commits: on `feature/218-configurable-changeset-review-max-lines-cap`
  (per-phase checkpoints preserved on the checkpoints branch after squash).
- Test results: g-testing-exec.md (TC-CONFIGCAP1–10 + 947-test full suite).
