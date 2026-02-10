# add slug generation to template-copier - Testing Plan
**Task**: 53 (bugfix)

## Task Reference
- **Task ID**: internal-53
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/53-add-slug-generation-to-template-copier
- **Template Version**: 2.1

## Goal
Verify slug generation correctness, destination auto-construction, and backward compatibility through manual function testing.

## Test Strategy
### Test Approach: Manual Function-Level Testing
Script modification testing (no automated test framework). Focus on:
1. **Function correctness**: Slug generation produces exact bash algorithm output
2. **Integration**: Optional destination parameter works in both modes
3. **Backward compatibility**: Existing workflows unchanged with explicit destination
4. **Edge cases**: Special characters, long strings, boundary conditions

### Test Levels
- **Function Tests**: Test `generate_slug()` with various inputs, compare to bash output
- **Integration Tests**: Test `template-copier-v2.1` with/without destination parameter
- **Regression Tests**: Verify existing task creation workflows still work

### Test Coverage Targets
- **Function Tests**: 100% - all slug algorithm steps verified (lowercase, special chars, hyphens, truncate)
- **Integration Tests**: 100% - both destination modes tested (explicit, omitted)
- **Regression Tests**: 100% - all task types tested (feature, bugfix, hotfix, chore)
- **Edge Cases**: 100% - special characters, empty, long strings, unicode

## Test Cases

### Functional Test Cases

**TC-F1: Slug Generation - Normal Case**
- **Given**: Description "Add User Authentication"
- **When**: Call `generate_slug("Add User Authentication")`
- **Then**: Returns "add-user-authentication"
- **Verification**: Compare to bash: `echo "Add User Authentication" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]//g' | tr ' ' '-' | sed 's/--*/-/g' | cut -c1-50`

**TC-F2: Slug Generation - Special Characters**
- **Given**: Description "Fix bug: API timeout (500ms)"
- **When**: Call `generate_slug("Fix bug: API timeout (500ms)")`
- **Then**: Returns "fix-bug-api-timeout-500ms" (special chars removed)
- **Verification**: Bash comparison confirms exact match

**TC-F3: Slug Generation - Long String**
- **Given**: Description "This is a very long task description that exceeds fifty characters"
- **When**: Call `generate_slug("This is a very long task description that exceeds fifty characters")`
- **Then**: Returns "this-is-a-very-long-task-description-that-exc" (50 chars)
- **Verification**: Length is exactly 50, truncation correct

**TC-F4: Slug Generation - Consecutive Hyphens**
- **Given**: Description "Add    multiple   spaces    test"
- **When**: Call `generate_slug("Add    multiple   spaces    test")`
- **Then**: Returns "add-multiple-spaces-test" (spaces collapsed to single hyphens)

**TC-F5: Destination Auto-Construction**
- **Given**: Parameters: `--task-type=bugfix --task-num=53 --description="add slug generation to template-copier"` (no --destination)
- **When**: template-copier-v2.1 invoked
- **Then**: Destination constructed as "implementation-guide/53-bugfix-add-slug-generation-to-template-copier"
- **Verification**: Path matches `directory-structure.pattern` from config

**TC-F6: Backward Compatibility - Explicit Destination**
- **Given**: Parameters include explicit `--destination=/tmp/test-task`
- **When**: template-copier-v2.1 invoked with explicit destination
- **Then**: Uses provided destination "/tmp/test-task", slug generation not used for path
- **Verification**: Destination unchanged from input, no auto-construction

**TC-F7: Integration - Task Creation Without Destination**
- **Given**: cig-new-task invocation without explicit destination construction
- **When**: Command calls template-copier with type/num/description only
- **Then**: Templates copied to auto-constructed path, branch created successfully
- **Verification**: Directory exists at expected path, templates present, git branch matches

### Non-Functional Test Cases

**TC-NF1: Error Handling - Missing Config**
- **Test**: Invoke template-copier when cig-project.json missing or malformed
- **Expected**: Clear error message, exit code 2, no partial state

**TC-NF2: Performance - Slug Generation**
- **Test**: Generate slugs for 100 descriptions
- **Expected**: Sub-millisecond per operation, no memory issues

**TC-NF3: Compatibility - Various Task Types**
- **Test**: Create tasks for all types (feature, bugfix, hotfix, chore, discovery) with auto destination
- **Expected**: All types work, paths follow pattern correctly

## Test Environment
### Setup Requirements
- **Git repository**: CIG project repository with cig-project.json
- **Perl environment**: Perl 5.x with CIG modules available
- **Test data**: Sample descriptions covering edge cases

### Automation
**Manual Testing**: No automated test framework needed for script modification
- **Test Execution**: Manual command invocations, visual verification
- **Comparison**: Bash pipeline vs Perl function output comparison
- **Validation**: Directory existence checks, file content verification

## Validation Criteria
- [ ] All 7 functional tests pass (TC-F1 through TC-F7)
- [ ] All 3 non-functional tests pass (TC-NF1 through TC-NF3)
- [ ] Slug generation output matches bash algorithm 100%
- [ ] Backward compatibility maintained (explicit destination still works)
- [ ] Existing task creation workflows unchanged
- [ ] Security hash updated and verification passes

**Success Metric**: 10/10 tests passing (100%)

## Status
**Status**: Finished
**Next Action**: /cig-implementation-exec 53
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
