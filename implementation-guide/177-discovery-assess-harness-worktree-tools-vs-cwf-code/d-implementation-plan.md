# Assess harness worktree tools vs CWF code - Implementation Plan
**Task**: 177 (discovery)

## Task Reference
- **Task ID**: internal-177
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/177-assess-harness-worktree-tools-vs-cwf-code
- **Template Version**: 2.1

## Goal
Execute the investigation designed in c-design-plan.md: gather cited evidence,
fill the two tables in `f-implementation-exec.md`, and rewrite the backlog item
via the helper. No CWF production code changes.

## Workflow
Gather evidence → record with citation → assign verdict + relevance → synthesise
reframing → rewrite backlog via helper → record what changed and why.

## Files to Modify
### Primary Changes
- `implementation-guide/177-.../f-implementation-exec.md` — the findings: claims
  table (C1–C5), call-site inventory table, deferred-tool note, synthesis.
- `BACKLOG.md` — the durable deliverable: the "Adopt guarded
  EnterWorktree/ExitWorktree…" entry, rewritten **only** through
  `cwf-backlog-manager` (delete+add or retire+add; never a direct edit).

## Implementation Steps

### Step 1: Source gathering
- [ ] `ToolSearch "select:EnterWorktree,ExitWorktree"`; copy the verbatim schema
      fragments bearing on C1 (EnterWorktree-only scope / no-op otherwise),
      C2 (refuses on uncommitted changes unless `discard_changes`), C3 (`fresh`
      default branches from `origin/<default>`), C4 (`head` branches from
      current HEAD), and any `worktree.baseRef` config text.
- [ ] Search for a current harness worktree doc; if none is reachable, record
      that gap rather than guessing.
- [ ] Re-derive the FR3 inventory from a fresh grep (do **not** copy counts from
      memory or this plan):
      - `git grep -n "git worktree" -- .cwf` (categorise add/remove/list/prune)
      - `git grep -n -- "--show-toplevel" .cwf` (enumerate every site by file:line)
      The "13 sites" figure in `feedback_worktree_cwd_dataloss` is known-stale
      (a current grep shows ~11 across ~6 files) — record the actual count, do
      not treat the mismatch as a surprise.

### Step 2: Build the inventory table (FR3)
- [ ] One row per `git worktree` occurrence and per `--show-toplevel` site, with
      file:line, category, guarded-tool-candidate?, and blocker/note.
- [ ] Explicitly state any empty category (e.g. "no `add`/`remove`/`prune`
      sites") as a finding, not an omission.
- [ ] Note that read-only `list` / `--show-toplevel` inspection sites are **not**
      candidates for `EnterWorktree`/`ExitWorktree` (they create/teardown, not
      inspect).

### Step 3: Resolve C5, then characterise the usage surface (C6)
- [ ] From the Step 2 inventory, assign C5's verdict (expected **Refuted** — no
      raw create/remove flow in CWF scripts). Record the citation as the
      inventory result.
- [ ] Decide the reframing branch — **Refuted ≠ "nothing to do"**:
      Refuted → CWF has no scripted worktree flow, but worktrees are used with
      CWF via undefined/unguarded paths (C6), so the feature is to **define a
      robust, guarded worktree process** around the harness tools; Confirmed →
      additionally route the scripted flow through the guarded tools.
- [ ] Characterise C6 (the actual usage surface): (i) a model deciding on its own
      to run raw `git worktree add` mid-task — unguarded; (ii) the harness Agent
      `isolation: worktree`; (iii) manual operator use; (iv) `EnterWorktree`/
      `ExitWorktree` (guarded but gated). State which paths are guarded and which
      are not. This is the justification for the feature.
- [ ] Specifically flag the backlog body's own counter-example: it cites "the
      self-worktree guard in `task-workflow.d/delete`" as a raw create/remove
      flow, but that guard only runs read-only `git worktree list` and *refuses*
      (dies) when a worktree holds the branch — it never creates or force-removes
      one. Correcting this specific false claim is part of the Step 7 rewrite.

