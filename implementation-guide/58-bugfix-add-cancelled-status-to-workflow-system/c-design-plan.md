# Add Cancelled status to workflow system - Design
**Task**: 58 (bugfix)

## Task Reference
- **Task ID**: internal-58
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/58-add-cancelled-status-to-workflow-system
- **Template Version**: 2.1

## Goal
Design the integration of "Cancelled" as a terminal status value across config, documentation, library code, and aggregator scripts.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1: Percentage Value — 0%
- **Decision**: `"Cancelled": 0` in `cig-project.json`
- **Rationale**: A cancelled task hasn't achieved its goals. 0% accurately reflects this. Consistent with Backlog/To-Do which are also 0%.
- **Trade-offs**: Alternative was `null` (like Skipped), but Skipped means "not applicable to this task type" while Cancelled means "this task existed but was abandoned". 0% preserves the semantic distinction.

### D2: Terminal Status Classification
- **Decision**: Treat Cancelled as terminal alongside Finished — no work is possible on a cancelled task.
- **Rationale**: `_is_blocked_or_finished` in TaskState.pm gates `state_achievable` (prospective scoring). Cancelled tasks must score 0 work potential.
- **Impact**: Rename `_is_blocked_or_finished` to `_is_terminal` and add Cancelled. This affects `state_achievable` only — `state_done` uses percentages directly.

### D3: Warning Suppression in Aggregators
- **Decision**: Update the "unknown status" warning regex in both status-aggregator-v2.0 and status-aggregator-v2.1 to exempt Cancelled.
- **Rationale**: Both aggregators warn when a status maps to 0% but isn't Backlog or To-Do. Without this fix, every Cancelled file would emit a spurious warning.
- **Change**: `$status !~ /^(Backlog|To-Do)$/i` → `$status !~ /^(Backlog|To-Do|Cancelled)$/i`

### D4: Display Handling
- **Decision**: No special display formatting for Cancelled. Show as `(0%)` with `-` indicator.
- **Rationale**: The status text "Cancelled" next to the percentage provides sufficient context. Unlike Skipped which shows "(N/A)", Cancelled has a real numeric value.

### D5: v2.0 and v2.1 Compatibility
- **Decision**: Cancelled works with both format versions. The status value is format-independent — it lives in `cig-project.json` and is consumed by both aggregators.
- **Rationale**: Task 11 is v2.0 format. The `status_percent` function in TaskState.pm reads from config regardless of format version. Both aggregators use `status_percent`.

### D6: Applying Cancelled to Task 11
- **Decision**: Set ALL five Task 11 workflow files to `**Status**: Cancelled`. Add a brief note in each explaining the cancellation reason.
- **Rationale**: A cancelled task is cancelled as a whole, not per-phase. Setting all files prevents partial-state confusion. Cancellation reason is documented separately from the status value (per user guidance: "reasons != status").

## Component Overview

### 1. Configuration (`cig-project.json`)
- Add `"Cancelled": 0` to `workflow.status-values`
- Single-line change

### 2. Documentation (`workflow-steps.md`)
- Add Cancelled to the Valid Status Values list
- Describe semantics: terminal status for abandoned/superseded tasks, 0%, works with both v2.0 and v2.1

### 3. Library (`TaskState.pm`)
- `_is_blocked_or_finished` → rename to `_is_terminal`, add Cancelled
- `_is_active_work`: No change — Cancelled is not active work (implicit exclusion is correct)
- `%DEFAULT_STATUS_MAP`: Add `'Cancelled' => 0` as fallback

### 4. Aggregator Scripts (both v2.0 and v2.1)
- Update warning regex to exempt Cancelled from "unknown 0% status" warning

### 5. Task 11 Workflow Files (5 files)
- Set status to Cancelled in all files
- Add cancellation reason: "Superseded by Task 57 — commands converted to skills, bypassing the $ARGUMENTS parsing bug entirely"

## Data Flow

1. User sets `**Status**: Cancelled` in workflow file
2. `status_extract()` reads "Cancelled" string from file
3. `status_percent("Cancelled")` looks up config → returns 0
4. `state_done()` uses 0 in MIN bottleneck formula → task reports 0%
5. `state_achievable()` calls `_is_terminal("Cancelled")` → returns true → scores 0 work potential
6. Status-aggregator displays `- 11 (bugfix): ... - 0%` with no warnings

## Constraints
- Must not break any existing status value behaviour
- Must not require format version detection for Cancelled (format-independent)
- TaskState.pm `$_status_map_cache` clears on process restart — no cache invalidation needed

## Decomposition Check
- [ ] **Time**: >1 week? **No** — under 1 hour
- [ ] **People**: >2 people? **No**
- [ ] **Complexity**: 3+ concerns? **No** — config, lib, docs, apply
- [ ] **Risk**: High-risk components? **No**
- [ ] **Independence**: Parts separable? **No** — tightly coupled

**Decision**: No decomposition needed (0 signals triggered).

## Validation
- [x] Design review completed
- [x] Architecture approved (minimal change, follows existing patterns)
- [x] Integration points verified (TaskState.pm, both aggregators, cig-project.json)

## Status
**Status**: Finished
**Next Action**: /cig-implementation-plan 58
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
