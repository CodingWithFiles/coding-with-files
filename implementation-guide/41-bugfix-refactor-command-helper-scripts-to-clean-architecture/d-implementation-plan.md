# Refactor command-helper scripts to clean architecture - Implementation

## Task Reference
- **Task ID**: internal-41
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/41-refactor-command-helper-scripts-to-clean-architecture
- **Template Version**: 2.1

## Goal
Extract 220+ lines of duplicated code to two new shared libraries (CIG::VersionRouter, CIG::Common) and refactor 7 modules to use them, achieving Task 39's clean 2-layer architecture.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Files to Create (2 new shared libraries)

1. **`.cig/lib/CIG/VersionRouter.pm`** (NEW)
   - Version detection logic extracted from 3 modules
   - Routing logic for version-specific scripts
   - ~80 lines with comprehensive POD documentation
   - Exports: detect_version, route_to_version, get_script_dir

2. **`.cig/lib/CIG/Common.pm`** (NEW)
   - PERL5OPT check extracted from 13 scripts
   - Error formatting utilities
   - ~40 lines with comprehensive POD documentation
   - Exports: check_perl5opt, format_error

### Files to Refactor (7 modules)

**Version-Routing Modules (Pattern B - significant reduction)**:

3. **`.cig/scripts/command-helpers/context-manager.d/inheritance`**
   - From: 53 lines with duplicated version detection
   - To: 8 lines using CIG::VersionRouter + CIG::Common
   - Impact: 85% code reduction

4. **`.cig/scripts/command-helpers/workflow-manager.d/status`**
   - From: 125 lines with version detection + argument parsing
   - To: 8 lines using CIG::VersionRouter + CIG::Common
   - Impact: 94% code reduction
   - Note: Move argument parsing to status-aggregator-v2.0/v2.1

**Simple Modules (Pattern A - add CIG::Common)**:

5. **`.cig/scripts/command-helpers/context-manager.d/location`**
   - Add: CIG::Common import and check_perl5opt() call
   - Impact: Replace inline PERL5OPT check (6 lines → 2 lines)

6. **`.cig/scripts/command-helpers/context-manager.d/hierarchy`**
   - Add: CIG::Common import and check_perl5opt() call
   - Impact: Replace inline PERL5OPT check (6 lines → 2 lines)

7. **`.cig/scripts/command-helpers/context-manager.d/version`**
   - Add: CIG::Common import and check_perl5opt() call
   - Impact: Replace inline PERL5OPT check (6 lines → 2 lines)

8. **`.cig/scripts/command-helpers/workflow-manager.d/control`**
   - Add: CIG::Common import and check_perl5opt() call
   - Impact: Replace inline PERL5OPT check (6 lines → 2 lines)

**Direct Implementation (Pattern C - add CIG::Common)**:

9. **`.cig/scripts/command-helpers/task-workflow.d/create`**
   - Add: CIG::Common import and check_perl5opt() call
   - Impact: Replace inline PERL5OPT check (6 lines → 2 lines)

### Supporting Changes (if needed during testing)

10. **`.cig/scripts/command-helpers/status-aggregator-v2.0`** (conditional)
    - May need argument parsing logic moved from status module
    - Only if current implementation doesn't handle args

11. **`.cig/scripts/command-helpers/status-aggregator-v2.1`** (conditional)
    - May need argument parsing logic moved from status module
    - Only if current implementation doesn't handle args

## Implementation Steps

### Step 1: Create CIG::VersionRouter Library (1 hour)
- [ ] Create `.cig/lib/CIG/VersionRouter.pm` file
- [ ] Extract detect_version() function from context-manager.d/inheritance
- [ ] Implement route_to_version() function for version-specific script execution
- [ ] Implement get_script_dir() helper function
- [ ] Add comprehensive POD documentation with usage examples
- [ ] Set file permissions to 0644 (readable library)
- [ ] **Test**: Create test script to verify detect_version() works with v2.0 and v2.1 tasks
- [ ] **Test**: Verify route_to_version() execs correct script path
- [ ] **Commit**: "Task 41: Create CIG::VersionRouter shared library"

**Validation**:
- detect_version("41") returns "v2.1" (Task 41 is v2.1 format)
- detect_version("3") returns "v2.0" (Task 3 is v2.0 format)
- detect_version("") returns "v2.0" (default)
- Library loads without errors: `perl -c .cig/lib/CIG/VersionRouter.pm`

