# fix nextAction template substitution in template-copier - Design
**Task**: 48 (bugfix)

## Task Reference
- **Task ID**: internal-48
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/48-fix-nextaction-template-substitution-in-template-copier
- **Template Version**: 2.1

## Goal
Design filename-to-command transformation algorithm that derives nextAction from template symlink filenames, eliminating hardcoded mapping and establishing directory structure as single source of truth.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice
- **Decision**: Derive command name from template filename using string transformation (regex-based)
- **Rationale**:
  - Establishes **single source of truth**: Directory structure (symlinks) defines workflow sequence AND command names
  - Eliminates **hardcoded mapping** (`%PHASE_COMMANDS`) that can drift from actual filenames
  - Automatic adaptation: If template files are renamed, commands automatically adapt
  - No manual synchronization needed between filenames and command routing
- **Trade-offs**:
  - **Benefit**: Zero maintenance cost, self-consistent system, no drift possible
  - **Benefit**: Simpler code (remove 12-line mapping, replace with 3-line transformation)
  - **Drawback**: Depends on stable filename convention (phase-letter prefix + name + .md.template)
  - **Drawback**: Less explicit than hardcoded mapping (transformation algorithm not immediately obvious)

### Algorithm Design
- **Input**: Next template filename from `get_phase_sequence()` (e.g., "b-requirements-plan.md.template")
- **Transformation Steps**:
  1. Strip phase prefix: `s/^[a-j]-//` → "requirements-plan.md.template"
  2. Strip extension: `s/\.md\.template$//` → "requirements-plan"
  3. Prepend command prefix: `"/cig-" . $filename` → "/cig-requirements-plan"
- **Output**: CIG command string (e.g., "/cig-requirements-plan")

## System Design
### Component Overview
- **`get_phase_sequence()`** (lines 219-240, **no changes needed**):
  - Purpose: Read symlinks from `.cig/templates/{task_type}/` directory
  - Responsibility: Return sorted array of phase letters (e.g., ["a", "c", "d", "e", "f", "g", "j"] for bugfix)
  - Already works correctly, provides single source of truth

- **`compute_next_action()`** (lines 256-290, **needs modification**):
  - Purpose: Calculate next command from current phase and task type
  - Current responsibility: Map phase letter → command using hardcoded `%PHASE_COMMANDS`
  - New responsibility: Transform next template filename → command string
  - Changes: Remove `%PHASE_COMMANDS` lookup, add filename transformation logic

- **`copy_templates()`** (lines 347-423, **no changes needed**):
  - Purpose: Copy templates and substitute variables
  - Responsibility: Call `compute_next_action()` for each template, substitute `{{nextAction}}`
  - Already calls `compute_next_action()` correctly at line 383

### Data Flow
1. **Template discovery**: `get_phase_sequence($templates_dir, $task_type)` → returns array of phase letters
2. **Current phase identification**: Extract phase letter from template filename (e.g., "g-testing-exec.md.template" → "g")
3. **Find next phase**: Look up current phase index in sequence, get next element (e.g., "g" at index 5 → next is "j" at index 6)
4. **Get next filename**: Use `discover_templates()` to map phase letter back to full filename (e.g., "j" → "j-retrospective.md.template")
5. **Transform to command**: Apply regex transformations (strip prefix, strip extension, prepend /cig-)
6. **Substitute**: Set `$template_vars{nextAction}` and substitute into template content

## Interface Design
### Function Signature (Modified)
```perl
sub compute_next_action {
    my ($templates_dir, $task_type, $template_file) = @_;

    # Extract current phase from template_file (e.g., "g-testing-exec.md.template" → "g")
    my ($phase) = $template_file =~ /^([a-j])-/;
    return "Begin next phase" unless $phase;

    # Get workflow sequence for this task type
    my @sequence = get_phase_sequence($templates_dir, $task_type);
    return "Unknown task type" unless @sequence;

    # Find current phase index
    my $current_idx;
    for my $i (0..$#sequence) {
        if ($sequence[$i] eq $phase) {
            $current_idx = $i;
            last;
        }
    }
    return "Unknown phase" unless defined $current_idx;

    # Check if last phase (no next action)
    if ($current_idx >= $#sequence) {
        return "Task complete";
    }

    # Get next phase letter and discover its template filename
    my $next_phase = $sequence[$current_idx + 1];
    my @templates = discover_templates($templates_dir, $task_type);

    # Find template matching next phase
    my $next_file;
    for my $t (@templates) {
        if ($t->{name} =~ /^$next_phase-/) {
            $next_file = $t->{name};
            last;
        }
    }
    return "Next phase template not found" unless $next_file;

    # Transform filename to command
    my $command_name = $next_file;
    $command_name =~ s/^[a-j]-//;              # Remove phase prefix
    $command_name =~ s/\.md\.template$//;      # Remove extension
    my $command = "/cig-" . $command_name;     # Prepend /cig-

    return $command;
}
```

### Edge Cases
1. **Last phase (j-retrospective.md)**:
   - `$current_idx >= $#sequence` → return "Task complete"
   - No next phase exists, retrospective is final step

2. **Invalid phase letter**:
   - `$template_file` doesn't match `/^([a-j])-/` → return "Begin next phase"
   - Defensive: shouldn't happen with valid templates

3. **Next phase template not found**:
   - Phase letter in sequence but no matching template file → return error
   - Defensive: indicates broken symlink or corrupt template directory

4. **Missing task type directory**:
   - `get_phase_sequence()` returns empty array → return "Unknown task type"
   - Already handled by existing function

## Constraints
### Technical Constraints
- **Filename convention stability**: Algorithm depends on phase-letter prefix format (e.g., "a-task-plan.md.template")
  - If filenames change format, transformation regex must be updated
  - Convention documented in `.cig/templates/pool/` structure
- **Backward compatibility**: Must not break existing template copying functionality
  - All other template variables (`{{description}}`, `{{taskId}}`, etc.) must still work
  - Function signature unchanged (`compute_next_action($templates_dir, $task_type, $template_file)`)

### Design Constraints
- **Single source of truth**: Directory structure must remain authoritative for workflow sequences
  - No fallback to hardcoded mapping if transformation fails
  - Clear error messages if filename doesn't match expected pattern
- **Simplicity over cleverness**: Use straightforward regex, avoid complex parsing
  - Prefer explicit transformations (`s/^[a-j]-//`) over general-purpose parsers

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - Single function modification, estimated 2-3 hours
- [ ] **People**: Does this need >2 people working on different parts? **NO** - Single developer, single function
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **NO** - Single concern: filename transformation
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** - Testable change, reversible
- [ ] **Independence**: Can parts be worked on separately? **NO** - Atomic modification

**Decision**: No decomposition needed (0/5 signals triggered)

## Validation
- [x] Design review completed - Algorithm verified with user (single source of truth principle)
- [x] Architecture approved - Filename transformation approach confirmed
- [x] Integration points verified - `get_phase_sequence()` provides input, `copy_templates()` consumes output
- [ ] Edge cases documented - Last phase, invalid filenames, missing templates
- [ ] Regex patterns validated - Tested against actual template filenames

## Status
**Status**: Finished
**Next Action**: /cig-implementation-plan 48 (bugfix workflow: design → implementation-plan → implementation-exec)
**Blockers**: Task 47 should be merged before implementation begins

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
