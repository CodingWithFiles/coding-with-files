# exclude-completed-tasks-from-recency - Testing Plan
**Task**: 171 (bugfix)

## Task Reference
- **Task ID**: internal-171
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/171-exclude-completed-tasks-from-recency
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for exclude-completed-tasks-from-recency.

## Test Strategy
### Test Levels
- **Unit Test (primary)**: one new subtest in `t/taskcontextinference.t` exercising
  `get_all_signals()` against a real on-disk fixture, asserting the `recency`
  signal's top candidate. This is the established pattern for the signal-collection
  layer (TC-8a/TC-8b).
- **Regression suite**: the full `prove -r t/` run confirms no collateral breakage,
  with particular attention to TC-8a/TC-8b (which the `state_done` predicate was
  chosen to preserve — see c-design-plan.md Decision 2).
- No integration/system/acceptance level needed: internal helper, no interface
  change, no new external surface (confirmed by design-phase security review).

### Test Coverage Targets
- **Critical path**: the new completed-task guard in `_get_recency_signal` —
  100% (the new subtest fails pre-fix, passes post-fix).
- **Regression**: all existing `taskcontextinference.t` subtests (TC-1..TC-8b)
  and the full `t/` suite remain green.

## Test Cases
### Functional Test Cases
- **TC-9 (new regression)**: recency excludes a completed task even when it is the
  most-recently-touched dir.
  - **Given**: a fixture repo with two top-level tasks —
    `implementation-guide/40-feature-active/f-implementation-exec.md` carrying
    `## Status` / `**Status**: In Progress` (→ `state_done` = 25, live), and
    `implementation-guide/41-feature-done/f-implementation-exec.md` carrying
    `**Status**: Finished` (→ `state_done` = 100, complete). The **completed**
    task's file is `utime`d to be the newest (`$now`); the active task's file is
    older (`$now - 100`).
  - **When**: `get_all_signals()` is called from within the fixture dir and the
    `recency` signal is extracted.
  - **Then**: `recency->{top}` is `'40'` (the live task). Pre-fix this assertion
    fails (recency returns `'41'`, the newest dir); post-fix it passes because the
    completed task is gated out before mtime scoring.
  - **Fixture note (load-bearing)**: each fixture file MUST contain a genuine
    `## Status` section with a `**Status**:` line, and MUST be named
    `f-implementation-exec.md` — `_get_all_statuses` keys v2.1 detection on that
    filename (`TaskState.pm:304`) and parses `## Status` → `**Status**:`
    (`:282-283`). A bare `"x"` file (as TC-8a uses) yields `state_done == 0` and
    would make the test pass even without the fix. Add a small `_write_status($rel,
    $status)` helper alongside `_build_fixture` to emit the marker.

- **TC-10 (boundary, retained-live)**: a fresh task is not excluded.
  - **Given**: a task whose `f-implementation-exec.md` carries `**Status**: To-Do`
    (or template `Backlog`) → `state_done` = 0, and it is the newest dir.
  - **When**: `get_all_signals()` → `recency`.
  - **Then**: `recency->{top}` is that task — confirms the guard excludes only
    *completed* tasks, never live/fresh ones (guards against an over-filter
    regression toward the rejected `state_achievable == 0` predicate).

### Non-Functional Test Cases
- **Reliability (fail-open)**: covered by design reasoning — if a status file is
  unparseable, `state_done` returns 0 and the task is retained. No separate test;
  the fail-open path is `state_done`'s own contract (owned by `taskstate` tests),
  not new behaviour introduced here.
- **Performance**: negligible — one extra `state_done` call per task dir, the same
  per-dir cost the adjacent `progress` signal already pays. No benchmark needed.
- **Security**: none — no new attack surface (design-phase security review: no
  FR4(a–e) findings).

## Test Environment
### Setup Requirements
- `prove` (core Perl `Test::More`), `PERL5OPT=-CDSLA` (set by the Claude Code
  session / shell).
- Fixtures are self-contained `File::Temp` tempdirs built in-test; each subtest
  `chdir`s in, asserts, and `chdir`s back to the saved cwd (TC-8a pattern). No
  touching of the real `implementation-guide/` tree.

### Automation
- Framework: `Test::More` via `prove`. No CI change; run locally in g-testing-exec.

## Validation Criteria
- [ ] TC-9 fails on the unpatched module, passes on the patched module
- [ ] TC-10 passes (live/fresh task retained)
- [ ] TC-1..TC-8b unchanged and green
- [ ] `prove -r t/` full suite green
- [ ] `.cwf/scripts/cwf-manage validate` clean (hash refreshed in same commit)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-9 and TC-10 implemented in `t/taskcontextinference.t` (commit `630add4`).
TC-9 proven load-bearing: fails on the unpatched module (`'41'`), passes patched
(`'40'`). TC-10 confirms the live/fresh task is retained. Full suite 636 green.

## Lessons Learned
The pre-fix failure verification (temporarily remove the guard, watch TC-9 turn
`not ok`) is a cheap, high-value step that converts a plausible regression test
into a verified one.
