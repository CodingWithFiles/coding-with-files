# Hierarchical Workflow System with Dynamic Step Transitions - Rollout

## Task Reference
- **Task ID**: internal-3
- **Type**: Feature
- **Status**: Not Started

## Rollout Strategy

This rollout is complex enough to warrant subtasks:

1. **Migration of existing tasks** - Structural changes, git renames
2. **Documentation updates** - Substantial content changes

Breaking these into subtasks provides:
- Focused work streams
- Isolated git commits per concern
- Easier rollback if issues found
- Better testing granularity

## Rollout Phases

### Phase 1: Pre-Rollout Validation
**Status**: Not Started

**Checklist**:
- [ ] All implementation complete
- [ ] All tests passing (from e-testing.md)
- [ ] Helper scripts verified and executable
- [ ] Templates validated
- [ ] Commands functional
- [ ] Backward compatibility confirmed
- [ ] Git branch created and up to date

**Validation**:
```bash
/cig-status 3  # Verify task status
/cig-security-check verify  # Verify script integrity
git status  # Ensure clean state
```

### Phase 2: Create Migration Subtask
**Status**: Not Started

**Demonstrates**: "Reached rollout, realized complexity, created subtask"

**Command**:
```bash
/cig-subtask 3 3.1 chore "Migrate existing tasks to hierarchical structure"
```

**Expected Result**:
- Subtask created: `implementation-guide/feature/3-hierarchical-workflow-system-with-dynamic-step-transitions/3.1-chore-migrate-existing-tasks/`
- Ready for migration planning

### Phase 3: Execute Migration Subtask
**Status**: Not Started

See: `3.1-chore-migrate-existing-tasks/` for detailed migration plan and execution

**Migration Scope**:
- Task 1: `chore/1-documentation-updates-project-status/` → `1-chore-documentation-updates-project-status/`
- Task 2: `chore/2-script-based-cig-command-helpers/` → `2-chore-script-based-cig-command-helpers/`
- Task 3: `feature/3-hierarchical-workflow-system/` → `3-feature-hierarchical-workflow-system-with-dynamic-step-transitions/`

**Migration Outcomes Expected**:
- [ ] All tasks migrated to new structure
- [ ] Git history preserved via `git mv`
- [ ] Single pure rename commit
- [ ] All tasks accessible via new paths
- [ ] Commands work with migrated tasks
- [ ] No broken references

**Validation**:
- [ ] `/cig-status` shows all tasks correctly
- [ ] Old paths no longer exist
- [ ] New paths fully functional
- [ ] `git log --follow` shows history preservation

### Phase 4: Documentation Updates
**Status**: Not Started

**Option A**: Create documentation subtask if substantial
```bash
/cig-subtask 3 3.2 chore "Update documentation for hierarchical workflow"
```

**Option B**: Handle in maintenance phase if minimal

**Documentation to Update**:
- [ ] README.md - Examples with new structure
- [ ] COMMANDS.md - New workflow commands, updated examples
- [ ] CLAUDE.md - Updated architecture section
- [ ] scratchpad.md - Mark as implemented/archived
- [ ] .cig/README.md - Helper script documentation

**Validation**:
- [ ] All examples use correct structure
- [ ] No references to old format (except backward compat notes)
- [ ] Commands documented with examples
- [ ] Architecture diagrams updated

### Phase 5: Final System Validation
**Status**: Not Started

**Full System Test**:
```bash
# Test new task creation
/cig-new-task 5 feature "Validation test task"
/cig-subtask 5 5.1 chore "Validation subtask"

# Test workflow commands
/cig-plan 5
/cig-requirements 5/5.1

# Test status display
/cig-status

# Test backward compatibility
/cig-status 1  # Migrated old task

# Test extraction
/cig-extract a-plan.md 5
```

**Validation Checklist**:
- [ ] New tasks use new format
- [ ] Subtask creation works at multiple levels
- [ ] All workflow commands functional
- [ ] Context inheritance works
- [ ] Status display shows hierarchy
- [ ] Migrated tasks accessible
- [ ] Extraction works for both formats
- [ ] No errors in any commands

### Phase 6: Cleanup
**Status**: Not Started

**Tasks**:
- [ ] Remove old type-based directories (if empty)
- [ ] Archive scratchpad.md (or mark implemented)
- [ ] Remove test task 4 (if created during testing)
- [ ] Clean up any temporary files
- [ ] Verify git status clean

