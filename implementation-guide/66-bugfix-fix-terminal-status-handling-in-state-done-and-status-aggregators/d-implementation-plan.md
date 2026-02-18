# Fix terminal status handling in state_done and status aggregators - Implementation Plan
**Task**: 66 (bugfix)

## Task Reference
- **Task ID**: internal-66
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/66-fix-terminal-status-handling-in-state-done-and-status-aggregators
- **Template Version**: 2.1

## Goal
Implement the approved design: introduce `_is_closed`, fix `state_done` MIN calculation, remove dead code from `state_achievable`, update both aggregator warning regexes, and update script hashes.

## Workflow
Patterns first → Minimal impl → Validate → Commit explains "why"

## Files to Modify

### Primary Changes
- `.cwf/lib/CWF/TaskState.pm` — 4 edits

### Supporting Changes
- `.cwf/scripts/command-helpers/status-aggregator-v2.0` — 1 line
- `.cwf/scripts/command-helpers/status-aggregator-v2.1` — 1 line
- `.cwf/security/script-hashes.json` — 3 hash updates

## Implementation Steps

### Step 1: Edit `CWF::TaskState.pm`

**1a. Add `Skipped => 100` to `%DEFAULT_STATUS_MAP`**

```perl
# Before
my %DEFAULT_STATUS_MAP = (
    'Finished'    => 100,
    'Testing'     => 75,
    ...
    'Cancelled'   => 0,
);

# After
my %DEFAULT_STATUS_MAP = (
    'Finished'    => 100,
    'Skipped'     => 100,
    'Testing'     => 75,
    ...
    'Cancelled'   => 0,
);
```

**1b. Replace `_is_terminal` with `_is_closed`**

```perl
# Remove entirely:
sub _is_terminal {
    my ($status) = @_;
    return ($status eq 'Blocked' || $status eq 'Finished' || $status eq 'Cancelled');
}

# Add in its place:
# Returns true for states that are intentionally ended (not a progress bottleneck)
sub _is_closed {
    my ($status) = @_;
    return ($status eq 'Finished' || $status eq 'Cancelled' || $status eq 'Skipped');
}
```

**1c. Fix `state_done` MIN calculation**

```perl
# Before
my @percentages = grep defined, map { status_percent($_) } @statuses;

# After
my @percentages = grep defined, map { _is_closed($_) ? 100 : status_percent($_) } @statuses;
```

**1d. Remove dead code from `state_achievable`**

Remove the `$blocked_count`, `$is_workable` lines and the `!$is_workable` branch:

```perl
# Before
my $blocked_count = grep { _is_terminal($_) } @statuses;
my $active_count = grep { _is_active_work($_) } @statuses;
my $total_count = scalar(@statuses);

my $is_workable = ($blocked_count < $total_count);

# Step 3: Cliff function
my $work_potential;

if ($completion >= 100) {
    # CLIFF: Complete, no work left
    $work_potential = 0;
} elsif (!$is_workable) {
    # BLOCKED: All steps blocked/finished, can't progress
    $work_potential = 0;
} elsif ($completion == 0 && $active_count == 0) {
    ...

# After
my $active_count = grep { _is_active_work($_) } @statuses;

# Step 3: Cliff function
my $work_potential;

if ($completion >= 100) {
    # CLIFF: Complete, no work left
    $work_potential = 0;
} elsif ($completion == 0 && $active_count == 0) {
    ...
```

Also update the pod comment on `state_achievable` to remove the reference to `_is_terminal` and the BLOCKED rule.

### Step 2: Edit `status-aggregator-v2.0`

Add `Skipped` to warning exclusion regex:

```perl
# Before
if ($pct == 0 && $status ne "Unknown" && $status !~ /^(Backlog|To-Do|Cancelled)$/i) {

# After
if ($pct == 0 && $status ne "Unknown" && $status !~ /^(Backlog|To-Do|Cancelled|Skipped)$/i) {
```

### Step 3: Edit `status-aggregator-v2.1`

Same change:

```perl
# Before
if (defined($pct) && $pct == 0 && $status ne "Unknown" && $status !~ /^(Backlog|To-Do|Cancelled)$/i) {

# After
if (defined($pct) && $pct == 0 && $status ne "Unknown" && $status !~ /^(Backlog|To-Do|Cancelled|Skipped)$/i) {
```

### Step 4: Update `script-hashes.json`

Regenerate SHA256 for all 3 modified files and update entries:

```bash
sha256sum .cwf/lib/CWF/TaskState.pm
sha256sum .cwf/scripts/command-helpers/status-aggregator-v2.0
sha256sum .cwf/scripts/command-helpers/status-aggregator-v2.1
```

Update the three entries in `.cwf/security/script-hashes.json` and set `last_updated` to today.

### Step 5: Verify

- [ ] `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` exits 0
- [ ] `perlcritic --stern .cwf/lib/CWF/TaskState.pm` passes
- [ ] `status-aggregator-v2.1` shows task 11 at 100%
- [ ] `status-aggregator-v2.1` active tasks unchanged

## Validation Criteria

- Task 11 (all Cancelled, v2.0 format) shows 100%
- A task with all Skipped files shows 100%
- A task with mix of Finished + Cancelled + Skipped shows 100%
- A task with Finished + In Progress still scores at In Progress level (25%)
- All-Blocked task scores non-zero (DORMANT ≈ 4) via `state_achievable`
- `cwf-manage validate` exits 0

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 66
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
