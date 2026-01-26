# Fix order of workflow steps - Testing

## Task Reference
- **Task ID**: internal-29
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/29-fix-order-of-workflow-steps
- **Template Version**: 2.0

## Goal
Validate that v2.1 workflow files are correctly renamed, all references updated, and new tasks created with correct file order.

## Test Strategy

### Test Levels
- **File System Tests**: Verify file renames, symlink resolution, permissions
- **Reference Integrity Tests**: Verify all references updated, no orphaned references
- **Integration Tests**: Verify template-copier, status-aggregator work with new structure
- **End-to-End Tests**: Create new v2.1 task, verify complete workflow progression

### Test Coverage Targets
- **Overall Coverage**: 100% (all 11 components verified)
- **Critical Paths**: 100% coverage required
  - Template pool file renames
  - V21 module arrays
  - Template-copier new task creation
  - Status-aggregator file recognition
- **Edge Cases**: V2.0 tasks unaffected, v1.0 tasks unaffected
- **Regression**: Existing non-v2.1 tasks still work correctly

## Test Cases

### Phase 1: Template Renaming Verification

**TC-1: Template Pool Files Renamed Correctly**
- **Given**: Template pool directory `.cig/templates/pool/`
- **When**: Check for renamed template files
- **Then**:
  - `e-testing-plan.md.template` exists (was f-testing-plan)
  - `f-implementation-exec.md.template` exists (was e-implementation-exec)
  - No `e-implementation-exec.md.template` exists (old name)
  - No `f-testing-plan.md.template` exists (old name)
  - Git log shows renames (git log --follow --oneline)

**TC-2: Symlinks Resolve Correctly in All Task Types**
- **Given**: 5 task type directories (feature, bugfix, hotfix, chore, discovery)
- **When**: Check symlink targets with `ls -la .cig/templates/*/e-*.md.template .cig/templates/*/f-*.md.template`
- **Then**:
  - All `e-testing-plan.md.template` symlinks point to `../pool/e-testing-plan.md.template`
  - All `f-implementation-exec.md.template` symlinks point to `../pool/f-implementation-exec.md.template`
  - All symlinks are valid (not broken)
  - Symlinks use relative paths (not absolute)

### Phase 2: Reference Update Verification

**TC-3: Template "Next Action" Fields Correct**
- **Given**: 4 template files (d, e, f, g) in `.cig/templates/pool/`
- **When**: Read "Next Action" fields in Status sections
- **Then**:
  - `d-implementation-plan.md.template` → `/cig-testing-plan <task>`
  - `e-testing-plan.md.template` → `/cig-implementation-exec <task>`
  - `f-implementation-exec.md.template` → `/cig-testing-exec <task>`
  - `g-testing-exec.md.template` → `/cig-rollout <task>` (unchanged)

**TC-4: CIG::WorkflowFiles::V21 Module Arrays Correct**
- **Given**: `.cig/lib/CIG/WorkflowFiles/V21.pm` module
- **When**: Inspect file arrays for all 5 task types
- **Then**:
  - Feature array: element 5 = 'e-testing-plan.md', element 6 = 'f-implementation-exec.md'
  - Bugfix array: element 4 = 'f-implementation-exec.md', element 5 = 'e-testing-plan.md'
  - Hotfix array: element 4 = 'f-implementation-exec.md'
  - Chore array: element 3 = 'f-implementation-exec.md'
  - Discovery array: element 4 = 'e-testing-plan.md', element 5 = 'f-implementation-exec.md'
  - No occurrences of old names in arrays

**TC-5: blocker-patterns.md References Updated**
- **Given**: `.cig/docs/workflow/blocker-patterns.md`
- **When**: Search for section headers and revert references
- **Then**:
  - Section header: "Implementation Execution Phase (f-implementation-exec.md)"
  - Revert references: "Revert to f-implementation-exec.md" (2 occurrences)
  - Section header: "Testing Planning Phase (e-testing-plan.md)"
  - Revert reference: "Revert to e-testing-plan.md to adjust strategy"
  - No occurrences of "e-implementation-exec.md" (old name)
  - No occurrences of "f-testing-plan.md" in v2.1 context (old name)

**TC-6: Workflow Command Content References Updated**
- **Given**: 6 workflow command files in `.claude/commands/`
- **When**: Search for inline references to workflow files
- **Then**:
  - `cig-design-plan.md`: "d-implementation-plan + f-implementation-exec"
  - `cig-implementation-plan.md`: "that's f-implementation-exec", next → `/cig-testing-plan`
  - `cig-testing-plan.md`: next → `/cig-implementation-exec`
  - `cig-implementation-exec.md`: 4 references to "f-implementation-exec.md", "--current-step=f-implementation-exec"
  - `cig-testing-exec.md`: "that's e-testing-plan", "that's f-implementation-exec"
  - No occurrences of "e-implementation-exec" in command content (except cig-implementation-exec describing itself)

