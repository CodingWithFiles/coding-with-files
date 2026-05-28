# task inference not subtask-aware - Plan
**Task**: 166 (bugfix)

## Task Reference
- **Task ID**: internal-166
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/166-task-inference-not-subtask-aware
- **Baseline Commit**: 1e3fffb4aa6799e799baba29ae0b83c8e4ede582
- **Template Version**: 2.1

## Goal
Make `task-context-inference` resolve an active subtask (decimal-numbered, e.g. `28.2`) conclusively, so skills invoked without an explicit task argument do not stall on subtask work.

## Success Criteria
- [ ] With a subtask checked out (branch and/or dirty wf files under `implementation-guide/<n>-…/<n>.<m>-…/`), `task-context-inference` exits 0 and reports `task_num: <n>.<m>` conclusively.
- [ ] All five signal collectors (branch, worktree, state file, recency, progress) accept and emit decimal task numbers; the four that currently regress on subtasks (branch, worktree, recency, progress) are fixed; state-file (already decimal-aware) is unchanged or refactored without behavioural change.
- [ ] Recency and progress signals enumerate nested subtask directories, not just top-level entries under `implementation-guide/`.
- [ ] `_get_task_dir`, `_get_task_slug`, and `_infer_workflow_step` resolve subtask paths.
- [ ] New regression tests cover (a) a subtask-only scenario resolving conclusively and (b) a parent-vs-subtask disambiguation scenario; pre-existing top-level inference tests remain green.

## Original Estimate
**Effort**: ~1 day
**Complexity**: Medium — small surface area, but five collectors plus three helpers all need consistent decimal handling, and the parent/subtask disambiguation semantics must be defined deliberately.
**Dependencies**: None.

## Major Milestones
1. **Reproducer**: deterministic test fixture (subtask directory + branch + dirty wf file) that drives the failing inference path; pinned as the first regression test.
2. **Decimal-aware parsing**: every task-number regex in `CWF::TaskContextInference` accepts `\d+(?:\.\d+)*` with an explicit dash boundary.
3. **Recursive enumeration**: recency and progress signals walk nested subtask dirs; helpers resolve subtask paths.
4. **Parent/subtask semantics**: defined and tested — when both parent `28` and subtask `28.2` have signals, the deepest active descendant wins (subject to design-phase confirmation).
5. **Hashes refreshed and full suite green**: `.cwf/security/script-hashes.json` updated in this task per the hash-updates convention.

## Risk Assessment
### High Priority Risks
- **Regex over-match**: loosening `(\d+)` to `(\d+(?:\.\d+)*)` could swallow trailing version-like fragments inside slugs or non-task strings.
  - **Mitigation**: anchor every regex to `^` (or `<separator>/`) and require an explicit `-` boundary after the captured number; add positive and negative tests for both top-level and subtask forms.
- **Parent/subtask disambiguation drift**: if recency now reports both `28` and `28.2`, signals may newly disagree where they previously agreed, flipping correlated outcomes to uncorrelated.
  - **Mitigation**: define the rule explicitly in the design phase (proposed default: deepest active descendant wins for recency/progress; state-file unchanged); cover with a regression test that asserts a single conclusive answer for the canonical subtask scenario.

### Medium Priority Risks
- **Subtask branch-naming convention**: branches for subtasks may not follow `<type>/<n>.<m>-<slug>` — `/cwf-new-subtask` may keep work on the parent branch. If so, the branch-signal fix is necessary but not sufficient.
  - **Mitigation**: verify subtask-branch convention by reading `cwf-new-subtask` skill and `task-workflow` helper during the design phase; record findings in `c-design-plan.md` before touching branch-signal code.
- **Hash-refresh churn**: `task-context-inference` and `CWF::TaskContextInference.pm` are both tracked in `.cwf/security/script-hashes.json`; an edit-then-forget cycle breaks `cwf-manage validate`.
  - **Mitigation**: declare the hashed files at plan time (this section), refresh hashes in the same commit that finalises the code change, and verify with `cwf-manage validate` before the testing-exec phase.

## Dependencies
- None. Self-contained change to `.cwf/lib/CWF/TaskContextInference.pm` and (likely) `.cwf/scripts/command-helpers/task-context-inference`.

## Constraints
- Perl core modules only ([[feedback-perl-core-only]]).
- POSIX paths only; no Windows-idiom file handling.
- Must not regress existing top-level inference; the canonical "conclusive on task 166" path observed at plan time is the floor.
- Hash refresh for `script-hashes.json` lands in this same task per the hash-updates convention.

## Decomposition Check
- [x] **Time**: ~1 day, under the >1-week threshold → no decomposition.
- [x] **People**: single contributor → no decomposition.
- [x] **Complexity**: two adjacent concerns (decimal regex parsing + recursive directory enumeration) but tightly coupled in one module → no decomposition.
- [x] **Risk**: risks are mitigable in-task with tests; no isolation needed.
- [x] **Independence**: the regex and enumeration fixes must land together to close the bug; they are not independently shippable.
→ **No subtasks.** Proceed as a single bugfix task.

## Related Work (Informational)
- Low-priority backlog item *Unify implementation-guide directory-scan helpers across CWF::Backlog and CWF::TaskContextInference* covers the directory-scan refactor that would naturally absorb the recursive-enumeration change. **Out of scope for task 166** — only fix the inference defect here; do not pre-empt the refactor.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 166
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met. Subtask `28.2` (hypothetical) resolves conclusively in the test fixture (TC-1); recency/progress enumerate subtasks (TC-8a/8b); parent/subtask disambiguation lands the deepest active descendant via the D3 ancestry-collapse predicate; pre-existing top-level inference scenarios remain green (TC-7 covered by the existing baseline subtest plus end-to-end smoke on task 166 itself).

## Lessons Learned
- Reading `cwf-new-subtask/SKILL.md` during c-design reframed the defect: subtasks share parent branches by design, so the branch signal returning the parent's number is *correct*. The fix moved from "loosen the branch regex" to "ancestry-collapse in the correlator" — a different shape than the original plan assumed.
- The Medium-priority risk *parent/subtask disambiguation drift* didn't materialise because the correlator's old fast path (`|unique| == 1`) is untouched; only the multi-unique branch gained the new predicate.
