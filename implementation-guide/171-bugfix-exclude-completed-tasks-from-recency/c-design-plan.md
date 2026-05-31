# exclude-completed-tasks-from-recency - Design
**Task**: 171 (bugfix)

## Task Reference
- **Task ID**: internal-171
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/171-exclude-completed-tasks-from-recency
- **Template Version**: 2.1

## Goal
Stop the `recency` task-candidate signal from nominating completed tasks, by
gating its candidate set through the existing `CWF::TaskState` framework — the
same module the `progress` signal already relies on.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Problem Statement (root cause)
`correlate_signals` takes the top candidate of each non-null task signal and
checks for agreement. Three task signals fire in the reported scenario:
- `branch` → the active task (e.g. `6` from `dis/6-...`)
- `progress` → the active task (completed tasks already drop out: `state_achievable`
  returns `0` at the 100% cliff, and `_get_progress_signal` filters `score > 0`)
- `recency` → **a recently-touched *completed* task** (`TaskContextInference.pm:387`
  scores purely by file mtime; merges, commits and hash refreshes bump mtimes on
  finished task dirs)

Two disagreeing tops on disjoint branches → D3 step 8 → `uncorrelated` →
the false-positive `candidates: 2`. `recency` is the only task-candidate signal
that does **not** consult the work-potential framework before nominating.

## Key Decisions

### Decision 1 — Reuse `CWF::TaskState`, do not invent a completion check
- **Decision**: Gate the recency candidate set through `CWF::TaskState`, the
  established task-state framework, rather than parsing status markers locally.
- **Rationale**: Directly answers "is there an existing framework?" — yes.
  `TaskState` already owns both task-state measures and is already a dependency
  of this module (`use CWF::TaskState qw(state_achievable)` at `:11`).
- **Trade-offs**: Adds one import symbol; no new concepts.

### Decision 2 — Predicate is `state_done($dir) >= 100` (complete), NOT `state_achievable($dir) == 0`
- **Decision**: Exclude a task from recency when `state_done($dir) >= 100`.
- **Rationale**: The bug is specifically *completed* tasks. `state_done` is the
  retrospective completion measure — the precise expression of "this task is
  finished". `state_achievable == 0` is the *prospective* work-potential measure
  the progress signal uses; it returns `0` for a **superset** — completed tasks
  **and** dirs with no parseable status **and** dormant tasks whose
  `int(completion * 0.3)` truncates to 0. Using it here would over-filter and,
  critically, would break the existing recency enumeration tests (TC-8a/TC-8b),
  whose synthetic fixtures contain no `**Status**:` markers and therefore yield
  `state_achievable == 0` for every dir.
- **Trade-offs**: `state_done` and `state_achievable` express different intents;
  using the completion measure for "exclude finished work" is the correct match
  and keeps the change tightly scoped to the reported defect.
- **Boundary note**: A freshly-created task has template `**Status**: Backlog`
  markers → `state_done` = 0 → retained (correct: it is live work). A complete
  task (all phases Finished/Skipped) → `state_done` = 100 → excluded.
- **Fail-open**: if a status file is unreadable/unparseable, `state_done` returns
  0 (`TaskState.pm:103`) → task retained. This is the correct failure direction —
  a task that cannot be *proven* complete stays a candidate; we never silently
  drop live work on a parse error.
- **`>= 100`, not `== 100`**: `state_done` is documented 0–100 so `> 100` is
  unreachable today, but `>=` is robust against any future formula change and
  must not be "tidied" to `==`.
- **Per-dir, no cascade**: `_enumerate_all_tasks` enumerates each subtask dir
  independently (the basis of TC-8a). The guard gates each dir on its own
  `state_done`, so a complete parent (`state_done` = 100, skipped) does **not**
  suppress a still-live subtask (`state_done` < 100, retained), and vice versa.
  Relevant given Task 166 made enumeration subtask-aware.

### Decision 3 — In-place guard in `_get_recency_signal`, not a shared enumeration helper
- **Decision**: Add the skip inside `_get_recency_signal`'s mtime-collection
  loop; leave `_enumerate_all_tasks` and the `progress` signal untouched.
- **Rationale**: `progress` already gates correctly via its score filter, so a
  shared "live-tasks" enumerator would be refactor scope without behaviour gain.
  Single new call site → Rule of Three not met. Smaller blast radius, fully
  reversible.
- **Rejected alternative**: factor `_enumerate_live_tasks()` shared by both
  signals — deferred; revisit only if a third caller appears.

## System Design
### Component Overview
- **`_get_recency_signal` (`TaskContextInference.pm:387`)**: the only file
  changed in `.cwf/lib`. Skips completed tasks before recording their mtime.
- **`CWF::TaskState::state_done` (`TaskState.pm:99`)**: unchanged; consulted as
  the completion gate. Added to the `use` import list.
- **No change** to `correlate_signals`, the D3 decision tree, `progress`,
  `branch`, `worktree`, `state`, or `format_output`.

### Data Flow
1. `get_all_signals` → `_get_recency_signal`
2. `_get_recency_signal` enumerates tasks (`_enumerate_all_tasks`)
3. **NEW**: for each task, `state_done(full_path) >= 100` → skip (no mtime recorded)
4. Remaining tasks scored by mtime decay as today → top candidate
5. `correlate_signals` sees a recency top drawn only from live tasks

## Interface Design
No public API change. Internal only:
- Add `state_done` to `use CWF::TaskState qw(...)` at `:11`.
- One guard line in `_get_recency_signal`'s loop, e.g.
  `next if CWF::TaskState::state_done($task->{full_path}) >= 100;` with a comment
  mirroring the existing cliff rationale ("completed tasks have no live work").

## Constraints
- Perl core modules only; `use utf8;` already present; POSIX-portable.
- `TaskContextInference.pm` is hash-tracked → same-commit `script-hashes.json`
  refresh (hash-updates convention).
- No behaviour change to any signal other than `recency`.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: >1 week? **No**.
- [x] **People**: >2 people? **No**.
- [x] **Complexity**: 3+ distinct concerns? **No** — one signal, one gate.
- [x] **Risk**: high-risk isolation needed? **No**.
- [x] **Independence**: separable parts? **No**.

No decomposition signals triggered → single task.

## Validation
- [x] Design review completed (plan-review subagents — see below)
- [x] Integration points verified (`state_done` exported `:14`; module already imports `TaskState`)
- [x] Existing-test impact assessed (TC-8a/TC-8b safe under `state_done` predicate)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design held through implementation. One supersession: the Interface section's
"add `state_done` to the import" was replaced in d-implementation-plan.md by a
fully-qualified call with no import edit (matching the module's `:519`
precedent), reducing the diff to one line.

## Lessons Learned
Reading the existing test fixtures (TC-8a/TC-8b) during design — not just the
source — is what surfaced the `state_achievable == 0` over-filter before any
code was written.
