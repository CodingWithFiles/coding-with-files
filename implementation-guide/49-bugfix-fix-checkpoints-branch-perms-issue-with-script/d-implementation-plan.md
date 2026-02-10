# fix-checkpoints-branch-perms-issue-with-script - Implementation Plan
**Task**: 49 (bugfix)

## Task Reference
- **Task ID**: internal-49
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/49-fix-checkpoints-branch-perms-issue-with-script
- **Template Version**: 2.1

## Goal
Create `checkpoints-branch-manager` script and update Step 10 instructions to eliminate permission prompts.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cig/scripts/command-helpers/checkpoints-branch-manager` - **CREATE** new Perl script with three subcommands
- `.claude/commands/cig-retrospective.md` - **UPDATE** Step 10.1, 10.2, 10.4 to use script
- `.cig/security/script-hashes.json` - **UPDATE** add SHA256 hash for new script

### Supporting Changes
- None required (frontmatter already allows `.cig/scripts/command-helpers/*:*`)

## Implementation Steps
### Step 1: Create Script Structure
- [ ] Create `.cig/scripts/command-helpers/checkpoints-branch-manager` file
- [ ] Add shebang (`#!/usr/bin/env perl`) and pragmas (`use strict; use warnings;`)
- [ ] Add `get_script_rel_path()` helper function (standard CIG pattern)
- [ ] Set up main argument parsing for subcommands
- [ ] Set file permissions to `u+rx,go-rwx` (0500)

### Step 2: Implement Subcommands
- [ ] Implement `create` subcommand:
  - Get current branch name with `git rev-parse --abbrev-ref HEAD`
  - Check for detached HEAD state
  - Create branch with `git branch "<branch>-checkpoints"`
  - Handle "branch already exists" error
- [ ] Implement `show-history` subcommand:
  - Accept optional count parameter (default: 20)
  - Execute `git log --oneline --graph -<count>`
  - Pass through git output preserving color
- [ ] Implement `verify` subcommand:
  - Get current branch name
  - Execute `git log "<branch>-checkpoints" --oneline`
  - Handle "branch doesn't exist" error

### Step 3: Add Error Handling
- [ ] Check if in git repository (exit 1 if not)
- [ ] Validate subcommand is one of: create, show-history, verify
- [ ] Print usage message for invalid subcommand
- [ ] Handle detached HEAD gracefully (error message, exit 1)
- [ ] Handle missing checkpoints branch in verify command

### Step 4: Update Step 10 Instructions
- [ ] Update `.claude/commands/cig-retrospective.md` line 168-171:
  - Replace bash code block with `checkpoints-branch-manager create`
- [ ] Update line 175-177:
  - Add `checkpoints-branch-manager show-history` before git rebase
- [ ] Update line 205-209:
  - Replace bash code block with `checkpoints-branch-manager verify`
- [ ] Preserve explanatory text and examples

### Step 5: Update Security Hash
- [ ] Generate SHA256 hash: `sha256sum .cig/scripts/command-helpers/checkpoints-branch-manager`
- [ ] Add entry to `.cig/security/script-hashes.json`
- [ ] Format: `"checkpoints-branch-manager": "<hash>"`

## Code Changes
### Script Structure (New File)
```perl
#!/usr/bin/env perl
use strict;
use warnings;

sub get_script_rel_path {
    use Cwd 'abs_path';
    my $git_root = `git rev-parse --show-toplevel 2>/dev/null`;
    chomp $git_root;
    my $script_path = abs_path($0);
    if ($git_root && $script_path =~ m{^\Q$git_root\E/(.+)$}) {
        return $1;
    }
    return 'checkpoints-branch-manager';
}

sub create_checkpoints_branch {
    my $rel_path = get_script_rel_path();

    # Get current branch
    my $branch = `git rev-parse --abbrev-ref HEAD 2>&1`;
    chomp $branch;
    if ($? != 0 || $branch eq 'HEAD') {
        print STDERR "$rel_path: error: not on a branch\n";
        exit 1;
    }

    # Create checkpoints branch
    my $checkpoints_branch = "$branch-checkpoints";
    system("git", "branch", $checkpoints_branch);
    if ($? != 0) {
        print STDERR "$rel_path: error: failed to create branch $checkpoints_branch\n";
        exit 1;
    }

    print "$rel_path: created branch $checkpoints_branch\n";
}

# ... show_history and verify subcommands ...

# Main
my $subcommand = shift @ARGV;
unless (defined $subcommand) {
    print STDERR "Usage: checkpoints-branch-manager <create|show-history|verify>\n";
    exit 1;
}

if ($subcommand eq 'create') {
    create_checkpoints_branch();
} elsif ($subcommand eq 'show-history') {
    show_history(@ARGV);
} elsif ($subcommand eq 'verify') {
    verify_checkpoints_branch();
} else {
    print STDERR "Unknown subcommand: $subcommand\n";
    exit 1;
}
```

### Step 10 Instructions (Before)
```bash
# 10.1 Create checkpoints branch
git branch "$(git rev-parse --abbrev-ref HEAD)-checkpoints"

# 10.2 Find base commit
git log --oneline --graph -20  # Identify base commit

# 10.4 Verify checkpoints branch
git log "$(git rev-parse --abbrev-ref HEAD)-checkpoints" --oneline
```

### Step 10 Instructions (After)
```bash
# 10.1 Create checkpoints branch
checkpoints-branch-manager create

# 10.2 Find base commit
checkpoints-branch-manager show-history  # Shows recent commits

# 10.4 Verify checkpoints branch
checkpoints-branch-manager verify
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

Key validation points:
- Script executes without permission prompts when called from Step 10
- All three subcommands work correctly (create, show-history, verify)
- Error handling works for all edge cases (detached HEAD, branch exists, not in repo)
- Security hash matches generated hash
- Step 10 instructions are clear and functional

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

Before marking complete:
- [ ] Script created with correct permissions (0500)
- [ ] All three subcommands functional
- [ ] Step 10 instructions updated and tested
- [ ] Security hash added to script-hashes.json
- [ ] No permission prompts when executing Step 10

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - estimated ~4 hours total
- [ ] **People**: Does this need >2 people working on different parts? **NO** - single developer
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **NO** - single concern (wrap git commands)
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** - low-risk wrapper
- [ ] **Independence**: Can parts be worked on separately? **NO** - tightly coupled

**Decomposition Decision**: No decomposition needed.

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
**Status**: In Progress
**Next Action**: /cig-testing-plan
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
