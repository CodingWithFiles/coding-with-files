# Add --workflow Option to status-aggregator - Implementation

## Task Reference
- **Task ID**: internal-18
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/18-add-workflow-option-to-status-aggregator
- **Template Version**: 2.0

## Goal
Implement enhanced status-aggregator.pl with CIG::Options integration, hierarchy depth control, workflow step visibility, flexible sorting, and ASCII status indicators.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `.cig/scripts/command-helpers/status-aggregator.pl` - Add CIG::Options, depth limiting, workflow display, sorting, ASCII indicators
- `.cig/security/script-hashes.json` - Update SHA256 hash for modified status-aggregator.pl

### Supporting Changes
- None - CIG::Options module already created and documented
- None - Existing CIG modules (CIG::WorkflowFiles, CIG::MarkdownParser, CIG::TaskPath) unchanged

## Implementation Steps

### Step 1: Replace Manual Option Parsing with CIG::Options
- [ ] Read current status-aggregator.pl option parsing (lines 27-37)
- [ ] Create CIG::Options specification with 5 options (help, workflow, depth, sort, format)
- [ ] Replace manual @ARGV parsing with `CIG::Options::parse($spec, @ARGV)`
- [ ] Update `use` statements to include `use CIG::Options;`
- [ ] Test: Verify `--help` works, verify existing `--format=json` still works

### Step 2: Replace Emoji with ASCII Status Indicators
- [ ] Find indicator generation code (lines 115-122)
- [ ] Replace emoji with ASCII: `*` (100%), `+` (1-99%), `-` (0%)
- [ ] Update both markdown output and JSON output (if indicators included)
- [ ] Test: Run status-aggregator.pl, verify indicators are single-character ASCII

### Step 3: Add Depth Limiting to build_tree()
- [ ] Modify build_tree() signature: add $max_depth and $current_depth parameters
- [ ] Add depth check at start: `return () if $max_depth >= 0 && $current_depth >= $max_depth;`
- [ ] Update recursive call: increment $current_depth by 1
- [ ] Update main execution: pass $opts{depth} (default 0) and current_depth 0
- [ ] Handle special case: $opts{depth} = -1 means unlimited (skip depth check)
- [ ] Test: Verify `--depth=0` shows only top-level, `--depth=1` shows one level deep

### Step 4: Add Workflow File Enumerator
- [ ] Create get_workflow_status($task_dir) function
- [ ] Call `CIG::WorkflowFiles::list($task_dir)` to get workflow files
- [ ] For each file: extract status using `CIG::MarkdownParser::extract_status($path)`
- [ ] For each file: convert status to percent using `CIG::WorkflowFiles::status_to_percent($status)`
- [ ] Return arrayref: `[{ name, path, status, percent }, ...]`
- [ ] Test: Call function on Task 18 directory, verify returns 8 workflow files with statuses

### Step 5: Enrich Task Tree with Workflow Files (Conditional)
- [ ] After build_tree() completes, check if `$opts{workflow}` is set
- [ ] If set: iterate through @tree, for each task call get_workflow_status($task->{dir})
- [ ] Store result in `$task->{workflow_files}`
- [ ] Test: Run with `--workflow`, verify workflow_files key populated

### Step 6: Add Task Sorting Functions
- [ ] Create natural_sort(\@tasks) function using algorithm from design
- [ ] Create get_task_timestamps($task_dir) function
  - Use `git log --diff-filter=A --format=%ct -- $task_dir/*.md | sort -n | head -1` for created
  - Use `git log -1 --format=%ct -- $task_dir/*.md` for modified
  - Fallback to filesystem mtime if git fails
- [ ] Create apply_sort(\@tree, $mode) function
  - Group tasks by depth/parent
  - Sort each group by mode (numeric, date, modified)
  - Preserve hierarchy structure
- [ ] Test: Verify each sort mode produces expected ordering

### Step 7: Update Output Formatter for Workflow Display
- [ ] Modify markdown output section (lines 189-193)
- [ ] After printing task line, check if `$task->{workflow_files}` exists
- [ ] If exists: loop through workflow files, print with 2-space indent and tab alignment
- [ ] Format: `  {indicator} {filename}\t{status}\t{percent}%`
- [ ] Update JSON output to include `workflow_files` array when present
- [ ] Test: Run with `--workflow`, verify output matches design format

