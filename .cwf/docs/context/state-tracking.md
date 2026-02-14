# Task Context Tracking

Signal-based inference system that identifies current task and workflow step from multiple environmental signals without explicit state management.

## Quick Reference - Output Formats

### Conclusive (Exit 0)
All signals agree on current task:
```
current: conclusive
confidence: correlated
task_num: 37
task_slug: fix-inconclusive-inference-output-format
workflow_step: g-testing-exec
```

### Inconclusive - Uncorrelated Signals (Exit 1)
Signals disagree:
```
current: inconclusive
confidence: uncorrelated
task_nums: 14,32,37
task_slugs: retro-suggest-updating,task-tracking-inference,fix-inconclusive-output
workflow_steps: j-retrospective,j-retrospective,g-testing-exec
candidates: 3
reasons: branch_signal,recency_signal,progress_signal
```

### Inconclusive - No Signals (Exit 3)
No signals detected:
```
current: inconclusive
confidence: no_signals
task_nums: unknown
task_slugs: unknown
workflow_steps: unknown
candidates: 0
reasons: none
```

## Signal Overview

### Task Inference Signals

| Signal | Purpose | Weight | Example |
|--------|---------|--------|---------|
| **branch** | Current git branch name | 100 | `bugfix/37-fix-output` → task 37 |
| **worktree** | Working directory path | 95 | `~/cwf-task-37/` → task 37 |
| **state** | Explicit state file | 85 | `.cwf/current-task` = "37" |
| **recency** | Recently modified files | 0-90 | Task 37 modified 5min ago = 85pts |
| **progress** | Work potential (cliff function) | 0-60 | 75% complete = 45pts (strong finish) |

**Note**: Workflow Status signal removed (Task 32) - low quality, heavily correlated with Progress, caused false negatives.

### Workflow Step Inference Signals

| Signal | Purpose | Weight | Example |
|--------|---------|--------|---------|
| **step_status** | Current step status marker | 100 | `d-implementation.md` status="In Progress" |
| **step_recency** | Most recently modified file | 0-90 | `e-testing.md` edited 2min ago = 88pts |
| **workflow_order** | Sequential step progression | 70 | a,d,e Finished → f next |
| **command_context** | Command invoked | 80 | `/cwf-testing` → e-testing-plan |

## Correlation Logic

**Correlated**: All non-null task signals agree on top task → conclusive
- Example: branch=37, recency=37, progress=37 → Task 37 (Exit 0)
- Output: Singular fields (task_num, task_slug, workflow_step)

**Uncorrelated**: Task signals disagree → inconclusive
- Example: branch=37, recency=32, progress=14 → Multiple candidates (Exit 1)
- Output: Plural fields (task_nums, task_slugs, workflow_steps, reasons)

**No Signals**: All task signals null/unavailable → inconclusive
- Example: On main branch, no recent work, empty state → Unknown (Exit 3)
- Output: "unknown" values

## Exit Codes

| Code | Meaning | Confidence | Output Format |
|------|---------|------------|---------------|
| 0 | Conclusive | correlated | Singular fields (task_num, task_slug, workflow_step) |
| 1 | Inconclusive | uncorrelated | Plural fields (task_nums, task_slugs, workflow_steps, reasons) |
| 3 | Inconclusive | no_signals | "unknown" values |

## Signal Details

### Progress Signal (Cliff Function)

Task progress calculation uses **work potential** (not completion percentage):
- **0-100% complete** → Linear ramp: Higher completion = higher desire to finish
- **100% complete** → Cliff to 0: No work remaining
- **Blocked tasks** → 0: Cannot progress

**Formula**:
```
if complete >= 100: work_potential = 0  # Cliff
elsif blocked: work_potential = 0       # Can't progress
elsif active: work_potential = completion_pct  # Linear ramp
else: work_potential = 10               # Fresh task baseline
```

**Examples**:
- Task 75% complete → 75% work potential → 45pts (strong momentum!)
- Task 100% complete → 0% work potential → 0pts (cliff drop)
- Task blocked → 0% work potential → 0pts (can't work)

### Recency Signal (Exponential Decay)

File modification times with exponential decay:
- 0-5 min ago → 90pts
- 5-15 min ago → 85pts
- 15-30 min ago → 70pts
- 30-60 min ago → 50pts
- 1-2 hours ago → 30pts
- >2 hours ago → 10pts

## Field Definitions

### Common Fields (all scenarios)
- `current`: "conclusive" | "inconclusive" - Can inference determine single task?
- `confidence`: "correlated" | "uncorrelated" | "no_signals" - Internal correlation status
- `candidates`: integer - Number of candidate tasks (0, 1, or N)

### Conclusive Fields (current=conclusive)
- `task_num`: single integer - The determined task number
- `task_slug`: single string - The task slug
- `workflow_step`: single string - The inferred workflow step

### Inconclusive Fields (current=inconclusive)
- `task_nums`: comma-separated integers or "unknown" - Candidate task numbers
- `task_slugs`: comma-separated strings or "unknown" - Candidate task slugs
- `workflow_steps`: comma-separated strings or "unknown" - Candidate workflow steps
- `reasons`: comma-separated signal names - Which signals contributed candidates

## Parsing Output

**Simple regex** (all formats):
```perl
/^(\w+): (.+)$/m
```

**Comma-separated values** (plural fields):
```perl
my @nums = split /,/, $task_nums;
my @slugs = split /,/, $task_slugs;
```

**Version detection** (backward compatibility):
```perl
if ($output =~ /^current:/m) {
    # v2 format (structured)
} else {
    # v1 format (conclusive only)
}
```

## Implementation

**Module**: `.cwf/lib/TaskContextInference.pm`
- `infer_task_context()` - Main entry point, returns context hash
- `get_all_signals()` - Collects all task inference signals
- `correlate_signals()` - Determines correlation status
- `format_output()` - Formats structured output for all scenarios

**Wrapper**: `.cwf/scripts/command-helpers/task-context-inference`
- Calls TaskContextInference.pm module
- Sets exit code based on confidence (0/1/3)
- Outputs formatted result to stdout

**Skills**: `/current-task-wf` - Invokes task context inference

## References

- **Task 32**: Initial implementation of signal-based inference system
- **Task 37**: Added structured output format for all scenarios (conclusive, inconclusive, no_signals)
- **Design docs**: `.cwf/docs/design/` (detailed signal specifications, scoring algorithms)
