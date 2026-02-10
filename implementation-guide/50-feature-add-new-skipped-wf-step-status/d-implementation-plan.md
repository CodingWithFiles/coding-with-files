# add-new-skipped-wf-step-status - Implementation Plan
**Task**: 50 (feature)

## Task Reference
- **Task ID**: internal-50
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/50-add-new-skipped-wf-step-status
- **Template Version**: 2.1

## Goal
Implement "Skipped" status with null-value sentinel pattern and filter-based exclusion for v2.1 format only.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes

**1. `implementation-guide/cig-project.json`** - Configuration schema
- Add `"Skipped": null` to workflow.status-values object
- Preserves existing status values (Backlog through Finished)
- JSON null value signals exclusion from progress calculation

**2. `.cig/lib/TaskState.pm`** - Status mapping module
- Modify `status_percent()`: Return undef when config value is null
- Modify `state_done()`: Filter undefined values before MIN calculation
- No changes to status_extract() or other functions

**3. `.cig/scripts/command-helpers/status-aggregator-v2.1`** - Display script
- Modify workflow display logic: Show "Skipped (N/A)" instead of percentage
- Check if status string equals "Skipped" for special formatting
- No changes to progress calculation (delegated to TaskState.pm)

**4. `.cig/docs/workflow/workflow-steps.md`** - Documentation
- Add "Skipped" to Status Values section with null percentage
- Add usage guidance: when to use "Skipped" status
- Provide examples: Maintenance for bugfixes, Requirements for hotfixes, etc.
- Note v2.1 requirement

### Supporting Changes

**5. `.cig/security/script-hashes.json`** - Security verification
- Update SHA256 hash for `.cig/lib/TaskState.pm`
- Update SHA256 hash for `.cig/scripts/command-helpers/status-aggregator-v2.1`
- No change to status-aggregator-v2.0 (unchanged)

## Implementation Steps

### Step 1: Configuration Update
- [ ] **1.1**: Open `implementation-guide/cig-project.json`
- [ ] **1.2**: Add `"Skipped": null` to workflow.status-values object (after "Finished")
- [ ] **1.3**: Verify JSON syntax: `jq . implementation-guide/cig-project.json`
- [ ] **1.4**: Verify null value: `jq '.workflow["status-values"]["Skipped"]' implementation-guide/cig-project.json` returns `null`

### Step 2: Status Mapping Module (TaskState.pm)
- [ ] **2.1**: Open `.cig/lib/TaskState.pm`
- [ ] **2.2**: Locate `status_percent()` function (line ~181)
- [ ] **2.3**: Verify existing return behavior: returns value from config map or 0 for unknown
- [ ] **2.4**: No code change needed (already returns config value directly, null becomes undef in Perl)
- [ ] **2.5**: Locate `state_done()` function (line ~91)
- [ ] **2.6**: Modify line 97: Add `grep defined` filter before MAP operation (idiomatic form)
  - Before: `my @percentages = map { status_percent($_) } @statuses;`
  - After: `my @percentages = grep defined, map { status_percent($_) } @statuses;`
- [ ] **2.7**: Verify filter preserves array context

### Step 3: Display Logic (status-aggregator-v2.1)
- [ ] **3.1**: Open `.cig/scripts/command-helpers/status-aggregator-v2.1`
- [ ] **3.2**: Locate workflow display logic (line ~419-425, inside for loop)
- [ ] **3.3**: Find where status and percentage are formatted for display
- [ ] **3.4**: Add ternary conditional for suffix: `(N/A)` for "Skipped", `(%d%%)` for others (idiomatic)
  - Pattern: `my $suffix = $status eq "Skipped" ? "(N/A)" : sprintf("(%d%%)", $percent);`
  - Then single printf with $suffix
- [ ] **3.5**: Ensure display distinguishes "Skipped (N/A)" from "Backlog (0%)"

### Step 4: Documentation Update
- [ ] **4.1**: Open `.cig/docs/workflow/workflow-steps.md`
- [ ] **4.2**: Locate Status Values section (line ~35-46)
- [ ] **4.3**: Add "Skipped" status entry:
  - `- **Skipped** (N/A): Phase not applicable to this specific task (may also apply to entire task type) (v2.1 only)`
- [ ] **4.4**: Add usage guidance after status values list:
  - When to use: any workflow step not applicable
  - Examples: Maintenance for bugfixes, Rollout for internal tools, Requirements for hotfixes
  - Clarify: "Skipped" (not applicable) vs "Backlog" (not started) vs "Finished" (completed)
