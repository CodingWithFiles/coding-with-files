# add-new-skipped-wf-step-status - Design
**Task**: 50 (feature)

## Task Reference
- **Task ID**: internal-50
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/50-add-new-skipped-wf-step-status
- **Template Version**: 2.1

## Goal
Define architecture for "Skipped" status that excludes inapplicable workflow phases from progress calculation while maintaining backward compatibility with v2.0 format.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice
- **Decision**: Null-value sentinel pattern with filter-based exclusion
- **Rationale**:
  - JSON null is semantically correct for "not applicable" (distinct from 0% or 100%)
  - Perl's `defined()` check provides clean discrimination between numeric and null values
  - Filter approach (exclude from denominator) is simpler than special-case arithmetic
  - Single source of truth in cig-project.json eliminates duplication
- **Trade-offs**:
  - ✅ **Benefits**: Clean semantics, minimal code changes (~15 lines), explicit null handling, reversible
  - ✅ **Benefits**: No magic numbers, self-documenting config, testable via existing tasks
  - ⚠️ **Drawbacks**: v2.1-only feature (v2.0 historic format unchanged)
  - ⚠️ **Drawbacks**: Requires Perl `defined()` checks in status aggregation logic

### Technology Stack
- **Configuration**: JSON null value in `cig-project.json` workflow.status-values
- **Processing**: Perl with explicit `defined()` checks for null discrimination
- **Display**: String concatenation for "Skipped (N/A)" format (not percentage formatting)

## System Design

### Component Overview

**1. Configuration Layer** (`cig-project.json`)
- **Purpose**: Single source of truth for status value definitions
- **Responsibility**: Define "Skipped": null alongside existing numeric status values
- **Interface**: JSON object read by TaskState::status_percent() via CIG::WorkflowFiles::load_config()

**2. Status Mapping Module** (`TaskState.pm`)
- **Purpose**: Map status strings to completion percentages (or null for "Skipped")
- **Responsibility**:
  - Load config from cig-project.json (with caching)
  - Return numeric percentage for normal statuses (0, 25, 50, 75, 100)
  - Return `undef` for "Skipped" status (null value in config)
  - Return 0 for unknown statuses (backward compatibility)
- **Interface**: `TaskState::status_percent($status) -> number | undef`

**3. Progress Calculation Module** (`TaskState::state_done()`)
- **Purpose**: Calculate task completion percentage using MIN bottleneck formula
- **Responsibility**:
  - Get all workflow file statuses via `_get_all_statuses()`
  - Map statuses to percentages via `status_percent()`
  - **NEW**: Filter out undefined values (skipped phases) before MIN calculation
  - Apply MIN bottleneck formula to applicable phases only
- **Interface**: `TaskState::state_done($task_dir) -> 0-100`

**4. Status Aggregator Script** (`status-aggregator-v2.1`)
- **Purpose**: Display task progress with optional workflow breakdown
- **Responsibility**:
  - Delegate progress calculation to TaskState::state_done()
  - **NEW**: Display "Skipped (N/A)" instead of percentage when status is "Skipped"
  - Maintain backward compatibility with v2.0 tasks (no changes to status-aggregator-v2.0)
- **Interface**: Command-line tool with `--workflow` flag for detailed display

**5. Documentation** (`workflow-steps.md`)
- **Purpose**: Guide developers on when to use "Skipped" status
- **Responsibility**: Explain semantics, provide examples, clarify v2.1 requirement
- **Interface**: Markdown documentation with usage examples

### Data Flow

```
1. User edits workflow file
   └─> Sets "Status: Skipped" in markdown file

2. status-aggregator-v2.1 invoked (e.g., via /cig-status)
   └─> TaskState::state_done(task_dir)

3. state_done() gets all workflow file statuses
   └─> TaskState::status_extract() for each file
   └─> Returns ["Finished", "Skipped", "Finished", ...]

4. state_done() maps statuses to percentages
   └─> status_percent("Finished") -> 100
   └─> status_percent("Skipped") -> undef  [NEW: null in config]
   └─> status_percent("Finished") -> 100
   └─> Returns [100, undef, 100, ...]

5. state_done() filters out undefined values [NEW]
   └─> grep { defined($_) } @percentages
   └─> Filtered: [100, 100]  (undef removed from calculation)

6. state_done() applies MIN bottleneck formula
   └─> MIN(100, 100) = 100
   └─> Returns 100% (not penalized for skipped phase)

7. status-aggregator displays results
   └─> Task progress: 100%
   └─> --workflow shows "i-maintenance: Skipped (N/A)"  [NEW: special display]
```

**Key Design Point**: Filtering happens in step 5 (exclude from denominator), not in display layer. Progress calculation sees only applicable phases.

## Interface Design

### Configuration Schema (cig-project.json)

**Current** (numeric values only):
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

**New** (with null value for "Skipped"):
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

**Verification**:
```bash
# Returns null (not "null" string, actual JSON null)
jq '.workflow["status-values"]["Skipped"]' implementation-guide/cig-project.json
```

### Module Interface (TaskState.pm)

**Current behavior** (`status_percent`):
```perl
# Returns numeric value or 0 for unknown
status_percent("Finished")     # -> 100
status_percent("In Progress")  # -> 25
status_percent("UnknownFoo")   # -> 0 (default)
```

**New behavior** (with null handling):
```perl
# Returns numeric, undef, or 0
status_percent("Finished")     # -> 100
status_percent("In Progress")  # -> 25
status_percent("Skipped")      # -> undef (null in config)
status_percent("UnknownFoo")   # -> 0 (default)
```

