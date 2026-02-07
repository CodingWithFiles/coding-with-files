# reduce permission prompts from git root detection - Implementation

## Task Reference
- **Task ID**: internal-39
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/39-reduce-permission-prompts-from-git-root-detection
- **Template Version**: 2.1

## Goal
Eliminate permission prompts from git root detection by implementing a trampoline/module architecture that decouples invocation permissions from functional implementation.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Create
### New Scripts (2 files)
- `.cig/scripts/command-helpers/context-manager` - Perl trampoline (no extension)
- `.cig/scripts/command-helpers/context-manager.d/location` - Perl module (no extension)

## Files to Modify
### Primary Changes (17 CIG command files)
- `.claude/commands/cig-config.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-design-plan.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-extract.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-implementation-exec.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-implementation-plan.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-init.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-maintenance.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-new-task.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-requirements-plan.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-retrospective.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-rollout.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-security-check.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-status.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-subtask.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-task-plan.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-testing-exec.md` - Replace inline bash → `context-manager location`
- `.claude/commands/cig-testing-plan.md` - Replace inline bash → `context-manager location`

### Supporting Changes
- `.claude/commands/cig-new-task.md` (Step 5) - Add note about template-copier creating directories

## Implementation Steps
### Step 1: Create Module Directory
- [ ] Create directory: `.cig/scripts/command-helpers/context-manager.d/`
- [ ] Verify directory permissions (should be u+rwx minimum)

### Step 2: Create context-manager Trampoline Script
- [ ] Create file: `.cig/scripts/command-helpers/context-manager`
- [ ] Write Perl trampoline code (see c-design-plan.md for specification)
- [ ] Set executable permissions: `chmod +x`
- [ ] Test: `context-manager location` (should fail gracefully - module not yet created)

### Step 3: Create location Module
- [ ] Create file: `.cig/scripts/command-helpers/context-manager.d/location`
- [ ] Write Perl module code (see c-design-plan.md for specification)
- [ ] Set executable permissions: `chmod +x`
- [ ] Test: `context-manager location` (should show git root and cwd)

### Step 4: Replace Inline Bash in CIG Command Files
- [ ] For each of 17 CIG command files, replace the 7-line bash with `context-manager location` call
- [ ] Old pattern (7 lines):
  ```bash
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$GIT_ROOT" ]; then
      echo "Error: Not in a git repository. CIG commands must be run from within a git repository."
      exit 1
  fi

  cd "$GIT_ROOT"
  echo "Working directory: $GIT_ROOT"
  ```
- [ ] New pattern (1 line):
  ```bash
  .cig/scripts/command-helpers/context-manager location
  ```

### Step 5: Update cig-new-task Documentation
- [ ] In `.claude/commands/cig-new-task.md`, find Step 5 (template-copier section)
- [ ] After the template-copier code block, add clarifying note:
  ```markdown
  **Note**: The template-copier script creates the destination directory automatically, so there's no need to create it with mkdir beforehand. Simply call template-copier with the desired destination path and it will handle directory creation and file copying in a single operation.
  ```

### Step 6: Validation
- [ ] Verify all 17 files have `context-manager location` call (grep count)
- [ ] Verify context-manager script exists and is executable
- [ ] Verify location module exists and is executable
- [ ] Verify cig-new-task has the clarifying note
- [ ] Test one command to confirm no permission prompts

## Code Changes

### Change 1: Create context-manager Trampoline

#### New File: `.cig/scripts/command-helpers/context-manager`
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

**Why this works**:
- Decouples permission (trampoline invocation) from implementation (module execution)
- Simple dispatcher - easy to audit and understand
- Extensible - add new subcommands by adding to %commands hash

### Change 2: Create location Module

#### New File: `.cig/scripts/command-helpers/context-manager.d/location`
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

**Why this works**:
- Runs inside pre-approved script context - no permission prompts
- Shows git root AND current directory (helpful for debugging)
- git rev-parse fails gracefully if not in repo
- Can be arbitrarily complex without triggering permission prompts

### Change 3: Replace Inline Bash Pattern

#### Before (7 lines, triggers permission prompts)
```bash
!{bash}
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "Error: Not in a git repository. CIG commands must be run from within a git repository."
    exit 1
fi

cd "$GIT_ROOT"
echo "Working directory: $GIT_ROOT"
```

#### After (1 line, zero permission prompts)
```bash
!{bash}
.cig/scripts/command-helpers/context-manager location
```

**Why this works**:
- Permission granted once at trampoline invocation
- Module implementation can use git rev-parse, echo, etc. without additional prompts
- Cleaner, more maintainable
- Follows existing helper script pattern

### Change 3: cig-new-task Documentation

#### Before
```markdown
### 5. Copy and Populate Template Files
**Key change**: Use template-copier helper script

Call template-copier to copy templates and substitute variables:

\`\`\`bash
.cig/scripts/command-helpers/template-copier \\
  --task-type="$TYPE" \\
  --destination="$TASK_DIR" \\
  --task-num="$NUM" \\
  --description="$DESCRIPTION"
\`\`\`
```

#### After
```markdown
### 5. Copy and Populate Template Files
**Key change**: Use template-copier helper script

Call template-copier to copy templates and substitute variables:

\`\`\`bash
.cig/scripts/command-helpers/template-copier \\
  --task-type="$TYPE" \\
  --destination="$TASK_DIR" \\
  --task-num="$NUM" \\
  --description="$DESCRIPTION"
\`\`\`

**Note**: The template-copier script creates the destination directory automatically, so there's no need to create it with mkdir beforehand. Simply call template-copier with the desired destination path and it will handle directory creation and file copying in a single operation.
```

**Why this helps**:
- Clarifies that mkdir is unnecessary
- Prevents LLM from creating directory separately (which triggers permission prompt)
- Makes template-copier behavior explicit

## Test Coverage
**See e-testing-plan.md for complete test plan**

### Key Validation Tests
- **VT-1**: Verify `context-manager` script exists and is executable
- **VT-2**: Verify `location` module exists and is executable
- **VT-3**: Verify pattern replaced in all 17 files (grep count = 17)
- **VT-4**: Verify cig-new-task has clarifying note
- **VT-5**: Manual test - run one CIG command, confirm 0 permission prompts

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

### Implementation Complete When:
- [ ] `context-manager` trampoline script created and executable
- [ ] `location` module created and executable
- [ ] All 17 CIG command files have `context-manager location` call
- [ ] cig-new-task has template-copier clarification note
- [ ] Manual test confirms zero permission prompts
- [ ] All 5 success criteria from a-task-plan.md met

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
**Next Action**: Move to testing planning (update e-testing-plan.md) → `/cig-testing-plan 39`
**Blockers**: None identified

**Note**: Implementation plan updated to reflect trampoline/module architecture instead of inline bash pattern replacement.

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
