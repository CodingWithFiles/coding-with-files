# dead-code-removal - Testing Plan
**Task**: 51 (bugfix)

## Task Reference
- **Task ID**: internal-51
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/51-dead-code-removal
- **Template Version**: 2.1

## Goal
Verify dead code removed cleanly with no hidden dependencies or regressions.

## Test Strategy

### Test Approach: Verification-Based Testing
Dead code removal doesn't require traditional unit tests (removed functions had no tests). Testing focuses on verification:
1. **Reference Verification**: Grep search confirms no usage
2. **Security Verification**: Hash validation confirms integrity
3. **Regression Testing**: Existing functionality still works
4. **Smoke Testing**: Manual verification of core workflows

### Test Levels
- **Verification Tests**: Grep searches, security hash checks
- **Regression Tests**: Existing modules still function correctly
- **Smoke Tests**: Manual testing of core CIG workflows (status aggregator, template copier)

**Note**: No unit tests needed (dead functions had no tests by definition)

### Test Coverage Targets
- **Verification**: 100% - all removed functions verified unused
- **Security**: 100% - all modified files hash-verified
- **Regression**: 100% - all CIG core workflows tested
- **Smoke Test**: Manual verification of 3-5 common operations

## Test Cases

### Verification Test Cases

**TC-V1: TaskContextInference Functions Removed**
- **Given**: TaskContextInference.pm has 4 functions removed
- **When**: Grep search for function names in codebase
  ```bash
  grep -r "_get_status_signal\|_score_status\|_get_task_status_score\|_format_uncorrelated" .cig/ .claude/
  ```
- **Then**: Zero matches found (exit code 1)

**TC-V2: WorkflowFiles Function Removed**
- **Given**: CIG::WorkflowFiles.pm has workflow_file_mappings() removed
- **When**: Grep search for "workflow_file_mappings" in codebase
  ```bash
  grep -r "workflow_file_mappings" .cig/ .claude/
  ```
- **Then**: Zero matches found (exit code 1)

**TC-V3: Common Function Removed**
- **Given**: CIG::Common.pm has format_error() removed
- **When**: Grep search for "format_error" in codebase
  ```bash
  grep -r "format_error" .cig/ .claude/
  ```
- **Then**: Zero matches found (exit code 1)

**TC-V4: Security Hashes Updated**
- **Given**: 3 library files modified
- **When**: Run `/cig-security-check verify`
- **Then**: All hashes match, exit code 0, no warnings

**TC-V5: Line Count Verification**
- **Given**: ~160 lines should be removed
- **When**: Check git diff stats
  ```bash
  git diff main --stat
  ```
- **Then**: Approximately 160 deletions, minimal insertions (hash updates only)

### Regression Test Cases

**TC-R1: Status Aggregator Still Works**
- **Given**: TaskContextInference.pm modified
- **When**: Run status aggregator on sample v2.1 task
  ```bash
  .cig/scripts/command-helpers/status-aggregator-v2.1 50
  ```
- **Then**: Output displays correctly, no Perl errors

**TC-R2: Template Copier Still Works**
- **Given**: CIG::WorkflowFiles.pm modified
- **When**: Create test task (if safe) or verify import syntax
  ```bash
  perl -I.cig/lib -MCIG::WorkflowFiles -e 'print "OK\n"'
  ```
- **Then**: Module loads successfully, no import errors

**TC-R3: Context Inheritance Still Works**
- **Given**: TaskContextInference.pm modified
- **When**: Run task context inference
  ```bash
  .cig/scripts/command-helpers/task-context-inference
  ```
- **Then**: Inference runs without errors, output formatted correctly

### Non-Functional Test Cases

**TC-NF1: No Performance Degradation**
- **Test**: Time status aggregator before/after removal
- **Expected**: No measurable difference (dead code doesn't execute)

**TC-NF2: Security Hash Integrity**
- **Test**: Verify all 3 modified files have updated hashes in script-hashes.json
- **Expected**: SHA256 hashes match actual file hashes

**TC-NF3: Code Cleanliness**
- **Test**: Review git diff for unintended changes
- **Expected**: Only intended functions removed, no formatting changes

## Test Environment

### Setup Requirements
- **No special setup needed** - tests run against modified codebase
- **Prerequisites**:
  - Perl 5.x with standard modules
  - Access to `.cig/lib/` directory
  - `grep` command available
  - `/cig-security-check` skill available
- **Test Data**: Use existing CIG tasks (e.g., Task 50) for smoke testing

### Automation
**Manual Testing**: No automated test framework exists for CIG
- **Test Execution**: Manual execution of verification commands
- **CI/CD**: Not applicable (CIG is local documentation system)
- **Test Documentation**: Results recorded in g-testing-exec.md

## Validation Criteria
- [ ] All 5 verification tests pass (TC-V1 through TC-V5)
- [ ] All 3 regression tests pass (TC-R1 through TC-R3)
- [ ] All 3 non-functional tests pass (TC-NF1 through TC-NF3)
- [ ] Zero grep matches for removed function names
- [ ] Security hash verification passes
- [ ] Manual smoke test confirms core workflows operational

**Success Metric**: 11/11 tests passing (100%)

## Status
**Status**: Finished
**Next Action**: /cig-implementation-exec 51
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
