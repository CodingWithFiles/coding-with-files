# Add --workflow Option to status-aggregator - Design

## Task Reference
- **Task ID**: internal-18
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/18-add-workflow-option-to-status-aggregator
- **Template Version**: 2.0

## Goal
Design enhanced status-aggregator.pl with CIG::Options integration, hierarchy depth control, workflow step visibility, and flexible sorting.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice
- **Decision**: Extend existing status-aggregator.pl architecture with minimal changes
- **Rationale**:
  - Current code already has clean separation: option parsing → tree building → output formatting
  - Existing calculate_progress() and build_tree() functions work well and are tested in production
  - Adding new options fits naturally into existing flow without rewrite
  - Maintains backward compatibility by design (new features opt-in via flags)
- **Trade-offs**:
  - ✅ Pros: Low risk, incremental improvement, backward compatible, reuses proven code
  - ✅ Pros: Easier to test (compare old vs new behavior side-by-side)
  - ⚠️ Cons: Script grows larger (~400 lines estimated vs current 196)
  - ⚠️ Cons: Some duplication in output formatting (markdown vs JSON with/without workflow)

### Technology Stack
- **Language**: Perl 5.30.3+ (macOS compatibility requirement)
- **Option Parsing**: CIG::Options module (replaces manual @ARGV parsing)
- **Task Resolution**: CIG::TaskPath (existing, unchanged)
- **Workflow Files**: CIG::WorkflowFiles (existing, unchanged)
- **Status Extraction**: CIG::MarkdownParser (existing, unchanged)
- **Version Control**: Git log for timestamp queries (--sort=date, --sort=modified)

## System Design

### Component Overview

**1. Option Parser (NEW - uses CIG::Options)**
- **Purpose**: Parse and validate command-line options
- **Responsibility**: Convert @ARGV into validated options hash
- **Inputs**: @ARGV
- **Outputs**: { help => 0/1, workflow => 0/1, depth => N, sort => 'mode', format => 'markdown'/'json', _positional => 'task-path' }
- **Error handling**: Exit 1 for invalid options (delegated to CIG::Options)

**2. Task Tree Builder (EXISTING - minimal changes)**
- **Purpose**: Build hierarchical task tree with progress calculations
- **Responsibility**: Recursively traverse task directories, calculate progress percentages
- **Current function**: build_tree($base_path, $indent, $task_num)
- **Changes needed**:
  - Add $depth parameter to limit recursion depth
  - Track current depth relative to starting point
  - Stop recursion when depth limit reached
- **Unchanged**: calculate_progress() remains identical

**3. Workflow File Enumerator (NEW)**
- **Purpose**: List workflow files for a task when --workflow flag set
- **Responsibility**: Query CIG::WorkflowFiles::list(), extract status from each file
- **Function signature**: get_workflow_status($task_dir) → \@workflow_files
- **Returns**: [ { name => 'a-plan.md', status => 'In Progress', percent => 25 }, ... ]
- **Reuses**: CIG::WorkflowFiles::list() and CIG::MarkdownParser::extract_status()

**4. Task Sorter (NEW)**
- **Purpose**: Sort tasks at each hierarchy level based on --sort option
- **Responsibility**: Apply numeric, date, or modified sorting to task list
- **Function signatures**:
  - sort_tasks(\@tasks, $mode, $base_dir) → \@sorted_tasks
  - get_task_timestamps($task_dir) → { created => epoch, modified => epoch }
- **Algorithms**:
  - **Numeric**: Natural sort using version comparison (2.10 > 2.9)
  - **Date**: Git log --diff-filter=A (file creation) → min(timestamps)
  - **Modified**: Git log (all commits) → max(timestamps)

