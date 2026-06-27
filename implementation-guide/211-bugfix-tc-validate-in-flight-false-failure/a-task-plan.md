# TC-VALIDATE in-flight false-failure - Plan
**Task**: 211 (bugfix)

## Task Reference
- **Task ID**: internal-211
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/211-tc-validate-in-flight-false-failure
- **Baseline Commit**: a4f3a65277ec61753d6f5d251bda86f700ec0686
- **Template Version**: 2.1

## Goal
Stop the TC-VALIDATE subtest in `t/security-review-changeset.t` from falsely
failing whenever the suite runs mid-workflow, by scoping its integrity check to
what AC8 actually asserts instead of demanding the whole live repo validate clean.

## Problem Statement
TC-VALIDATE (AC8) exists to confirm the *changed helper + migrated agent* carry a
consistent same-commit hash refresh. It does this with two correctly-scoped
`unlike` checks (no violation names `security-review-changeset` /
`cwf-security-reviewer-changeset`) **plus** a broad `is($rc, 0, 'validate exits 0
fully clean')`. The broad assertion couples the test to the entire live repo's
state, so it goes red for reasons unrelated to the change under test:
- in-flight phase files carry placeholder `Status` values not in
  `cwf-project.json` (flagged by `CWF::Validate::Workflow`); and
- transient permission/hash drift on unrelated files (flagged by
  `CWF::Validate::Security`) — observed live this task on the Task-210 agent files.
Each red run costs diagnostic effort to confirm it is environmental, not a
regression (Task 203 paid that cost).

## Success Criteria
- [ ] TC-VALIDATE passes when run mid-workflow (in-flight task present with
      non-terminal phase statuses) — no dependence on whole-repo validate state.
- [ ] TC-VALIDATE still catches a genuine integrity violation on the changed
      helper/agent (the two scoped `unlike` checks are preserved or strengthened).
- [ ] A "validate exits 0 on a clean repo" assertion, if retained, runs against a
      controlled fixture, not the live repo (decision deferred to design phase).
- [ ] No production-code change to `security-review-changeset` or `cwf-manage`.
- [ ] Full `t/security-review-changeset.t` suite green.

## Original Estimate
**Effort**: <0.5 day
**Complexity**: Low
**Dependencies**: None (test-only change; reuses existing `make_synthetic_repo` helper)

## Major Milestones
1. **Design decision**: choose option (a) fixture-scoped clean-repo assertion vs
   (b) drop the broad assertion and rely on the scoped `unlike` checks.
2. **Fix**: rework the TC-VALIDATE subtest accordingly.
3. **Verify**: suite green both mid-flight and against a terminal-status fixture.

## Risk Assessment
### Medium Priority Risks
- **Risk**: Over-narrowing loses real coverage — silently dropping the only
  assertion that a clean repo validates 0.
  - **Mitigation**: Prefer option (a) — keep a genuine exit-0 assertion but
    against a synthetic terminal-status repo, so coverage moves rather than dies.

## Dependencies
- None. Self-contained test change.

## Constraints
- Test-only; no changes to validators or the helper under test.
- Reuse the file's existing synthetic-repo scaffolding rather than adding new
  fixture machinery (Rule of Three not met for new abstraction).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: No — well under a day.
- [x] **People**: No — single concern, one person.
- [x] **Complexity**: No — one test subtest, one decision.
- [x] **Risk**: No — test-only, no production code touched.
- [x] **Independence**: No — single indivisible change.

No decomposition signals triggered. Proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
The single-instance framing was incomplete: design review found an identical twin
(TC-10). For "remove a fragile assertion" tasks, scope the search to the defect *class*,
not the reported site. See j-retrospective.md.
