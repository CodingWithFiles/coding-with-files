# add-task-stack-script - Implementation Plan

## Task Reference
- **Task ID**: internal-34
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/34-add-task-stack-script
- **Template Version**: 2.1

## Goal
Implement task stack management system with script, skill, security hook, Task 32 integration, and initialization updates following approved design.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes (New Files)
- `.cig/scripts/command-helpers/task-stack` - Core Perl script with 6 operations
- `.claude/skills/cig-current-task/SKILL.md` - User-facing skill wrapper
- `.claude/skills/cig-current-task/skill-metadata.json` - Skill metadata (if required)

### Supporting Changes (Modifications)
- `.cig/scripts/command-helpers/task-context-inference` - Update `.cig/current-task` → `.cig/task-stack` in comments
- `.cig/lib/TaskContextInference.pm` - Update file path reference if it exists
- `.claude/skills/cig-init/SKILL.md` - Add `.cig/task-stack` to gitignore logic
- `.gitignore` - Add `.cig/task-stack` entry (manual or via `/cig-init`)

### Cleanup (Optional Files to Remove)
- `.claude/commands/cig-current.md` - Remove if exists
- `.claude/skills/cig-current/` - Remove directory if exists

### Security/Documentation
- `.claude/CLAUDE.md` - Add PreToolUse hook documentation (or plugin hooks if using plugin architecture)
- `.cig/security/script-hashes.json` - Add task-stack script hash

## Implementation Steps

### Step 1: Core Script Implementation
- [ ] Create `.cig/scripts/command-helpers/task-stack` with shebang `#!/usr/bin/env perl`
- [ ] Add `use strict; use warnings;` and required modules (Fcntl, FindBin, CIG::TaskPath)
- [ ] Implement `get_script_rel_path()` function for self-documenting output
- [ ] Implement `push_task($task_num)` with resolve_num, format_dirname, flock, append
- [ ] Implement `pop_task()` with read, pop, truncate, parse_dirname
- [ ] Implement `peek_stack()` with read last line only
- [ ] Implement `list_stack()` with self-documenting header format
- [ ] Implement `clear_stack()` with idempotent unlink
- [ ] Implement `get_size()` with line count
- [ ] Add operation dispatch (main section parsing $ARGV[0])
- [ ] Set permissions: `chmod 755 .cig/scripts/command-helpers/task-stack`

### Step 2: User Skill Implementation
- [ ] Create `.claude/skills/cig-current-task/` directory
- [ ] Create `SKILL.md` with skill definition
- [ ] Define user-invocable: true
- [ ] Add argument parsing (no args → list, push <num>, pop, clear)
- [ ] Delegate to task-stack script via Bash tool
- [ ] Handle output display to user
- [ ] Add usage examples and help text

### Step 3: Task 32 Integration
- [ ] Update `task-context-inference` header comment: `.cig/current-task` → `.cig/task-stack`
- [ ] If `TaskContextInference.pm` exists, update `$STACK_FILE` variable
- [ ] Verify `read_state_signal()` checks file existence before reading
- [ ] Test that inference works when file doesn't exist (optional signal)

### Step 4: Initialization Integration
- [ ] Open `.claude/skills/cig-init/SKILL.md`
- [ ] Add step to check if `.gitignore` exists
- [ ] Add logic to append `.cig/task-stack` to `.gitignore` if not present
- [ ] Use `grep -q` check before appending (idempotent)

### Step 5: Security Hook (Advisory)
- [ ] Document PreToolUse hook pattern in `.claude/CLAUDE.md` or plugin hooks
- [ ] Hook checks: `if tool in [Edit, Write] and file_path contains ".cig/task-stack"`
- [ ] Hook action: Block + explain + suggest `/cig-current-task` instead
- [ ] Note: Advisory only, script validates on read

### Step 6: Cleanup
- [ ] Check for `.claude/commands/cig-current.md` - delete if exists
- [ ] Check for `.claude/skills/cig-current/` - delete if exists
- [ ] Grep codebase for `/cig-current` references (except `/cig-current-task`)
- [ ] Update any remaining references

### Step 7: Security Hashes
- [ ] Run `/cig-security-check verify` to identify new script
- [ ] Add `task-stack` to `.cig/security/script-hashes.json`
- [ ] Generate SHA256 hash: `sha256sum .cig/scripts/command-helpers/task-stack`

### Step 8: Manual Testing
- [ ] Test push operation: `/cig-current-task push 34`
- [ ] Verify file created with dirname format
- [ ] Test list operation: `/cig-current-task`
- [ ] Verify self-documenting output format
- [ ] Test pop operation: `/cig-current-task pop`
- [ ] Verify file truncated correctly
- [ ] Test concurrent pushes (open two terminals)
- [ ] Test with non-existent task number (error handling)

