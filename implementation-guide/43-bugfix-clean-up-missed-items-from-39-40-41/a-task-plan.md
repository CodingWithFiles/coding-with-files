# Clean up missed items from 39/40/41 - Plan

## Task Reference
- **Task ID**: internal-43
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/43-clean-up-missed-items-from-39-40-41
- **Template Version**: 2.1

## Goal
Remove obsolete standalone scripts that were superseded by Tasks 39/40/41's trampoline/module architecture

## Success Criteria
- [ ] 7 obsolete scripts removed: context-inheritance, format-detector, hierarchy-resolver, status-aggregator, template-copier, template-version-parser, workflow-control
- [ ] `.cig/security/script-hashes.json` updated (remove hashes for deleted scripts)
- [ ] `/cig-security-check` command references updated (if any exist)
- [ ] Verification: no remaining references to old scripts in active code
- [ ] Zero functional regressions (all CIG commands still work)

## Original Estimate
**Effort**: 30 minutes
**Complexity**: Low
**Dependencies**: Task 41 complete (new architecture in place), understanding of which scripts are obsolete

## Major Milestones
1. **Identify Obsolete Scripts**: Verify 7 scripts are truly superseded by new architecture
2. **Remove Scripts**: Delete files and update security configuration
3. **Verify**: Confirm no references remain, all commands still work

## Risk Assessment
### High Priority Risks
- **Breaking active commands**: Removing scripts that are still referenced somewhere
  - **Mitigation**: Grep for all references before removal, verify in `.claude/commands/` and active scripts
  - **Validation**: Test key CIG commands after removal (/cig-status, /cig-task-plan, /cig-new-task)

### Medium Priority Risks
- **Security hash mismatch**: Forgetting to update script-hashes.json causes /cig-security-check to fail
  - **Mitigation**: Update `.cig/security/script-hashes.json` as part of the same commit
  - **Validation**: Run `/cig-security-check verify` after changes

## Dependencies
- Task 39: Trampoline architecture exists
- Task 40: All helpers migrated to trampoline pattern
- Task 41: Shared libraries created (clean architecture complete)
- No external dependencies

## Constraints
- Must not break existing CIG commands
- Must update security configuration atomically (same commit)
- Should verify Tasks 35-40 still work after removal

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - Estimated 30 minutes
- [ ] **People**: Does this need >2 people working on different parts? **No** - Single person cleanup
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - Just removal + security update
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - Low risk, easily reversible
- [ ] **Independence**: Can parts be worked on separately? **No** - All 7 scripts removed together

**Decision**: No decomposition needed (0 signals triggered)

## Status
**Status**: In Progress
**Next Action**: Move to design phase → `/cig-design-plan 43`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
