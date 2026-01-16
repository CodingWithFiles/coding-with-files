# new-helper-script-to-setup-templates-for-new-task - Design

## Task Reference
- **Task ID**: internal-17
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/17-new-helper-script-to-setup-templates-for-new-task
- **Template Version**: 2.0

## Goal
Design template-copier.pl - a Perl helper script that copies template files from the pool and substitutes variables, extracting logic from /cig-new-task command.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice
- **Decision**: Single-file Perl script with inline functions (no separate modules)
- **Rationale**:
  - Template copying is script-specific logic, not reused elsewhere
  - Keeps implementation simple and self-contained (~150 lines)
  - Follows pattern of hierarchy-resolver.pl (~80 lines), status-aggregator.pl (~200 lines)
  - Easier to maintain when all logic is in one place
- **Trade-offs**:
  - ✅ Pros: Simple, fast to implement, easy to understand and debug
  - ✅ Pros: No new module dependencies, follows existing CIG patterns
  - ⚠️ Cons: Template substitution logic not reusable (acceptable - specific use case)

### Technology Stack
- **Language**: Perl 5 (existing CIG standard)
- **Core Modules**: FindBin, File::Basename, File::Spec, Cwd
- **CIG Modules**: CIG::TaskPath (validation, parent computation), CIG::WorkflowFiles (config loading)
- **No external dependencies** - uses only Perl core + existing CIG modules

## System Design

### Component Overview

**1. Parameter Parser**
- Purpose: Parse and validate --name=value command-line arguments
- Responsibility: Validate required params (task-type, destination, task-num, description)
- Error handling: Exit 1 for invalid/missing params

**2. Git Root Detector**
- Purpose: Find repository root and template directory
- Responsibility: Use `git rev-parse --show-toplevel`, fallback to relative paths
- Error handling: Exit 2 if .cig/templates/ not found

**3. Template Discoverer**
- Purpose: List symlinks in .cig/templates/{task-type}/
- Responsibility: Read directory, follow symlinks to pool, verify targets exist
- Error handling: Exit 2 for broken symlinks or missing pool files

**4. Variable Substitutor**
- Purpose: Replace {{variable}} placeholders with actual values
- Responsibility: Compute and substitute 5 template variables
- Variables: description, taskId, taskUrl, parentTask, branchName

**5. File Writer**
- Purpose: Write templates to destination with correct permissions
- Responsibility: Atomic writes (temp + rename), chmod 0600, track created/overwritten
- Error handling: Exit 3 for permission errors, warn on overwrite (idempotency)

**6. Output Formatter**
- Purpose: Generate markdown or JSON output
- Responsibility: Format results for STDOUT, errors for STDERR

### Data Flow

```
1. Parse parameters (--task-type, --destination, --task-num, --description)
   └─> Validate or exit 1

2. Find git root and templates directory
   └─> git rev-parse --show-toplevel
   └─> Validate .cig/templates/ exists or exit 2

3. Load config and validate task-type
   └─> CIG::WorkflowFiles::load_config()
   └─> Check task-type in supported-task-types or exit 1

4. Discover templates for task-type
   └─> readdir(.cig/templates/{task-type}/)
   └─> Filter for *.template symlinks
   └─> Follow symlinks to pool or exit 2

5. Compute template variables
   └─> description (from param)
   └─> taskId ("internal-{task-num}")
   └─> taskUrl ("N/A (internal task)")
   └─> parentTask (CIG::TaskPath::get_parent() or "N/A")
   └─> branchName ("{task-type}/{task-num}-{slug}")
   └─> slug (extract from destination basename)

6. For each template file:
   └─> Read pool template content
   └─> Substitute variables (s/\{\{var\}\}/value/g)
   └─> Check if destination file exists (for idempotency tracking)
   └─> Write to destination/{filename without .template}
   └─> chmod 0600
   └─> Track created vs overwritten

7. Output results
   └─> Markdown: "Files created: ...\nTotal: N files"
   └─> JSON: {"destination": "...", "files_created": [...], ...}
```

## Interface Design

### Script Location
- **Path**: `.cig/scripts/command-helpers/template-copier.pl`
- **Permissions**: 0500 (read/execute owner only)

### Command-Line Interface

**Usage**:
```bash
template-copier.pl --task-type=TYPE --destination=PATH --task-num=NUM --description=DESC [--format=json]
```

**Parameters**:
- `--task-type=TYPE` - Required. One of: feature, bugfix, hotfix, chore, discovery
- `--destination=PATH` - Required. Full path to task directory
- `--task-num=NUM` - Required. Task number (e.g., "17", "1.2.3")
- `--description=DESC` - Required. Task description/slug
- `--format=FORMAT` - Optional. Output format: markdown (default) or json
- `--help` - Optional. Show usage and exit

