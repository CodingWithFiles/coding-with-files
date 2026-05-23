# Progress-signal inference conflict still present - Implementation Execution
**Task**: 157 (discovery)

## Task Reference
- **Task ID**: internal-157
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/157-progress-signal-inference-conflict-still-present
- **Template Version**: 2.1

## Goal
Execute the investigation per d-implementation-plan.md: trace the cliff path
(FR1), reproduce the reported scenario with a scratch fixture (FR2), and record
reproducible evidence for the verdict (FR3) and recommendation (FR4). The verdict
and recommendation are written up in g-testing-exec.md / j-retrospective.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met (scratch root, source citations)
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Actual Results

### Step 1: Setup
- **Planned**: `mkdir -m 0700 -p` the project-namespaced scratch root; note repo root for `use lib`.
- **Actual**: Created `/tmp/-home-matt-repo-coding-with-files-task-157/` (perms `drwx------`). Repo root `/home/matt/repo/coding-with-files`.
- **Deviations**: None.

### Step 2: FR1 — trace the cliff path (re-read from current source, not memory)
Each hop cited at a current file:line:

1. `_get_progress_signal` scans the relative dir `'implementation-guide'` (`TaskContextInference.pm:385`); per task dir whose name matches `^(\d+)-`, keys `%task_progress` by the leading number (`:400-403`).
2. → `_calculate_task_progress($path)` (`:402`) which returns `CWF::TaskState::state_achievable($task_dir)` (`:488`) — i.e. **post-cliff work potential, not raw completion**.
3. → `state_achievable` (`TaskState.pm:135`): `state_done` MIN-bottleneck with closed statuses (Finished/Cancelled/Skipped) counted as 100 (`:105`, `_is_closed` `:332`); then the cliff — `if ($completion >= 100) { $work_potential = 0 }` (`:150-152`). FRESH→10 (`:153-155`), DORMANT→`int(completion*0.3)` (`:156-158`), ACTIVE→completion (`:159-161`).
4. → `_score_progress($work_potential)` = `int(($wp/100)*WEIGHT_PROGRESS_MAX)`, `WEIGHT_PROGRESS_MAX=60` (`TaskContextInference.pm:447,453,27`).
5. → zero-score filter `grep { $_->{score} > 0 }` (`:418`) after a descending sort (`:417`) and top-5 splice (`:419`); `top => $candidates[0]->{task}` (`:428`).

**Conclusion (confirmed)**: a correctly-finished task (all steps terminal) → `state_done` 100 → cliff → work potential 0 → `_score_progress` 0 → dropped at the `:418` filter. It can be neither a candidate, nor `top`, nor a source of dissent, so it cannot drive an inconclusive result.

**TC-1 citation drift**: none material. The stale comment is at `TaskContextInference.pm:410` (`# Score tasks by progress (bell curve, peak at 50%)`); the misleading parameter name `$percentage` is at `:447`. Note the comment *inside* `_score_progress` (`:450-452`) is already accurate ("higher work potential = higher score … Cliff function from state_achievable") — only the `:410` comment and the `:447` parameter name misdescribe the function.

### Step 3: FR2 — build the fixture (scratch)
- **Planned**: three `<num>-feature-<slug>` dirs, two files each (`a-task-plan.md` + `f-implementation-exec.md`), each with a `## Status` heading + `**Status**:` line.
- **Actual**: built under `.../task-157/implementation-guide/`:
  - `201-feature-finished/` — both files `**Status**: Finished`
  - `202-feature-backlog/` — both files `**Status**: Backlog` (the "task 104" role: low-progress, non-active)
  - `203-feature-active/` — `a-task-plan.md` `Backlog` + `f-implementation-exec.md` `In Progress`
- **Deviations**: None. Two files per dir suffice — `_get_all_statuses` skips absent files (`TaskState.pm:320`) and `f-implementation-exec.md` presence triggers v2.1 detection (`:304`); both filenames are in the v2.1 `feature` set (`WorkflowFiles/V21.pm:51,56`).

### Step 4: FR2 — write and run the probe
- **Planned**: throwaway Perl probe; standard preamble; status-map guard + parse-success guard before trusting the candidate list; unit (absolute paths, pre-chdir) then integration (chdir, `_get_progress_signal`).
- **Actual**: `probe.pl` written and run:
  ```
  chmod +x /tmp/-home-matt-repo-coding-with-files-task-157/probe.pl
  PERL5OPT=-CDSLA /tmp/-home-matt-repo-coding-with-files-task-157/probe.pl
  ```
  Exit code 0. Captured output (`probe.out`):
  ```
  == Guard 1: status map in force ==
  PASS  status_percent('Finished') = 100
  PASS  status_percent('Backlog') = 0
  PASS  status_percent('In Progress') = 25

  == Guard 2: fixtures parsed (state_done) ==
  PASS  state_done(201 finished) = 100
  PASS  state_done(202 backlog) = 0
  PASS  state_done(203 active) = 25

  == Unit: state_achievable -> _score_progress (absolute paths, pre-chdir) ==
    201 finished   wp=0   score=0   (expect wp=0 score=0)
    202 backlog    wp=10  score=6   (expect wp=10 score=6)
    203 active     wp=25  score=15  (expect wp=25 score=15)

  == Integration: _get_progress_signal against synthetic tree ==
    null = 0
    top  = 203
    candidates:
      task=203  score=15
      task=202  score=6

  == Observations ==
  PASS  201 (finished) absent from candidates
  PASS  top == 203 (active out-scores backlog)
  PASS  202 (backlog) present with score 6
  ```
- **Deviations**: None. Both guards passed, so the `201` exclusion is attributable to the cliff (work potential 0), not to a parse failure (`state_done(201)==100` proves it parsed as fully-closed).

### Step 5: Record evidence
- Trace (Step 2), probe invocation and captured output (Step 4) recorded above.
- Observed scores match the c-design fixture matrix exactly: `201`→0/filtered, `202`→6, `203`→15; `top`=203.

### Step 6: Verdict + recommendation
Deferred to g-testing-exec.md (validation against ACs) and j-retrospective.md
(verdict + backlog action), per d-implementation-plan.md Step 6. Evidence here
supports: **premise is a misread** — `_score_progress` receives post-cliff work
potential, and a correctly-finished task is filtered out (`201` absent above).

## Blockers Encountered
None.

## Read-only constraint
This is a read-only discovery. No `.cwf/**` or other tracked source file was
modified. All artefacts (fixture, `probe.pl`, `probe.out`) live in
`/tmp/-home-matt-repo-coding-with-files-task-157/` and are throwaway.

## Security Review

**State**: no findings

no findings: empty changeset

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md addressed (verdict/rec finalised in j)
- [x] All requirements from b-requirements-plan.md addressed (FR1-FR4 evidence captured; FR3/FR4 written up in g/j)
- [x] All design guidance in c-design-plan.md followed (two-level evidence, scratch fixture, guards)
- [x] No planned work deferred without approval (verdict/rec deferral to g/j is per the plan)

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
`_score_progress`'s input is the post-cliff work potential (`_calculate_task_progress:488 → state_achievable`), not raw completion. The misleading param name `$percentage` (`:447`) and the stale `:410` comment are the root of the misread; the comment inside `_score_progress` (`:450-452`) is already accurate. See j-retrospective.md.