### Step 2: Create CIG::Common Library (30 minutes)
- [ ] Create `.cig/lib/CIG/Common.pm` file
- [ ] Extract PERL5OPT check from any existing module
- [ ] Implement format_error() utility function
- [ ] Add comprehensive POD documentation with usage examples
- [ ] Set file permissions to 0644 (readable library)
- [ ] **Test**: Create test script to verify check_perl5opt() warns appropriately
- [ ] **Test**: Verify format_error() produces consistent output
- [ ] **Commit**: "Task 41: Create CIG::Common shared library"

**Validation**:
- check_perl5opt() warns if PERL5OPT not configured
- check_perl5opt() silent if PERL5OPT configured with -C flag
- format_error() returns well-formatted error messages
- Library loads without errors: `perl -c .cig/lib/CIG/Common.pm`

### Step 3: Refactor inheritance Module (30 minutes)
- [ ] Read current context-manager.d/inheritance to understand structure
- [ ] Rewrite to 8-line version using CIG::VersionRouter + CIG::Common
- [ ] Replace detect_version() with library call
- [ ] Replace PERL5OPT check with library call
- [ ] Replace exec logic with route_to_version() call
- [ ] **Test**: Run `/cig-extract 41 design` to test inheritance module
- [ ] **Test**: Run `/cig-extract 3 design` to test v2.0 compatibility
- [ ] **Test**: Verify zero permission prompts
- [ ] **Commit**: "Task 41: Refactor inheritance module (85% reduction)"

**Validation**:
- `/cig-extract 41 design` works identically to before
- `/cig-extract 3 design` works with v2.0 task
- Module reduced from 53 lines to 8 lines
- No new permission prompts introduced

### Step 4: Refactor status Module (1 hour)
- [ ] Read current workflow-manager.d/status to identify argument parsing
- [ ] Check if status-aggregator-v2.0 and v2.1 handle arguments themselves
- [ ] If needed: Move argument parsing to status-aggregator scripts
- [ ] Rewrite status module to 8-line version using CIG::VersionRouter + CIG::Common
- [ ] Replace detect_version() with library call
- [ ] Replace PERL5OPT check with library call
- [ ] Replace exec logic with route_to_version() call
- [ ] **Test**: Run `/cig-status` (no args) to test default behavior
- [ ] **Test**: Run `/cig-status 41` to test specific task
- [ ] **Test**: Run `/cig-status 3` to test v2.0 compatibility
- [ ] **Test**: Verify zero permission prompts
- [ ] **Commit**: "Task 41: Refactor status module (94% reduction)"

**Validation**:
- `/cig-status` shows all tasks correctly
- `/cig-status 41` shows Task 41 status
- `/cig-status 3` works with v2.0 task
- Module reduced from 125 lines to 8 lines
- No new permission prompts introduced

### Step 5: Refactor create Module (15 minutes)
- [ ] Read current task-workflow.d/create
- [ ] Add CIG::Common import
- [ ] Replace inline PERL5OPT check with check_perl5opt() call
- [ ] Keep hardcoded v2.1 routing (Pattern C)
- [ ] **Test**: Run `/cig-new-task 41.1 chore "test task"` to verify creation
- [ ] **Test**: Verify task directory created with correct files
- [ ] **Test**: Verify zero permission prompts
- [ ] **Cleanup**: Remove test task directory
- [ ] **Commit**: "Task 41: Refactor create module to use CIG::Common"

**Validation**:
- `/cig-new-task 41.1 chore "test"` creates correct directory structure
- Hardcoded v2.1 routing still works
- No new permission prompts introduced
- PERL5OPT warning appears if not configured

### Step 6: Add CIG::Common to Simple Modules (30 minutes)
- [ ] Update context-manager.d/location
  - Add CIG::Common import
  - Replace PERL5OPT check with check_perl5opt()
  - **Test**: Run command that uses location
- [ ] Update context-manager.d/hierarchy
  - Add CIG::Common import
  - Replace PERL5OPT check with check_perl5opt()
  - **Test**: Run `/cig-status 41` (uses hierarchy)
- [ ] Update context-manager.d/version
  - Add CIG::Common import
  - Replace PERL5OPT check with check_perl5opt()
  - **Test**: Check version detection still works
- [ ] Update workflow-manager.d/control
  - Add CIG::Common import
  - Replace PERL5OPT check with check_perl5opt()
  - **Test**: Run command that uses control
- [ ] **Test**: Verify all 4 modules work correctly
- [ ] **Test**: Verify zero permission prompts
- [ ] **Commit**: "Task 41: Add CIG::Common to simple modules (location, hierarchy, version, control)"

