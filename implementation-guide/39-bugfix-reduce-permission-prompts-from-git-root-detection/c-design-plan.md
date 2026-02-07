# reduce permission prompts from git root detection - Design

## Task Reference
- **Task ID**: internal-39
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/39-reduce-permission-prompts-from-git-root-detection
- **Template Version**: 2.1

## Goal
Eliminate permission prompts from git root detection by implementing a trampoline/module architecture that decouples invocation permissions from functional implementation.

## Design Priorities
Simplicity → Readability → Consistency → Testability → Reversibility

## Architecture Preferences
For this documentation update: Explicit over implicit. Consistency over customization. Progressive disclosure (clear error messages).

## Key Decisions

### Architecture Choice: Trampoline/Module Pattern
- **Decision**: Create `context-manager` trampoline script with `location` subcommand module
- **Rationale**:
  - **Decouples permissions from implementation**: Permission granted to trampoline invocation, not to implementation details
  - **Eliminates permission prompts**: Complex bash (echo, git rev-parse, subshells, quotes) runs inside pre-approved script
  - **Scalable**: Easy to add new subcommands without new permission patterns
  - **Follows conventions**: Go, git, docker all use this pattern
- **Trade-offs**:
  - **Benefit**: Zero permission prompts, cleaner frontmatter, extensible architecture
  - **Drawback**: Requires creating new scripts (minimal effort)

### Pattern Design

**Old Pattern** (17 files, triggers permission prompts):
```bash
!{bash}
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository..."
    exit 1
fi
cd "$GIT_ROOT"              # ← Permission prompt
echo "Working directory: $GIT_ROOT"
```

**New Pattern** (zero permission prompts):
```bash
!{bash}
.cig/scripts/command-helpers/context-manager location
```

**Design Rationale**:
1. Permission check happens once at trampoline invocation
2. Module implementation (`location`) can be arbitrarily complex without additional prompts
3. Consistent with existing helper script pattern
4. Self-documenting subcommand name

### Trampoline Architecture

**Trampoline** (`.cig/scripts/command-helpers/context-manager`):
- Perl script (no extension, Unix convention)
- Parses subcommand argument
- Dispatches to module in `context-manager.d/`
- Simple, predictable, easy to audit

**Module** (`.cig/scripts/command-helpers/context-manager.d/location`):
- Perl script (no extension)
- Shows git repository root and current working directory
- Handles errors gracefully
- Can use complex bash logic without triggering permission prompts

### Frontmatter Permission Design
- **Decision**: Replace multiple patterns with single trampoline permission
- **Rationale**: Simpler, cleaner, matches existing helper script pattern

**Before** (fragile, requires multiple patterns):
```yaml
allowed-tools: Bash(echo:*), Bash(git rev-parse:*), ...
```

**After** (clean, already matches existing pattern):
```yaml
allowed-tools: Bash(.cig/scripts/command-helpers/context-manager:*)
```

Note: Most CIG commands already have `Bash(.cig/scripts/command-helpers/*:*)` which covers this.

## System Design

### Component Overview
This bugfix creates 2 new scripts and updates 18 files:

1. **New: context-manager Trampoline** (`.cig/scripts/command-helpers/context-manager`)
   - Purpose: Dispatch to context-related subcommands
   - Language: Perl (no extension)
   - Permissions: u+rx (0500 minimum)
   - Subcommands: `location` (extensible for future: `hierarchy`, `inheritance`, etc.)

2. **New: location Module** (`.cig/scripts/command-helpers/context-manager.d/location`)
   - Purpose: Show git repository root and current working directory
   - Language: Perl (no extension)
   - Permissions: u+rx (0500 minimum)
   - Output: Git root path, cwd, relative path (for debugging)

3. **CIG Command Files** (17 files in `.claude/commands/cig-*.md`)
   - Purpose: Define user-facing workflow commands
   - Change: Replace inline bash → `context-manager location` call

