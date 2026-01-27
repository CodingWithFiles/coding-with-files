# Fix format detector for v2.1 format - Testing

## Task Reference
- **Task ID**: internal-30
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/30-fix-format-detector-for-v2.1-format
- **Template Version**: 2.1

## Goal
Validate header-based v2.1 format detection with file fallback, template updates, trampoline consolidation, and task migration.

## Test Strategy

### Test Levels
- **Integration Tests**: Primary focus - verify detect_format() with TaskPath module integration
- **System Tests**: End-to-end command validation (hierarchy-resolver, /cig-status, etc.)
- **Regression Tests**: Verify v2.0 and v1.0 detection unchanged
- **Acceptance Tests**: Verify all success criteria from planning phase

**Rationale**: No unit tests needed (simple detection logic). Focus on integration and system tests since changes span multiple components.

### Test Coverage Targets
- **Overall Coverage**: 100% of modified components
- **Critical Paths**: 100% - v2.1 detection is core functionality
- **Edge Cases**: Version mismatch warning, partial tasks, missing headers
- **Regression**: All v2.0 and v1.0 tasks (verify no breaking changes)

### File Naming Conventions (Critical for Testing)
- **v1.0 format**: `plan.md` (single monolithic file)
- **v2.0 format**: `a-plan.md`, `d-implementation.md`, `e-testing.md`, `f-rollout.md`, etc. (8 files)
- **v2.1 format**: `a-task-plan.md`, `e-testing-plan.md`, `f-implementation-exec.md`, etc. (10 files, different names)
- **CRITICAL**: v2.0 uses `a-plan.md`, NOT `a-task-plan.md` (Task 29 renamed files for v2.1)

### Test Execution Order
1. **Phase 1 Tests** - Core detection logic with warnings
2. **Phase 2 Tests** - Template headers and new task creation
3. **Phase 3 Tests** - Task migration verification
4. **Phase 4 Tests** - Regression and security validation

## Test Cases

### Phase 1: Core Detection Logic Tests

#### TC-1: v2.1 Detection with Mismatch Warning (Pre-Migration)
- **Given**: Task 30 exists with header "Template Version: 2.0" but has e-testing-plan.md and f-implementation-exec.md files
- **When**: Run `.cig/scripts/command-helpers/hierarchy-resolver 30`
- **Then**:
  - Warning printed to stderr: "WARNING: Version mismatch in [...]/30-bugfix-fix-format-detector-for-v2.1-format"
  - Warning shows: "Header says: v2.0"
  - Warning shows: "Files indicate: v2.1"
  - Warning shows: "Using header version (v2.0)"
  - Output shows: "Format: v2.0" (header takes precedence)

#### TC-2: Trampoline Uses CIG::TaskPath (status-aggregator)
- **Given**: Task 30 exists, status-aggregator updated to use CIG::TaskPath::resolve()
- **When**: Run `.cig/scripts/command-helpers/status-aggregator 30 2>&1 | head -1`
- **Then**: No errors, script executes successfully (routes to correct version-specific script)

#### TC-3: Trampoline Uses CIG::TaskPath (context-inheritance)
- **Given**: Task 30 exists, context-inheritance updated to use CIG::TaskPath::resolve()
- **When**: Run `.cig/scripts/command-helpers/context-inheritance 30 2>&1 | head -1`
- **Then**: No errors, script executes successfully (routes to correct version-specific script)

### Phase 2: Template Header Tests

#### TC-4: New Task Created with v2.1 Headers
- **Given**: Templates updated to "Template Version: 2.1"
- **When**: Create test task: `template-copier --task-type=bugfix --destination=implementation-guide/99-test-v21 --task-num=99 --description="Test v2.1 headers"`
- **Then**:
  - Task created successfully
  - All workflow files contain "Template Version: 2.1"
  - `hierarchy-resolver 99` reports "Format: v2.1"
  - No version mismatch warning