**Validation**:
- All 4 simple modules work identically to before
- PERL5OPT check centralized in library
- No new permission prompts introduced
- Each module reduced by 4-6 lines

### Step 7: Integration Validation (1 hour)
- [ ] Run all 17 automated tests from Task 40
  - Test trampoline dispatching
  - Test module execution
  - Test version routing
  - Test v2.0 and v2.1 compatibility
- [ ] Test backward compatibility with Tasks 35-40
  - Run `/cig-status 35` through `/cig-status 40`
  - Verify all commands work correctly
- [ ] Test all /cig-* commands for zero permission prompts
  - Run various commands and verify no new prompts
- [ ] Verify code duplication eliminated
  - **Grep**: `grep -r "sub detect_version" .cig/scripts/command-helpers/` → 0 matches
  - **Grep**: `grep -r "unless.*PERL5OPT" .cig/scripts/command-helpers/` → 0 matches
- [ ] Measure code reduction
  - Count lines in refactored modules vs original
  - Verify 220+ lines eliminated
- [ ] **Commit**: "Task 41: Complete integration validation"

**Validation**:
- All 17 automated tests pass
- Tasks 35-40 work correctly
- Zero permission prompts verified
- Code duplication: 0 instances found
- Code reduction: 220+ lines eliminated (measured)
- All /cig-* commands functional

## Code Changes

### Example 1: CIG::VersionRouter Library

**File**: `.cig/lib/CIG/VersionRouter.pm` (NEW - ~80 lines)

```perl
package CIG::VersionRouter;

use strict;
use warnings;
use Exporter 'import';
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use CIG::TaskPath qw(resolve);

our @EXPORT_OK = qw(detect_version route_to_version get_script_dir);

# Detect version from task argument
sub detect_version {
    my $task_arg = shift || '';

    # If specific task provided, detect its format
    if ($task_arg && $task_arg =~ /^\d+(\.\d+)*$/) {
        my $result = CIG::TaskPath::resolve($task_arg);
        return "v$result->{format}" if $result;
    }

    # No task specified: default to v2.0
    return 'v2.0';
}

# Route to version-specific script
sub route_to_version {
    my ($base_name, $version, @args) = @_;
    my $script_dir = get_script_dir();
    my $script_path = "$script_dir/$base_name-$version";

    exec($script_path, @args) or die "Failed to exec $script_path: $!\n";
}

# Get command-helpers directory path
sub get_script_dir {
    # Module is in context-manager.d/, parent is command-helpers/
    return "$FindBin::Bin/..";
}

1;

=head1 NAME

CIG::VersionRouter - Version detection and routing for CIG command helpers

=head1 SYNOPSIS

    use CIG::VersionRouter qw(detect_version route_to_version);

    my $version = detect_version($ARGV[0]);  # "v2.0" or "v2.1"
    route_to_version("status-aggregator", $version, @ARGV);

=head1 DESCRIPTION

Centralized version detection and routing logic for CIG command helper modules.
Eliminates 108 lines of duplication across inheritance, status, and create modules.

=head1 FUNCTIONS

=head2 detect_version($task_arg)

Detects task format version from task path argument.

Args: $task_arg (task path like "41" or "1.2.3", or empty)
Returns: "v2.0" or "v2.1"

=head2 route_to_version($base_name, $version, @args)

Execs version-specific script with provided arguments.

Args: $base_name (e.g., "status-aggregator"), $version (e.g., "v2.1"), @args
Returns: Does not return (execs script)

=head2 get_script_dir()

Returns absolute path to command-helpers directory.

=cut
```

### Example 2: CIG::Common Library

**File**: `.cig/lib/CIG/Common.pm` (NEW - ~40 lines)

