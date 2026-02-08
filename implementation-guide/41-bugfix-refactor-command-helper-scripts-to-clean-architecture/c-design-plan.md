# Refactor command-helper scripts to clean architecture - Design

## Task Reference
- **Task ID**: internal-41
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/41-refactor-command-helper-scripts-to-clean-architecture
- **Template Version**: 2.1

## Goal
Eliminate 220+ lines of code duplication by extracting common functionality to shared libraries, transforming Task 40's 3-layer architecture into Task 39's intended clean 2-layer architecture.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice: Clean 2-Layer Architecture with Shared Libraries

- **Decision**: Extract duplicated code to 2 new shared libraries (CIG::VersionRouter, CIG::Common) and refactor 7 modules to use them
- **Rationale**:
  - **Eliminates duplication**: detect_version() copied 3x (108 lines), PERL5OPT check copied 13x (78 lines)
  - **Clarifies responsibilities**: Trampolines dispatch, modules implement, libraries provide shared utilities
  - **Follows Task 39 pattern**: Task 39 designed clean 2-layer architecture (trampoline → module), but Task 40 created 3-layer confusion
  - **Matches Perl best practices**: CIG::TaskPath.pm already demonstrates the pattern (28 exported functions, comprehensive POD)
  - **Improves maintainability**: Change once in library, applies everywhere
- **Trade-offs**:
  - **Benefit**: 85-94% code reduction in modules, single source of truth for version routing
  - **Benefit**: Easier to extend (add new version = update library, not 7 modules)
  - **Benefit**: Consistent patterns make codebase easier to understand
  - **Drawback**: Adds dependency on shared libraries (minimal risk, well-established pattern)
  - **Drawback**: Requires careful testing to ensure no regressions

### Problem Analysis: What Went Wrong in Task 40

**Task 39's Intent** (2-layer architecture):
```
Trampoline (14 lines) → Module (simple implementation) → Version-specific script (if needed)
                                   ↓
                            Shared Libraries (common utilities)
```

**Task 40's Result** (3-layer confusion):
```
Trampoline → Module (with version routing) → Version-specific implementation
             ↑
             Duplicated version detection logic (3x)
             Duplicated PERL5OPT check (13x)
             Preserved old 3-layer architecture
```

**Root Causes**:
1. Copied entire scripts into modules instead of extracting shared functionality
2. Put version routing logic inside modules instead of shared library
3. Mixed patterns: some modules are simple, others route to versions, creating confusion

### Refactoring Strategy: Extract and Centralize

**Two New Shared Libraries**:

1. **CIG::VersionRouter** - Centralize version detection and routing
   - `detect_version($task_arg)` - Returns 'v2.0' or 'v2.1' based on task format
   - `route_to_version($base_name, $version, @args)` - Exec correct version-specific script
   - `get_script_dir()` - Calculate command-helpers directory
   - **Impact**: Replaces 108 lines of duplicated code across 3 modules

2. **CIG::Common** - Common utilities for all modules
   - `check_perl5opt()` - Verify PERL5OPT configuration (currently duplicated 13x)
   - `format_error($type, $message, $usage)` - Consistent error formatting
   - **Impact**: Replaces 78 lines of duplicated code across 13 scripts

**Three Module Patterns** (post-refactoring):

**Pattern A: Simple Modules** (no version routing):
- location, hierarchy, version, control
- Use CIG::Common for PERL5OPT check
- Contain business logic directly
- Example: `location` just outputs git root + cwd

**Pattern B: Version-Routing Modules** (delegate to version-specific scripts):
- inheritance, status
- Use CIG::VersionRouter + CIG::Common
- Thin wrapper (8 lines): detect version, exec appropriate script
- Example: `inheritance` detects v2.0/v2.1, execs context-inheritance-v2.0 or -v2.1

**Pattern C: Direct Implementation** (always latest version):
- create
- Hardcoded to v2.1
- Use CIG::Common for PERL5OPT check
- No version detection needed

## System Design

### Component Overview

