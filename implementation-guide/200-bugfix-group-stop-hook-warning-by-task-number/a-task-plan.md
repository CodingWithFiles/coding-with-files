# Group Stop-hook warning by task number - Plan
**Task**: 200 (bugfix)

## Task Reference
- **Task ID**: internal-200
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/200-group-stop-hook-warning-by-task-number
- **Baseline Commit**: ce000869457a98792f779af066d4969a564ce372
- **Template Version**: 2.1

## Goal
Make the Stop-hook uncommitted-files warning group its file list by owning
task number, so the operator can see which task each dirty wf file belongs to.

## Success Criteria
- [ ] Dirty wf files in the warning are grouped under their owning task number
      (e.g. `199`, or `28.1` for a nested subtask)
- [ ] When all dirty files belong to a single task, the task number is elided
      and output matches today's flat format
- [ ] The `+N more` overflow cap still bounds total message length, and its
      interaction with grouping is defined (not silently dropping a whole group)
- [ ] Hook still always exits 0 and emits valid single-line JSON

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None (self-contained Perl hook + its test)

## Major Milestones
1. **Design**: Settle the grouped output format and the `+N more` interaction
2. **Implement**: Derive task number per file, group, render, elide-on-single
3. **Test**: Cover single-task, multi-task, nested-subtask, and overflow cases

## Risk Assessment
### High Priority Risks
- **Risk 1**: Overflow truncation hides an entire task's group, defeating the
  point of grouping.
  - **Mitigation**: Decide the cap semantics explicitly in design (cap within
    vs across groups) and test the overflow case.

### Medium Priority Risks
- **Risk 2**: Task-number derivation breaks on edge paths (nested subtasks,
  unexpected segment order).
  - **Mitigation**: Derive the number from the file's immediate parent dir
    prefix; cover nested-subtask paths in tests.

## Dependencies
- None beyond the existing hook and its test harness.

## Constraints
- Perl core-only, `use utf8;`, hook must never exit non-zero.
- Single-line JSON systemMessage output (consumed by the harness).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? No — well under a day.
- [x] **People**: Does this need >2 people? No — single hook + test.
- [x] **Complexity**: Does this involve 3+ distinct concerns? No — one concern.
- [x] **Risk**: High-risk components needing isolation? No.
- [x] **Independence**: Can parts be worked on separately? No.

No decomposition signals triggered; proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four success criteria met. Dirty wf files are grouped by owning task number
(via `CWF::TaskPath::parse_dirname`), the number is elided when a single task is
dirty (byte-identical to the prior flat output), the `+N more` cap now applies
per-group (no group silently dropped), and the hook still always exits 0 with
valid single-line JSON. Effort matched the estimate (<1 day); no decomposition
needed. Verified by a new 7-case subprocess harness (20 assertions) and the full
suite (782 tests green).

## Lessons Learned
*Captured in j-retrospective.md*
