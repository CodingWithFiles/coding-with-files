# Refactor command-helper scripts to clean architecture - Testing

## Task Reference
- **Task ID**: internal-41
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/41-refactor-command-helper-scripts-to-clean-architecture
- **Template Version**: 2.1

## Goal
Validate that 220+ lines of code duplication have been eliminated, all modules work correctly with shared libraries, and zero regressions occur in Tasks 1-40 or any /cig-* commands.

## Test Strategy

### Test Levels

**1. Unit Tests** (Shared Libraries)
- Test CIG::VersionRouter functions in isolation
- Test CIG::Common functions in isolation
- Mock external dependencies (CIG::TaskPath::resolve, ENV variables)
- Verify correct behavior with various inputs

**2. Integration Tests** (Refactored Modules)
- Test modules with actual shared libraries loaded
- Verify modules correctly call library functions
- Test version routing with real v2.0 and v2.1 tasks
- Verify PERL5OPT warnings appear appropriately

**3. System Tests** (End-to-End Commands)
- Test all /cig-* commands that use refactored modules
- Verify identical behavior to pre-refactoring
- Test with various task paths and arguments
- Verify zero permission prompts throughout

**4. Regression Tests** (Backward Compatibility)
- Test Tasks 1-40 to ensure no functionality broken
- Test all workflow commands on existing tasks
- Verify v2.0 and v2.1 format support maintained
- Test edge cases from Task 40's 17 automated tests

### Test Coverage Targets

- **Overall Coverage**: 100% for refactored code (all 7 modules + 2 libraries)
- **Critical Paths**: 100% coverage required
  - Version detection for v2.0 and v2.1 tasks
  - Version routing to correct scripts
  - PERL5OPT warning system
- **Edge Cases**: Comprehensive coverage
  - Invalid task paths
  - Missing tasks
  - Undefined PERL5OPT environment variable
  - Empty argument lists
- **Regression**: 100% of existing functionality validated
  - All 17 automated tests from Task 40 must pass
  - Tasks 35-40 must work identically

### Test Approach

**Incremental Testing** (after each implementation step):
1. Create library → Unit test library immediately
2. Refactor module → Integration test module immediately
3. Complete all refactoring → Run full regression suite

**Duplication Verification** (automated):
- Grep for `sub detect_version` in modules → expect 0 matches
- Grep for `unless.*PERL5OPT` in modules → expect 0 matches
- Line count comparison before/after → expect 220+ lines eliminated

**Permission Testing** (manual):
- Execute various /cig-* commands
- Watch for permission prompts
- Verify wildcard pattern still works

## Test Cases

### Unit Test Cases (Shared Libraries)

**CIG::VersionRouter Tests**:

- **TC-U1**: detect_version() with v2.1 task
  - **Given**: Task 41 exists in v2.1 format
  - **When**: Call `detect_version("41")`
  - **Then**: Returns "v2.1"

- **TC-U2**: detect_version() with v2.0 task
  - **Given**: Task 3 exists in v2.0 format
  - **When**: Call `detect_version("3")`
  - **Then**: Returns "v2.0"

- **TC-U3**: detect_version() with no arguments
  - **Given**: No task specified
  - **When**: Call `detect_version("")`
  - **Then**: Returns "v2.0" (default)

- **TC-U4**: detect_version() with invalid task
  - **Given**: Task 999 does not exist
  - **When**: Call `detect_version("999")`
  - **Then**: Returns "v2.0" (default when resolve fails)

- **TC-U5**: get_script_dir() returns correct path
  - **Given**: Module is in context-manager.d/
  - **When**: Call `get_script_dir()`
  - **Then**: Returns path to command-helpers/ directory

**CIG::Common Tests**:

- **TC-U6**: check_perl5opt() warns when not configured
  - **Given**: PERL5OPT not set or missing -C flag
  - **When**: Call `check_perl5opt()`
  - **Then**: Outputs warning message to STDERR

- **TC-U7**: check_perl5opt() silent when configured
  - **Given**: PERL5OPT="-CDSL" is set
  - **When**: Call `check_perl5opt()`
  - **Then**: No output, returns silently

- **TC-U8**: format_error() with usage string
  - **Given**: Error details provided with usage
  - **When**: Call `format_error("validation", "Invalid task", "script <task>")`
  - **Then**: Returns formatted error with usage

### Integration Test Cases (Refactored Modules)

**inheritance Module Tests**:

- **TC-I1**: inheritance routes v2.1 task correctly
  - **Given**: Task 41 is v2.1 format
  - **When**: Execute `context-manager inheritance 41`
  - **Then**: Execs context-inheritance-v2.1 with args ["41"]

