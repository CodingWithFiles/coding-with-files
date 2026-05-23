# Progress-signal inference conflict still present - Implementation Plan
**Task**: 157 (discovery)

## Task Reference
- **Task ID**: internal-157
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/157-progress-signal-inference-conflict-still-present
- **Template Version**: 2.1

## Goal
Execute the investigation defined in the design: trace the cliff path (FR1),
run the scratch-fixture probe to reproduce the reported scenario (FR2), and
record the verdict (FR3) and recommendation (FR4).

## Workflow
Trace → fixture → probe → record evidence → verdict → recommendation

## Files to Modify
### Primary Changes
- **None in the repository.** This is a read-only discovery; no `.cwf/**` or other tracked file is edited in this task.

### Artefacts produced (not committed as code)
- Scratch fixture + probe under `/tmp/-home-matt-repo-coding-with-files-task-157/` (throwaway).
- `f-implementation-exec.md` — records the trace, probe commands, and observed output (committed as the wf record).
- `g-testing-exec.md` — validates the evidence against the b-phase ACs.
- `j-retrospective.md` — verdict + the concrete backlog action (retire / rescope).

## Implementation Steps
### Step 1: Setup
- [ ] `mkdir -m 0700 -p /tmp/-home-matt-repo-coding-with-files-task-157` (scratch root; `-p` makes the 0700 first-use guard idempotent, per tmp-paths convention)
- [ ] Note repo root for the probe's `use lib "$repo/.cwf/lib"`

### Step 2: FR1 — trace the cliff path
- [ ] Record each hop with current file:line:
  - `_get_progress_signal` scans relative `'implementation-guide'` (`TaskContextInference.pm:385`)
  - → `_calculate_task_progress($path)` (`:402`)
  - → `CWF::TaskState::state_achievable($dir)` → `state_done` MIN bottleneck, closed statuses = 100 (`TaskState.pm:105`) → cliff `completion >= 100 → 0` (`TaskState.pm:150`)
  - → `_score_progress($work_potential)` = `int(($wp/100)*60)` (`TaskContextInference.pm:453`)
  - → zero-score filter `grep { $_->{score} > 0 }` (`:418`), then `sort`/`splice`, `top` (`:417-428`)
- [ ] State the conclusion: a correctly-finished task (all steps terminal) → completion 100 → work potential 0 → score 0 → filtered out

### Step 3: FR2 — build the fixture (scratch)
- [ ] Create three task dirs under `.../task-157/implementation-guide/`, each named `<num>-feature-<slug>`, each containing **two** files (`_get_all_statuses` reads only existing files in the type's set; `f-implementation-exec.md` presence also triggers v2.1 detection — `TaskState.pm:304`, set confirmed in `WorkflowFiles/V21.pm:50-57`):
  - `201-feature-finished/`: `a-task-plan.md` + `f-implementation-exec.md`, both `**Status**: Finished` → completion 100 → cliff → 0 (filtered)
  - `202-feature-backlog/`: both `**Status**: Backlog` → completion 0, no active → FRESH → 10 → score 6 (the 104 role)
  - `203-feature-active/` *(optional)*: `a-task-plan.md` `**Status**: Backlog` + `f-implementation-exec.md` `**Status**: In Progress` → completion 25, active → 25 → score 15
- [ ] Each file must contain a `## Status` section heading **and** a `**Status**: <value>` line — `find_field_line` only matches the key inside the section (`MarkdownParser.pm`); a bare `**Status**:` with no heading parses as "Unknown"
- [ ] Note: two files per dir intentionally narrows the design's "full v2.1 set" wording — `_get_all_statuses` skips absent files (`TaskState.pm:320`), so two suffice; deliberate, not an oversight

### Step 4: FR2 — write and run the probe
- [ ] Write `/tmp/-home-matt-repo-coding-with-files-task-157/probe.pl` via the Write tool (no heredocs/inline `-e`); preamble `#!/usr/bin/env perl`, `use utf8;`, run under `PERL5OPT=-CDSLA`
- [ ] Probe contents:
  - `use lib "$repo/.cwf/lib"`; `use CWF::TaskState qw(state_achievable status_percent state_done);` `use CWF::TaskContextInference;`
  - **Status-map assertion** (config-source independent): `status_percent('Finished')==100`, `('Backlog')==0`, `('In Progress')==25`
  - **Parse-success assertion** (guards against a malformed fixture silently faking the verdict — a missing `## Status` heading makes `status_get` return "Unknown" and would exclude `201` for the *wrong* reason): assert `state_done(201)==100`, `state_done(202)==0`, `state_done(203)==25` (203 only if built) before trusting the candidate list
  - Unit (pass **absolute** fixture dir paths, before any chdir): for each fixture dir print `state_achievable($dir)` and `CWF::TaskContextInference::_score_progress(...)`
  - Integration: `chdir` into the fixture root **immediately before this call only**, then `CWF::TaskContextInference::_get_progress_signal()`; print `candidates` (task+score) and `top`
- [ ] `chmod +x probe.pl && PERL5OPT=-CDSLA /tmp/.../probe.pl > /tmp/.../probe.out 2>&1`
- [ ] Read `probe.out`; confirm all assertions passed, `201` absent from candidates, and `top` matches expectation (`top==202` if `203` omitted; `top==203` if built)

### Step 5: Record evidence (f-implementation-exec.md)
- [ ] Paste the trace (Step 2), the probe invocation, and the captured candidate list / `top`
- [ ] Cross-check observed scores against the design fixture matrix (201→0/filtered, 202→6, 203→15)

### Step 6: Verdict + recommendation (deferred to g / j)
- [ ] FR3 verdict (holds / misread) with the falsifying condition explicitly addressed
- [ ] FR4 recommendation: retire, or rescope to clarity chore (rename `$percentage` `TaskContextInference.pm:447`; delete stale comment `:410`) — naming behaviour-change implication (expected: none)

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete the trace, the probe run, and the recommendation before
marking the task Finished. The deliverable is the recorded evidence + verdict +
the concrete backlog action — not just "the code looks right". Do not edit any
`.cwf/**` file in this task; the clarity fix (if recommended) is a separate task
with a same-commit `script-hashes.json` refresh.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All steps executed (see f-implementation-exec.md). Fixture built with two files per dir; probe ran clean (rc=0) with both guard layers passing. No tracked file modified.

## Lessons Learned
The parse-success guard (`state_done(201)==100`) was the step that mattered most: without it, a malformed fixture could have excluded the finished task for the wrong reason and faked the verdict.