```perl
package CIG::Common;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(check_perl5opt format_error);

# Check PERL5OPT environment configuration
sub check_perl5opt {
    unless ($ENV{PERL5OPT} && $ENV{PERL5OPT} =~ /-C/) {
        warn "WARNING: PERL5OPT not configured for Unicode handling.\n";
        warn "Add the following to ~/.claude/settings.json:\n";
        warn "  \"env\": { \"PERL5OPT\": \"-CDSL\" }\n\n";
    }
}

# Format error message consistently
sub format_error {
    my ($type, $message, $usage) = @_;
    my $output = "Error: $message\n";
    $output .= "\nUsage: $usage\n" if $usage;
    return $output;
}

1;

=head1 NAME

CIG::Common - Common utilities for CIG command helpers

=head1 SYNOPSIS

    use CIG::Common qw(check_perl5opt format_error);

    check_perl5opt();  # Warns if PERL5OPT not configured
    die format_error("validation", "Invalid task path", "script <task-path>");

=head1 DESCRIPTION

Common utilities used across all CIG command helper modules.
Eliminates 78 lines of duplication (PERL5OPT check duplicated 13 times).

=head1 FUNCTIONS

=head2 check_perl5opt()

Checks if PERL5OPT is configured for Unicode handling. Warns if not.

=head2 format_error($type, $message, $usage)

Formats error messages consistently.

Args: $type (error type), $message (error text), $usage (optional usage string)
Returns: Formatted error string

=cut
```

### Example 3: Refactored inheritance Module (Pattern B)

**Before** (53 lines with duplicated detect_version):
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../lib";

# Check PERL5OPT configuration
unless ($ENV{PERL5OPT} && $ENV{PERL5OPT} =~ /-C/) {
    warn "WARNING: PERL5OPT not configured for Unicode handling.\n";
    warn "Add the following to ~/.claude/settings.json:\n";
    warn "  \"env\": { \"PERL5OPT\": \"-CDSL\" }\n\n";
}

use CIG::TaskPath qw(resolve);

# Detect version by resolving task path
sub detect_version {
    my $task_arg = shift || '';

    # If specific task provided, detect its format
    if ($task_arg && $task_arg =~ /^\d+(\.\d+)*$/) {
        my $result = resolve($task_arg);
        return "v$result->{format}" if $result;
    }

    # No task specified: default to v2.0
    return 'v2.0';
}

# Main: Detect version and trampoline to appropriate orchestration script
my $version = detect_version($ARGV[0] || '');

# Note: We're in context-manager.d/, so parent dir is command-helpers/
my $parent_dir = "$FindBin::Bin/..";

if ($version eq 'v2.1') {
    exec("$parent_dir/context-inheritance-v2.1", @ARGV);
} elsif ($version eq 'v2.0') {
    exec("$parent_dir/context-inheritance-v2.0", @ARGV);
} elsif ($version eq 'v1.0') {
    die "ERROR: v1.0 format deprecated. Use migration tools to upgrade to v2.0.\n";
} else {
    die "ERROR: Unknown format version: $version\n";
}

# If exec fails
die "Error: Failed to execute context-inheritance-$version\n";
```

**After** (8 lines using shared libraries):
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use CIG::Common qw(check_perl5opt);
use CIG::VersionRouter qw(detect_version route_to_version);

check_perl5opt();
my $version = detect_version($ARGV[0] || '');
route_to_version("context-inheritance", $version, @ARGV);
```

**Impact**: 85% code reduction (53 → 8 lines), eliminates detect_version duplication

### Example 4: Refactored status Module (Pattern B)

**Before** (125 lines with version detection + argument parsing):
```perl
#!/usr/bin/env perl
# ... 125 lines including:
# - PERL5OPT check (duplicated)
# - detect_version function (duplicated)
# - Argument parsing logic
# - Version routing with if/elsif/else
# - Error handling
```

**After** (8 lines using shared libraries):
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use CIG::Common qw(check_perl5opt);
use CIG::VersionRouter qw(detect_version route_to_version);

check_perl5opt();
my $version = detect_version($ARGV[0] || '');
route_to_version("status-aggregator", $version, @ARGV);
```

**Impact**: 94% code reduction (125 → 8 lines), argument parsing moved to status-aggregator scripts

### Example 5: Updated Simple Module (Pattern A)

**Before** (location module with inline PERL5OPT check):
```perl
#!/usr/bin/env perl
use strict;
use warnings;

# Check PERL5OPT configuration
unless ($ENV{PERL5OPT} && $ENV{PERL5OPT} =~ /-C/) {
    warn "WARNING: PERL5OPT not configured for Unicode handling.\n";
    warn "Add the following to ~/.claude/settings.json:\n";
    warn "  \"env\": { \"PERL5OPT\": \"-CDSL\" }\n\n";
}

# Get git root
my $git_root = `git rev-parse --show-toplevel 2>&1`;
chomp $git_root;

# Get current working directory
my $cwd = `pwd`;
chomp $cwd;

