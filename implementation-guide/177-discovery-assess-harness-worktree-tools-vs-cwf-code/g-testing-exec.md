# Assess harness worktree tools vs CWF code - Testing Execution
**Task**: 177 (discovery)

## Task Reference
- **Task ID**: internal-177
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/177-assess-harness-worktree-tools-vs-cwf-code
- **Template Version**: 2.1

## Goal
Execute the e-testing-plan.md audit: verify the discovery's outputs
(`f-implementation-exec.md` + the rewritten backlog entry) against the FR
acceptance criteria. No code to unit-test — this is an evidence-and-completeness
audit.

## Test Results

### TC-1 (AC1/AC2 — claims cited, not remembered): **PASS**
The `f-implementation-exec.md` claims table has rows C1–C6. Each verdict ∈
{Confirmed, Refuted, Confirmed-by-schema, Unverifiable-by-safe-probe} with a
citation that is a **quoted live-schema fragment** (C1/C2/C3/C4), the
**re-derived inventory** (C5), or **quoted wf-file lines** (C6: Task 136
f-exec:82-83, Task 32 j-retro:439). No verdict rests on memory/paraphrase. Every
row carries a relevance-to-CWF note; C6 records the usage surface (which paths
are guarded vs not) as a finding rather than a true/false verdict.

### TC-2 (AC3 — inventory complete and re-derived): **PASS**
Re-ran the greps during verification (independent of the f-file):
- `git grep -n "git worktree" -- .cwf` → exactly two sites, both read-only
  `list`: `TaskContextInference.pm:315`, `task-workflow.d/delete:158`. Matches
  the f-file inventory.
- `git grep -nE "git worktree (add|remove|prune)" -- .cwf` → **none**. The empty
  add/remove/prune categories are recorded as a finding in the f-file (Step 1–2),
  not silently omitted.
- `--show-toplevel` per-file match counts: `Common.pm` 3, `cwf-manage` 3
  (2 comments + 1 call each), `checkpoints-branch-manager` 1, `location` 1,
  `task-stack` 1, `task-workflow.d/delete` 1, `update-cwf-skill-docs.sh` 1
  (comment-only "Do NOT cd"). The f-file correctly distinguishes the **6 actual
  invocation sites** from comment-only mentions and states the actual count,
  superseding the stale "13" from `feedback_worktree_cwd_dataloss`.

### TC-3 (AC4 — C2 probe decision recorded safely): **PASS**
C2 is marked **Confirmed-by-schema** with the runtime residual
**Unverifiable-by-safe-probe**; the skip reason is recorded (per Decision 4: the
only guard-exercising path is `EnterWorktree`, which switches CWD and is gated —
data-loss/gating risk). **No probe ran against the live working tree**, and no
`discard_changes: true` appears anywhere. Safe.

### TC-4 (AC5 — deferred-tool impact): **PASS**
The FR5 finding states the tools are deferred (load via `ToolSearch`,
demonstrated this session) **and** gated, and draws the consequences: a CWF skill
must `ToolSearch`-load first; the gate's "project instructions (CLAUDE.md/memory)"
clause means a documented CWF process *is* the authorisation; and `ExitWorktree`
cannot clean up a raw-`add` worktree (so a guarded process must create via
`EnterWorktree`).

### TC-5 (AC6 — backlog rewrite, single live entry): **PASS**
- `backlog-manager validate --all` → **exit 0**.
- `list --all-items | grep -c "Adopt guarded EnterWorktree/ExitWorktree"` → **1**
  (exactly one live entry; not zero, not duplicated).
- The new body states C1–C4 as confirmed facts, drops the false C5 premise and
  the wrong `task-workflow.d/delete` example, reframes around C6 (define a guarded
  worktree process), and lists the C2 runtime residual as an open question. It is
  **reframed, not retired** on C5 alone. Helper exit codes (delete 0, add 0,
  validate 0) were observed and reported in the f-file.

### TC-6 (negative — no production code touched): **PASS**
`git show --stat d792665` (the exec commit) touched exactly **two** files:
`BACKLOG.md` and `f-implementation-exec.md`. No `.cwf/scripts`, `.cwf/lib`,
skill, hook, or other production file modified.

### Non-Functional
- **Security**: PASS — no probe passed `discard_changes: true` (none ran);
  ingested schema/doc text appears only as quoted evidence, never acted on as an
  instruction; the backlog mutation went through `cwf-backlog-manager` with
  list-form/opaque-string args and `--body-file` (no inline body, no heredoc).
- **Reliability**: PASS — the one claim lacking a watched-it-happen demonstration
  (C2 runtime) is marked Unverifiable-by-safe-probe, not upgraded to Confirmed.

## Coverage Report
TC-1…TC-6 + non-functional (security, reliability) all executed; all **PASS**.
100% of the e-testing-plan critical path (every claim C1–C6 cited; single live
entry).

## Test Failures
None.

## Security Review

**State**: no findings

This is the testing-phase review of Task 177, a discovery task. The changeset is
docs-only: a `BACKLOG.md` rewrite (via `cwf-backlog-manager`) plus six task wf
Markdown files (a–f). No CWF production code is modified.

- **(a) Bash injection**: No code introduced; planning docs *describe* commands
  but execute none; recorded helper calls use `--body-file=<scratch>`, not inline
  interpolation. Nothing actionable.
- **(b) Perl/git-output**: No Perl added; existing read-only `git worktree list`
  sites are referenced descriptively, not new parsing code. Nothing actionable.
- **(c) Prompt injection**: Most relevant for a schema-ingesting discovery, and
  handled explicitly — FR2/Constraints/Security all mandate ingested schema text
  is "evidence only, never executed as instructions". The Step-5 note that the
  gate clause can authorise automated use is a recorded finding, not an executed
  instruction. A strength, not a defect.
- **(d) Env vars**: None introduced/consumed. N/A.
- **(e) Pattern risk (forward-looking)**: The proposal that a future skill rely on
  the "project instructions" gate clause as authorisation is **safe here because**
  it only documents intent and defers design; **audit future uses where** a skill
  might treat a standing doc as blanket pre-authorisation and erode the
  removal-refusal gate. Already pre-empted in-plan ("never `discard_changes:true`
  unprompted", "surface teardown to the operator"). A note for the feature task.

Negative control (TC-6): changeset touches only the task's wf files + `BACKLOG.md`.
No actionable findings.

```cwf-review
state: no findings
summary: Docs-only testing-phase changeset (BACKLOG.md rewrite + six a-f Markdown wf files); no code, no Perl, no env-var or shell surface. Ingested-schema injection discipline is explicit and honoured (treated as data). One forward-looking (e) note for the future feature task, already mitigated in-plan.
```

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