4. **cig-new-task Command** (1 file: `.claude/commands/cig-new-task.md`)
   - Purpose: Document template-copier usage
   - Change: Clarify that template-copier creates directories AND copies files

### Update Strategy

**Phase 1: Create Trampoline Script**
```perl
#!/usr/bin/env perl
# context-manager trampoline
# Dispatches to subcommand modules in context-manager.d/
```

**Phase 2: Create location Module**
```perl
#!/usr/bin/env perl
# Shows git repository root and current working directory
# Output format: Git root, cwd, relative path
```

**Phase 3: Update CIG Command Files**
```
Find (multi-line):
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$GIT_ROOT" ]; then
      echo "Error: Not in a git repository..."
      exit 1
  fi

  cd "$GIT_ROOT"
  echo "Working directory: $GIT_ROOT"

Replace with (single line):
  .cig/scripts/command-helpers/context-manager location
```

**Phase 4: Update cig-new-task Documentation**
```
Find: "Call template-copier to copy templates and substitute variables:"
Add after code block: "Note: template-copier creates the destination directory automatically, so no mkdir is needed."
```

## Interface Design

### Files to Create (2 new scripts)

**New Scripts**:
1. `.cig/scripts/command-helpers/context-manager` (Perl trampoline, no extension)
2. `.cig/scripts/command-helpers/context-manager.d/location` (Perl module, no extension)

### Files to Modify (18 total)

**CIG Commands with Git Root Detection** (17 files):
1. `.claude/commands/cig-config.md`
2. `.claude/commands/cig-design-plan.md`
3. `.claude/commands/cig-extract.md`
4. `.claude/commands/cig-implementation-exec.md`
5. `.claude/commands/cig-implementation-plan.md`
6. `.claude/commands/cig-init.md`
7. `.claude/commands/cig-maintenance.md`
8. `.claude/commands/cig-new-task.md`
9. `.claude/commands/cig-requirements-plan.md`
10. `.claude/commands/cig-retrospective.md`
11. `.claude/commands/cig-rollout.md`
12. `.claude/commands/cig-security-check.md`
13. `.claude/commands/cig-status.md`
14. `.claude/commands/cig-subtask.md`
15. `.claude/commands/cig-task-plan.md`
16. `.claude/commands/cig-testing-exec.md`
17. `.claude/commands/cig-testing-plan.md`

**Documentation File** (1 file):
18. `.claude/commands/cig-new-task.md` (Step 5 documentation update)

### Script Specifications

**context-manager Trampoline**:
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;

my $subcommand = shift @ARGV or die "Usage: context-manager {location}\n";
my $script_dir = dirname(__FILE__);

my %commands = (
    location => "$script_dir/context-manager.d/location",
);

die "Unknown subcommand: $subcommand\n" unless exists $commands{$subcommand};
exec $commands{$subcommand}, @ARGV or die "Failed to exec: $!\n";
```

**location Module**:
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(getcwd abs_path);

# Get git root
my $git_root = `git rev-parse --show-toplevel 2>&1`;
chomp $git_root;

# Get current working directory
my $cwd = getcwd();

# Output
print "Git repo root: \"$git_root\"\n";
print "Current directory: \"$cwd\"\n";

exit 0;
```

### Pattern Replacement Specification

**Search for** (multi-line):
```
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository. CIG commands must be run from within a git repository."
    exit 1
fi

cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"
```

**Replace with** (single line):
```
.cig/scripts/command-helpers/context-manager location
```

## Constraints
- **Backward compatibility**: New pattern must work identically to old pattern
- **No code changes**: Only documentation/command file updates
- **Absolute paths required**: Commands must already use absolute paths (verify during implementation)
- **Error handling**: git rev-parse failure must be visible to user (handled automatically)

## Validation
- [x] Design review completed
- [x] Pattern tested manually (works without permission prompts)
- [x] File count verified (17 command files confirmed)
- [x] Integration points verified (all commands use absolute paths to helper scripts)

## Status
**Status**: Finished
**Next Action**: Move to implementation planning → `/cig-implementation-plan 39`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
