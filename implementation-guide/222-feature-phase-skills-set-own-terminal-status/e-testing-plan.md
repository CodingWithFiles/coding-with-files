# Phase skills set own terminal status at checkpoint - Testing Plan
**Task**: 222 (feature)

## Task Reference
- **Task ID**: internal-222
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/222-phase-skills-set-own-terminal-status
- **Template Version**: 2.1

## Goal
Validate FR1–FR4 / AC1–AC5: template status hygiene, the `j` own-status
precondition stamp, the Skipped rationale, retention of the sweep, and the
regression guard — with deterministic, non-flaky tests and no hashed-file churn.

## Test Strategy
### Test Levels
- **Unit**: the terminal-set predicate (`_is_closed`) and status validity
  (`status_is_valid`) — reused, asserted directly (no new production code).
- **Static/content**: template-hygiene scan over the real pool templates.
- **Integration (manual E2E)**: a real `j` retrospective checkpoint leaves
  `Status: Finished`, and a forced `cwf-set-status` failure blocks the commit.
- **Regression**: full `prove -l t/` + `cwf-manage validate`.

### Coverage Targets
- **Critical path (the leak)**: 100% — every pool template's status-context lines
  asserted canonical; the terminal predicate asserted on all three terminal
  values and representative non-terminal ones.
- **Regression**: existing `t/` suite unaffected; `validate` green; no hash refresh.

## Test Cases
### Functional Test Cases

- **TC-1 — Template hygiene, green on fixed pool (FR1/FR4b, AC1)**
  - **Given**: `f:20` hint deleted, `g:20` kept (canonical), `t/status-terminality.t` present.
  - **When**: `prove -lv t/status-terminality.t`.
  - **Then**: every `**Status**:` value and every quoted token on any `Update
    status to "…"` line across the ten pool templates passes `status_is_valid`
    (incl. `g:20`'s `Testing`/`Finished`); test GREEN.

- **TC-2 — Template hygiene, red on seed (FR4b, AC5 red-on-seed)**
  - **Given**: the fixed pool.
  - **When**: temporarily reintroduce `Update status to "Implemented"` in `f`, run the test.
  - **Then**: test goes RED naming the offending token; revert → GREEN. (Proves the
    guard actually catches the regression, per test-first discipline.)

- **TC-3 — `Backlog` seed intact (FR1, AC1)**
  - **Given**: the edited templates.
  - **When**: grep each pool template for its `**Status**:` seed line.
  - **Then**: every template still ships `**Status**: Backlog` (the seed is the
    start state, deliberately unchanged) — the test does not flag it (`Backlog` is
    a valid enum value).

- **TC-4 — Terminal-set predicate (FR4a, AC5)**
  - **Given**: the `subtest` added to `t/task-state.t`.
  - **When**: `prove -lv t/task-state.t`.
  - **Then**: `_is_closed` is true for `Finished`/`Skipped`/`Cancelled`, false for
    `Backlog`/`In Progress` — the single terminal-set source is asserted without a
    duplicated literal set and without a new export.

- **TC-5 — j own-status stamp, happy path (FR2a, AC2)**
  - **Given**: the `&&`-chained `cwf-set-status {j} Finished && git add … && git
    commit …` step in `retrospective-extras.md`.
  - **When**: a real (or fixture) `j` checkpoint runs to completion.
  - **Then**: the committed `j-retrospective.md` carries `Status: Finished`,
    produced by the scripted stamp (verifiable without running the manual sweep).

- **TC-6 — j stamp is a hard precondition (FR2a, robustness #2)**
  - **Given**: a fixture where `cwf-set-status` would exit non-zero (e.g. a target
    file with no `**Status**:` field).
  - **When**: the `&&`-chained step runs.
  - **Then**: the chain stops at `cwf-set-status`; **no** `git add`/`git commit`
    occurs — the stamp genuinely gates the commit (prose alone would not).

- **TC-7 — Skipped path (FR2b, AC3)**
  - **Given**: a present phase file to be skipped.
  - **When**: `cwf-set-status <phase-file> Skipped`.
  - **Then**: the file ends `Status: Skipped` (terminal); and the design rationale
    ("no committed-leak path under the symlink model") is recorded in
    `f-implementation-exec.md` Actual Results.

- **TC-8 — Manual sweep retained (FR3, AC4)**
  - **Given**: the retrospective SKILL gotcha #1 + `retrospective-extras.md`
    "Verify Task Status" step unchanged.
  - **When**: inspect them, and inject a non-terminal status into a fixture phase file.
  - **Then**: both surfaces are still present; the manual sweep
    (`workflow-manager status … --workflow`) still surfaces the injected
    non-terminal status — defence in depth intact.

- **TC-9 — Strengthened hook decision (FR3/D6, AC4)**
  - **Given**: the refactored `stop-stale-status-detector` `is_flaggable` predicate.
  - **When**: call it with each of `Backlog`, `Design` (non-canonical),
    `In Progress` (valid non-terminal), `Finished` (terminal).
  - **Then**: **flags** `Backlog` and `Design`; **does not flag** `In Progress` or
    `Finished` — catches the observed invalid-enum leaks without firing on valid
    in-progress work. (Automated in `t/status-terminality.t`.)

- **TC-10 — Hook integrity (D6, AC5)**
  - **Given**: the hook edited and its `script-hashes.json` entry refreshed in-task.
  - **When**: `cwf-manage validate`.
  - **Then**: OK — the one hashed-file edit is recorded; no other hashed path changed.

### Non-Functional Test Cases
- **Installed-artefact neutrality (NFR4)**: grep the edited templates/docs for
  repo-specific strings (paths, task numbers, names) → none.
- **Single hashed-file edit (NFR4)**: only `stop-stale-status-detector` (the hook)
  appears in both the task diff and `script-hashes.json`; its SHA256 is refreshed
  in-task and `cwf-manage validate` → OK. No other hashed path changes.
- **Performance (NFR1)**: `cwf-checkpoint-commit` / `validate` timings unchanged
  (no runtime path modified) — spot-check, no benchmark needed.
- **Prose (Conventions)**: British spelling; no personal names in edited docs.

## Test Environment
### Setup Requirements
- Local repo checkout on `feature/222-…`; core Perl (`Test::More`, `File::Temp`
  not required after the fixture-drop — predicate assertions need neither).
- Fixture phase files created inline in tests (temp) for TC-6/TC-8; no external
  services, no database.

### Automation
- `prove -l t/status-terminality.t t/task-state.t` for the automated guard.
- `cwf-manage validate` as the integrity gate (run by `cwf-checkpoint-commit`).
- TC-5/TC-6/TC-8 j-flow checks are manual/E2E in g-testing-exec (the retro flow is
  operator-driven prose, not a unit under test).

## Validation Criteria
- [ ] TC-1..TC-4, TC-7, TC-9 automated and passing; TC-2 proven red-on-seed.
- [ ] TC-5, TC-6, TC-8 executed as documented manual E2E checks in g.
- [ ] TC-10: full `prove -l t/` green; `cwf-manage validate` OK; hook SHA256 refreshed in-task.
- [ ] Non-functional checks (neutrality, single hashed edit, prose) pass.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 10 functional + 5 non-functional cases executed and passed (g-testing-exec). The
red-on-seed case (TC-2) and the fail-closed precondition (TC-6) proved the guards
genuinely fail when they should. Full suite 998 tests green.

## Lessons Learned
Planning a red-on-seed test (reintroduce the removed hint → assert RED → revert) turned
"we deleted a bad hint" into a durable regression guard — the test now fails the moment
any non-canonical hint returns to the pool.
