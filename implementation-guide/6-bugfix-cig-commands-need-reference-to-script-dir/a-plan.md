# CIG Commands Need Reference to Script Dir - Plan

## Task Reference
- **Task ID**: internal-6
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/6-cig-commands-need-reference-to-script-dir
- **Template Version**: 2.0

## Goal
Add explicit helper scripts directory reference to all CIG command files to prevent LLM path hallucination

## Success Criteria
- [ ] All 14 CIG command files updated with helper scripts location line
- [ ] Line format consistent: `**Helper scripts location**: `.cig/scripts/command-helpers/``
- [ ] Line placement consistent (after task description, before arguments/steps)
- [ ] Zero ENOENT errors from hallucinated script paths in manual testing
- [ ] No disruption to existing Context sections or allowed-tools declarations

## Original Estimate
**Effort**: 0.25 days (2 hours)
**Complexity**: Low
**Dependencies**: None - simple text addition to existing command files

## Major Milestones
1. **File Identification**: Locate all 14 command files requiring the update
2. **Systematic Updates**: Add helper scripts location line to each file
3. **Validation**: Verify consistent formatting and no markdown structure disruption

## Risk Assessment
### High Priority Risks
No high-priority risks identified

### Medium Priority Risks
- **Inconsistent Placement**: Adding line in different locations across files could cause confusion
  - **Mitigation**: Define exact placement rule (after task description, before arguments/steps) and follow consistently
- **Markdown Formatting**: Incorrect markdown could break command file rendering
  - **Mitigation**: Use exact template format with proper bold markdown syntax

## Dependencies
- No external dependencies
- All 14 command files must exist in `.claude/commands/` directory (already present)

## Constraints
- Must add exactly ONE line per command file (per user requirement)
- Cannot modify Context sections or allowed-tools declarations
- Must maintain existing markdown structure

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 2 hours
- [ ] **People**: Does this need >2 people working on different parts? **No** - single-person text addition
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - simple text insertion
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low-risk change
- [ ] **Independence**: Can parts be worked on separately? **No** - all changes follow same pattern

**Analysis**: 0/5 signals triggered. Task is straightforward and does not require decomposition.

## Status
**Status**: Finished
**Next Action**: Task complete - ready for commit
**Blockers**: None

## Actual Results
Task completed within estimate (0.25 days). All 14 CIG command files updated successfully with explicit helper scripts location reference. Zero scope creep - completed exactly as planned.

**Changes**: 14 files, 28 insertions (+)
**Format**: `**Helper scripts location**: `.cig/scripts/command-helpers/``
**Result**: Prevents LLM path hallucination by placing critical path information in main instruction section

## Lessons Learned
- Plan mode exploration correctly identified that paths existed in Context but weren't visible in step instructions
- User clarification critical - initial assumption was paths were missing, reality was LLM attention focus issue
- Low complexity estimate accurate - simple, systematic change completed quickly