#### TC-5: New Task Detection (No Warning)
- **Given**: Test task 99 created in TC-4
- **When**: Run `hierarchy-resolver 99`
- **Then**:
  - Output shows "Format: v2.1"
  - No warning printed (header matches files)
  - stderr is empty (no mismatch)

### Phase 3: Task Migration Tests

#### TC-6: Task 26 Migration
- **Given**: Task 26 headers updated to "Template Version: 2.1"
- **When**: Run `hierarchy-resolver 26`
- **Then**:
  - Output shows "Format: v2.1"
  - No version mismatch warning
  - All 7 workflow files have "Template Version: 2.1" header

#### TC-7: Task 30 Migration
- **Given**: Task 30 headers updated to "Template Version: 2.1"
- **When**: Run `hierarchy-resolver 30`
- **Then**:
  - Output shows "Format: v2.1"
  - No version mismatch warning
  - All 7 workflow files have "Template Version: 2.1" header

#### TC-8: status-aggregator Routes to v2.1 Script
- **Given**: Task 30 migrated to v2.1 headers
- **When**: Run `/cig-status 30` (uses status-aggregator)
- **Then**:
  - Command executes successfully
  - Output includes workflow breakdown (v2.1 feature)
  - Shows 10 workflow files (a-j) with status indicators

#### TC-9: context-inheritance Routes to v2.1 Script
- **Given**: Task 30 migrated to v2.1 headers
- **When**: Invoke context-inheritance via workflow command (e.g., `/cig-requirements 30`)
- **Then**:
  - Command executes successfully
  - Context inheritance uses v2.1 file structure
  - No errors about missing files

### Phase 4: Regression Tests

#### TC-10: v1.0 Task Detection (Pure v1.0)
- **Given**: Pure v1.0 task exists (has plan.md only, never migrated)
- **When**: Run `hierarchy-resolver <task-num>` or check with `find implementation-guide -name "plan.md"`
- **Then**:
  - Output shows "Format: v1.0"
  - No version mismatch warning
  - File-based detection works: presence of `plan.md` indicates v1.0

#### TC-11: v2.0 Task Detection (Migrated from v1.0)
- **Given**: v2.0 task that was migrated from v1.0 (has `a-plan.md`, `d-implementation.md`, header says "2.0")
- **When**: Run `hierarchy-resolver <task-num>` (e.g., Task 24)
- **Then**:
  - Output shows "Format: v2.0" (not v1.0!)
  - No version mismatch warning
  - File-based detection: presence of `a-plan.md` OR `d-implementation.md` indicates v2.0

#### TC-12: v2.0 Task Detection (Native v2.0)
- **Given**: Native v2.0 task created with v2.0 templates (never migrated from v1.0)
- **When**: Run `hierarchy-resolver <task-num>`
- **Then**:
  - Output shows "Format: v2.0"
  - No version mismatch warning
  - Header and file-based detection both agree on v2.0

#### TC-13: v2.1 Task Detection (After Migration)
- **Given**: v2.1 task with correct headers (Tasks 26, 30 after migration in Phase 3)
- **When**: Run `hierarchy-resolver <task-num>`
- **Then**:
  - Output shows "Format: v2.1"
  - No version mismatch warning
  - Header and file-based detection both agree on v2.1

### Edge Case Tests

#### TC-14: Partial v2.1 Task (Only a-d Files)
- **Given**: Task directory with only a-d files (e-testing-plan.md not yet created)
- **When**: Run `hierarchy-resolver <task-num>`
- **Then**:
  - Output shows "Format: v2.0" (file-based detection: no e/f files)
  - If header says "2.1", warning appears about mismatch
  - Behavior is acceptable (task incomplete)

#### TC-15: Missing Header (Fallback to File Detection)
- **Given**: Task with v2.1 files but no "Template Version" header in any file
- **When**: Run `hierarchy-resolver <task-num>`
- **Then**:
  - Output shows "Format: v2.1" (file-based fallback)
  - No warning (header absent, not mismatched)
  - detect_format() returns file_version

### Non-Functional Test Cases