- **TC-I2**: inheritance routes v2.0 task correctly
  - **Given**: Task 3 is v2.0 format
  - **When**: Execute `context-manager inheritance 3`
  - **Then**: Execs context-inheritance-v2.0 with args ["3"]

- **TC-I3**: inheritance shows PERL5OPT warning if needed
  - **Given**: PERL5OPT not configured
  - **When**: Execute `context-manager inheritance 41`
  - **Then**: Warning message appears before execution

**status Module Tests**:

- **TC-I4**: status routes v2.1 task correctly
  - **Given**: Task 41 is v2.1 format
  - **When**: Execute `workflow-manager status 41`
  - **Then**: Execs status-aggregator-v2.1 with args ["41"]

- **TC-I5**: status routes v2.0 task correctly
  - **Given**: Task 3 is v2.0 format
  - **When**: Execute `workflow-manager status 3`
  - **Then**: Execs status-aggregator-v2.0 with args ["3"]

- **TC-I6**: status works with no arguments
  - **Given**: No task specified
  - **When**: Execute `workflow-manager status`
  - **Then**: Execs status-aggregator-v2.0 (default)

**create Module Tests**:

- **TC-I7**: create always uses v2.1
  - **Given**: Any task number provided
  - **When**: Execute `task-workflow create --task-num=41.1 --task-type=chore`
  - **Then**: Execs template-copier-v2.1 (hardcoded)

**Simple Module Tests** (location, hierarchy, version, control):

- **TC-I8**: location uses CIG::Common
  - **Given**: location module refactored
  - **When**: Execute `context-manager location`
  - **Then**: PERL5OPT warning appears if not configured, output identical to before

- **TC-I9**: hierarchy uses CIG::Common
  - **Given**: hierarchy module refactored
  - **When**: Execute `context-manager hierarchy 41`
  - **Then**: PERL5OPT warning appears if not configured, output identical to before

- **TC-I10**: version uses CIG::Common
  - **Given**: version module refactored
  - **When**: Execute `context-manager version <task-dir> <file>`
  - **Then**: PERL5OPT warning appears if not configured, output identical to before

- **TC-I11**: control uses CIG::Common
  - **Given**: control module refactored
  - **When**: Execute `workflow-manager control --current-step=a --task-path=41`
  - **Then**: PERL5OPT warning appears if not configured, output identical to before

### System Test Cases (End-to-End Commands)

- **TC-S1**: /cig-status command works correctly
  - **Given**: Refactored status module in use
  - **When**: Execute `/cig-status 41`
  - **Then**: Shows Task 41 status correctly, zero permission prompts

- **TC-S2**: /cig-extract command works correctly
  - **Given**: Refactored inheritance module in use
  - **When**: Execute `/cig-extract 41 design`
  - **Then**: Extracts design section correctly, zero permission prompts

- **TC-S3**: /cig-new-task command works correctly
  - **Given**: Refactored create module in use
  - **When**: Execute `/cig-new-task 41.1 chore "test task"`
  - **Then**: Creates task directory with v2.1 files, zero permission prompts

- **TC-S4**: All /cig-* commands work with various tasks
  - **Given**: Multiple refactored modules in use
  - **When**: Execute various /cig-* commands (status, extract, plan, design, etc.)
  - **Then**: All commands work identically to before, zero permission prompts

### Regression Test Cases (Backward Compatibility)

- **TC-R1**: Tasks 35-40 still work
  - **Given**: Recently completed tasks (35-40)
  - **When**: Execute `/cig-status 35` through `/cig-status 40`
  - **Then**: All show correct status, no errors

- **TC-R2**: v2.0 format tasks still work
  - **Given**: Task 3 is v2.0 format
  - **When**: Execute `/cig-status 3` and `/cig-extract 3 design`
  - **Then**: Both commands work correctly with v2.0 task

- **TC-R3**: v2.1 format tasks still work
  - **Given**: Task 41 is v2.1 format
  - **When**: Execute `/cig-status 41` and `/cig-extract 41 design`
  - **Then**: Both commands work correctly with v2.1 task

- **TC-R4**: All 17 automated tests from Task 40 pass
  - **Given**: Task 40's test suite exists
  - **When**: Run all 17 automated tests
  - **Then**: All tests pass, proving trampoline architecture still works

### Non-Functional Test Cases

**Code Quality Tests**:

- **TC-NF1**: Code duplication eliminated
  - **Given**: Refactoring complete
  - **When**: Run `grep -r "sub detect_version" .cig/scripts/command-helpers/`
  - **Then**: 0 matches found (only in library)

