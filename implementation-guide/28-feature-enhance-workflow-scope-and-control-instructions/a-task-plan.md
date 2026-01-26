# Enhance workflow scope and control instructions - Plan

## Task Reference
- **Task ID**: internal-28
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/28-enhance-workflow-scope-and-control-instructions
- **Template Version**: 2.0

## Goal
Consolidate verbose workflow instructions into concise "Scope & Boundaries" sections and create workflow-control helper script to centralize continuation logic for both user-driven and LLM-driven workflow modes.

## Success Criteria
- [ ] All 10 workflow commands have consolidated "Scope & Boundaries" section (5-6 lines) replacing current 33-line verbose sections
- [ ] "Scope & Boundaries" appears at top of each command (after frontmatter, before Context)
- [ ] workflow-control helper script created and returns appropriate control flow for Finished/Blocked/In-Progress statuses
- [ ] Detailed blocker patterns documentation moved to `.cig/docs/workflow/blocker-patterns.md`
- [ ] Zero regression in functionality (workflow commands still work correctly)

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Low
**Dependencies**: None (updates existing workflow commands and adds new helper script)

## Major Milestones
1. **Design consolidated format**: Define "Scope & Boundaries" section template (~2-3 hours)
2. **Create workflow-control script**: Implement minimal version returning "ask-user" for Finished/Blocked (~1-2 hours)
3. **Update all 10 workflow commands**: Replace verbose sections with consolidated format (~4-6 hours)
4. **Extract blocker patterns**: Move detailed guidance to separate doc (~1-2 hours)
5. **Test and validate**: Verify all commands work, no regressions (~2-3 hours)

## Risk Assessment
### High Priority Risks
- **Risk**: Breaking existing workflow commands during refactoring
  - **Mitigation**: Update one command first, test thoroughly, then batch update remaining 9

### Medium Priority Risks
- **Risk**: "Scope & Boundaries" format too terse, LLM doesn't follow boundaries
  - **Mitigation**: Test with actual usage (run through a small task), adjust wording if needed
- **Risk**: workflow-control interface design locks us into bad pattern
  - **Mitigation**: Keep interface minimal (just status-based logic), easy to extend later with config matrix

## Dependencies
- None - this is purely an enhancement to existing workflow commands
- No external dependencies or coordination needed

## Constraints
- Must maintain backward compatibility (existing tasks using old format should still work)
- Must support both user-driven and LLM-driven modes (current: user-driven, future: config-driven)
- Template changes only affect NEW tasks, existing tasks keep their current format

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 1-2 days
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - just documentation refactoring + small script
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low risk, incremental changes
- [ ] **Independence**: Can parts be worked on separately? **Maybe** - could split script creation from command updates, but not worth the overhead

**Decomposition Decision**: No decomposition needed - task is small, low complexity, single developer effort

## Status
**Status**: Finished
**Next Action**: Task completed - all phases finished
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
