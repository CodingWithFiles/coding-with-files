# Progress-signal inference conflict still present - Design
**Task**: 157 (discovery)

## Task Reference
- **Task ID**: internal-157
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/157-progress-signal-inference-conflict-still-present
- **Template Version**: 2.1

## Goal
Define the investigation method: how the cliff path is traced (FR1) and how the
reported 103-vs-104 scenario is reconstructed and exercised against the live
progress signal (FR2), producing reproducible evidence for the verdict (FR3)
and recommendation (FR4).

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

For a discovery the deliverable is *evidence*, so the priority is reproducibility
and minimal moving parts: prefer calling existing module functions over building
new harness code, and keep all generated artefacts in scratch so the repo is
untouched (reversibility).

## Key Decisions

### Decision 1 — Two-level evidence, not one
- **Decision**: Answer FR1 by static source trace, and FR2 by an executable probe at two fidelities: (a) unit — call `state_achievable($dir)` then `_score_progress(...)` per fixture task; (b) integration — call `_get_progress_signal()` against a synthetic `implementation-guide/` tree.
- **Rationale**: The static trace proves the finished-task *exclusion* deductively, but the task's premise is empirical ("are we *still* getting conflicts"). The probe guards against a static-read error — exactly the `{code} != {purpose}` trap this task exists to avoid — and the integration level is the only one that exercises the dir-scan + zero-score filter (`TaskContextInference.pm:418`) end-to-end.
- **Trade-offs**: A reviewer noted the unit layer alone could prove the scores, making the integration layer redundant. Kept it because it is the only level that exhibits what the backlog actually claims — the *candidate-list assembly* (`sort`/`grep`/`splice`) and the `top` selection in `_get_progress_signal` (`TaskContextInference.pm:417-428`). The unit layer proves a finished task scores 0; only the integration layer proves it is therefore *absent from the candidate list and not `top`*, which is the reported symptom. Accepted cost: a small scratch fixture.

### Decision 2 — Fixture lives in scratch, never the tracked tree
- **Decision**: Build the fixture `implementation-guide/` under `/tmp/-home-matt-repo-coding-with-files-task-157/` (`mkdir -m 0700`). The integration probe `chdir`s into the fixture root before calling `_get_progress_signal()` (which scans the relative path `'implementation-guide'`, `TaskContextInference.pm:385`).
- **Rationale**: `_get_progress_signal` scans the live `implementation-guide/`; running it against the real tree would (a) be non-deterministic and (b) read tracked state. A synthetic tree isolates the test. Per tmp-paths convention.
- **Trade-offs**: Config/status-map resolution is independent of the verdict. `load_config()` keys off `git rev-parse --show-toplevel` (`WorkflowFiles.pm:159`), and both `_config_cache` (`WorkflowFiles.pm:153`) and `_status_map_cache` (`TaskState.pm:272`) are process-lifetime caches resolved on first use — so whichever config is seen first wins, and the `chdir` does not reliably force a defaults fallback (an earlier unit call, made while still in the repo, would cache the real config). It does not matter: the real `implementation-guide/cwf-project.json` status-values are identical to `%DEFAULT_STATUS_MAP` for every value the fixture uses (Finished 100, Backlog 0, In Progress 25), so the matrix outcomes hold regardless of source. The probe asserts those three values are in force — not that any fallback fired (the two maps are indistinguishable on these keys). The `chdir` is still required for `_get_progress_signal`'s relative `'implementation-guide'` scan; the only invariant that matters there is that the scratch dir is outside any git tree.

### Decision 3 — Reuse module functions; the probe is throwaway
- **Decision**: The probe is a single throwaway Perl script in scratch with the standard preamble (`#!/usr/bin/env perl`, `use utf8;`, run under `PERL5OPT=-CDSLA` per `docs/conventions/perl.md`, since it reads UTF-8 status markers). It does `use lib "$repo/.cwf/lib"` and calls the functions directly (`state_achievable` is exportable via `@EXPORT_OK`, imported with `use CWF::TaskState qw(state_achievable)`; `_score_progress` / `_get_progress_signal` called fully-qualified). It asserts the three status-map values it depends on at start. No new code under `.cwf/`.
- **Rationale**: Core-Perl-only, no new dependencies (NFR3). Calling the real functions — not a re-implementation — is what makes the evidence trustworthy.
- **Trade-offs**: Calling private subs by fully-qualified name is mildly intrusive, but it is read-only and discarded with the scratch dir.