**Commands**:
```bash
# Remove empty type directories
rmdir implementation-guide/chore 2>/dev/null || true
rmdir implementation-guide/feature 2>/dev/null || true
rmdir implementation-guide/bugfix 2>/dev/null || true
rmdir implementation-guide/hotfix 2>/dev/null || true

# Cleanup test artifacts
rm -rf implementation-guide/4-feature-test-feature-task/

git status
```

## Rollout Subtasks

### 3.1: Migrate Existing Tasks
**Status**: Pending
**Path**: `3.1-chore-migrate-existing-tasks/`

**Deliverables**:
- Migration plan (a-plan.md)
- Executed git mv commands (d-implementation.md)
- Validation results (e-testing.md)

### 3.2: Update Documentation (Optional)
**Status**: To Be Determined
**Path**: `3.2-chore-update-documentation/` (if created)

**Deliverables**:
- Documentation plan
- Updated files
- Validation

## Git Commit Strategy

### Migration Commit (in subtask 3.1)
```
Migrate existing tasks to hierarchical structure

- Rename directories: {type}/{num}-{name} → {num}-{type}-{name}
- Rename workflow files: plan.md → a-plan.md, etc
- Remove type-based directory segregation
- Git tracks as renames for history preservation

Related: internal-3

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Documentation Commit (in subtask 3.2 or maintenance)
```
Update documentation for hierarchical workflow system

- Add new command documentation
- Update examples to new structure
- Document context inheritance
- Add migration guide

Related: internal-3

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Final Rollout Commit
```
Complete rollout of hierarchical workflow system

- All tasks migrated successfully
- Documentation updated
- System validated
- Ready for production use

Related: internal-3

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Rollback Procedure

If critical issues discovered during rollout:

### Rollback Steps
1. **Identify issue severity**
   - Critical: Immediate rollback
   - Major: Consider fix vs rollback
   - Minor: Fix in place

2. **Execute rollback** (if needed)
   ```bash
   # Revert migration commit
   git log --oneline  # Find migration commit hash
   git revert <migration-commit-hash>

   # Or hard reset (if not pushed)
   git reset --hard HEAD~1
   ```

3. **Verify rollback**
   ```bash
   /cig-status  # Verify old structure restored
   ls implementation-guide/  # Check directory structure
   ```

4. **Document issues**
   - Create issue in h-retrospective.md
   - Document root cause
   - Plan fix approach

5. **Re-rollout** (after fix)
   - Fix issues
   - Re-test
   - Execute rollout again

## Monitoring

**During Rollout**:
- Monitor git status at each phase
- Verify commands after each change
- Check `/cig-status` output frequently
- Test both old and new format access

**Post-Rollout**:
- Monitor for user issues
- Check command execution success
- Verify no broken references
- Validate git history integrity

## Success Criteria

Rollout is successful when:
- [ ] All existing tasks migrated
- [ ] Git history preserved
- [ ] All commands functional
- [ ] Status display correct
- [ ] Documentation updated
- [ ] No broken references
- [ ] Backward compatibility maintained
- [ ] Tests passing
- [ ] User validation complete

## Rollout Timeline

**Estimated Duration**: 1-2 days

- Phase 1 (Validation): 30 minutes
- Phase 2 (Create subtask): 5 minutes
- Phase 3 (Migration): 2-4 hours (in subtask 3.1)
- Phase 4 (Documentation): 2-3 hours (in subtask 3.2 or maintenance)
- Phase 5 (Validation): 1 hour
- Phase 6 (Cleanup): 30 minutes

## Communication

**Stakeholders**: User (Matt)

**Updates**:
- Before rollout: Confirm readiness
- After migration: Verify success
- After completion: Final validation

## Notes

- This rollout demonstrates the dynamic workflow pattern we're implementing
- Migration is complex enough to warrant subtask (our own pattern)
- f-rollout.md becomes coordination document (as designed)
- Actual migration work happens in subtask 3.1
- Documentation may be subtask 3.2 or handled in g-maintenance

## Rollout Status

**Current Phase**: Not Started
**Next Action**: Complete implementation and testing phases first
**Blocked By**: Implementation (d-implementation.md), Testing (e-testing.md)
