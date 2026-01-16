# new-helper-script-to-setup-templates-for-new-task - Plan

## Task Reference
- **Task ID**: internal-17
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/17-new-helper-script-to-setup-templates-for-new-task
- **Template Version**: 2.0

## Goal
Create a reusable helper script that copies template files from the pool to new task directories, reducing code duplication in `/cig-new-task` command.

## Success Criteria
- [ ] Helper script successfully copies templates based on task type
- [ ] Script follows symlinks to read from pool (DRY principle maintained)
- [ ] Script handles all 5 task types (feature, bugfix, hotfix, chore, discovery)
- [ ] `/cig-new-task` command updated to use the new helper script
- [ ] File permissions set correctly (0600 for markdown files)

## Original Estimate
**Effort**: 0.5-1 day
**Complexity**: Low
**Dependencies**:
- Existing template pool structure in `.cig/templates/pool/`
- Existing symlink structure in `.cig/templates/<type>/`
- Understanding of current `/cig-new-task` command logic

## Major Milestones
1. **Design script interface**: Define parameters, error handling, output format
2. **Implement helper script**: Create script with symlink resolution and template copying
3. **Integrate with cig-new-task**: Update command to use helper instead of inline logic
4. **Security verification**: Add script hash to `.cig/security/script-hashes.json`

## Risk Assessment
### High Priority Risks
- **Broken symlinks in template directories**: If symlinks point to non-existent pool files, script will fail
  - **Mitigation**: Add validation to check symlink targets exist before copying
- **Permission errors**: Script may not have correct permissions to read templates or write to task directories
  - **Mitigation**: Validate read access to template pool, handle permission errors gracefully

### Medium Priority Risks
- **Inconsistent behaviour with `/cig-new-task`**: Helper script output may not match current inline logic
  - **Mitigation**: Test against existing task creation workflow, validate file contents match
- **Security hash mismatch**: Forgetting to update `.cig/security/script-hashes.json` breaks integrity checks
  - **Mitigation**: Include hash update as mandatory step in integration milestone

## Dependencies
- Template pool structure must remain stable (`.cig/templates/pool/`)
- Symlink structure in `.cig/templates/<type>/` must follow naming convention
- `/cig-new-task` command refactoring depends on helper script completion
- Existing CIG Perl module infrastructure

## Constraints
- Must maintain backward compatibility with existing task creation workflow
- Script must follow CIG security model (u+rx minimum permissions for scripts)
- Must not modify template pool files (read-only operations)
- Output must be deterministic and testable
- Must work from any directory within git repository tree
- **Idempotency principle**: Support "upsert" behavior - warn on overwrite but don't block
- **Trust git for safety**: Don't over-engineer protection mechanisms, git provides rollback capability

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 0.5-1 day
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - focused on template copying logic
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - low risk, well-understood requirements
- [ ] **Independence**: Can parts be worked on separately? **No** - script creation and integration are sequential

**Decomposition Decision**: No decomposition needed - task is small, focused, and can be completed in <1 day

## Status
**Status**: Finished
**Next Action**: Requirements phase completed
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
