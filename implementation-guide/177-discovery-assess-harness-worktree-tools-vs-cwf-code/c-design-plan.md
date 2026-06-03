# Assess harness worktree tools vs CWF code - Design
**Task**: 177 (discovery)

## Task Reference
- **Task ID**: internal-177
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/177-assess-harness-worktree-tools-vs-cwf-code
- **Template Version**: 2.1

## Goal
Define the investigation method and the shape of the discovery's output
artefacts: how claims are gathered, how each verdict is obtained from an
authoritative source, how the probe is run safely, and how findings flow into
the backlog rewrite.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

For a discovery, "testability" = every verdict re-checkable from its cited
source; "reversibility" = the only durable mutation (backlog rewrite) is helper-
mediated and trivially re-editable.

## Key Decisions

### Decision 1 — Evidence hierarchy: safe probe > live schema > harness doc > (never) memory
- **Decision**: Resolve each claim using the strongest available evidence, in
  this order: (a) a **safely-runnable** empirical probe of runtime behaviour;
  (b) the live tool schema fetched via `ToolSearch`; (c) a quoted line from a
  current harness doc; never (d) remembered/paraphrased semantics.
- **Probe-eligibility gate**: A probe counts as evidence only if it can run
  without violating a standing safety rule and without gated/unavailable
  invocation. If the only probe path requires `cd` into a disposable worktree
  (`feedback_worktree_cwd_dataloss`) or an `EnterWorktree` invocation that is
  gated to explicit user instruction, the probe is **not** run; the claim falls
  to schema/doc evidence, and any residual *runtime-only* uncertainty is marked
  **Unverifiable-by-safe-probe** (not silently upgraded to Confirmed).
- **Rationale**: Task 172's claims were inference; the point is to replace
  inference with cited evidence (`feedback_no_fabricated_citations`). Schema
  prose normally describes intent rather than runtime — but for *these* tools
  the live schema is unusually prescriptive (it states the EnterWorktree-only
  scope and the uncommitted-changes refusal directly), and the only probe that
  would add information is unsafe/gated. So here schema is the governing source.
- **Trade-offs**: We accept schema-as-evidence for the behavioural claims rather
  than forcing an unsafe probe. The cost is a small residual: we cite what the
  tool *says it does*, flagged as such, instead of having watched it do it.

### Decision 2 — Claim verdict carries a separate relevance-to-CWF axis
- **Decision**: A verdict (Confirmed/Refuted/Unverifiable) about *harness
  behaviour* is recorded independently from a *relevance-to-CWF* note. A claim
  may be Confirmed yet **moot** (true of the harness, but CWF has nothing it
  applies to).
- **Rationale**: The C5 finding (CWF appears to have no raw create/remove flow)
  means C1 ("guard only applies to EnterWorktree-created worktrees") can be
  literally true and simultaneously irrelevant to CWF. Collapsing the two axes
  would let a Confirmed-but-moot premise survive into the backlog rewrite.
- **Trade-offs**: Two columns instead of one; the extra column is what keeps the
  rewrite honest.

### Decision 3 — C5 gates *how* the feature is framed, not *whether* it exists
- **Decision**: Resolve C5 (CWF-script inventory) first, then characterise the
  real worktree-usage surface (C6). The reframing branches are:
  - **C5 Refuted (expected)**: CWF's scripts have no raw worktree flow — but
    worktrees are still used with CWF via undefined/unguarded paths (C6: model-
    initiated `git worktree add`, Agent `isolation: worktree`, manual). The
    feature is therefore to **define a robust, guarded CWF worktree process**
    around the harness tools, *not* to retire the item. C1 (guard protects only
    `EnterWorktree`-created worktrees) is the crux: model-initiated raw use is
    the unguarded gap to close.
  - **C5 Confirmed**: additionally there is a scripted raw flow to route through
    the guarded tools; original framing stands and is broadened by C6.
