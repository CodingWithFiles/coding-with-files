# changeset omits untracked files from git diff - Retrospective
**Task**: 194 (bugfix)

## Task Reference
- **Task ID**: internal-194
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/194-changeset-omits-untracked-files-from-git-diff
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-12

## Executive Summary
- **Duration**: ~0.5 day (estimated: ~0.5 day, variance: ~0%)
- **Scope**: As planned — one helper (`security-review-changeset`) plus its test
  file. One small unplanned addition: an out-of-tree relocation of the test
  harness's capture files (forced by the new behaviour).
- **Outcome**: Success. Untracked, non-ignored files are now included in both
  the reviewed changeset body and the `--max-lines` production count, closing a
  gap where a new source file created before the exec checkpoint commit was
  shipped to the security reviewer unreviewed and uncounted.

## Variance Analysis
### Time and Effort
- **Estimated**: Planning ~0.1d, Design ~0.1d, Implementation ~0.15d,
  Testing ~0.15d (bugfix workflow: a, c, d, e, f, g, j).
- **Actual**: Closely matched. The empirical git-mechanics probe front-loaded
  effort into design, which paid back in a near-verbatim implementation.
- **Variance**: ~0%. No phase overran materially.

### Scope Changes
- **Additions**:
  - Out-of-tree relocation of `run_helper_raw`'s stdout/stderr capture files
    (`$CAPTURE_DIR`). Forced — the new untracked-enumeration behaviour correctly
    swept the in-tree capture files into the helper's own changeset, breaking 8
    pre-existing subtests. Small, well-contained, and a genuine latent-defect fix.
- **Removals**: None. The signal-interrupt case was always planned as a
  documented manual check, not a descope.
- **Impact**: Negligible on timeline; net-positive on test-suite hygiene.

### Quality Metrics
- **Test Coverage**: All new/changed branches exercised. TC-1…TC-7 added;
  `t/security-review-changeset.t` = 42/42, full `t/` tree = 741/741 PASS.
- **Defect Rate**: 0 defects in the fix. 1 latent harness defect surfaced and
  fixed. 2 security reviews (implementation-exec, testing-exec) = no findings.
- **Performance**: N/A. The transient `git add -N`/`git reset` pair is O(untracked
  files) and bounded by the existing diff cost.

## What Went Well
- The pre-design empirical probe turned the central mechanism choice
  (`git add -N` vs `git diff --no-index`) into an evidence-backed decision; every
  later phase inherited that certainty.
- The chosen mechanism preserved the helper's "git owns all path-matching"
  invariant, so the body-render and count code paths needed zero edits — a small
  review surface for a security-critical helper.
- The 4-agent plan reviews (design + implementation) caught the END-vs-eval
  hazard, the forked-child PID-guard requirement, the signal-interrupt window,
  and the `--` option-injection invariant before any code was written.
- Two clean security reviews with substantive, specific reasoning — not rubber
  stamps.

## What Could Be Improved
- The in-tree capture-file pollution could in principle have been predicted at
  design time ("what untracked files exist while the helper runs under test?").
  It was caught immediately by the shared harness, but a design-phase note on
  "test-environment untracked noise" would have pre-empted the red test run.

## Key Learnings
### Technical Insights
- `git add -N` (intent-to-add) makes untracked files visible to
  `git diff <anchor>` and `--numstat` while preserving `:(glob,exclude)` magic
  pathspecs and returning rc 0 — the property that let the existing exit-code
  handling stay untouched.
- Perl `END` blocks run on `exit` and `die` but not on signal-kill; an `eval {}`
  wrapper catches only `die`. For exit-path cleanup, `END` + signal handlers is
  the correct pair; `eval` would have silently missed every `exit` branch.
- A forked child (here `git_check`) inherits `END` blocks; a `$$ == $MAIN_PID`
  guard is mandatory so cleanup never fires in the child. (Same class as the
  recorded `POSIX::_exit`-in-forked-child incident.)

### Process Learnings
- A behaviour change scoped to "one helper" can still ripple through shared test
  scaffolding. Reading the resulting test failures as signal (a true positive
  pointing at a latent harness defect) — rather than noise to suppress by
  weakening assertions — led to the right fix.
- Naming invariants explicitly in the design doc made them directly testable:
  each named invariant (`--` guard, probe-before-`-N` ordering) became a named
  test case.

### Risk Mitigation Strategies
- Both a-task-plan risks (invariant erosion; index side-effects / exit codes)
  were resolved in the design phase, exactly where the plan said they would be —
  the decomposition/risk framing did its job.

## Recommendations
### Process Improvements
- When a change alters what the working tree looks like at tool-run time,
  add a design-phase line on "untracked/scratch noise in the test environment"
  to pre-empt harness-pollution surprises.

### Tool and Technique Recommendations
- Keep using a throwaway empirical probe for any change that hinges on exact
  tool (git) behaviour — it is cheaper than a wrong design.

### Future Work
- The sibling backlog item — the dead `UserPromptSubmit`-as-`PreToolUse`-matcher
  hook in `cwf-init` (reported alongside this bug) — remains a separate
  High-priority bugfix for a future task. Not part of Task 194.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to user
**Blockers**: None identified
**Completion Date**: 2026-06-12
**Sign-off**: CWF maintainer (AI-assisted)

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, c-design-plan.md, d-implementation-plan.md, e-testing-plan.md
- Implementation: f-implementation-exec.md (commit ed8f97d)
- Testing: g-testing-exec.md (commit 2fcf069); `t/security-review-changeset.t`
- Security reviews: scratch `security-review-output-{implementation,testing}-exec.out`
