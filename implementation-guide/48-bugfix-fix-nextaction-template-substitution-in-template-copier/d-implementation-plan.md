# fix nextAction template substitution in template-copier - Implementation Plan
**Task**: 48 (bugfix)

## Task Reference
- **Task ID**: internal-48
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/48-fix-nextaction-template-substitution-in-template-copier
- **Template Version**: 2.1

## Goal
Modify `compute_next_action()` in template-copier-v2.1 to derive command names from template filenames instead of hardcoded mapping, establishing directory structure as single source of truth.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cig/scripts/command-helpers/template-copier-v2.1` (lines 243-290):
  - **Remove**: Hardcoded `%PHASE_COMMANDS` mapping hash (lines 243-254)
  - **Modify**: `compute_next_action()` function (lines 256-290) to transform filename → command
  - **Add**: Template filename discovery logic (call `discover_templates()` to get next filename)
  - **Add**: Regex transformation logic (strip phase prefix, strip extension, prepend /cig-)

### Supporting Changes
- None - This is a pure bugfix to existing script, no configuration or documentation changes needed

## Implementation Steps

### Step 1: Pre-Implementation Verification
- [ ] Read template-copier-v2.1 lines 243-290 to understand current implementation
- [ ] Verify `%PHASE_COMMANDS` hash location (lines 243-254)
- [ ] Verify `compute_next_action()` function signature and current logic
- [ ] Verify `discover_templates()` function is available for reuse

### Step 2: Remove Hardcoded Mapping
- [ ] Delete `%PHASE_COMMANDS` hash (lines 243-254, 12 lines total)
- [ ] Remove any references to `$PHASE_COMMANDS{$next_phase}` in `compute_next_action()`

### Step 3: Implement Filename Discovery
- [ ] After finding `$next_phase` letter, call `discover_templates($templates_dir, $task_type)` to get template list
- [ ] Loop through templates to find one matching `$next_phase` (pattern: `/^$next_phase-/`)
- [ ] Store matching template's `{name}` field as `$next_file`
- [ ] Add error handling: Return "Next phase template not found" if no match

### Step 4: Implement Filename Transformation
- [ ] Copy `$next_file` to `$command_name` variable
- [ ] Apply regex 1: `$command_name =~ s/^[a-j]-//;` (strip phase prefix)
- [ ] Apply regex 2: `$command_name =~ s/\.md\.template$//;` (strip extension)
- [ ] Build command: `my $command = "/cig-" . $command_name;`
- [ ] Return `$command`

### Step 5: Verify Edge Cases
- [ ] Test last phase handling: `if ($current_idx >= $#sequence)` returns "Task complete"
- [ ] Test invalid phase: `unless $phase` returns "Begin next phase"
- [ ] Test missing next file: `unless $next_file` returns error message
- [ ] Verify all error paths have clear messages

### Step 6: Manual Validation
- [ ] Create test task: `task-workflow create --task-type=bugfix --destination=/tmp/test-48 --task-num=99 --description="test"`
- [ ] Verify g-testing-exec.md contains "Next Action: /cig-retrospective" (NOT "/cig-rollout")
- [ ] Verify all template variables still substitute correctly
- [ ] Verify file permissions still set to 0600
- [ ] Delete test directory after validation

## Code Changes

### Before (Lines 243-290)
```perl
# Phase-to-command mapping
my %PHASE_COMMANDS = (
    'a' => '/cig-requirements-plan',
    'b' => '/cig-design-plan',
    'c' => '/cig-implementation-plan',
    'd' => '/cig-testing-plan',
    'e' => '/cig-implementation-exec',
    'f' => '/cig-testing-exec',
    'g' => '/cig-rollout',
    'h' => '/cig-maintenance',
    'i' => '/cig-retrospective',
    'j' => undef,  # Task complete
);

# Compute next action based on current phase and task type
sub compute_next_action {
    my ($templates_dir, $task_type, $template_file) = @_;

    # Extract phase letter from template filename
    my ($phase) = $template_file =~ /^([a-j])-/;
    return "Begin next phase" unless $phase;

    # Get sequence for this task type
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

    # If last phase, return retrospective
    if ($current_idx >= $#sequence) {
        return "Task complete → /cig-retrospective";
    }

    # Get next phase and map to command
    my $next_phase = $sequence[$current_idx + 1];
    my $command = $PHASE_COMMANDS{$next_phase};  # HARDCODED LOOKUP

    return $command if $command;
    return "Unknown next phase";
}
```

### After (Lines 243-276, ~14 lines shorter)
```perl
# Compute next action based on current phase and task type
sub compute_next_action {
    my ($templates_dir, $task_type, $template_file) = @_;

    # Extract phase letter from template filename
    my ($phase) = $template_file =~ /^([a-j])-/;
    return "Begin next phase" unless $phase;

    # Get sequence for this task type
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

    # If last phase, return completion message
    if ($current_idx >= $#sequence) {
        return "Task complete";
    }

    # Get next phase letter
    my $next_phase = $sequence[$current_idx + 1];

    # Discover template filename for next phase
    my @templates = discover_templates($templates_dir, $task_type);
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

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

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
**Next Action**: /cig-testing-plan 48 (bugfix workflow: implementation-plan → testing-plan → implementation-exec)
**Blockers**: Task 47 should be merged before implementation execution begins

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
