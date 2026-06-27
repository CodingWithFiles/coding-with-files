# TC-VALIDATE in-flight false-failure - Retrospective
**Task**: 211 (bugfix)

## Task Reference
- **Task ID**: internal-211
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/211-tc-validate-in-flight-false-failure
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-27

## Executive Summary
- **Duration**: ~0.5 day (estimated: <0.5 day; on estimate).
- **Scope**: Planned as one subtest fix; design review widened it to the identical twin
  (TC-10 in `t/exec-changeset-reviewers.t`) — a one-instance grew to a two-instance
  defect-class fix, no estimate impact.
- **Outcome**: Success. The fragile whole-repo `is($rc,0)` coupling is gone from both
  changeset-reviewer integrity subtests; full suite green; no production code touched.

## Variance Analysis
### Time and Effort
- **Estimated**: Planning/Design/Impl/Testing all "Low", whole task <0.5 day.
- **Actual**: On estimate. The bulk of effort was review reasoning (verifying the
  liveness-banner claim against `cwf-manage`), not edit volume (a few lines per file).
- **Variance**: Negligible. The two plan-review passes added thinking time but prevented
  a re-plant (TC-10) and a vacuous-pass hole — net time saved versus shipping and
  re-opening.

### Scope Changes
- **Additions**: (1) TC-10 twin folded in at design review. (2) A liveness
  `like(qr/validate: OK|\d+ violation\(s\) found/)` added at impl review to close the
  vacuous-pass gap the dropped `is($rc,0)` had incidentally covered.
- **Removals**: Design rejected Option (a) (stand up a `.cwf/` fixture to re-assert a
  whole-repo exit-0) — disproportionate, fails Rule of Three.
- **Impact**: Strictly improved correctness of the fix; no timeline cost.

### Quality Metrics
- **Test Coverage**: Test-only change. TC-B proved the retained `unlike` checks still bite
  on a real named-file perturbation; TC-C proved the liveness `like` rejects empty output.
- **Defect Rate**: 0 escaped. One *unrelated* environmental failure surfaced and was fixed
  on-sight (see below).
- **Performance**: N/A.

## What Went Well
- The plan-review map/reduce earned its keep twice: it caught the TC-10 twin (scope) and
  the vacuous-pass robustness gap (correctness) before any code was written.
- Reviewers independently re-derived the load-bearing claim (both verdict banners always
  reach stdout, `cwf-manage:41,619,632`) rather than trusting the plan — the right
  scepticism for a change whose safety rests on that fact.
- The fix removes a coupling without weakening the integrity gate: `cwf-manage validate`
  is untouched and TC-B shows it still names genuine violations.

## What Could Be Improved
- Best-practice tag resolution again returned Go/Postgres for a Perl/Markdown change —
  noise the reviewers had to read past each phase. Tracked already; see Future Work.
- The `cd` into the scratch dir for the classify step stranded the shell's working
  directory and forced a `cwf-git` detour. Avoid `cd`-ing out of the repo root for
  one-off helper runs; pass absolute paths instead.

## Key Learnings
### Technical Insights
- **Dual semantics of recorded perms.** `cwf-manage validate` treats `permissions` as a
  *ceiling* (under-permissive is fine); `t/cwf-manage-fix-security.t` TC-8 treats the same
  value as a *provisioning floor*. A `fix-security` run on an over-permissive file reduces
  it by removing excess bits, which can land it *below* the recorded value (observed:
  Task-210 agent files `0600` → `0400` against recorded `0444`). Result: a state `validate`
  accepts but TC-8 rejects. Restoring the exact recorded `0444` satisfies both. This is the
  kind of in-flight environmental noise this very task is about — fittingly, it surfaced
  through a *different* test that (correctly) asserts a file-scoped property, reinforcing
  the design thesis: scope integrity assertions to the property under test.
- The liveness banner is a cheap, environment-independent way to distinguish
  "validate ran and found nothing about my files" from "validate never produced output".

### Process Learnings
- For a "delete a fragile assertion" change, the risk is *what the assertion incidentally
  covered*. Naming that (here: the vacuous-pass guard) and replacing it deliberately is
  more honest than a silent deletion.

### Risk Mitigation Strategies
- Fix-on-sight for permission drift worked exactly as intended — the drift was clamped to
  the recorded value the moment it blocked the suite, not deferred.

## Recommendations
### Process Improvements
- Keep the two-pass plan review for "remove an assertion" bugfixes; the incidental-coverage
  question is where the value is.

### Tool and Technique Recommendations
- The fix-security ceiling-vs-floor tension is already on the backlog (see Future Work) —
  this task independently rediscovered it, which is corroboration, not a new item.

### Future Work
- Existing backlog item "Narrow best-practice active-tags for CWF internal Perl/Markdown
  tasks" would remove the recurring Go/Postgres review noise.
- Existing backlog item "fix-security TC-8 asserts a 0444 floor that contradicts the
  recorded-perms ceiling model" (identified Task 188) covers the perm dual-semantics this
  task re-encountered. No new item filed — it would duplicate.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-27
**Sign-off**: Task maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Phase docs: `a-task-plan.md`, `c-design-plan.md`, `d-implementation-plan.md`,
  `e-testing-plan.md`, `f-implementation-exec.md`, `g-testing-exec.md` (this directory).
- Commits (pre-squash): a=8fa30a8, c=1fa1cc5, d=4066ef0, e=6cfd90c, f=2138d20, g=1d3eb90.
- Reviewer outputs: task scratch dir `/tmp/cwf-home-matt-repo-coding-with-files/task-211/`.
