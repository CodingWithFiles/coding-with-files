# suggest fresh install on cwf-manage update failure - Retrospective
**Task**: 156 (bugfix)

## Task Reference
- **Task ID**: internal-156
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/156-suggest-fresh-install-on-cwf-manage-update-failure
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-23

## Executive Summary
- **Duration**: <1 day (estimated: <1 day; on estimate).
- **Scope**: Delivered as planned — `cwf-manage` now suggests a fresh install when an update's laydown fails, scoped via a single flag. No scope change.
- **Outcome**: Success. All success criteria met; full suite green (509 tests); both exec-phase security reviews returned no findings.

## Variance Analysis
### Time and Effort
- **Estimated**: planning + design + implementation + testing all within a single sub-day session.
- **Actual**: matched. No phase overran.
- **Variance**: none material.

### Scope Changes
- **Additions**: none.
- **Removals**: forced-write-failure test for the version-file-write region (456–464) deliberately not written — that region shares TC-1's `die_msg`-with-flag-set path, so a separate brittle test (e.g. read-only `.cwf/version`) would assert nothing new. Documented in e-testing-plan and g-testing-exec rather than silently dropped.
- **Impact**: none on timeline or quality.

### Quality Metrics
- **Test Coverage**: both scoping branches covered — hint present (TC-1), hint absent on pre-flight (TC-2) and clone/resolve (TC-3) failures; single set point asserted statically (TC-4).
- **Defect Rate**: zero defects found in testing; no rework.
- **Performance**: N/A (additive STDERR text on an exit path).

## What Went Well
- The single-flag design (set before laydown, checked in `die_msg`) covered every laydown/artefact/perms/version-write failure — including those raised inside shared helpers — with one change point, and was reached unanimously sound by all four plan reviewers on both the design and implementation plans.
- The existing end-to-end harness made the positive case deterministic: tagging an upstream version with a failing `install.bash` reliably triggers a laydown error past the flag-set point.
- Hash refresh travelled in the same commit as the source edit; `validate` stayed clean throughout.

## What Could Be Improved
- Initial design enumerated covered-failure lines but stopped at `apply_exact_perms_or_die`; the robustness/improvements reviewers caught the missing version-file-write region. Enumerations of "covered failures" should be derived by walking to the end of the function, not stopped at the last obvious helper.

## Key Learnings
### Technical Insights
- `die_msg` calls `exit`, so an `eval`/wrapper approach to scope the hint is not viable without reworking the error model — a file-scoped flag is the right mechanism, and declaring it as `my` before `die_msg` matches the script's only existing file-scope lexical.
- Placing the flag-set point *after* clone/checkout is a correctness decision, not a stylistic one: clone/checkout touch only a throwaway tempdir, so a same-source bootstrap would hit the identical failure — suggesting a fresh install there would mislead.

### Process Learnings
- The negative assertions (hint absence) are the load-bearing tests for a scoping change; the testing plan correctly made them mandatory rather than only asserting the positive path.
- Keeping the bootstrap line's `<tag>`/`<source-url>` literal is enforced by a test (`like($out, qr/<source-url>/)`), so a future env-var interpolation would fail the suite — turning the FR4(d) guardrail into a regression test rather than a comment.

### Risk Mitigation Strategies
- The same-commit hash refresh (disclosed at plan time) avoided the deferred-refresh anti-pattern; `validate` never went red.

## Recommendations
### Process Improvements
- When a design lists "covered failures" by line, walk the enclosing function to its end so trailing failure paths are not omitted.

### Tool and Technique Recommendations
- Encoding a security invariant (no interpolation) as a test assertion is worth reusing for similar display-only-but-could-leak surfaces.

### Future Work
- None. The change is self-contained; no follow-up task identified.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-23
**Sign-off**: The maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Workflow docs: `implementation-guide/156-bugfix-suggest-fresh-install-on-cwf-manage-update-failure/`
- Implementation commit: `ed81272` (`cwf-manage` + hash refresh); testing commit: `5fe021e`
- Recovery procedure referenced by the hint: `INSTALL.md` "Recovering an install stuck on an old cwf-manage"