**Layer 1: Trampolines** (unchanged - already correct from Task 39/40)
- **context-manager** - Dispatches to location, hierarchy, inheritance, version
- **workflow-manager** - Dispatches to status, control
- **task-workflow** - Dispatches to create
- Responsibility: Simple hash-based routing (14-18 lines each)
- Pattern: Pure dispatchers, no business logic

**Layer 2: Modules** (refactor to use shared libraries)

1. **context-manager.d/location** - Simple module (Pattern A)
   - Current: 18 lines
   - After refactoring: 18 lines (no change needed, already clean)
   - Uses: CIG::Common for PERL5OPT check
   - Purpose: Output git root and current directory

2. **context-manager.d/hierarchy** - Simple module (Pattern A)
   - Current: 86 lines (copied from hierarchy-resolver)
   - After refactoring: Keep as-is (contains business logic, not duplication)
   - Uses: CIG::TaskPath, CIG::Common
   - Purpose: Resolve task number to directory path

3. **context-manager.d/inheritance** - Version-routing module (Pattern B)
   - Current: 53 lines (includes duplicated detect_version)
   - After refactoring: 8 lines
   - Uses: CIG::VersionRouter, CIG::Common
   - Purpose: Route to context-inheritance-v2.0 or context-inheritance-v2.1
   - **Impact**: 85% code reduction (53 → 8 lines)

4. **context-manager.d/version** - Simple module (Pattern A)
   - Current: 144 lines (copied from format-detector)
   - After refactoring: Keep as-is (contains business logic, not duplication)
   - Uses: CIG::TaskPath, CIG::Common
   - Purpose: Detect task format version

5. **workflow-manager.d/status** - Version-routing module (Pattern B)
   - Current: 125 lines (includes version routing + argument parsing)
   - After refactoring: 8 lines
   - Uses: CIG::VersionRouter, CIG::Common
   - Purpose: Route to status-aggregator-v2.0 or status-aggregator-v2.1
   - **Impact**: 94% code reduction (125 → 8 lines)
   - **Note**: Move argument parsing to status-aggregator-v2.* scripts (where it belongs)

6. **workflow-manager.d/control** - Simple module (Pattern A)
   - Current: 107 lines (copied from workflow-control)
   - After refactoring: Keep as-is (contains business logic, not duplication)
   - Uses: CIG::Common
   - Purpose: Workflow state machine logic

7. **task-workflow.d/create** - Direct implementation (Pattern C)
   - Current: 16 lines (hardcoded to v2.1)
   - After refactoring: 8 lines
   - Uses: CIG::Common
   - Purpose: Copy task templates (always use latest v2.1)

**Shared Libraries** (NEW):

8. **CIG::VersionRouter** (NEW: `.cig/lib/CIG/VersionRouter.pm`)
   - Purpose: Centralize version detection and routing logic
   - Exports: detect_version, route_to_version, get_script_dir
   - ~80 lines with POD documentation
   - Eliminates: 108 lines of duplication across 3 modules

9. **CIG::Common** (NEW: `.cig/lib/CIG/Common.pm`)
   - Purpose: Common utilities for all modules
   - Exports: check_perl5opt, format_error
   - ~40 lines with POD documentation
   - Eliminates: 78 lines of duplication across 13 scripts

### Target Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: Trampolines (Pure Dispatchers - 14 lines each)        │
│  - context-manager {location|hierarchy|inheritance|version}     │
│  - workflow-manager {status|control}                            │
│  - task-workflow {create}                                       │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Layer 2: Modules (Use Shared Libraries)                        │
│                                                                 │
│  Pattern A: Simple Modules                                     │
│  ├─ location (18 lines) → git root + cwd                       │
│  ├─ hierarchy (86 lines) → resolve task to directory           │
│  ├─ version (144 lines) → detect v2.0/v2.1                     │
│  └─ control (107 lines) → workflow state machine               │
│                                                                 │
│  Pattern B: Version-Routing Modules                            │
│  ├─ inheritance (8 lines) → route to context-inheritance-v*    │
│  └─ status (8 lines) → route to status-aggregator-v*           │
│                                                                 │
│  Pattern C: Direct Implementation                              │
│  └─ create (8 lines) → hardcoded to v2.1                       │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Shared Libraries (Eliminate Duplication)                       │
│  - CIG::VersionRouter (version detection + routing)            │
│  - CIG::Common (PERL5OPT check, error formatting)              │
│  - CIG::TaskPath (existing - task path operations)             │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

