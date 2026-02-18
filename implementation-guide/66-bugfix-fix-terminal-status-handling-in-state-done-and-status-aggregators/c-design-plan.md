# Fix terminal status handling in state_done and status aggregators - Design
**Task**: 66 (bugfix)

## Task Reference
- **Task ID**: internal-66
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/66-fix-terminal-status-handling-in-state-done-and-status-aggregators
- **Template Version**: 2.1

## Goal
Fix `CWF::TaskState` so that tasks where all workflow files are in closed terminal states (Finished, Cancelled, Skipped) report 100% completion, and simplify `state_achievable` by removing the now-redundant `_is_terminal`/`$is_workable` concept.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Root Cause Analysis

**Primary bug**: `state_done` uses `status_percent` for all statuses in the MIN bottleneck formula. Since `Cancelled => 0` and `Skipped` is absent from `%DEFAULT_STATUS_MAP` (also returns 0), these closed states drag task completion to 0% even when all steps are intentionally ended.

**Secondary issue — `_is_terminal` is a misnomer and partially redundant**:

`_is_terminal` currently contains `Blocked | Finished | Cancelled`. But:
- `Blocked` is *not* terminal — it is a recoverable stuck state with a normal workflow transition out
- The variable it feeds (`$blocked_count`) is used only to compute `$is_workable`
- With the `_is_closed` fix to `state_done`, any all-closed task scores 100% → the CLIFF check in `state_achievable` fires first (`completion >= 100`) → the `!$is_workable` branch becomes **dead code** and can be removed entirely

**Tertiary issue**: Both aggregators' "unknown status" warning regex does not exclude `Skipped`, so once `Skipped` had a 0 score it would generate spurious warnings.

## Key Design Decision: Single concept — `_is_closed`

Replace `_is_terminal` with `_is_closed`, defined as:

```
_is_closed: Finished | Cancelled | Skipped
```

"Closed" = step intentionally ended, not a bottleneck. `Blocked` is explicitly excluded — it represents stuck work that *is* a bottleneck and should surface in inference.

This one concept serves both fixes:
1. `state_done`: treat closed steps as 100 for MIN purposes (not bottlenecks)
2. `state_achievable`: remove `_is_terminal`/`$is_workable` entirely — CLIFF handles all-closed tasks; Blocked falls through to DORMANT naturally

## Component Design

### `CWF::TaskState.pm` — changes

**1. Add `Skipped => 100` to `%DEFAULT_STATUS_MAP`**

Skipped = "deliberately not applicable". The step is satisfied by design. 100 is correct for per-file display and consistent with Finished.

`Cancelled` stays at 0 in the raw map — semantically correct for per-file display (cancelled work is 0% of what was intended). Only `state_done` overrides this for the MIN calculation.

**2. Replace `_is_terminal` with `_is_closed`**

```
# Remove:
sub _is_terminal { Blocked | Finished | Cancelled }

# Add:
sub _is_closed { Finished | Cancelled | Skipped }
```

**3. Fix `state_done` MIN calculation**

Override closed terminal scores to 100 before applying MIN:

```
# Before
map { status_percent($_) } @statuses

# After
map { _is_closed($_) ? 100 : status_percent($_) } @statuses
```

Scoring outcomes:
| Statuses | Before | After |
|----------|--------|-------|
| All Cancelled | 0% | 100% ✓ |
| All Skipped | 0% | 100% ✓ |
| Finished + Cancelled + Skipped | 0% | 100% ✓ |
| Finished + In Progress | 25% | 25% (unchanged) ✓ |
| All Blocked | 15% | 15% (unchanged) ✓ |
| All active | unchanged | unchanged ✓ |

**4. Remove `_is_terminal`, `$blocked_count`, `$is_workable`, `!$is_workable` branch from `state_achievable`**

The `!$is_workable` branch is now dead code:
- All-closed tasks → `state_done` returns 100 → CLIFF fires → `work_potential = 0` ✓
- All-Blocked tasks → `state_done` returns 15 → DORMANT → `work_potential ≈ 4`

The behaviour change for Blocked is intentional: blocked tasks were previously hidden from inference (score 0). Surfacing them at a low DORMANT score (≈ 4) is better — a blocked task should be visible so it can be unblocked.

Simplified `state_achievable` logic after removing dead code:
```
if (completion >= 100)         → CLIFF: 0
elsif (completion == 0 && no active work) → FRESH: 10
elsif (no active work)         → DORMANT: completion × 0.3
else                           → ACTIVE: completion
```

### `status-aggregator-v2.0` and `status-aggregator-v2.1` — 1 change each

Add `Skipped` to the warning exclusion regex:
```
# Before
$status !~ /^(Backlog|To-Do|Cancelled)$/i

# After
$status !~ /^(Backlog|To-Do|Cancelled|Skipped)$/i
```

Note: once `Skipped => 100` is in the map, `status_percent('Skipped')` returns 100 so `$pct == 0` is false and the warning won't fire regardless. The regex change makes intent explicit.

## Data Flow

```
status-aggregator-v2.0 / v2.1
  └─ state_done(task_dir)
       └─ map { _is_closed($_) ? 100 : status_percent($_) }
            → Finished|Cancelled|Skipped → 100 (not a bottleneck)
            → Blocked → 15, In Progress → 25, etc.
       └─ MIN bottleneck formula

task-context-inference
  └─ state_achievable(task_dir)
       └─ state_done() → completion
       └─ CLIFF (completion >= 100) → 0
       └─ FRESH / DORMANT / ACTIVE (Blocked falls to DORMANT ≈ 4)
```

## Files to Modify

| File | Change |
|------|--------|
| `.cwf/lib/CWF/TaskState.pm` | Add `Skipped => 100`; replace `_is_terminal` with `_is_closed`; fix `state_done`; remove dead code from `state_achievable` |
| `.cwf/scripts/command-helpers/status-aggregator-v2.0` | Add `Skipped` to warning exclusion regex |
| `.cwf/scripts/command-helpers/status-aggregator-v2.1` | Add `Skipped` to warning exclusion regex |
| `.cwf/security/script-hashes.json` | Update hashes for 3 modified files |

## Decomposition Check
- [ ] **Time**: >1 week? — No
- [ ] **People**: >2 people? — No
- [ ] **Complexity**: 3+ distinct concerns? — No (one concept, three files)
- [ ] **Risk**: High-risk components? — No
- [ ] **Independence**: Parts separable? — No

No decomposition needed.

## Constraints
- Do not change the public API of `CWF::TaskState`
- `Cancelled => 0` stays in the raw map — only `state_done` overrides it for MIN purposes
- `script-hashes.json` must be updated after modifying any tracked file

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 66
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