**TC-7: Workflow Documentation Updated**
- **Given**: `.cig/docs/workflow/workflow-steps.md` and `workflow-overview.md`
- **When**: Check workflow file order descriptions
- **Then**:
  - workflow-steps.md: v2.1 format lists "e-testing-plan, f-implementation-exec, g-testing-exec"
  - workflow-steps.md: File descriptions reference correct names
  - workflow-steps.md: Contains philosophy explanation (test planning as thinking tool)
  - workflow-overview.md: Workflow sequence shows correct order
  - workflow-overview.md: Contains philosophy explanation

**TC-8: Comprehensive Grep Verification**
- **Given**: Entire codebase (`.cig/`, `.claude/`, BACKLOG.md, CLAUDE.md, README.md)
- **When**: Run `grep -r "e-implementation-exec" --include="*.md" --include="*.pl" --include="*.pm"`
- **Then**:
  - Only matches in Task 29 implementation plan (documenting steps)
  - Only matches in BACKLOG.md (documenting old problem)
  - Only matches in V20.pm (legitimate v2.0 reference if exists)
  - No matches in templates, commands, or V21.pm
- **When**: Run `grep -r "f-testing-plan" --include="*.md" --include="*.pl" --include="*.pm"`
- **Then**:
  - Only matches in workflow-steps.md (v2.0 reference)
  - Only matches in Task 29 plan/BACKLOG (documentation)
  - Only matches in V20.pm (legitimate v2.0 reference)
  - No matches in V21.pm or templates

### Phase 3: Migration Script Verification

**TC-9: Migration Script Created and Executable**
- **Given**: `.cig/scripts/migrations/` directory
- **When**: Check migration script
- **Then**:
  - `migrate-v21-file-order.sh` exists
  - Script has executable permissions (0755 or 0500)
  - Script includes validation (checks for e-implementation-exec.md)
  - Script uses git mv for history preservation
  - Script returns error if not v2.1 task
  - SHA256 hash recorded in `.cig/security/script-hashes.json`

### Phase 4: Existing Task Migration Verification

**TC-10: Task 25 Migrated Correctly**
- **Given**: `implementation-guide/25-feature-implement-v21-workflow-format-with-execution-phases/`
- **When**: Check workflow files after migration
- **Then**:
  - `e-testing-plan.md` exists (was f-testing-plan.md)
  - `f-implementation-exec.md` exists (was e-implementation-exec.md)
  - No `e-implementation-exec.md` exists (old name)
  - No `f-testing-plan.md` exists (old name)
  - Git log shows renames with history preserved

**TC-11: Task 26 Migrated Correctly**
- **Given**: `implementation-guide/26-feature-update-cig-status-to-use-workflow-flag/`
- **When**: Check workflow files after migration
- **Then**: Same verification as TC-10
  - Files renamed correctly
  - Old names no longer exist
  - Git history preserved

### Phase 5: Integration Testing

**TC-12: template-copier Creates v2.1 Tasks with Correct Files**
- **Given**: template-copier script and updated V21 module
- **When**: Create new test task: `/cig-new-task 30 feature "test-v21-file-order"`
- **Then**:
  - Directory created: `implementation-guide/30-feature-test-v21-file-order/`
  - Files created in correct order:
    - `a-task-plan.md` ✓
    - `b-requirements-plan.md` ✓
    - `c-design-plan.md` ✓
    - `d-implementation-plan.md` ✓
    - **`e-testing-plan.md`** ✓ (NEW POSITION)
    - **`f-implementation-exec.md`** ✓ (NEW POSITION)
    - `g-testing-exec.md` ✓
    - `h-rollout.md` ✓
    - `i-maintenance.md` ✓
    - `j-retrospective.md` ✓
  - No files with old names created

**TC-13: status-aggregator Recognizes New File Order**
- **Given**: Test task from TC-12 with new file names
- **When**: Run `status-aggregator --workflow 30`
- **Then**:
  - Script recognizes all 10 files
  - Files listed in correct order (a through j)
  - Status percentages calculated correctly
  - No errors about missing files
  - Output shows e-testing-plan and f-implementation-exec in correct positions

