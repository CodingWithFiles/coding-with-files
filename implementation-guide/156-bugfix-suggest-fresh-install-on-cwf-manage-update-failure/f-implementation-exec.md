# suggest fresh install on cwf-manage update failure - Implementation Execution
**Task**: 156 (bugfix)

## Task Reference
- **Task ID**: internal-156
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/156-suggest-fresh-install-on-cwf-manage-update-failure
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [ ] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [ ] Verify all prerequisites met
- [ ] Execute implementation steps sequentially
- [ ] Update "Actual Results" for each step
- [ ] Document any deviations from plan
- [ ] Update status to "Implemented" when complete

## Actual Results

### Step 1: Source edits to `cwf-manage`
- **Planned**: three edits — declare `my $update_in_progress = 0;` above `die_msg`; extend `die_msg` to print the suggestion when the flag is set; set the flag before the laydown dispatch.
- **Actual**: all three applied. Flag + invariant comment added above `die_msg` (line 50); `die_msg` now prints the 5-line `[CWF]` suggestion guarded by `if ($update_in_progress)`; `$update_in_progress = 1;` set after the checkout, immediately before `if ($method eq 'subtree')` (now line ~424). Bootstrap line kept literal (`<tag>`/`<source-url>`) per the FR4(d) guardrail.
- **Deviations**: none.

### Step 2: Hash refresh (same commit)
- **Planned**: recompute `sha256sum` and update `script-hashes.json:207`.
- **Actual**: digest changed `1311378e…0777` → `669ca7e1…608a`; entry updated. `cwf-manage validate` → `validate: OK`.
- **Deviations**: none.

### Step 3: Regression + smoke
- **Planned**: run the update/security regression tests.
- **Actual**: `prove t/cwf-manage-update.t t/cwf-manage-update-end-to-end.t t/validate-security.t` → all pass (23 tests). Smoke: `cwf-manage status` in the source repo fails its pre-flight (`No .cwf/version`) and does **not** print the hint — confirms a non-update `die_msg` stays clean. `grep -c '$update_in_progress = 1'` → 1 (single set point).
- **Deviations**: none.

## Blockers Encountered

None.

## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements-plan.md addressed (if applicable)
- [ ] All design guidance in c-design-plan.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings
Reviewed the cwf-manage diff for implementation-phase security concerns; the change only adds a stderr advisory message gated by an in-process flag, with no new input handling, file writes, command execution, or interpolation of untrusted data. The `<tag>`/`<source-url>` tokens in the suggested command are literal placeholder text, not shell-expanded values.

## Lessons Learned
*To be captured during retrospective*