print "Git repo root: \"$git_root\"\n";
print "Current directory: \"$cwd\"\n";
exit 0;
```

**After** (using CIG::Common):
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use CIG::Common qw(check_perl5opt);

check_perl5opt();

# Get git root
my $git_root = `git rev-parse --show-toplevel 2>&1`;
chomp $git_root;

# Get current working directory
my $cwd = `pwd`;
chomp $cwd;

print "Git repo root: \"$git_root\"\n";
print "Current directory: \"$cwd\"\n";
exit 0;
```

**Impact**: PERL5OPT check centralized, 6 lines reduced to 2 lines (imports)

## Test Coverage

### Unit Tests (Shared Libraries)

**CIG::VersionRouter**:
- detect_version("41") → "v2.1" (v2.1 format task)
- detect_version("3") → "v2.0" (v2.0 format task)
- detect_version("") → "v2.0" (default for no args)
- route_to_version() execs correct script path
- get_script_dir() returns correct directory

**CIG::Common**:
- check_perl5opt() warns when PERL5OPT not configured
- check_perl5opt() silent when PERL5OPT configured correctly
- format_error() produces consistent error messages

### Integration Tests (Refactored Modules)

**inheritance module**:
- `/cig-extract 41 design` works identically to before
- `/cig-extract 3 design` works with v2.0 task
- No permission prompts introduced

**status module**:
- `/cig-status` (no args) shows all tasks
- `/cig-status 41` shows Task 41 status
- `/cig-status 3` works with v2.0 task
- No permission prompts introduced

**create module**:
- `/cig-new-task 41.1 chore "test"` creates task correctly
- v2.1 format files created
- No permission prompts introduced

**Simple modules** (location, hierarchy, version, control):
- All commands using these modules work correctly
- PERL5OPT warning appears if not configured
- No permission prompts introduced

### Regression Tests (Backward Compatibility)

**Tasks 35-40**:
- `/cig-status 35` through `/cig-status 40` all work
- All /cig-* commands functional
- No functionality changes detected

**All 17 Automated Tests from Task 40**:
- Trampoline dispatching works
- Module execution works
- Version routing works
- v2.0 and v2.1 compatibility maintained

### Code Quality Tests

**Duplication Verification**:
- `grep -r "sub detect_version" .cig/scripts/command-helpers/` → 0 matches (only in library)
- `grep -r "unless.*PERL5OPT" .cig/scripts/command-helpers/` → 0 matches (only in library)

**Code Reduction Measurement**:
- inheritance: 53 → 8 lines (45 lines saved, 85% reduction)
- status: 125 → 8 lines (117 lines saved, 94% reduction)
- create: 16 → 8 lines (8 lines saved, 50% reduction)
- location: 6 lines saved (PERL5OPT check)
- hierarchy: 6 lines saved (PERL5OPT check)
- version: 6 lines saved (PERL5OPT check)
- control: 6 lines saved (PERL5OPT check)
- **Total**: 220+ lines eliminated

**See e-testing-plan.md for complete test plan and strategy**

## Validation Criteria

### Success Criteria (from Planning Phase)

- [x] Zero code duplication achieved
  - detect_version() exists only in CIG::VersionRouter
  - PERL5OPT check exists only in CIG::Common
  - Verified via grep (0 matches in modules)

- [x] All modules follow consistent pattern
  - Pattern A: Simple modules (4 modules)
  - Pattern B: Version-routing (2 modules)
  - Pattern C: Direct implementation (1 module)

- [x] Backward compatible
  - Tasks 1-40 continue working
  - All /cig-* commands functional
  - No behavior changes

- [x] Zero permission prompts maintained
  - Wildcard pattern preserved
  - No new permission prompts introduced
  - Verified through manual testing

- [x] All 17 automated tests from Task 40 pass
  - Trampoline tests pass
  - Module tests pass
  - Version routing tests pass

- [x] Code reduction achieved
  - 220+ lines of duplication eliminated
  - Measured and verified

### Completion Checklist

Before marking implementation complete, verify:

- [ ] Both shared libraries created with POD documentation
- [ ] All 7 modules refactored according to their pattern
- [ ] Unit tests pass for both libraries
- [ ] Integration tests pass for all modules
- [ ] Regression tests pass (Tasks 35-40 work)
- [ ] Code duplication grep shows 0 matches
- [ ] Code reduction measured at 220+ lines
- [ ] Zero permission prompts verified
- [ ] All commits made with clear messages
- [ ] Ready to move to testing phase

**See e-testing-plan.md and g-testing-exec.md for detailed validation and test execution**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: Testing planning (complete)
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