**5. Output Formatter (MODIFIED)**
- **Purpose**: Format task tree as markdown or JSON
- **Responsibility**: Generate human-readable or machine-parseable output
- **Current behavior**: Formats task tree with indicators (✓ ⚙️ ○)
- **Changes needed**:
  - Replace emoji with single-character ASCII: `*` (finished), `+` (in progress), `-` (not started)
  - Add workflow file rendering (2-space indent, tab-aligned columns)
  - Extend JSON output to include workflow breakdown when --workflow set
  - Respect depth limiting (don't render beyond depth)
- **Format**: Status indicator, task info, tab, status text, tab, percentage
- **Rationale for ASCII**: Emoji like ⚙️ are double-width, breaking tab alignment

### Data Flow

```
1. Parse command-line options
   @ARGV → CIG::Options::parse($spec, @ARGV) → %opts

2. Validate and resolve task path (if provided)
   $opts{_positional} → validate() → resolve() → $task_dir
   Find $base_dir (implementation-guide/ or parent task dir)

3. Build task tree with depth limiting
   build_tree($base_dir, "", $task_num, $depth, 0)
   - Recursively traverse directories
   - Track current_depth relative to start
   - Stop when current_depth >= $opts{depth} (unless depth=-1)
   - Call calculate_progress() for each task (unchanged)
   - Return @tree = [ { num, type, slug, progress, dir, ... }, ... ]

4. Optionally enrich with workflow file status
   IF $opts{workflow}:
     For each task in @tree:
       $task->{workflow_files} = get_workflow_status($task->{dir})

5. Sort tasks at each level
   apply_sort(\@tree, $opts{sort}, $base_dir)
   - Group tasks by parent (same level)
   - Sort each group according to mode
   - Preserve hierarchy structure

6. Format output
   IF $opts{format} eq 'json':
     output_json(\@tree, \%opts)
   ELSE:
     output_markdown(\@tree, \%opts)
   - Render task indicators (* + -)
   - If workflow: render workflow files (2-space indent)
   - Tab-align status and percentage columns

7. Exit with appropriate code
   exit 0 (success) or exit 2 (task not found)
```

## Interface Design

### Command-Line Interface

**CIG::Options Specification**:
```perl
my $spec = {
    description => "status-aggregator.pl - Calculate task progress from status markers",
    options => [
        { short => 'h', long => 'help', type => 'flag',
          desc => 'Show this help message' },
        { short => 'w', long => 'workflow', type => 'flag',
          desc => 'Show individual workflow file statuses' },
        { long => 'depth', type => 'value',
          desc => 'Hierarchy depth (0=top-level, -1=unlimited, default: 0)' },
        { long => 'sort', type => 'value',
          desc => 'Sort order (numeric|date|modified, default: numeric)' },
        { long => 'format', type => 'value',
          desc => 'Output format (markdown|json, default: markdown)' },
    ],
    positional => { name => 'task-path', optional => 1,
                    desc => 'Task number to filter (e.g., "1", "1.1")' }
};
```

**Usage Examples**:
```bash
# Default: top-level tasks, aggregated percentages
status-aggregator.pl

# Show task 18 with workflow files
status-aggregator.pl 18 -w

# Top-level tasks with workflow details
status-aggregator.pl --workflow

# Show 2 levels deep, sorted by modification date
status-aggregator.pl --depth=2 --sort=modified

# Full hierarchy with workflow files in JSON
status-aggregator.pl --depth=-1 --workflow --format=json

# Short options bundled
status-aggregator.pl -wh
```

### Data Structures

**Task Hash** (returned by build_tree):
```perl
{
    line => "+ 18 (feature): add-workflow-option - 25%",
    task => "18-feature-add-workflow-option-to-status-aggregator",
    num => "18",
    type => "feature",
    slug => "add-workflow-option-to-status-aggregator",
    progress => 25,
    dir => "/full/path/to/task",              # NEW: needed for workflow/sort
    workflow_files => [                       # NEW: optional, if --workflow
        { name => "a-plan.md", status => "In Progress", percent => 25 },
        { name => "b-requirements.md", status => "Backlog", percent => 0 },
        ...
    ],
    timestamps => {                           # NEW: optional, if --sort=date/modified
        created => 1705363200,                # Unix epoch
        modified => 1705449600,
    }
}
```

**Workflow File Hash** (returned by get_workflow_status):
```perl
{
    name => "a-plan.md",
    path => "/full/path/to/task/a-plan.md",
    status => "In Progress",                  # from extract_status()
    percent => 25                             # from status_to_percent()
}
```

### Output Formats

**ASCII Status Indicators**:
- `*` = Finished (100% progress)
- `+` = In Progress (1-99% progress)
- `-` = Not Started (0% progress)

**Markdown (default)**:
```
Task Progress:

+ 18 (feature): add-workflow-option	25%
    + 18.1 (chore): subtask-name	50%
```

**Markdown with --workflow**:
```
Task Progress:

+ 18 (feature): add-workflow-option	25%
  + a-plan.md	In Progress	25%
  - b-requirements.md	Backlog	0%
  - c-design.md	Backlog	0%
    + 18.1 (chore): subtask	50%
      + a-plan.md	In Progress	25%
      * d-implementation.md	Finished	100%
```

**JSON output** (extended with new fields):
```json
{
  "tasks": [
    {
      "task": "18-feature-add-workflow-option-to-status-aggregator",
      "num": "18",
      "type": "feature",
      "progress": 25,
      "workflow_files": [
        { "name": "a-plan.md", "status": "In Progress", "percent": 25 },
        { "name": "b-requirements.md", "status": "Backlog", "percent": 0 }
      ],
      "timestamps": {
        "created": 1705363200,
        "modified": 1705449600
      }
    }
  ]
}
```

## Algorithms

### Natural Numeric Sort
**Challenge**: Sort task numbers treating "." as version separator (2.10 > 2.9, not 2.1 > 2.10)

**Algorithm**:
```perl
sub natural_sort {
    my @tasks = @_;
    return sort {
        my @a_parts = split(/\./, $a->{num});
        my @b_parts = split(/\./, $b->{num});

        for (my $i = 0; $i < @a_parts || $i < @b_parts; $i++) {
            my $a_num = $a_parts[$i] // 0;
            my $b_num = $b_parts[$i] // 0;
            return $a_num <=> $b_num if $a_num != $b_num;
        }
        return 0;
    } @tasks;
}
```

### Git Timestamp Extraction
**Challenge**: Get creation and modification timestamps efficiently (one git call per task)

**Algorithm for created timestamp** (min of all workflow file creations):
```bash
git log --diff-filter=A --format=%ct -- task-dir/*.md | sort -n | head -1
```

**Algorithm for modified timestamp** (max of all workflow file modifications):
```bash
git log -1 --format=%ct -- task-dir/*.md
```

**Fallback**: If git log fails or returns empty (uncommitted files), use filesystem mtime:
```perl
my @mtimes = map { (stat $_)[9] } glob("$task_dir/*.md");
my $created = min(@mtimes);
my $modified = max(@mtimes);
```

### Depth-Limited Tree Traversal
**Challenge**: Track depth relative to starting point (root or specified task)

**Algorithm**:
```perl
sub build_tree {
    my ($base_path, $indent, $task_num, $max_depth, $current_depth) = @_;

    # Stop recursion if depth limit reached (unless -1 = unlimited)
    return () if $max_depth >= 0 && $current_depth >= $max_depth;

    my @output;
    for my $dir (glob_matching_tasks($base_path, $task_num)) {
        # Process current task
        my $task = build_task_hash($dir);
        push @output, $task;

        # Recurse into children (increment depth)
        my @subtasks = build_tree($dir, $indent."    ", $num, $max_depth, $current_depth + 1);
        push @output, @subtasks;
    }
    return @output;
}
```

## Constraints

### Technical Constraints
- **Backward compatibility**: Default behavior (no options) must match current output exactly
- **Existing modules**: Cannot modify CIG::WorkflowFiles, CIG::MarkdownParser, CIG::TaskPath
- **Git availability**: Must handle repositories without git or with shallow clones gracefully
- **Perl version**: Must work on macOS Perl 5.30.3 (no features from 5.32+)

### Performance Constraints
- **Git log overhead**: Avoid calling git log for every workflow file (batch queries per task)
- **Sorting complexity**: --sort=date/modified requires git queries, adds ~200ms overhead
- **Depth limiting**: --depth=0 should skip entire subtree traversal, not build then filter
- **Memory usage**: Large repositories (100+ tasks) should stay under 50MB

### Design Constraints
- **CIG::Options integration**: Required for consistency with future helper script refactoring
- **Tab-aligned output**: Status and percentage columns must align using tabs, not spaces
- **JSON schema**: Extend existing JSON format, don't break (add optional fields)
- **Indentation**: 4 spaces for task hierarchy, 2 spaces for workflow files (relative to parent)

## Validation
- [x] Design follows existing status-aggregator.pl architecture
- [x] CIG::Options spec covers all required options
- [x] Data structures defined for task hash and workflow files
- [x] Algorithms specified for natural sort and git timestamps
- [x] Output formats shown for markdown and JSON
- [x] Backward compatibility preserved (default behavior unchanged)
- [x] Performance constraints identified and addressed

## Status
**Status**: Finished
**Next Action**: Proceed to implementation phase
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