### Step 8: Implement Default Depth Change
- [ ] Change default depth from unlimited to 0 (top-level only)
- [ ] Update CIG::Options spec: depth defaults to 0
- [ ] Update backward compatibility: positional arg changes depth to -1 (unlimited)
- [ ] Logic: if `$opts{_positional}` exists, set `$opts{depth} = -1` unless user specified --depth
- [ ] Test: `status-aggregator.pl` shows top-level only, `status-aggregator.pl 18` shows full subtree

### Step 9: Add Input Validation and Error Messages
- [ ] Add validation for --depth option after parsing
  - Check if value is numeric using regex: `/^-?\d+$/`
  - Accept -1 (unlimited) or 0+ (limited depth)
  - Error message: "Error: Invalid depth value '$value', expected integer >= -1"
  - Exit with code 1 if invalid
- [ ] Add validation for --sort option after parsing
  - Check if value is one of: 'numeric', 'date', 'modified'
  - Error message: "Error: Invalid sort mode '$value', expected one of: numeric, date, modified"
  - Exit with code 1 if invalid
- [ ] Add validation after CIG::Options parsing, before git operations
- [ ] Test: `--depth=abc` produces error and exits 1
- [ ] Test: `--sort=invalid` produces error and exits 1
- [ ] Test: `--depth=-2` produces error (only -1 or 0+ allowed)

### Step 10: Update Script Hash
- [ ] Calculate new SHA256: `sha256sum .cig/scripts/command-helpers/status-aggregator.pl`
- [ ] Update `.cig/security/script-hashes.json` with new hash
- [ ] Test: Run cig-security-check if available

### Step 11: Validation Testing
- [ ] Test all acceptance criteria (AC1-AC16 from requirements)
- [ ] Test backward compatibility: existing usage patterns unchanged
- [ ] Test performance: < 500ms for --depth=0, < 2s for --depth=-1 on this repo
- [ ] Test error handling: invalid --depth, invalid --sort, unknown options

## Code Changes

### Change 1: CIG::Options Integration

**Before** (lines 27-37):
```perl
# Parse arguments
my $task_path = "";
my $format = "markdown";

for my $arg (@ARGV) {
    if ($arg eq "--format=json") {
        $format = "json";
    } elsif ($arg !~ /^--/) {
        $task_path = $arg;
    }
}
```

**After**:
```perl
use CIG::Options;

my $spec = {
    description => "status-aggregator.pl - Calculate task progress from status markers",
    options => [
        { short => 'h', long => 'help', type => 'flag', desc => 'Show this help message' },
        { short => 'w', long => 'workflow', type => 'flag', desc => 'Show individual workflow file statuses' },
        { long => 'depth', type => 'value', desc => 'Hierarchy depth (0=top-level, -1=unlimited, default: 0)' },
        { long => 'sort', type => 'value', desc => 'Sort order (numeric|date|modified, default: numeric)' },
        { long => 'format', type => 'value', desc => 'Output format (markdown|json, default: markdown)' },
    ],
    positional => { name => 'task-path', optional => 1, desc => 'Task number to filter' }
};

my $opts = CIG::Options::parse($spec, @ARGV);

# Set defaults
$opts->{depth} //= 0;
$opts->{sort} //= 'numeric';
$opts->{format} //= 'markdown';

# Backward compatibility: positional arg implies unlimited depth unless --depth specified
if ($opts->{_positional} && !defined $ARGV_depth) {
    $opts->{depth} = -1;
}

my $task_path = $opts->{_positional} // "";
my $format = $opts->{format};
```

### Change 2: ASCII Status Indicators

**Before** (lines 115-122):
```perl
# Determine status indicator
my $indicator;
if ($progress >= 100) {
    $indicator = "\x{2713}";      # ✓
} elsif ($progress > 0) {
    $indicator = "\x{2699}\x{FE0F}";  # ⚙️
} else {
    $indicator = "\x{25CB}";      # ○
}
```