**Simple Module Flow** (Pattern A: location, hierarchy, version, control):
```
User → /cig-status 41
  → Trampoline: workflow-manager parses "status" subcommand
  → Module: workflow-manager.d/status uses CIG::VersionRouter
  → Library: detect_version("41") → "v2.1"
  → Library: route_to_version("status-aggregator", "v2.1", "41")
  → Exec: status-aggregator-v2.1 with args ["41"]
  → Output: Task status to user
```

**Version-Routing Flow** (Pattern B: inheritance, status):
```
User → /cig-extract 41 design
  → Trampoline: context-manager parses "inheritance" subcommand
  → Module: context-manager.d/inheritance (8 lines)
    ├─ CIG::Common::check_perl5opt() → warns if not configured
    ├─ CIG::VersionRouter::detect_version("41") → "v2.1"
    └─ CIG::VersionRouter::route_to_version("context-inheritance", "v2.1", "41")
  → Exec: context-inheritance-v2.1 with args ["41"]
  → Output: Parent context structural map to user
```

**Direct Implementation Flow** (Pattern C: create):
```
User → /cig-new-task 42 feature "description"
  → Trampoline: task-workflow parses "create" subcommand
  → Module: task-workflow.d/create (8 lines)
    ├─ CIG::Common::check_perl5opt() → warns if not configured
    └─ Hardcoded: exec("template-copier-v2.1", @args)
  → Exec: template-copier-v2.1 (always latest version)
  → Output: Task directory created
```

## Interface Design

### CIG::VersionRouter API

**Module**: `.cig/lib/CIG/VersionRouter.pm`

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
# Args: $task_arg (task path like "41" or "1.2.3", or empty)
# Returns: "v2.0" or "v2.1"
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
# Args: $base_name (e.g., "status-aggregator"), $version (e.g., "v2.1"), @args
# Returns: Does not return (execs script)
sub route_to_version {
    my ($base_name, $version, @args) = @_;
    my $script_dir = get_script_dir();
    my $script_path = "$script_dir/$base_name-$version";

    exec($script_path, @args) or die "Failed to exec $script_path: $!\n";
}

# Get command-helpers directory path
# Returns: Absolute path to .cig/scripts/command-helpers/
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

=cut
```

### CIG::Common API

**Module**: `.cig/lib/CIG/Common.pm`

```perl
package CIG::Common;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(check_perl5opt format_error);

# Check PERL5OPT environment configuration
# Args: none
# Returns: none (warns if not configured)
sub check_perl5opt {
    unless ($ENV{PERL5OPT} && $ENV{PERL5OPT} =~ /-C/) {
        warn "WARNING: PERL5OPT not configured for Unicode handling.\n";
        warn "Add the following to ~/.claude/settings.json:\n";
        warn "  \"env\": { \"PERL5OPT\": \"-CDSL\" }\n\n";
    }
}

# Format error message consistently
# Args: $type (error type), $message (error message), $usage (usage string)
# Returns: formatted error string
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

=cut
```

### Refactored Module Examples

**Pattern A: Simple Module** (location - no changes needed)
```perl
#!/usr/bin/env perl
use strict;
use warnings;
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

**Pattern B: Version-Routing Module** (inheritance - 8 lines)
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

**Pattern C: Direct Implementation** (create - 8 lines)
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use CIG::Common qw(check_perl5opt);

