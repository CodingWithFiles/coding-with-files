# Add Cancelled status to workflow system - Implementation Plan
**Task**: 58 (bugfix)

## Task Reference
- **Task ID**: internal-58
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/58-add-cancelled-status-to-workflow-system
- **Template Version**: 2.1

## Goal
Implement Cancelled status across config, library, aggregators, documentation, and apply to Task 11.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `implementation-guide/cig-project.json` — Add `"Cancelled": 0` to `status-values`
- `.cig/lib/TaskState.pm` — Add Cancelled to `%DEFAULT_STATUS_MAP`, rename `_is_blocked_or_finished` → `_is_terminal`, add Cancelled to terminal check
- `.cig/scripts/command-helpers/status-aggregator-v2.0` — Update warning regex to exempt Cancelled
- `.cig/scripts/command-helpers/status-aggregator-v2.1` — Update warning regex to exempt Cancelled
- `.cig/docs/workflow/workflow-steps.md` — Add Cancelled to Valid Status Values documentation

### Supporting Changes (Task 11 Application)
- `implementation-guide/11-bugfix-only-pass-needed-args-to-scripts/a-plan.md` — Set status to Cancelled
- `implementation-guide/11-bugfix-only-pass-needed-args-to-scripts/c-design.md` — Set status to Cancelled
- `implementation-guide/11-bugfix-only-pass-needed-args-to-scripts/d-implementation.md` — Set status to Cancelled
- `implementation-guide/11-bugfix-only-pass-needed-args-to-scripts/e-testing.md` — Set status to Cancelled
- `implementation-guide/11-bugfix-only-pass-needed-args-to-scripts/h-retrospective.md` — Set status to Cancelled

## Implementation Steps

### Step 1: Config — Add Cancelled to cig-project.json
- [ ] Add `"Cancelled": 0` after `"Finished": 100` in `workflow.status-values`

### Step 2: Library — Update TaskState.pm
- [ ] Add `'Cancelled' => 0` to `%DEFAULT_STATUS_MAP`
- [ ] Rename `_is_blocked_or_finished` → `_is_terminal`
- [ ] Add `$status eq 'Cancelled'` to terminal check
- [ ] Update caller in `state_achievable` to use `_is_terminal`
- [ ] Update POD comment on the renamed function

### Step 3: Aggregators — Update warning regex
- [ ] In `status-aggregator-v2.0` line 101: change regex to `/^(Backlog|To-Do|Cancelled)$/i`
- [ ] In `status-aggregator-v2.1` line 123: change regex to `/^(Backlog|To-Do|Cancelled)$/i`

### Step 4: Documentation — Update workflow-steps.md
- [ ] Add `- **Cancelled** (0%): Task abandoned or superseded; terminal status, no further work expected` to the Valid Status Values list (after Finished, before Skipped)

### Step 5: Apply — Set Task 11 to Cancelled
- [ ] Update status in all 5 Task 11 workflow files to `**Status**: Cancelled`
- [ ] Add `**Cancellation Reason**: Superseded by Task 57 — commands converted to skills, bypassing the $ARGUMENTS parsing bug entirely` below status line in each file

### Step 6: Validate
- [ ] Run `status-aggregator-v2.0 11 --workflow` — expect 0% with no warnings
- [ ] Run `status-aggregator-v2.1 58 --workflow` — expect Task 58 to report correctly
- [ ] Run `status-aggregator-v2.0` — verify no warnings from any task
- [ ] Verify Task 11 shows `- 11 (bugfix): ... - 0%` (not 25%)

## Code Changes

### cig-project.json — Before
```json
"Finished": 100,
"Skipped": null
```

### cig-project.json — After
```json
"Finished": 100,
"Cancelled": 0,
"Skipped": null
```

### TaskState.pm — Before
```perl
sub _is_blocked_or_finished {
    my ($status) = @_;
    return ($status eq 'Blocked' || $status eq 'Finished');
}
```

### TaskState.pm — After
```perl
sub _is_terminal {
    my ($status) = @_;
    return ($status eq 'Blocked' || $status eq 'Finished' || $status eq 'Cancelled');
}
```

### Aggregator warning regex — Before
```perl
$status !~ /^(Backlog|To-Do)$/i
```

### Aggregator warning regex — After
```perl
$status !~ /^(Backlog|To-Do|Cancelled)$/i
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
**Status**: Finished
**Next Action**: /cig-testing-plan 58
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