- [ ] **4.5**: Note v2.1 requirement prominently

### Step 5: Security Hash Update
- [ ] **5.1**: Calculate new hash for TaskState.pm: `shasum -a 256 .cig/lib/TaskState.pm`
- [ ] **5.2**: Calculate new hash for status-aggregator-v2.1: `shasum -a 256 .cig/scripts/command-helpers/status-aggregator-v2.1`
- [ ] **5.3**: Open `.cig/security/script-hashes.json`
- [ ] **5.4**: Update TaskState.pm hash entry
- [ ] **5.5**: Update status-aggregator-v2.1 hash entry
- [ ] **5.6**: Verify: `/cig-security-check verify` should pass

### Step 6: Integration Testing
- [ ] **6.1**: Test with existing v2.1 task without "Skipped" (verify no regression)
- [ ] **6.2**: Test with v2.1 task with 1 phase marked "Skipped" (verify 9/9 = 100%)
- [ ] **6.3**: Test with v2.0 task (verify unchanged behavior, no "Skipped" support)
- [ ] **6.4**: Test `cig-status --workflow` display format (verify "Skipped (N/A)" shown)
- [ ] **6.5**: Test performance: time status aggregation (verify <100ms)

### Step 7: Validation
- [ ] **7.1**: All 10 acceptance criteria from b-requirements-plan.md met
- [ ] **7.2**: No regressions in existing v2.0 or v2.1 tasks
- [ ] **7.3**: Security hashes verified with `/cig-security-check verify`
- [ ] **7.4**: Documentation complete and clear

## Code Changes

### Change 1: Configuration (cig-project.json)

**Before** (lines 69-76):
```json
{
  "workflow": {
    "status-values": {
      "Backlog": 0,
      "Blocked": 15,
      "To-Do": 0,
      "In Progress": 25,
      "Implemented": 50,
      "Testing": 75,
      "Finished": 100
    }
  }
}
```

**After** (add "Skipped" entry):
```json
{
  "workflow": {
    "status-values": {
      "Backlog": 0,
      "Blocked": 15,
      "To-Do": 0,
      "In Progress": 25,
      "Implemented": 50,
      "Testing": 75,
      "Finished": 100,
      "Skipped": null
    }
  }
}
```

### Change 2: Status Mapping (TaskState.pm)

**Before** (lines 91-106):
```perl
sub state_done {
    my ($task_dir) = @_;

    my @statuses = _get_all_statuses($task_dir);
    return 0 unless @statuses;

    my @percentages = map { status_percent($_) } @statuses;
    return 0 unless @percentages;

    # MIN bottleneck formula
    my $max_pct = _max(@percentages);
    my $min_pct = _min(@percentages);
    my $base_pct = ($max_pct >= 25) ? 25 : 0;
    my $progress = ($min_pct > $base_pct) ? $min_pct : $base_pct;

    return $progress;
}
```

**After** (add filter on line 97 - idiomatic grep defined):
```perl
sub state_done {
    my ($task_dir) = @_;

    my @statuses = _get_all_statuses($task_dir);
    return 0 unless @statuses;

    my @percentages = grep defined, map { status_percent($_) } @statuses;
    return 0 unless @percentages;

    # MIN bottleneck formula
    my $max_pct = _max(@percentages);
    my $min_pct = _min(@percentages);
    my $base_pct = ($max_pct >= 25) ? 25 : 0;
    my $progress = ($min_pct > $base_pct) ? $min_pct : $base_pct;

    return $progress;
}
```

**Note**: `grep defined` without block is more idiomatic than `grep { defined($_) }`

**Note**: No change to `status_percent()` needed - it already returns config value directly (null becomes undef in Perl)

### Change 3: Display Logic (status-aggregator-v2.1)

**Before** (approximate lines 195-210, workflow display):
```perl
for my $file (@$files) {
    my $status = TaskState::status_extract($file->{path});
    my $percent = TaskState::status_percent($status);

    printf("  %-30s %s (%d%%)\n",
        $file->{name} . ":",
        $status,
        $percent
    );
}
```

