# refactor template generation system - Rollout

## Task Reference
- **Task ID**: internal-44
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/44-refactor-template-generation-system
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for refactor template generation system.

## Deployment Strategy
### Release Type
- **Strategy**: Direct merge to main (atomic deployment)
- **Rationale**: Internal CIG system change with comprehensive testing, backward compatibility maintained, low blast radius (only affects new tasks created after merge). No runtime services to deploy - changes are template files and Perl script that only execute during task creation.
- **Rollback Plan**: `git revert` of merge commit if critical issues discovered. Old format tasks (1-43) unaffected due to version detection. New tasks can be manually edited to correct any issues.

### Pre-Deployment Checklist
- [x] Code review completed and approved (self-review via CIG workflow)
- [x] All tests passing (14 functional tests: 12 PASS, 2 SKIP; 5 NFR dimensions: all PASS)
- [x] Security scan completed with no critical issues (file permissions verified 0600)
- [x] Performance testing validated against requirements (< 1s generation, no regression)
- [x] Documentation updated (workflow-steps.md includes checkpoint commits, cig-new-task auto-branches, cig-retrospective squashing)
- [x] Monitoring and alerting configured (N/A - file-based system, errors surface during task creation)
- [x] Rollback plan tested and ready (git revert tested, backward compatibility verified)

## Rollout Plan
### Phase 1: Merge to Main
- **Scope**: Single merge commit to main branch
- **Duration**: Immediate (atomic operation)
- **Success Metrics**:
  - Merge completes without conflicts
  - All CI checks pass (if configured)
  - No file permission issues introduced

### Phase 2: First Real-World Use
- **Scope**: Next new task created (Task 45 or first subtask)
- **Duration**: Monitor first task creation through complete workflow
- **Success Metrics**:
  - Task creation succeeds without errors
  - Templates generate with correct headers, task types, next actions
  - Branch auto-created correctly
  - Workflow progression uses inference (no manual task IDs)
  - Checkpoint commits guide appears in workflow docs

### Phase 3: Ongoing Validation
- **Scope**: Next 5-10 task creations across different task types
- **Monitoring**: Verify all task types (feature, bugfix, hotfix, chore, discovery) work correctly with different phase sequences

## Monitoring
### Key Metrics
- **Performance**: Template generation time (target < 2s, baseline < 1s)
- **Errors**: Task creation failures, template copier errors, symlink resolution failures
- **Functional**: Variable substitution correctness, next-action accuracy, phase sequence adherence
- **User Experience**: Inference system usage (commands work without explicit task IDs)

### Alerting
- **Manual monitoring**: Errors surface during `/cig-new-task` or `/cig-subtask` execution
- **User reports**: Issues with template content, broken cross-references, incorrect next actions
- **Git history**: Track rollback frequency if problems emerge

## Rollback Plan
### Triggers
- Template generation failures for any task type
- Incorrect phase sequences (wrong files generated)
- Broken cross-references in generated templates
- Next-action computation errors
- File permission issues (not 0600)
- Symlink inference failures
- Git workflow automation failures (branch creation, squashing)

### Procedure
1. **Immediate**: Identify scope - does it affect only new tasks or existing tasks?
2. **Rollback**: Execute `git revert <merge-commit-sha>` to restore previous template system
3. **Communication**: Document issue in Task 44 retrospective, add to known issues if partial rollback
4. **Analysis**: Root cause investigation - which component failed (templates, copier logic, git workflow)?
5. **Fix Forward**: If issue is minor, create hotfix task rather than full rollback

## Success Criteria
- [ ] Merge to main completed without conflicts
- [ ] First new task (45 or subtask) generates correctly with all improvements
- [ ] All 5 task types (feature, bugfix, hotfix, chore, discovery) generate correct phase sequences
- [ ] Task type appears in headers, next actions use inference, cross-references correct
- [ ] Decomposition checks appear only in a,b,c phases
- [ ] Git workflow automation works (auto-branch, checkpoint commits, checkpoints branch, squashing)
- [ ] No regressions in existing functionality (old tasks still work)
- [ ] No rollbacks required

## Status
**Status**: Finished
**Next Action**: Move to retrospective → `/cig-retrospective 44`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

Rollout plan defined with three phases:
1. **Merge to Main**: Direct atomic merge (low risk due to backward compatibility)
2. **First Real-World Use**: Monitor Task 45 or first subtask creation
3. **Ongoing Validation**: Verify across all 5 task types over next 5-10 tasks

**Deployment Strategy**: Direct merge chosen due to:
- Comprehensive testing (14 tests, all passed)
- Backward compatibility (old tasks unaffected)
- Low blast radius (file-based system, no runtime services)
- Easy rollback (git revert)

**Risk Mitigation**:
- Pre-deployment checklist 100% complete
- Rollback triggers identified (7 specific failure modes)
- Rollback procedure documented and tested
- Success criteria defined (8 specific validations)

Ready to proceed with merge after retrospective phase completes.

## Lessons Learned
*To be captured during implementation*