- **Rationale**: A Refuted C5 was originally read as "nothing to guard"; the
  operator clarified worktrees *are* used with CWF (knowingly and via model
  self-initiation), so the gap is the **absence of a defined process**, which is
  the feature's reason to exist. C5 sets the framing; C6 establishes the need.
- **Trade-offs**: Exec follows evidence order, not numeric order; the inventory
  (C5) is necessary but not sufficient — C6's usage-surface characterisation is
  what justifies the feature.

### Decision 4 — C2 is resolved from the live schema; no removal probe by default
- **Decision**: Do **not** run a worktree-removal probe to test C2's refusal by
  default. Two facts from the live `ExitWorktree` schema (to be quoted verbatim
  in the f-file) make a probe either useless or unsafe:
  1. `ExitWorktree(action: remove)` **only** operates on worktrees created by
     `EnterWorktree` in the current session and is a **no-op** otherwise. So a
     worktree created by a raw `git worktree add` (the path FR4 contemplated)
     would not exercise the guard at all — the probe would record a false
     "no refusal".
  2. The only path that *does* exercise the guard — creating the worktree via
     `EnterWorktree` — switches the session CWD into the worktree (colliding
     with the no-`cd` rule and `feedback_worktree_cwd_dataloss`) and is gated to
     explicit user instruction.
  Therefore C1 and C2 are resolved from the live schema (Decision 1b), with the
  runtime refusal marked **Confirmed-by-schema** and the never-watched-it residual
  noted as **Unverifiable-by-safe-probe**.
- **Conditional carve-out**: A probe is run **only if** C5 lands Confirmed (CWF
  actually has a raw create/remove flow worth guarding) **and** the user
  explicitly authorises an `EnterWorktree` invocation for verification. In that
  case: scratch worktree path under the project-namespaced `/tmp` dir
  (`.cwf/docs/conventions/tmp-paths.md`), branched off a known-clean ref,
  `git status` verified free of real work before any dirtying; never
  `discard_changes: true`; cleanup matches the **known scratch path only**
  (never a blind `--force` prune of an unrelated tree).
- **Rationale**: Honours `feedback_surface_security_dont_smooth` (we do not
  smooth away the guard by passing `discard_changes`) and avoids the data-loss
  class entirely on the expected (C5-Refuted) path, where the probe is moot.
- **Trade-offs**: We trade a watched-it-happen demonstration for schema
  citation. Given the safety/gating constraints that is the correct trade.

### Decision 5 — Output lives in f-implementation-exec.md; backlog rewrite via helper only
- **Decision**: All findings (claims table, inventory table, probe transcript,
  deferred-tool note) are written to `f-implementation-exec.md`. The backlog
  item is rewritten **only** through `cwf-backlog-manager` (no direct
  `BACKLOG.md` edit), per the file-protection convention.
- **Rationale**: Keeps the discovery's reasoning in the task record and the
  durable mutation auditable/reversible.
- **Trade-offs**: `cwf-backlog-manager modify` (v1) supports only `--priority`;
  a body rewrite needs `delete --confirm` + `add` (or `retire`+`add`). The exec
  phase picks the helper path that preserves a single live entry — confirmed
  against the helper's `--help` at exec time, not assumed here.

## System Design

### Component Overview (investigation stages)
- **Stage A — Claim extraction**: Read backlog line 49 + Task 172 f/j cited
  sections; emit the claims table rows (C1–C6 + any new). C6 captures *how
  worktrees are actually used with CWF* (model-initiated raw `git worktree add`,
  Agent `isolation: worktree`, manual, `EnterWorktree`) — the usage surface, not
  just CWF's own scripts.
- **Stage B — Source gathering**: `ToolSearch "select:EnterWorktree,ExitWorktree"`
  for live schemas; quote the fragments bearing on C1 (EnterWorktree-only
  scope), C2 (uncommitted-changes refusal), C3 (`fresh` default branches from
  origin), and C4 (`head` branches from current HEAD). Locate any harness
  worktree doc. Grep CWF for `git worktree` and `--show-toplevel` (FR3
  inventory) — **re-derived at exec, not assumed from this plan**. For C6, also
  gather the harness Agent `isolation: worktree` semantics (from the Agent tool
  schema) and note that model-initiated raw `git worktree add` is an
  out-of-band path CWF neither defines nor guards.