- **TC-NF2**: PERL5OPT check centralized
  - **Given**: Refactoring complete
  - **When**: Run `grep -r "unless.*PERL5OPT" .cig/scripts/command-helpers/`
  - **Then**: 0 matches found (only in library)

- **TC-NF3**: Code reduction achieved
  - **Given**: Line counts measured before and after
  - **When**: Compare module sizes
  - **Then**: 220+ lines eliminated (inheritance 53→8, status 125→8, etc.)

**Performance Tests**:

- **TC-NF4**: Library loading overhead negligible
  - **Given**: Modules now load shared libraries
  - **When**: Execute commands with time measurement
  - **Then**: No measurable performance degradation (<10ms difference)

**Security Tests**:

- **TC-NF5**: Zero permission prompts maintained
  - **Given**: Wildcard pattern covers trampolines
  - **When**: Execute various /cig-* commands
  - **Then**: No new permission prompts appear

- **TC-NF6**: Script permissions correct
  - **Given**: Shared libraries created
  - **When**: Check file permissions
  - **Then**: Libraries are 0644 (readable), modules remain 0500+ (executable)

**Usability Tests**:

- **TC-NF7**: Error messages remain clear
  - **Given**: format_error() used for errors
  - **When**: Trigger error conditions (invalid task, missing file)
  - **Then**: Error messages are clear and consistent

- **TC-NF8**: PERL5OPT warning is helpful
  - **Given**: PERL5OPT not configured
  - **When**: Run any command
  - **Then**: Warning message shows correct settings.json configuration

## Test Environment

### Setup Requirements

**Prerequisites**:
- Git repository with CIG system installed
- Tasks 1-40 exist (for regression testing)
- Both v2.0 and v2.1 format tasks available (e.g., Task 3 for v2.0, Task 41 for v2.1)
- PERL5OPT environment variable configurable (test both configured and unconfigured states)

**Test Data**:
- Existing task hierarchy (Tasks 1-41)
- v2.0 format tasks: 1-34
- v2.1 format tasks: 35-41
- No additional test data creation needed

**Environment Configuration**:
- **Standard Testing**: PERL5OPT="-CDSL" (configured correctly)
- **Warning Testing**: PERL5OPT unset or missing -C flag (test warnings)

**Dependencies**:
- CIG::TaskPath.pm (existing shared library)
- All version-specific scripts (context-inheritance-v2.0, context-inheritance-v2.1, status-aggregator-v2.0, status-aggregator-v2.1, template-copier-v2.1)
- All trampolines (context-manager, workflow-manager, task-workflow)

### Automation

**Test Execution Approach**:
- **Manual Testing**: For incremental testing after each implementation step
- **Automated Verification**: For duplication checks (grep commands)
- **Regression Suite**: Run Task 40's 17 automated tests
- **Script-Based Testing**: Create simple Perl test scripts for unit tests

**Unit Test Automation** (optional, recommended):
```perl
#!/usr/bin/env perl
# test-version-router.pl - Unit test for CIG::VersionRouter

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CIG::VersionRouter qw(detect_version get_script_dir);

# Test TC-U1: detect_version with v2.1 task
my $version = detect_version("41");
die "TC-U1 FAILED: Expected v2.1, got $version\n" unless $version eq "v2.1";
print "TC-U1 PASSED: detect_version('41') returned 'v2.1'\n";

# Test TC-U2: detect_version with v2.0 task
$version = detect_version("3");
die "TC-U2 FAILED: Expected v2.0, got $version\n" unless $version eq "v2.0";
print "TC-U2 PASSED: detect_version('3') returned 'v2.0'\n";

# Test TC-U3: detect_version with no arguments
$version = detect_version("");
die "TC-U3 FAILED: Expected v2.0, got $version\n" unless $version eq "v2.0";
print "TC-U3 PASSED: detect_version('') returned 'v2.0' (default)\n";

# Test TC-U5: get_script_dir returns path
my $dir = get_script_dir();
die "TC-U5 FAILED: get_script_dir returned empty\n" unless $dir;
print "TC-U5 PASSED: get_script_dir() returned '$dir'\n";

print "\nAll unit tests passed!\n";
```

**Duplication Verification** (automated):
```bash
#!/bin/bash
# verify-no-duplication.sh

echo "Checking for duplicated detect_version function..."
count=$(grep -r "sub detect_version" .cig/scripts/command-helpers/ 2>/dev/null | wc -l)
if [ "$count" -eq 0 ]; then
    echo "✓ TC-NF1 PASSED: No duplicated detect_version (0 matches)"
else
    echo "✗ TC-NF1 FAILED: Found $count instances of detect_version"
    exit 1
fi

echo "Checking for duplicated PERL5OPT check..."
count=$(grep -r "unless.*PERL5OPT" .cig/scripts/command-helpers/ 2>/dev/null | wc -l)
if [ "$count" -eq 0 ]; then
    echo "✓ TC-NF2 PASSED: No duplicated PERL5OPT check (0 matches)"
else
    echo "✗ TC-NF2 FAILED: Found $count instances of PERL5OPT check"
    exit 1
fi

echo "All duplication checks passed!"
```

