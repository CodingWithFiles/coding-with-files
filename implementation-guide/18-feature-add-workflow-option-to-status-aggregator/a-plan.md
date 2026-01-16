# Add --workflow Option to status-aggregator - Plan

## Task Reference
- **Task ID**: internal-18
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/18-add-workflow-option-to-status-aggregator
- **Template Version**: 2.0

## Goal
Add `--workflow` option to status-aggregator.pl that displays individual workflow file statuses, highlights current step, and suggests next action.

## Success Criteria
- [ ] `--workflow` flag successfully parses and enables workflow breakdown mode
- [ ] Each workflow file's status displayed (Backlog, In Progress, Finished, etc.)
- [ ] Current workflow step clearly highlighted in output
- [ ] Next recommended action shown based on workflow progression
- [ ] Backward compatibility maintained - existing usage without --workflow flag unchanged
- [ ] JSON output mode supports workflow breakdown (--format=json --workflow)

## Original Estimate
**Effort**: 0.5-1 day
**Complexity**: Low-Medium
**Dependencies**:
- Understanding of current status-aggregator.pl implementation (lines 1-196)
- CIG::WorkflowFiles module for workflow file listing
- CIG::MarkdownParser module for status extraction
- Knowledge of workflow step ordering (a-h)

## Major Milestones
1. **Design workflow display format**: Define output format for individual file statuses
2. **Implement --workflow flag parsing**: Add parameter handling and mode switching
3. **Add workflow file iteration**: Loop through workflow files, extract statuses
4. **Highlight current step logic**: Determine current step based on status values
5. **Integration testing**: Test with various task states, verify JSON mode

## Risk Assessment
### High Priority Risks
- **Breaking existing status-aggregator.pl functionality**: Changes could affect current percentage calculation
  - **Mitigation**: Keep calculate_progress() unchanged, add separate workflow display function
- **Inconsistent workflow file detection**: Not all task types have all 8 files (bugfix=5, hotfix=5, chore=4)
  - **Mitigation**: Use CIG::WorkflowFiles::list() which already handles task-type differences

### Medium Priority Risks
- **Output format confusion**: Too much detail could make output hard to parse
  - **Mitigation**: Design clear, scannable format with visual indicators (✓, ⚙️, ○)
- **JSON schema compatibility**: New --workflow mode needs JSON representation
  - **Mitigation**: Extend existing JSON output with optional "workflow_breakdown" field

## Dependencies
- Existing status-aggregator.pl implementation (must not break)
- CIG::WorkflowFiles module (already used at line 24)
- CIG::MarkdownParser module (already used at line 25)
- Workflow file naming convention (a-plan.md through h-retrospective.md)

## Constraints
- Must maintain backward compatibility with existing usage
- Must work with all 5 task types (feature=8 files, bugfix=5, hotfix=5, chore=4, discovery=6)
- Must follow existing exit code convention (0=success, 1=invalid args, 2=not found)
- Must respect existing output format conventions (markdown default, JSON optional)
- Performance: Should not significantly slow down status-aggregator.pl execution

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 0.5-1 day
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - focused on adding one option to existing script
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low risk, isolated feature addition
- [ ] **Independence**: Can parts be worked on separately? **No** - sequential implementation (flag parsing → workflow display → testing)

**Decomposition Decision**: No decomposition needed - task is small, focused, and can be completed in <1 day. Similar in scope to Task 17 (template-copier.pl creation).

## Status
**Status**: Finished
**Next Action**: Task complete - ready for merge to main
**Blockers**: None

## Actual Results

**Planning outcome**: Successfully scoped enhancement to status-aggregator.pl
- Estimated effort: 0.5-1 day (accurate - completed in ~1 day)
- Decomposition: Correctly determined no subtasks needed
- Scope: All planned features implemented plus input validation
- Success criteria: All achieved (31/31 tests passing, 100% pass rate)

## Lessons Learned

- Initial estimate of 0.5-1 day was accurate for core implementation
- Discovered emoji tab alignment issue during design (resolved with ASCII indicators)
- Created CIG::Options module "off-piste" during planning (documented retrospectively)
- Template design flaw identified (d-implementation.md duplicates e-testing.md content)
