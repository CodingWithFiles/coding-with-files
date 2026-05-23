# Progress-signal inference conflict still present - Testing Plan
**Task**: 157 (discovery)

## Task Reference
- **Task ID**: internal-157
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/157-progress-signal-inference-conflict-still-present
- **Template Version**: 2.1

## Goal
Define how the discovery evidence is validated: the probe's assertions, the
observed candidate list, and the trace citations must all hold before the
verdict (FR3) and recommendation (FR4) can be trusted.

## Test Strategy
### Test Levels
- **Trace validation**: Each FR1 hop citation resolves to the stated behaviour at a current file:line (re-grep, not memory).
- **Unit (probe)**: Real `state_achievable` / `_score_progress` produce the matrix scores for each fixture.
- **Integration (probe)**: Real `_get_progress_signal()` assembles the candidate list and `top` from the synthetic tree.
- **Guard assertions**: Status-map and parse-success checks must pass, so a confirming result cannot be faked by a malformed fixture or a surprising config.

### Test Coverage Targets
- The three `state_achievable` branches the verdict touches (CLIFF, FRESH, ACTIVE) are each exercised by a fixture.
- The falsifying condition (FR3) is explicitly checked, not just the confirming one.

## Test Cases
### Functional Test Cases
- **TC-1 (AC1) — Trace citations current**
  - **Given**: the FR1 hop list (`TaskContextInference.pm:385/402/418/453`, `TaskState.pm:105/150`)
  - **When**: each line is re-read in the current source
  - **Then**: each cited line still performs the stated step; any drift is corrected in the f-record

- **TC-2 (guard) — Status map in force**
  - **Given**: the probe under `PERL5OPT=-CDSLA`
  - **When**: it calls `status_percent` for the three statuses
  - **Then**: `Finished==100`, `Backlog==0`, `In Progress==25` (else abort — outcomes would be unsound)

- **TC-3 (guard) — Fixtures parsed correctly**
  - **Given**: the three fixture task dirs
  - **When**: the probe calls `state_done` on each
  - **Then**: `201==100`, `202==0`, `203==25` (proves no "Unknown" parse; a missing `## Status` heading would surface here, not as a false-confirm)

- **TC-4 (AC2) — Unit scores match the matrix**
  - **Given**: each fixture dir (absolute path)
  - **When**: the probe computes `state_achievable` then `_score_progress`
  - **Then**: `201 → wp 0 → score 0`; `202 → wp 10 → score 6`; `203 → wp 25 → score 15`

- **TC-5 (AC2, the core observation) — Finished task excluded from candidates**
  - **Given**: the synthetic `implementation-guide/` containing `201` (finished) + `202` (backlog) [+ optional `203`]
  - **When**: the probe `chdir`s in and calls `_get_progress_signal()`
  - **Then**: `201` is **absent** from `candidates`; `top == 202` (or `203` if built); a finished task is never the progress signal's nominee

- **TC-6 (AC3) — Falsifying condition addressed**
  - **Given**: the recorded candidate list
  - **When**: checked against "what would show the premise holds"
  - **Then**: it is stated that `201` appearing as a candidate (or as `top`) would confirm the backlog claim, and that this did **not** occur — so "misread" rests on evidence, not assumption

### Non-Functional Test Cases
- **Reliability**: TC-5 is deterministic — re-running the probe yields the same candidate list and `top` (NFR5).
- **Security/Integrity**: No tracked file is modified; `git status` on `.cwf/**` shows no changes after the run (read-only constraint upheld).
- **Performance / Usability**: N/A.

## Test Environment
### Setup Requirements
- Scratch root `/tmp/-home-matt-repo-coding-with-files-task-157/` (`mkdir -m 0700 -p`), outside any git tree.
- Synthetic `implementation-guide/` with fixtures `201`/`202`[/`203`], each a `<num>-feature-<slug>` dir with `a-task-plan.md` + `f-implementation-exec.md` carrying `## Status` markers.
- Probe `probe.pl` with `use lib "$repo/.cwf/lib"`; core Perl only.

### Automation
- Single throwaway probe script; no CI integration (one-off discovery evidence).
- Output captured to `probe.out` and pasted into `f-implementation-exec.md`.

## Validation Criteria
- [ ] TC-1: trace citations current (or corrected)
- [ ] TC-2 + TC-3: guard assertions pass (else outcomes void)
- [ ] TC-4: unit scores match the matrix
- [ ] TC-5: `201` absent from candidates; `top` as expected
- [ ] TC-6: falsifying condition stated and shown not to have occurred
- [ ] No tracked file modified (read-only upheld)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All six TCs and both applicable NFR checks PASS (see g-testing-exec.md). TC-6 (falsifying condition) confirmed the finished task absent — the premise-holding outcome was defined and did not occur.

## Lessons Learned
Including an explicit falsifying test case (TC-6), not just confirming ones, is what makes a discovery verdict defensible.