#### NF-1: Performance - Detection Speed
- **Test**: Measure time for `hierarchy-resolver 30` to complete
- **Target**: <100ms (detection should be fast)
- **Rationale**: Format detection runs frequently, must not slow down commands

#### NF-2: Usability - Warning Message Clarity
- **Test**: Review warning message when header/files mismatch
- **Target**: Warning provides clear action (run migration script)
- **Rationale**: Users need guidance on fixing version mismatches

#### NF-3: Reliability - Script Hash Verification
- **Test**: Run `/cig-security-check verify` after changes
- **Target**: All modified scripts pass hash verification
- **Rationale**: Ensures script integrity maintained

#### NF-4: Maintainability - Code Consolidation
- **Test**: Grep for duplicate detection logic: `grep -rn "e-testing-plan\|f-implementation-exec" .cig/scripts/`
- **Target**: Only appears in TaskPath.pm and template-copier (different purpose)
- **Rationale**: DRY principle - single source of truth

## Test Environment

### Setup Requirements
- **Clean Git State**: Working directory clean before testing
- **Existing Tasks**: Tasks 26, 30 available for migration testing
- **v2.0 Task**: At least one v2.0 task for regression testing
- **Script Permissions**: All helper scripts executable (chmod +x)

### Test Data
- **Task 26**: Existing v2.1 bugfix task (pre-migration state: header 2.0, files v2.1)
- **Task 30**: Existing v2.1 bugfix task (pre-migration state: header 2.0, files v2.1)
- **Task 99**: Temporary test task (create in TC-4, cleanup after tests)
- **v1.0 Task**: Pure v1.0 task with plan.md (if exists, check with `find implementation-guide -name "plan.md"`)
- **v2.0 Migrated Task**: Task 24 or similar (has `a-plan.md`, `d-implementation.md`, header says "2.0")
- **v2.0 Native Task**: Any v2.0 task created with v2.0 templates (never migrated from v1.0)

### Automation
- **Test Framework**: Manual testing via bash commands
- **Test Script**: Create `test-format-detection.sh` for automated regression testing
- **CI/CD**: Not applicable (internal CIG system, no CI/CD pipeline)
- **Cleanup**: Remove test task 99 after Phase 2 tests complete

## Validation Criteria

### Functional Validation
- [ ] All 15 functional test cases pass (TC-1 through TC-15)
- [ ] v2.1 detection works with correct headers (TC-6, TC-7, TC-13)
- [ ] Warning appears on mismatch (TC-1)
- [ ] Trampolines use centralized detection (TC-2, TC-3, TC-8, TC-9)
- [ ] New tasks created with v2.1 headers (TC-4, TC-5)
- [ ] v1.0 detection works (TC-10)
- [ ] v2.0 detection works for migrated tasks (TC-11)
- [ ] v2.0 detection works for native tasks (TC-12)
- [ ] Edge cases handled (TC-14, TC-15)

### Non-Functional Validation
- [ ] All 4 non-functional test cases pass
- [ ] Performance <100ms (NF-1)
- [ ] Warning messages clear (NF-2)
- [ ] Script hashes verified (NF-3)
- [ ] Code consolidated (NF-4)

### Coverage Validation
- [ ] 100% of modified components tested
- [ ] All 4 implementation phases validated
- [ ] Edge cases covered (TC-12, TC-13)
- [ ] Backward compatibility verified (TC-10, TC-11)

### Sign-Off Criteria
- [ ] All test cases documented with pass/fail status
- [ ] Zero test failures
- [ ] Zero regressions detected
- [ ] Script hashes updated and verified
- [ ] Test task 99 cleaned up

## Status
**Status**: Finished
**Next Action**: Proceed to retrospective → `/cig-retrospective 30`
**Blockers**: None
**Change Log**:
- 2026-01-27: Added TC-10 (v1.0 detection), TC-11 (v2.0 migrated), TC-12 (v2.0 native), TC-13 (v2.1)
- 2026-01-27: Added file naming conventions section for clarity
- 2026-01-27: Updated test counts from 13 to 15 functional tests
- 2026-01-27: Test plan completed and validated

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
