# Add Re-Execution Guidance to Implementation and Testing Exec Skills - Plan
**Task**: 76 (bugfix)

## Task Reference
- **Task ID**: internal-76
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/76-add-re-execution-guidance-to-exec-skills
- **Template Version**: 2.1

## Goal
Add clear re-execution guidance to `cwf-implementation-exec` and `cwf-testing-exec`
skill instructions so agents handle Pass 2+ correctly: no commit reverts, forward-only
history, predictable commit naming.

## Background
When a user asks Claude to re-run an exec skill on an already-executed phase (e.g.
after fixing a bug found in testing, or after revising the implementation plan), the
agent currently has no guidance on how to proceed. The risks are:
- Reverting commits to "start fresh" (destroys history)
- Calling old results a "blocker" and refusing to continue
- Overwriting the exec file without acknowledging prior work

The fix is lightweight: a short prose section in the skill instructions (and optionally
a shared reference doc) that tells agents to work forward, not backward.

## Success Criteria
- [ ] `cwf-implementation-exec` SKILL.md has a "Re-execution" section covering:
      detection, commit naming (`Task N: Pass 2: …`), and doc handling
- [ ] `cwf-testing-exec` SKILL.md has equivalent guidance
- [ ] Both reference a shared doc (or inline) — design decision in c-design-plan
- [ ] Existing exec skill behaviour is unchanged for first-execution (Pass 1)
- [ ] No commit-revert pattern documented or encouraged anywhere

## Original Estimate
**Effort**: Trivial (<1 session)
**Complexity**: Low — prose additions to two skill files, possibly one new shared doc
**Dependencies**: None

## Major Milestones
1. **Design**: Decide shared doc vs inline; define commit naming convention
2. **Implementation**: Edit skill files (and create shared doc if chosen)
3. **Verify**: Manual review that guidance is clear and unambiguous

## Risk Assessment

### Low Priority Risks
- **Guidance too vague**: If the re-execution section is ambiguous, agents may still
  revert or block.
  - **Mitigation**: Include a concrete example commit message and an explicit "do NOT
    revert" instruction.
- **Guidance conflicts with existing instructions**: Existing skill steps may implicitly
  assume first-execution.
  - **Mitigation**: Read both skill files in full before editing.

## Dependencies
- None

## Constraints
- Must not change first-execution (Pass 1) behaviour
- Must not introduce complex detection logic — prose guidance only

## Decomposition Check
- [ ] **Time**: No
- [ ] **People**: No
- [ ] **Complexity**: No — two skill file edits, one optional doc
- [ ] **Risk**: No
- [ ] **Independence**: No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 76
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
One new shared doc (`re-execution.md`), two conditional one-liners in exec skill files.
All success criteria met; 6/6 tests pass.

## Lessons Learned
Agent misbehaviour under re-execution was a missing-instructions problem, not a code
problem. The original backlog item over-specified the solution; re-evaluate from first
principles rather than implementing proposed solutions verbatim.