**Integration Testing** (manual commands):
- Execute actual /cig-* commands and verify output
- Watch for permission prompts
- Compare output to pre-refactoring behavior

**CI/CD Integration** (future):
- Add unit test scripts to `.cig/tests/` directory
- Add duplication verification to pre-commit hooks
- Run regression suite on every commit to main branch

## Validation Criteria

### Success Criteria Checklist

**Unit Tests** (8 test cases):
- [ ] TC-U1: detect_version("41") returns "v2.1"
- [ ] TC-U2: detect_version("3") returns "v2.0"
- [ ] TC-U3: detect_version("") returns "v2.0"
- [ ] TC-U4: detect_version("999") returns "v2.0" (default)
- [ ] TC-U5: get_script_dir() returns correct path
- [ ] TC-U6: check_perl5opt() warns when not configured
- [ ] TC-U7: check_perl5opt() silent when configured
- [ ] TC-U8: format_error() returns formatted error

**Integration Tests** (11 test cases):
- [ ] TC-I1: inheritance routes v2.1 correctly
- [ ] TC-I2: inheritance routes v2.0 correctly
- [ ] TC-I3: inheritance shows PERL5OPT warning
- [ ] TC-I4: status routes v2.1 correctly
- [ ] TC-I5: status routes v2.0 correctly
- [ ] TC-I6: status works with no arguments
- [ ] TC-I7: create always uses v2.1
- [ ] TC-I8: location uses CIG::Common
- [ ] TC-I9: hierarchy uses CIG::Common
- [ ] TC-I10: version uses CIG::Common
- [ ] TC-I11: control uses CIG::Common

**System Tests** (4 test cases):
- [ ] TC-S1: /cig-status works correctly
- [ ] TC-S2: /cig-extract works correctly
- [ ] TC-S3: /cig-new-task works correctly
- [ ] TC-S4: All /cig-* commands work

**Regression Tests** (4 test cases):
- [ ] TC-R1: Tasks 35-40 still work
- [ ] TC-R2: v2.0 format tasks still work
- [ ] TC-R3: v2.1 format tasks still work
- [ ] TC-R4: All 17 automated tests from Task 40 pass

**Non-Functional Tests** (8 test cases):
- [ ] TC-NF1: Code duplication eliminated (0 matches)
- [ ] TC-NF2: PERL5OPT check centralized (0 matches)
- [ ] TC-NF3: Code reduction achieved (220+ lines)
- [ ] TC-NF4: Library loading overhead negligible
- [ ] TC-NF5: Zero permission prompts maintained
- [ ] TC-NF6: Script permissions correct
- [ ] TC-NF7: Error messages remain clear
- [ ] TC-NF8: PERL5OPT warning is helpful

### Coverage Targets

- **Overall Coverage**: 35/35 test cases pass (100%)
- **Critical Paths**: All version routing tests pass (TC-I1, TC-I2, TC-I4, TC-I5)
- **Edge Cases**: All edge case tests pass (TC-U4, TC-I3, TC-I6)
- **Regression**: All 4 regression tests pass + 17 Task 40 tests

### Performance Benchmarks

- **Library Loading**: <10ms overhead per command
- **Command Execution**: Identical timing to pre-refactoring
- **Memory Usage**: No measurable increase

### Security Validation

- **Permission Model**: Zero new permission prompts (TC-NF5)
- **Script Permissions**: Libraries 0644, modules 0500+ (TC-NF6)
- **No Security Regressions**: All existing security controls maintained

### Quality Validation

- **Code Duplication**: 0 instances of detect_version or PERL5OPT check in modules (TC-NF1, TC-NF2)
- **Code Reduction**: Measured 220+ lines eliminated (TC-NF3)
- **Pattern Consistency**: All 7 modules follow one of 3 defined patterns (A, B, or C)

### Final Validation (Before Marking Complete)

All of the following must be true:
- [ ] All 35 test cases pass (100% pass rate)
- [ ] Code duplication grep shows 0 matches
- [ ] Code reduction measured at 220+ lines
- [ ] Tasks 35-40 work identically to before
- [ ] Zero permission prompts verified
- [ ] All /cig-* commands functional
- [ ] Both v2.0 and v2.1 formats supported

## Status
**Status**: Finished
**Next Action**: Implementation execution (complete)
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