**After**:
```perl
# Determine status indicator (single-width ASCII)
my $indicator;
if ($progress >= 100) {
    $indicator = "*";  # Finished
} elsif ($progress > 0) {
    $indicator = "+";  # In Progress
} else {
    $indicator = "-";  # Not Started
}
```

### Change 3: Depth-Limited build_tree()

**Before** (line 78):
```perl
sub build_tree {
    my ($base_path, $indent, $task_num) = @_;
    $indent //= "";
    $task_num //= "";

    my @output;
    # ... rest of function
}
```

**After**:
```perl
sub build_tree {
    my ($base_path, $indent, $task_num, $max_depth, $current_depth) = @_;
    $indent //= "";
    $task_num //= "";
    $max_depth //= -1;
    $current_depth //= 0;

    # Stop recursion if depth limit reached (unless -1 = unlimited)
    return () if $max_depth >= 0 && $current_depth >= $max_depth;

    my @output;
    # ... rest of function ...

    # Recursively process subtasks (increment depth)
    my @subtasks = build_tree($dir, "${indent}  ", $num, $max_depth, $current_depth + 1);
    push @output, @subtasks;
}
```

### Change 4: Workflow File Display

**New function**:
```perl
sub get_workflow_status {
    my ($task_dir) = @_;

    my $files = CIG::WorkflowFiles::list($task_dir);
    my @workflow_files;

    for my $file (@$files) {
        my $status = CIG::MarkdownParser::extract_status($file->{path});
        my $percent = CIG::WorkflowFiles::status_to_percent($status);

        push @workflow_files, {
            name => $file->{name},
            path => $file->{path},
            status => $status,
            percent => $percent
        };
    }

    return \@workflow_files;
}
```

**Markdown output addition** (after line 192):
```perl
for my $t (@tree) {
    print "$t->{line}\n";

    # Show workflow files if --workflow flag set
    if ($t->{workflow_files}) {
        for my $wf (@{$t->{workflow_files}}) {
            my $indicator = $wf->{percent} >= 100 ? "*" :
                           $wf->{percent} > 0 ? "+" : "-";
            printf "  %s %s\t%s\t%d%%\n",
                $indicator, $wf->{name}, $wf->{status}, $wf->{percent};
        }
    }
}
```

### Change 5: Input Validation

**After CIG::Options parsing** (after line 55):
```perl
my $task_path = $opts->{_positional} // "";
my $format = $opts->{format};

# Validate --depth option
if (defined $opts->{depth}) {
    unless ($opts->{depth} =~ /^-?\d+$/) {
        print STDERR "Error: Invalid depth value '$opts->{depth}', expected integer >= -1\n";
        exit 1;
    }
    if ($opts->{depth} < -1) {
        print STDERR "Error: Invalid depth value '$opts->{depth}', expected integer >= -1\n";
        exit 1;
    }
}

# Validate --sort option
my %valid_sort_modes = (numeric => 1, date => 1, modified => 1);
unless (exists $valid_sort_modes{$opts->{sort}}) {
    print STDERR "Error: Invalid sort mode '$opts->{sort}', expected one of: numeric, date, modified\n";
    exit 1;
}
```

## Test Coverage

**See e-testing.md for complete test plan with 31 test cases:**
- 24 functional tests (TC1-TC24) covering all 7 functional requirements
- 4 performance tests (PT1-PT4) validating speed benchmarks
- 2 usability tests (UT1-UT2) for help text and error messages
- 3 reliability tests (RT1-RT3) for edge cases

All tests documented in Given/When/Then format with clear validation criteria.

## Validation Criteria
- [ ] All 31 test cases pass (see e-testing.md for details)
- [ ] AC1-AC16 from requirements verified
- [ ] Script hash updated in .cig/security/script-hashes.json
- [ ] Code follows existing status-aggregator.pl style and patterns
- [ ] Performance benchmarks met (< 500ms depth=0, < 2s depth=-1)
- [ ] No regressions in existing functionality

## Status
**Status**: Finished
**Next Action**: Proceed to testing phase
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