### Step 9: Integration Testing
- [ ] Run `/cig-init` and verify `.gitignore` updated
- [ ] Push task 34 to stack
- [ ] Run task-context-inference and verify it detects task 34
- [ ] Remove `.cig/task-stack` and verify inference still works (graceful degradation)

### Step 10: Documentation Updates
- [ ] Update any relevant docs in `.cig/docs/` if needed
- [ ] Ensure skill has clear usage examples
- [ ] Document PreToolUse hook behavior

## Code Changes

### Core Script Structure
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Fcntl qw(:flock :seek O_RDWR O_CREAT O_APPEND);
use FindBin;
use lib "$FindBin::Bin/../../lib";
use CIG::TaskPath qw(resolve_num format_dirname parse_dirname);

my $STACK_FILE = '.cig/task-stack';

sub get_script_rel_path {
    my $git_root = `git rev-parse --show-toplevel 2>/dev/null`;
    chomp $git_root;
    my $script_path = $0;
    if ($git_root && $script_path =~ m{^\Q$git_root\E/(.+)$}) {
        return $1;
    }
    return 'task-stack';
}

sub push_task {
    my ($task_num) = @_;
    my $rel_path = get_script_rel_path();

    my $task_info = resolve_num($task_num);
    unless ($task_info) {
        print STDERR "$rel_path: error: task $task_num not found\n";
        exit 1;
    }

    my $dirname = format_dirname(
        num  => $task_info->{num},
        type => $task_info->{type},
        slug => $task_info->{slug}
    );

    open my $fh, '>>', $STACK_FILE or die "$rel_path: cannot open stack: $!";
    flock($fh, LOCK_EX) or die "$rel_path: cannot lock: $!";
    print $fh "$dirname\n";
    close $fh;

    print "$rel_path: pushed $dirname\n";
}

sub list_stack {
    my $rel_path = get_script_rel_path();

    unless (-e $STACK_FILE) {
        print "$rel_path: list task stack (use --help for options)\n";
        print "$rel_path: 0 tasks in stack (empty)\n";
        return;
    }

    open my $fh, '<', $STACK_FILE or die "$rel_path: cannot open stack: $!";
    my @lines = <$fh>;
    close $fh;

    chomp @lines;
    my $total = scalar @lines;
    my @recent = @lines[($total > 5 ? $total - 5 : 0) .. $total - 1];
    my $showing = scalar @recent;

    print "$rel_path: list task stack (use --help for options)\n";
    print "$rel_path: showing $showing of $total total tasks, most recent last\n";

    for my $dirname (@recent) {
        print "$dirname\n";
    }
}

# Main dispatch
my $op = shift @ARGV or die "Usage: task-stack {push|pop|peek|list|clear|size} [args]\n";

if ($op eq 'push') {
    my $task = shift @ARGV or die "Usage: task-stack push <task-num>\n";
    push_task($task);
} elsif ($op eq 'list') {
    list_stack();
} elsif ($op eq 'pop') {
    pop_task();
} elsif ($op eq 'peek') {
    peek_stack();
} elsif ($op eq 'clear') {
    clear_stack();
} elsif ($op eq 'size') {
    print get_size() . "\n";
} else {
    die "Unknown operation: $op\n";
}
```

### Skill Definition
```markdown
# cig-current-task

Manage the current task stack.

## Your task

Parse user arguments and call task-stack script:

- No args: Show stack (list)
- `push <num>`: Push task onto stack
- `pop`: Pop task from stack
- `clear`: Clear entire stack

Use Bash tool to call:
```bash
.cig/scripts/command-helpers/task-stack {operation} [args]
```

Display output to user.
```

### Task 32 Update
```perl
# Before (in task-context-inference header):
#   - State file (.cig/current-task)

# After:
#   - State file (.cig/task-stack)
```

### Initialization Update
```bash
# In /cig-init skill, add after creating .cig/ directory:
if [ ! -f .gitignore ] || ! grep -q '^\.cig/task-stack$' .gitignore; then
    echo '.cig/task-stack' >> .gitignore
    echo "Added .cig/task-stack to .gitignore"
fi
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

Key test scenarios:
- Push valid task → verify file contains dirname
- Pop from stack → verify last entry removed
- List empty stack → verify "0 tasks" message
- Concurrent pushes → verify no corruption
- Invalid task number → verify error message
- Task 32 integration → verify inference uses stack

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

Success criteria:
- All 6 operations work correctly (push/pop/peek/list/clear/size)
- Output format matches design (self-documenting with relative path)
- File permissions correct (0755 for script)
- flock prevents race conditions
- Task 32 integration functional
- `.gitignore` includes `.cig/task-stack`
- All 22 acceptance criteria pass (AC1-AC22)

## Status
**Status**: Finished
**Next Action**: Move to testing planning → `/cig-testing-plan 34`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
