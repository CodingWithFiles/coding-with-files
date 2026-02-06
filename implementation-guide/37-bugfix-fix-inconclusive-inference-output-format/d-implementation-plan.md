# fix inconclusive inference output format - Implementation

## Task Reference
- **Task ID**: internal-37
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/37-fix-inconclusive-inference-output-format
- **Template Version**: 2.1

## Goal
Implement fix inconclusive inference output format following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cig/lib/TaskContextInference.pm` - Update `format_output()` to handle all scenarios (conclusive, inconclusive, no_signals)
- `.cig/lib/TaskContextInference.pm` - Replace `_format_uncorrelated()` with structured format generation
- `.cig/lib/TaskContextInference.pm` - Update `infer_task_context()` to populate plural fields for inconclusive cases

### Supporting Changes
- `implementation-guide/32-feature-add-task-tracking-inference-system/e-testing-plan.md` - Update test expectations for TC-I2, TC-I3, TC-I4 (inconclusive scenarios)
- `.cig/docs/context/state-tracking.md` - Update documentation with new output format specification

## Implementation Steps
### Step 1: Setup
- [ ] Create task branch: `bugfix/37-fix-inconclusive-inference-output-format`
- [ ] Review design document (c-design-plan.md) and output format specification
- [ ] Read current `format_output()` and `_format_uncorrelated()` implementations

### Step 2: Update Context Hash Structure
- [ ] Modify `infer_task_context()` to populate plural fields for inconclusive cases
- [ ] Add `task_nums` array field (when uncorrelated or no_signals)
- [ ] Add `task_slugs` array field (when uncorrelated or no_signals)
- [ ] Add `workflow_steps` array field (when uncorrelated or no_signals)
- [ ] Add `reasons` array field showing which signals contributed candidates
- [ ] Ensure singular fields (task_num, task_slug, workflow_step) still populated when correlated

### Step 3: Refactor format_output() Function
- [ ] Add conditional logic based on `$context->{current}` field
- [ ] Handle conclusive case: format singular fields (task_num, task_slug, workflow_step)
- [ ] Handle inconclusive case: format plural fields (task_nums, task_slugs, workflow_steps, reasons)
- [ ] Join array values with comma separator for plural fields
- [ ] Add `candidates` field showing count of candidate tasks
- [ ] Add `confidence` field (correlated, uncorrelated, no_signals)
- [ ] Maintain backward compatibility by always including `current` field

### Step 4: Replace _format_uncorrelated() Function
- [ ] Remove prose generation logic from `_format_uncorrelated()`
- [ ] Replace with call to unified `format_output()` function
- [ ] Remove or update `_format_verbose_breakdown()` if affected
- [ ] Ensure exit codes remain unchanged (wrapper script handles this)

### Step 5: Handle No Signals Case
- [ ] Update `_format_no_signals()` (if exists) or add handling to `format_output()`
- [ ] Set plural fields to "unknown" when no signals available
- [ ] Set `candidates` to 0, `reasons` to "none"
- [ ] Maintain structured format (no prose fallback)

### Step 6: Update Tests
- [ ] Update TC-I2 expectations (two conflicting signals - branch vs recency)
- [ ] Update TC-I3 expectations (all three signals disagree)
- [ ] Update TC-I4 expectations (no signals available)
- [ ] Verify tests check for structured format, not prose
- [ ] Add regex or field extraction tests to verify parseability

### Step 7: Update Documentation
- [ ] Update `.cig/docs/context/state-tracking.md` with complete format specification
- [ ] Document conclusive, inconclusive, and no_signals output formats
- [ ] Document field definitions (current, confidence, candidates, reasons)
- [ ] Add examples showing how commands can parse output
- [ ] Document backward compatibility (check for `current` field)

### Step 8: Validation
- [ ] Run Task 32 test suite to verify no regressions in conclusive cases
- [ ] Manually test inconclusive scenario with conflicting signals
- [ ] Manually test no_signals scenario in empty repository
- [ ] Verify exit codes unchanged (0=conclusive, 1=uncorrelated, 3=no_signals)
- [ ] Verify skills can parse output programmatically

## Code Changes

### Change 1: format_output() Function

#### Before (lines 145-160 in TaskContextInference.pm)
```perl
sub format_output {
    my ($context, $verbose) = @_;

    my $output = sprintf(
        "task_num: %s\ntask_slug: %s\nworkflow_step: %s\n",
        $context->{task_num},
        $context->{task_slug},
        $context->{workflow_step}
    );

    if ($verbose) {
        $output .= "\n" . _format_verbose_breakdown($context);
    }

    return $output;
}
```

#### After
```perl
sub format_output {
    my ($context, $verbose) = @_;

    my $output = sprintf("current: %s\nconfidence: %s\n",
        $context->{current},
        $context->{confidence}
    );

    if ($context->{current} eq 'conclusive') {
        # Singular fields for conclusive
        $output .= sprintf(
            "task_num: %s\ntask_slug: %s\nworkflow_step: %s\n",
            $context->{task_num},
            $context->{task_slug},
            $context->{workflow_step}
        );
    } else {
        # Plural fields for inconclusive
        my $task_nums = join(',', @{$context->{task_nums} || ['unknown']});
        my $task_slugs = join(',', @{$context->{task_slugs} || ['unknown']});
        my $workflow_steps = join(',', @{$context->{workflow_steps} || ['unknown']});
        my $reasons = join(',', @{$context->{reasons} || ['none']});

        $output .= sprintf(
            "task_nums: %s\ntask_slugs: %s\nworkflow_steps: %s\ncandidates: %d\nreasons: %s\n",
            $task_nums,
            $task_slugs,
            $workflow_steps,
            $context->{candidates} || 0,
            $reasons
        );
    }

    if ($verbose) {
        $output .= "\n" . _format_verbose_breakdown($context);
    }

    return $output;
}
```

### Change 2: _format_uncorrelated() Function

#### Before (lines 609-627 in TaskContextInference.pm)
```perl
sub _format_uncorrelated {
    my ($correlation, $verbose) = @_;

    my @candidates = @{$correlation->{candidates}};

    my $output = "Signals disagree on current task.\n\n";
    $output .= "Top candidates:\n";
    for my $task (@candidates) {
        $output .= "  - Task $task\n";
    }
    $output .= "\nPlease specify task number explicitly or clarify context.\n";

    if ($verbose) {
        $output .= "\n" . _format_signal_details($correlation->{signals});
    }

    return $output;
}
```

#### After
```perl
sub _format_uncorrelated {
    my ($correlation, $verbose) = @_;

    # Unified format - delegate to format_output()
    return format_output($correlation, $verbose);
}
```

### Change 3: Context Hash Population (in infer_task_context())

#### Before (conceptual - returns only correlated fields)
```perl
return {
    confidence => 'correlated',
    current => 'conclusive',
    task_num => $task_num,
    task_slug => $task_slug,
    workflow_step => $workflow_step,
};
```

#### After (adds plural fields for uncorrelated)
```perl
# For correlated
return {
    confidence => 'correlated',
    current => 'conclusive',
    candidates => 1,
    task_num => $task_num,
    task_slug => $task_slug,
    workflow_step => $workflow_step,
};