check_perl5opt();
my $script_dir = "$FindBin::Bin/..";
exec("$script_dir/template-copier-v2.1", @ARGV) or die "Failed to exec: $!\n";
```

## Constraints

### Technical Constraints

1. **Backward Compatibility**: Must not break existing Tasks 1-40 or any /cig-* commands
   - All refactored modules must produce identical output
   - Version detection must work for both v2.0 and v2.1 tasks
   - Test with Tasks 35-40 to ensure recent work unaffected

2. **Zero Permission Prompts**: Wildcard pattern must remain functional
   - Trampolines already have permission grants
   - Shared libraries don't need permissions (loaded by modules)
   - Test after each module refactor to verify

3. **Functionality Preservation**: No behavior changes, only structural refactoring
   - Version-specific scripts (context-inheritance-v2.0, status-aggregator-v2.1, etc.) unchanged
   - Modules become thin wrappers that delegate
   - Business logic stays where it is

4. **Incremental Approach**: Each module refactoring must be independently testable
   - Create libraries first (foundation)
   - Refactor modules one at a time with tests
   - Atomic commits with clear messages

5. **Version Support**: Must support both v2.0 and v2.1 task formats
   - detect_version() must correctly identify format
   - route_to_version() must exec correct script
   - Default to v2.0 when no task specified (backward compatibility)

### Design Constraints

1. **Follow CIG::TaskPath Pattern**: Use existing shared library as reference
   - Comprehensive POD documentation
   - Explicit exports (@EXPORT_OK)
   - Clear function signatures
   - Example usage in documentation

2. **Perl Best Practices**:
   - `use strict; use warnings;`
   - Explicit imports (no implicit exports)
   - Clear error messages with context
   - POD documentation for all functions

3. **Module Pattern Consistency**:
   - All modules must follow one of 3 patterns (A, B, or C)
   - Pattern choice based on requirements, not arbitrary
   - Clear decision matrix for future modules

### Performance Considerations

1. **No Performance Impact**: Refactoring is structural only
   - Library function calls are negligible overhead
   - Version detection uses existing CIG::TaskPath::resolve()
   - exec() to version-specific scripts (no change from current)

2. **Token Efficiency** (for LLM context):
   - Shorter modules = less token consumption when reading
   - Single source of truth = less duplication in context
   - Clear patterns = easier for LLM to understand and extend

### Security Requirements

1. **Permission Model Preservation**:
   - Trampolines remain single permission boundary
   - Shared libraries loaded via @INC, no exec needed
   - No new permission prompts introduced

2. **Script Hash Verification** (future):
   - New libraries will need SHA256 hashes in `.cig/security/script-hashes.json`
   - Update after final testing, before retrospective
   - Include in /cig-security-check verification

## Validation

### Design Review Checklist

- [x] **Addresses Root Cause**: Refactoring fixes Task 40's duplication and 3-layer confusion
- [x] **Follows Task 39 Pattern**: Clean 2-layer architecture (trampoline → module → library)
- [x] **Measurable Impact**: 220+ lines eliminated, 85-94% code reduction in 2 modules
- [x] **Clear Patterns**: 3 module patterns (A, B, C) with decision criteria
- [x] **Backward Compatible**: No behavior changes, identical output, version support
- [x] **Testable**: Incremental approach with tests after each step
- [x] **Reference Implementation**: CIG::TaskPath.pm provides proven library pattern
- [x] **Documentation**: Comprehensive POD for both new libraries

### Architecture Validation

- [x] **Layer Separation**: Trampolines dispatch, modules implement, libraries provide utilities
- [x] **Single Responsibility**: Each library has focused purpose (version routing, common utilities)
- [x] **DRY Principle**: Each concept implemented once (detect_version, check_perl5opt)
- [x] **Extensibility**: Add new version = update library, not 7 modules
- [x] **Consistency**: All modules follow established patterns

### Integration Points Verified

- [x] **Trampolines**: No changes needed (already correct)
- [x] **Version-Specific Scripts**: No changes needed (context-inheritance-v2.*, status-aggregator-v2.*)
- [x] **CIG::TaskPath**: Used by CIG::VersionRouter for format detection
- [x] **PERL5OPT Warning**: Centralized in CIG::Common, shown to user if not configured
- [x] **Test Suite**: 17 automated tests from Task 40 verify integration

### Risk Mitigation Confirmed

- [x] **Permission Model**: Shared libraries loaded via @INC, no exec needed, no new prompts
- [x] **Incremental Testing**: Create libraries → refactor modules one-by-one → test after each
- [x] **Rollback Plan**: Atomic commits allow reverting individual changes if needed
- [x] **Validation Strategy**: Unit tests (libraries) + integration tests (modules) + regression tests (Tasks 35-40)

## Status
**Status**: Finished
**Next Action**: Implementation planning (complete)
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