**Implementation change** (status_percent function):
```perl
# Current (line 195-196)
if (exists $_status_map_cache->{$status}) {
    return $_status_map_cache->{$status};  # Returns value directly
}

# New (explicit null handling)
if (exists $_status_map_cache->{$status}) {
    my $value = $_status_map_cache->{$status};
    return $value;  # May be numeric or undef (null)
}
```

**Implementation change** (state_done function):
```perl
# Current (line 97-98)
my @percentages = map { status_percent($_) } @statuses;
return 0 unless @percentages;

# New (filter undefined values)
my @percentages = grep { defined($_) }
                  map { status_percent($_) } @statuses;
return 0 unless @percentages;
```

### Display Interface (status-aggregator-v2.1)

**Current display** (all statuses shown with percentages):
```
Task: 50-feature-add-new-skipped-wf-step-status (100%)
  a-task-plan:           Finished (100%)
  b-requirements-plan:   Finished (100%)
  i-maintenance:         Backlog (0%)     ← Problem: penalizes progress
```

**New display** (skipped phases shown as "N/A"):
```
Task: 50-feature-add-new-skipped-wf-step-status (100%)
  a-task-plan:           Finished (100%)
  b-requirements-plan:   Finished (100%)
  i-maintenance:         Skipped (N/A)    ← NEW: explicitly not applicable
```

**Implementation location**: Workflow display logic in status-aggregator-v2.1 (lines ~195-210)

## Constraints

### Technical Constraints

**Perl Null Handling**:
- JSON::PP parses JSON null as Perl `undef`
- Must use `defined()` check, not truthiness (0 is valid numeric status)
- Cache invalidation not needed (config loaded once per invocation)

**v2.1 Format Only**:
- "Skipped" status only available in v2.1 format (10-phase workflow)
- v2.0 format unchanged (historic stability, 8-phase workflow)
- No migration required (feature is additive, not breaking)

**MIN Bottleneck Formula**:
- Current formula: `MIN(all_percentages)` with base threshold
- After filtering: `MIN(applicable_percentages)` excludes skipped
- Empty array after filtering: return 0 (all phases skipped = incomplete task)

**Backward Compatibility**:
- Existing v2.1 tasks without "Skipped" status: unchanged behavior
- Unknown statuses continue defaulting to 0% (existing behavior)
- Config file remains valid JSON (null is valid JSON value)

### Performance Considerations

**No Performance Impact**:
- `defined()` check: O(1) per status value (~10 checks per task)
- `grep { defined($_) }`: O(n) where n=10 (workflow files), negligible
- Config caching unchanged (single load per invocation)
- No additional I/O, no network calls, no external dependencies

### Security Requirements

**Script Hash Update**:
- Modify `.cig/scripts/command-helpers/status-aggregator-v2.1`: requires new SHA256 hash
- Modify `.cig/lib/TaskState.pm`: requires new SHA256 hash
- Update `.cig/security/script-hashes.json` with both new hashes
- Verify with `/cig-security-check verify` after changes

## Design Validation

### Critical Design Questions

**Q: Why null instead of special numeric value (e.g., -1)?**
- A: Null is semantically correct ("not applicable" not "negative progress")
- A: Avoids magic numbers in code
- A: JSON null is standard, self-documenting
- A: Perl `defined()` provides clean discrimination

**Q: Why filter in state_done() instead of status_percent()?**
- A: Separation of concerns: status_percent() maps, state_done() aggregates
- A: Filtering at aggregation level is more testable
- A: Allows display layer to distinguish "Skipped" from unknown statuses

**Q: Why v2.1 only?**
- A: v2.0 is historic format (no new features)
- A: Reduces risk (v2.0 tasks unaffected)
- A: Simpler implementation (1 aggregator instead of 2)

**Q: What if all phases are skipped?**
- A: `@percentages` becomes empty array after filtering
- A: `state_done()` returns 0 (task is incomplete)
- A: Correct behavior: task with all phases skipped hasn't made progress

**Q: How does this affect subtasks?**
- A: Same logic applies recursively (subtask can have skipped phases)
- A: Parent task progress aggregates from subtasks (unchanged)

### Integration Verification

- [ ] **Config integration**: cig-project.json accepts null value (JSON spec allows null)
- [ ] **Module integration**: TaskState.pm loaded by status-aggregator-v2.1 (existing pattern)
- [ ] **Display integration**: status-aggregator-v2.1 checks for "Skipped" status string (simple string comparison)
- [ ] **Documentation integration**: workflow-steps.md references cig-project.json (existing cross-reference pattern)

### Trade-off Analysis

**Chosen Approach**: Null-value sentinel with filter-based exclusion

**Alternatives Considered**:

1. **Magic number (-1 or 999)**
   - ❌ Rejected: Requires special-case arithmetic, magic numbers in code
   - ❌ Not semantically correct ("not applicable" ≠ numeric value)

2. **Separate "skipped-phases" config array**
   - ❌ Rejected: Violates DRY (phase names in two places)
   - ❌ More complex (two-pass lookup: status value, then skipped check)

3. **Add "Skipped" to both v2.0 and v2.1**
   - ❌ Rejected: v2.0 is historic, no need to touch it
   - ❌ Higher risk, more testing, more code changes

**Decision Rationale**: Null-value approach is simplest, most semantically correct, and lowest risk.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - estimated 1-2 days (design confirms)
- [ ] **People**: Does this need >2 people working on different parts? **NO** - single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **YES** (4 components) **BUT tightly coupled**
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** - changes are localized, well-tested
- [ ] **Independence**: Can parts be worked on separately? **NO** - config/module/display must work atomically

**Decomposition Decision**: No subtasks. Design confirms 4 components are tightly coupled (config defines null, module returns undef, aggregation filters, display formats). Atomic implementation with comprehensive testing is appropriate.

## Status
**Status**: Finished
**Next Action**: /cig-implementation-plan 50
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