# For uncorrelated
return {
    confidence => 'uncorrelated',
    current => 'inconclusive',
    candidates => scalar(@candidate_tasks),
    task_nums => \@task_nums,
    task_slugs => \@task_slugs,
    workflow_steps => \@workflow_steps,
    reasons => \@contributing_signals,
};

# For no_signals
return {
    confidence => 'no_signals',
    current => 'inconclusive',
    candidates => 0,
    task_nums => ['unknown'],
    task_slugs => ['unknown'],
    workflow_steps => ['unknown'],
    reasons => ['none'],
};
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

### Key Test Cases to Update
- **TC-I2**: Two conflicting signals (branch vs recency)
  - Expected output: Structured format with `task_nums: X,Y`, `reasons: branch_signal,recency_signal`
- **TC-I3**: All three signals disagree
  - Expected output: Structured format with `task_nums: X,Y,Z`, `reasons: branch_signal,recency_signal,progress_signal`
- **TC-I4**: No signals available
  - Expected output: Structured format with `task_nums: unknown`, `reasons: none`

### Regression Tests
- **TC-C1**: Conclusive case (all signals agree)
  - Verify: Still outputs singular fields (task_num, task_slug, workflow_step)
  - Verify: Includes new `current: conclusive` and `confidence: correlated` fields
  - Verify: Exit code remains 0

### Parseability Tests
- Verify output can be parsed with simple regex: `/^(\w+): (.+)$/`
- Verify plural fields can be split on comma: `split(/,/, $value)`
- Verify no nested structures or JSON required

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

### Implementation Complete When:
- [ ] All TC-I2, TC-I3, TC-I4 tests pass with structured output
- [ ] All TC-C1 tests pass (no regression in conclusive case)
- [ ] Exit codes unchanged (0=conclusive, 1=uncorrelated, 3=no_signals)
- [ ] Output is parseable with simple string operations (no JSON parser required)
- [ ] Documentation updated with format specification and examples
- [ ] Commands/skills can programmatically extract task numbers from inconclusive output

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will implementation take >1 week? **No** - 4-6 hours estimated for bugfix
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **No** - 2 concerns (output format, test updates)
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - medium risk, good test coverage from Task 32
- [ ] **Independence**: Can parts be worked on separately? **No** - tightly coupled (format changes require test updates)

**Analysis**: 0/5 signals triggered. Implementation is appropriately scoped as single bugfix task with 8 sequential steps.

## Status
**Status**: Finished
**Next Action**: Move to testing planning → `/cig-testing-plan 37`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