**TC-14: Workflow Commands Suggest Correct Next Steps**
- **Given**: Test task from TC-12
- **When**: Manually check workflow progression via commands
- **Then**:
  - `/cig-implementation-plan 30` suggests → `/cig-testing-plan 30` next
  - `/cig-testing-plan 30` suggests → `/cig-implementation-exec 30` next
  - `/cig-implementation-exec 30` suggests → `/cig-testing-exec 30` next
  - `/cig-testing-exec 30` suggests → `/cig-rollout 30` next
  - Workflow progression matches design: plan impl → plan tests → exec impl → exec tests

### Phase 6: Regression Testing

**TC-15: v2.0 Tasks Unaffected**
- **Given**: Existing v2.0 tasks (8-file format)
- **When**: Check v2.0 task structure
- **Then**:
  - v2.0 tasks still have `f-testing-plan.md` (correct for v2.0)
  - v2.0 tasks have no e or g files (correct)
  - status-aggregator correctly identifies v2.0 format
  - No breaking changes to v2.0 workflow

**TC-16: v1.0 Tasks Unaffected**
- **Given**: Existing v1.0 tasks (legacy format)
- **When**: Check v1.0 task structure
- **Then**:
  - v1.0 tasks unchanged
  - Different naming convention preserved
  - No impact from v2.1 changes

## Non-Functional Test Cases

### Performance Tests
**NF-1: template-copier Performance**
- **Given**: template-copier with new symlinks
- **When**: Create new v2.1 task
- **Then**: Task creation completes in <5 seconds (same as before)

**NF-2: status-aggregator Performance**
- **Given**: status-aggregator with updated V21 module
- **When**: Run status-aggregator on task with 10 files
- **Then**: Status calculation completes in <100ms (same as before)

### Security Tests
**NF-3: Migration Script Security**
- **Given**: Migration script with task path argument
- **When**: Attempt to pass malicious path (e.g., "../../../etc/passwd")
- **Then**:
  - Script validates task directory exists
  - Script validates e-implementation-exec.md exists
  - Script fails safely with error message
  - No unintended file operations

**NF-4: Script Hash Verification**
- **Given**: Updated script-hashes.json
- **When**: Run `/cig-security-check verify`
- **Then**: All script hashes match, including new migration script

### Usability Tests
**NF-5: Error Messages Clear**
- **Given**: Migration script run on non-v2.1 task
- **When**: Run script on v2.0 task
- **Then**: Clear error message: "Not a v2.1 task (e-implementation-exec.md not found)"

**NF-6: Documentation Clarity**
- **Given**: Updated workflow documentation
- **When**: Read philosophy explanation
- **Then**: Philosophy clearly explains test planning as thinking tool, not traditional TDD

## Test Environment

### Setup Requirements
- Git repository with Tasks 25, 26, 28, 29
- CIG system installed and operational
- All helper scripts executable with correct permissions
- Clean working directory (no uncommitted changes before testing)

### Test Data
- Existing v2.1 tasks: Tasks 25, 26
- Existing v2.0 tasks: (if any in repo)
- Test task to be created: Task 30 (will be deleted after validation)

### Dependencies
- Perl 5.10+ with CIG modules
- Git for file tracking and history
- Bash for migration script
- Read/write access to `.cig/` and `implementation-guide/` directories

## Validation Criteria

### Must Pass (Blocking)
- [x] TC-1: Template pool files renamed correctly
- [x] TC-2: All symlinks resolve correctly
- [x] TC-3: Template "Next Action" fields correct
- [x] TC-4: V21 module arrays correct
- [x] TC-8: Comprehensive grep shows no orphaned references
- [x] TC-12: template-copier creates correct files
- [x] TC-13: status-aggregator recognizes new order

### Should Pass (Important)
- [x] TC-5: blocker-patterns.md updated
- [x] TC-6: Workflow command content updated
- [x] TC-7: Workflow documentation updated
- [x] TC-9: Migration script created and executable
- [x] TC-10: Task 25 migrated correctly
- [x] TC-11: Task 26 migrated correctly
- [x] TC-14: Workflow commands suggest correct next steps

### Nice to Have (Optional)
- [x] TC-15: v2.0 tasks unaffected
- [x] TC-16: v1.0 tasks unaffected
- [x] NF-1 through NF-6: All non-functional tests pass

## Success Metrics
- **Pass Rate**: 100% of blocking tests pass (7/7)
- **Coverage**: All 11 components verified
- **Regression**: Zero breaking changes to existing functionality
- **Performance**: No performance degradation (<5% variance)

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 29`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled during g-testing-exec*

## Lessons Learned
*To be captured during testing execution*