### Step 4: Build the claims table (FR1/FR2)
- [ ] One row per claim C1–C5 (+ any new claim surfaced): claim, source, verdict,
      citation, relevance-to-CWF.
- [ ] C1–C4: verdict + citation from the Step 1 schema fragments. Mark C2's
      runtime refusal **Confirmed-by-schema**; note the runtime residual as
      **Unverifiable-by-safe-probe** per design Decision 4 (no removal probe by
      default; record the skip + reason).
- [ ] Relevance column: if C5 is Refuted, mark C1 (and any guard-dependent claim)
      **Moot** with the one-line reason, so the rewrite cannot resurrect a dead
      premise.

### Step 5: Deferred-tool assessment (FR5)
- [ ] State whether a CWF skill / acting model can reliably invoke
      `EnterWorktree`/`ExitWorktree` given they are deferred (load via
      `ToolSearch`) **and** gated to explicit user/project instruction. Note the
      consequence for any future adoption (e.g. a skill must trigger a
      `ToolSearch` load and obtain explicit authorisation first).

### Step 6: Synthesis
- [ ] Short prose summary: which premises held, which fell, the C6 usage surface,
      and the resulting framing — the feature is to **define a guarded worktree
      process** built on the harness tools (it stays a feature; C5-Refuted
      reframes, does not retire).

### Step 7: Rewrite the backlog item (FR6) — the deliverable
- [ ] Draft the new entry body and **write it to a project-namespaced scratch
      file first** (`.cwf/docs/conventions/tmp-paths.md`; no heredocs/inline
      bodies per `feedback_no_heredocs`). This file is the recovery source, so
      it must exist before any destructive helper op.
- [ ] `cwf-backlog-manager <subcmd> --help` to confirm the body-rewrite path.
      `modify` is `--priority`-only, so a body rewrite needs delete+add or
      retire+add — confirm at exec, do not assume. Pass the body via
      `--body-file=<scratch>` (not inline `--body`); other args list-form/opaque.
- [ ] Rewrite the entry: confirmed facts as facts; refuted premises removed/
      flagged; Unverifiable items listed as open questions; reframe around C6
      (define a guarded worktree process) — keep it a feature, do **not** retire
      on C5 alone; correct the false `task-workflow.d/delete` example.
- [ ] **Partial-failure recovery**: delete+add and retire+add are two ops. If the
      first (delete/retire) succeeds but the `add` fails, do **not** proceed —
      re-run `add --body-file=<scratch>` from the saved file; never leave zero
      live entries. (The body also persists in `f-implementation-exec.md`.)
- [ ] **Post-rewrite single-entry assertion**: `backlog-manager validate --all`
      checks *format*, not entry count — additionally confirm via
      `backlog-manager list` (grep the title) that **exactly one** live
      "Adopt guarded EnterWorktree/ExitWorktree…" entry remains (no stale
      duplicate, no zero). Observe and report every helper exit code.

## Code Changes
N/A — discovery produces documents + a helper-mediated backlog edit; no source
code is modified.

## Test Coverage
**See e-testing-plan.md** — verification is a checklist against the FR ACs
(every claim cited, inventory complete, helper exit code 0, single live entry).

## Validation Criteria
**See e-testing-plan.md** for the full checklist.

## Scope Completion
**IMPORTANT**: Complete all steps before marking Finished. The backlog rewrite
(Step 7) is the deliverable — do not stop after the findings tables. If the user
must review findings before the rewrite, that pause is explicit, not a silent
deferral.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 7 steps executed. Step 7 paused for operator review before the backlog rewrite
(explicit gate), then completed via `delete`+`add` with `--body-file`; single-live-entry
assertion passed (validate exit 0, count 1). No production code touched.

## Lessons Learned
The scratch-file-first + partial-failure-recovery plan for the delete+add made the
only durable mutation safe; the recovery path didn't fire. See `j-retrospective.md`.