### Output Formats

**Markdown (default)**:
```
Template files copied to: implementation-guide/17-feature-...
Files created:
  - a-plan.md
  - b-requirements.md
  ...
Total: 8 files copied
```

**JSON (--format=json)**:
```json
{
  "destination": "implementation-guide/17-feature-...",
  "task_type": "feature",
  "task_num": "17",
  "files_created": ["a-plan.md", ...],
  "files_overwritten": [],
  "warnings": [],
  "total_files": 8
}
```

### Exit Codes
- `0` - Success (files copied and substituted)
- `1` - Invalid arguments (bad task-type, missing param, invalid format)
- `2` - Not found (template directory missing, pool file missing)
- `3` - Permission error (can't read templates or write to destination)

## Function Decomposition

### Main Script Flow (~150 lines total)
1. parse_parameters(@ARGV) → %params (~20 lines)
2. find_templates_directory() → $path (~15 lines)
3. validate_task_type($type) (~10 lines)
4. discover_templates($base, $type) → @files (~15 lines)
5. compute_variables(\%params) → %variables (~20 lines)
6. copy_templates(\@templates, $base, $dest, \%vars) → ($created, $overwritten) (~30 lines)
7. output_results(\%params, $created, $overwritten) (~20 lines)

### Key Algorithms

**Slug Extraction**:
```perl
my $basename = basename($params{destination});
# "17-feature-new-helper-script-..." → "new-helper-script-..."
$basename =~ /^\d+-[^-]+-(.+)$/;
my $slug = $1;
```

**Parent Task Computation**:
```perl
my $parent = CIG::TaskPath::get_parent($params{task_num});
my $parent_task = $parent ? $parent : "N/A";
```

**Branch Name Generation**:
```perl
my $pattern = $config->{'branch-naming-convention'};
$pattern =~ s/\{\{task-type\}\}/$params{task_type}/g;
$pattern =~ s/\{\{task-id\}\}/$params{task_num}/g;
$pattern =~ s/\{\{description-slug\}\}/$slug/g;
```

**Atomic File Writing**:
```perl
my $temp_file = "$dest_file.tmp.$$";
open my $fh, '>', $temp_file or die;
print $fh $content;
close $fh;
chmod 0600, $temp_file;
rename $temp_file, $dest_file or do { unlink $temp_file; die; };
```

## Error Handling Strategy

### Input Validation (Exit 1)
- Missing required parameters
- Invalid task-type (not in supported-task-types)
- Invalid task-num format (doesn't match decimal notation)

### Resource Not Found (Exit 2)
- Templates directory not found
- Pool template file not found
- Broken symlink detected

### Permission Errors (Exit 3)
- Cannot read template file
- Cannot write to destination

### Warnings (Non-fatal)
- Overwriting existing file (idempotency warning to STDERR)

## Integration with /cig-new-task

### Current Step 5 (to be replaced)
Inline bash logic (~30-40 lines) that lists symlinks and copies templates

### New Step 5
```bash
.cig/scripts/command-helpers/template-copier.pl \
  --task-type="$TYPE" \
  --destination="$TASK_DIR" \
  --task-num="$NUM" \
  --description="$DESCRIPTION"
```

**Benefits**:
- Removes ~30-40 lines from cig-new-task.md
- Testable independently
- Reusable by /cig-subtask
- Consistent error handling
- JSON output option for scripting

## Constraints

### Technical Constraints
- Must use Perl (for CIG:: modules)
- Must work from any directory (git root detection)
- Must not modify template pool (read-only)
- Must set 0600 permissions on created files
- Must follow 0500 permissions for script itself

### Behavioral Constraints
- Idempotency: overwrite with warning, don't block
- Trust git: no confirmations or complex protection
- Deterministic: same inputs → same outputs
- STDERR for errors, STDOUT for results

## Validation

- [x] Follows existing helper script patterns (manual @ARGV parsing, inline functions)
- [x] Uses CIG:: modules appropriately (TaskPath, WorkflowFiles)
- [x] Error handling matches exit code conventions (0, 1, 2, 3)
- [x] Output formats match existing patterns (markdown/JSON)
- [x] All 7 functional requirements addressable
- [x] All 5 non-functional requirements achievable
- [x] Atomic file writes prevent partial state
- [x] Idempotency behavior defined (warn + overwrite)

## Status
**Status**: Finished
**Next Action**: Implementation phase completed
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