**After** (add conditional for "Skipped" status - idiomatic single printf with ternary):
```perl
for my $file (@$files) {
    my $status = TaskState::status_extract($file->{path});
    my $percent = TaskState::status_percent($status);

    my $suffix = $status eq "Skipped" ? "(N/A)" : sprintf("(%d%%)", $percent);
    printf("  %-30s %s %s\n",
        $file->{name} . ":",
        $status,
        $suffix
    );
}
```

**Note**: Single printf with ternary for suffix matches existing codebase style (see lines 420-424 nested ternaries)

### Change 4: Documentation (workflow-steps.md)

**Before** (lines 35-46):
```markdown
### Valid Status Values

The following status values are defined in the project configuration:

- **Backlog** (0%): Task not started, queued for future work
- **Blocked** (15%): Task started but cannot proceed until blocker resolved
- **To-Do** (0%): Task ready to begin, prioritized
- **In Progress** (25%): Work actively underway
- **Implemented** (50%): Code complete, not yet tested
- **Testing** (75%): Testing in progress, validation ongoing
- **Finished** (100%): Fully complete, all criteria met
```

**After** (add "Skipped" entry and usage guidance):
```markdown
### Valid Status Values

The following status values are defined in the project configuration:

- **Backlog** (0%): Task not started, queued for future work
- **Blocked** (15%): Task started but cannot proceed until blocker resolved
- **To-Do** (0%): Task ready to begin, prioritized
- **In Progress** (25%): Work actively underway
- **Implemented** (50%): Code complete, not yet tested
- **Testing** (75%): Testing in progress, validation ongoing
- **Finished** (100%): Fully complete, all criteria met
- **Skipped** (N/A): Phase not applicable to this specific task (may also apply to entire task type) (v2.1 only)

**Using "Skipped" Status** (v2.1 only):

Mark any workflow step as "Skipped" when it's not applicable. This is typically a **per-task decision** (this specific task doesn't need this phase) but may also be a **task-type pattern** (e.g., most bugfixes skip rollout).

Examples:
- **Maintenance** for a specific bugfix (this fix doesn't need ongoing monitoring)
- **Rollout** for internal tools (this tool has no external deployment)
- **Requirements** for a specific hotfix (requirements already clear for this fix)
- **Design** for a trivial change (this change needs no architecture)

"Skipped" phases are excluded from progress calculation. Example: 9 completed + 1 skipped = 9/9 = 100% (not 9/10 = 90%).

**Distinction**: "Skipped" (not applicable to this task) ≠ "Backlog" (not started yet) ≠ "Finished" (completed).
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

**Summary of test areas**:
- Unit tests: TaskState::status_percent() with null config value
- Unit tests: TaskState::state_done() with filtered percentages
- Integration tests: v2.1 task with "Skipped" phase shows correct progress
- Integration tests: v2.0 task unchanged (no "Skipped" support)
- Display tests: `--workflow` shows "Skipped (N/A)" format
- Regression tests: Existing tasks without "Skipped" status show same progress

## Validation Criteria

**Functional validation** (from AC1-AC5):
- [ ] Configuration: `jq '.workflow["status-values"]["Skipped"]'` returns `null`
- [ ] Aggregation: v2.1 task with 1 skipped + 9 finished shows 100% (9/9 not 9/10)
- [ ] v2.0 unchanged: Existing v2.0 tasks show correct progress with no "Skipped" support
- [ ] Display: `cig-status --workflow` shows "Phase: Skipped (N/A)" not percentage
- [ ] Documentation: workflow-steps.md includes "Skipped" definition with v2.1 requirement

**Non-functional validation** (from AC6-AC8):
- [ ] Backward compatibility: Existing v2.0 and v2.1 tasks without "Skipped" show correct progress
- [ ] Performance: Status aggregation with "Skipped" phases executes within <100ms
- [ ] Security: Script hashes updated in `.cig/security/script-hashes.json` and verified

**Integration validation** (from AC9-AC10):
- [ ] Format isolation: v2.0 aggregator unchanged, v2.1 handles "Skipped"
- [ ] BACKLOG resolution: Developers can mark any workflow step as "Skipped"

**Manual validation**:
1. Create test v2.1 task with maintenance phase marked "Skipped"
2. Run `/cig-status <task>` and verify 100% when all other phases finished
3. Run `/cig-status <task> --workflow` and verify "i-maintenance: Skipped (N/A)"
4. Run on existing v2.0 task and verify no changes
5. Run on existing v2.1 task without "Skipped" and verify no regression

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
**Next Action**: /cig-testing-plan 50
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