## System Design

### Component Overview (investigation activities)
- **Trace (FR1)**: Read-only walk of the scoring chain, citing file:line at each hop. No code execution.
- **Fixture builder**: Writes three synthetic task dirs into scratch `implementation-guide/` with status markers chosen to hit three `state_achievable` branches.
- **Probe**: Computes per-task `state_achievable` + `_score_progress` (unit), then `_get_progress_signal()` candidate list + `top` (integration); prints results and the status map in force.

### Data Flow (the chain under test)
1. `_get_progress_signal` scans `implementation-guide/` → per task dir → `_calculate_task_progress($dir)` (`TaskContextInference.pm:402`)
2. → `CWF::TaskState::state_achievable($dir)` → `state_done` (MIN bottleneck; closed statuses = 100, `TaskState.pm:105`) → cliff (`completion >= 100 → 0`, `TaskState.pm:150`)
3. → `_score_progress($work_potential)` → `int(($wp/100)*60)` (`TaskContextInference.pm:453`)
4. → zero-score filter `grep { $_->{score} > 0 }` (`TaskContextInference.pm:418`) → `top` = highest-scoring surviving task

### Fixture matrix (the three branches that decide the verdict)
| Fixture task | Step statuses | `state_done` | `state_achievable` branch | `_score_progress` | In candidate list? |
|---|---|---|---|---|---|
| `201-feature-finished` | all steps Finished | 100 | CLIFF → 0 | 0 | **No** (filtered) |
| `202-feature-backlog` (the 104 role) | all steps Backlog | 0 | FRESH → 10 | 6 | Yes |
| `203-feature-active` *(optional)* | one step In Progress, rest Backlog | 25 (base) | ACTIVE → 25 | 15 | Yes (`top`) |

The load-bearing pair is `201` + `202` — directly mirroring the reported
103-vs-104 case (finished vs ~10% backlog). Expected: `201` (finished) is absent
from the candidate list; `202` (backlog) survives and is `top`. `203` (active) is
optional corroboration showing a non-trivial `top` (an active task out-scores the
backlog one, so `top` becomes `203`); it is not required for the verdict. If the
finished task appears as a candidate at all, the backlog premise *holds* — the
falsifying condition (FR3).

## Interface Design
- **API Endpoints**: N/A (no service surface).
- **Data Models**: N/A.
- **Functions exercised** (existing, unchanged):
  - `CWF::TaskState::state_achievable($task_dir)` → int 0-100
  - `CWF::TaskContextInference::_score_progress($work_potential)` → int score
  - `CWF::TaskContextInference::_get_progress_signal()` → `{ candidates => [...], top => N, null => 0|1 }`

## Constraints
- Read-only on the real repo; no edits to `.cwf/lib/**` or any hash-tracked file in this task. Any clarity fix (FR4) is a separate task with a same-commit `script-hashes.json` refresh.
- v2.1 format detection requires `f-implementation-exec.md` to exist in each fixture task dir (`TaskState.pm:304`); the fixture builder must create the full v2.1 step-file set for the dir's task type.

## Decomposition Check
- [ ] **Time**: >1 week? No
- [ ] **People**: >2 people? No
- [ ] **Complexity**: 3+ distinct concerns? No
- [ ] **Risk**: High-risk components? No
- [ ] **Independence**: Parts separable? No

No decomposition signals triggered.

## Validation
- [ ] Trace hops each cite a current file:line
- [ ] Probe runs deterministically and asserts the three status values it depends on (Finished 100, Backlog 0, In Progress 25), independent of config source
- [ ] Fixture matrix outcomes observed match (or refute) the expected column

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Two-level evidence design executed as planned. The scratch fixture matrix held exactly: `201`→0/filtered, `202`→6, `203`→15; integration top=203. Config-source-independence reasoning (corrected during plan review) confirmed by the status-map guard assertions.

## Lessons Learned
Plan review caught two design errors (`find_git_root()` citation; an unreachable "chdir → defaults fallback"). Reasoning about caches and config resolution from memory is error-prone — verifying against the actual `load_config`/cache code was necessary.