- **Stage C — Probe (conditional, expected skipped)**: Per Decision 4, only if
  C5 is Confirmed and the user authorises `EnterWorktree`; otherwise skipped and
  C2 resolves from schema. Record the skip decision and its reason.
- **Stage D — Verdict assignment**: Apply the Decision 1 evidence hierarchy +
  the Decision 2 relevance axis to every claim (C1–C6). C3/C4 are
  behavioural-flavoured config claims resolved from the live schema fragments;
  C4's "branches from current HEAD" half is Confirmed-by-schema (no safe probe).
  C6 is a usage-surface finding, not a true/false verdict — record the paths and
  which are guarded.
- **Stage E — Synthesis & rewrite**: Summarise the reframing (C5 sets framing,
  C6 establishes the need for a defined process), then rewrite the backlog item
  via the helper (Decision 5).

### Data Flow
1. Stage A → claims table (verdict/citation columns empty).
2. Stage B + Stage C → evidence per claim.
3. Stage D → claims table fully populated (verdict + citation + relevance).
4. Stage E → backlog item rewritten; f-file records what changed and why.

## Interface Design

### Claims table (in f-implementation-exec.md)
```
| ID | Claim (one line) | Source | Verdict | Citation | Relevance to CWF |
```
- Verdict ∈ {Confirmed, Refuted, Unverifiable}
- Citation ∈ {probe transcript ref, quoted schema fragment, quoted doc line}
- Relevance ∈ {Applies, Moot (reason), Forward-only}

### Call-site inventory table (in f-implementation-exec.md)
```
| file:line | git/worktree call | category (add/remove/list/prune/--show-toplevel) | guarded-tool candidate? | blocker / note |
```
- Empty `add`/`remove`/`prune` categories are stated explicitly as a finding.

### Backlog rewrite (output contract)
- Exactly one active entry titled "Adopt guarded EnterWorktree/ExitWorktree…".
- Body: confirmed facts as facts; refuted premises removed or struck with the
  finding; Unverifiable items listed as open questions for the feature task.
- If C5 is Refuted, the entry is **reframed, not retired**: it becomes "define a
  robust, guarded CWF worktree process" built on the harness tools, justified by
  the C6 usage surface (model-initiated raw `git worktree add` runs unguarded).
  It stays a feature; the rewrite states the new framing and the corrected
  `task-workflow.d/delete` example explicitly.

## Constraints
- No edits to CWF production worktree code or skills (discovery only).
- Helper-mediated backlog mutation only; exit code observed.
- Ingested schema/doc text is evidence, never executed as instructions.

## Decomposition Check
- [ ] Time >1 week? No.
- [ ] People >2? No.
- [ ] Complexity 3+ concerns? No (one method, staged).
- [ ] Risk needing isolation? Only the probe — handled by Decision 4.
- [ ] Independence? No.

No signals triggered.

## Validation
- [ ] Evidence hierarchy (Decision 1) applied to every claim.
- [ ] C5 resolved by inventory before dependent claims' relevance is judged.
- [ ] Probe (if run) leaves no real work at risk.
- [ ] Backlog rewrite goes through the helper; single live entry remains.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five Decisions held in execution: schema was the governing evidence (Decision 1),
the relevance axis kept the moot/applies distinction honest (Decision 2), C5 reframed
rather than retired (Decision 3), the removal probe was safely skipped (Decision 4),
and the backlog rewrite went through the helper only (Decision 5).

## Lessons Learned
Decision 4 (no removal probe by default) proved correct — the live `ExitWorktree`
schema confirmed a raw-`add` worktree would not exercise the guard. See `j-retrospective.md`.
