# Phase skills set own terminal status at checkpoint - Design
**Task**: 222 (feature)

## Task Reference
- **Task ID**: internal-222
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/222-phase-skills-set-own-terminal-status
- **Template Version**: 2.1

## Goal
Design the minimal change set that satisfies FR1–FR4: template status hygiene,
own-status terminal stamping for `j-retrospective` (and the Skipped case) by
**reusing** existing helpers, retention of the sweep, and a non-flaky, reuse-based
regression guard.

> **Plan-review REDUCE + pre-exec user review.** D1 deletes the redundant `f:20`
> hint (**`g:20` kept** per user review — it is canonical). D2 makes the j-stamp a
> hard precondition via `&&`-chaining. D3 drops the `workflow-steps.md` re-statement.
> D5 reuses `status_get`/`status_is_valid`/`_is_closed` (the impl REDUCE dropped the
> test-only `status_is_terminal` export — it only bought a hashed-`TaskState.pm`
> edit). **D6 (new, folded in per user review)** strengthens the Stop hook to flag
> Backlog **+ non-canonical** statuses (reusing exported `status_is_valid`),
> catching the observed `Design`/`Requirements`/`Planning` leaks without firing on
> valid in-progress work. Net hashed edits: **one** — the hook.

## Design Priorities
Correctness → Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1 — Template status hygiene (FR1)
- **Decision**: **Delete** the redundant completion-hint checkbox at
  `.cwf/templates/pool/f-implementation-exec.md.template:20`
  (`- [ ] Update status to "Implemented" when complete`). The checkpoint helper
  already sets the terminal status automatically, so an operator checkbox naming a
  *non-canonical* value is redundant and is the injection point for the leak.
  **Delete `f:20` only; keep `g:20`** (per pre-exec review) — `g`'s hint uses
  canonical `Testing`/`Finished` and reads as a deliberate testing-state cue.
  `f` is the only non-canonical token in the pool (verified by four reviewers).
  Audit the remaining templates to confirm no other non-canonical token exists.
- **Rationale**: deleting removes the leak *class* (a template instructing a hand
  status), not just the bad token — the minimal, lowest-phrasing-coupling fix.
- **Trade-offs**: none material; pool templates are not hash-tracked.

### D2 — j-retrospective own-status stamp (FR2a)
- **Decision**: Reuse `cwf-set-status <j-file> Finished` as a **scripted** step in
  `.cwf/docs/skills/retrospective-extras.md` "Retrospective Checkpoint Commit",
  immediately before `git add {task-dir}/`. A **non-zero exit must abort the
  commit** (the stamp is a precondition, not best-effort).
- **Rationale**: `j` cannot use `cwf-checkpoint-commit` (that stages a single file
  and makes its own commit; `j` stages the whole dir and is squashed).
  `cwf-set-status` wraps the same validated `CWF::TaskState::status_set`, so `j`
  is stamped by the same mechanism as a–i, with no new file and no extra commit
  (the stamp rides the retro commit and survives the squash).
- **Backstop (corrected)**: the Step-7 "Verify Task Status" sweep runs *before*
  this stamp, so it cannot backstop a *failed* stamp within the same run — the
  true backstop for a failed/absent j-stamp is the `stop-stale-status-detector`
  hook. Defence-in-depth still holds; the framing is just ordered correctly.
- **Trade-offs**: one scripted line added to the retro flow.

### D3 — Skipped case (FR2b)
- **Decision**: Reuse `cwf-set-status <phase-file> Skipped` for the rare
  present-but-skipped case. **No `workflow-steps.md` edit** — `Skipped` semantics
  and the skip-decision point are already fully defined there (lines 33–47); a
  re-statement would duplicate. At most a single cross-reference is added if a
  natural anchor exists; otherwise nothing.
- **Rationale**: under the symlink template model a skipped phase has **no file**
  (feature = 10, bugfix = 7, chore = 6, …), so there is normally **no
  committed-leak path**. AC3 is discharged by that argument plus the sweep
  catching any present non-terminal file; the existing helper covers the rare
  present-file case. `status_set` already rejects non-canonical values, so no new
  validation is needed. D5 adds a `Skipped` fixture so the guard *proves* the
  predicate treats `Skipped` as terminal (closing the robustness gap).

### D4 — Retain the sweep (FR3)
- **Decision**: No change to retrospective SKILL gotcha #1 or the
  `retrospective-extras.md` "Verify Task Status" step (the manual sweep).
- **Rationale**: defence in depth — after D2 the sweep is a no-op on healthy runs
  but still fires on drift (manual edits, older-CWF projects, a failed j-stamp).
  It remains the catcher for *valid-but-non-terminal* committed statuses
  (`In Progress` on a completed phase) that the hook (D6) deliberately does not flag.

### D6 — Strengthen the stop-stale-status-detector hook (FR3, folded in per pre-exec review)
- **Decision**: Broaden the Stop-event hook's flag test from `$status eq 'Backlog'`
  to **`$status eq 'Backlog' OR NOT status_is_valid($status)`**, and generalise its
  message. Refactor the decision into a small testable named predicate.
- **Rationale**: the hook only inspects phase files **changed since HEAD**
  (`git diff HEAD`), so flagging *all* non-terminal would be noisy on legitimately
  in-progress work. Flagging **Backlog + non-canonical** instead catches the exact
  leaks observed in the atch logs (`Design`/`Requirements`/`Planning`/`Implemented`
  are all invalid enum values) while leaving valid in-progress statuses
  (`In Progress`/`Testing`) alone. Reuses the **already-exported**
  `CWF::TaskState::status_is_valid` — so **no `TaskState.pm` change and no
  `status_is_terminal` export**; only the hook changes.
- **Trade-offs**: the hook is hash-tracked → one in-task SHA256 refresh (the hook).
  The residual "valid non-terminal on a committed phase" case stays with the manual
  sweep (D4) — the established division of labour, now with a tighter hook half.

### D5 — Regression guard (FR4) — reuse-based, non-flaky *(revised by the impl REDUCE)*
- **Decision**: New test `t/status-terminality.t` (`use strict; use warnings; use
  utf8; use Test::More;` — core only, **not** `Test2::V0`), plus a `subtest` in
  `t/task-state.t`. Three assertions, all reuse:
  1. **Template hygiene (FR4b)** — read each `.cwf/templates/pool/*.md.template`
     with an explicit UTF-8 layer; reuse `CWF::TaskState::status_get` for the
     `**Status**:` token and a **global** match over any `Update status to "…"`
     line (captures every quoted token — `g:20` has two); assert each passes the
     **reused, already-exported** `CWF::TaskState::status_is_valid` (`:260`) — no
     hand-rolled JSON parse. Reintroducing `"Implemented"` turns it red.
  2. **Terminal-set predicate (FR4a)** — assert `CWF::TaskState::_is_closed`
     (called **fully-qualified**, `:330`) is true for `Finished`/`Skipped`/
     `Cancelled`, false for `Backlog`/`In Progress`. Single source, **no new
     export** (the impl REDUCE dropped the test-only `status_is_terminal` — it was
     public surface whose only effect was a hashed-`TaskState.pm` edit).
  3. **Hook flag decision (FR3/D6)** — assert the strengthened
     `stop-stale-status-detector` predicate flags `Backlog` and a non-canonical
     value (`Design`) but **not** a valid non-terminal (`In Progress`) or terminal
     (`Finished`).
- **Rationale**: reuse (`status_get`, `status_is_valid`, `_is_closed`) keeps a
  single source for the enum and terminal set — no drift-prone copy; no fixtures
  needed (the assertions exercise the predicates directly, so no live-repo coupling
  and no in-flight task like 222 can trip them).
- **Trade-off**: none for `TaskState.pm` (untouched). The only hashed edit is the
  D6 hook (one in-task refresh).

## System Design
### Components touched
- **`.cwf/templates/pool/f-implementation-exec.md.template`** — D1 (delete `f:20`
  hint; `g:20` kept). *(not hash-tracked)*
- **`.cwf/docs/skills/retrospective-extras.md`** (`&&`-chained `cwf-set-status`
  precondition + `:135` xref) — D2. *(not hash-tracked)*
- **`.cwf/scripts/hooks/stop-stale-status-detector`** — D6 (flag Backlog +
  non-canonical; testable predicate; generalised message). *(hash-tracked →
  refresh in-task)*
- **`t/status-terminality.t`** (new) + **`t/task-state.t`** (subtest) — D5.
- **Reused unmodified**: `cwf-set-status`, `CWF::TaskState` (`status_set` /
  `status_get` / `status_is_valid` / `_is_closed`), the retro manual sweep.
  **`TaskState.pm` is not modified** (no `status_is_terminal` export).

### Data flow (own-status stamping)
1. Phases a–i: skill → `cwf-checkpoint-commit {task} {letter}` →
   `status_set(file,'Finished')` → stage single file → commit. *(unchanged)*
2. Phase j: retrospective skill → `cwf-set-status {j-file} Finished` (abort on
   non-zero) → `git add {task-dir}/` → retro commit → squash. *(new scripted stamp)*
3. Skipped phase (present file, rare): `cwf-set-status {phase-file} Skipped`. *(reuse)*
4. Backstops (defence in depth): Step-7 sweep for phases stamped *before* the
   retro; `stop-stale-status-detector` hook for a failed/absent j-stamp. *(unchanged)*

## Interface Design
- `cwf-set-status <file-path> <canonical-status>` — existing; no signature change.
- `CWF::TaskState::status_is_valid` / `_is_closed` — existing; reused as-is (no new
  export; no signature change).
- The hook gains an internal testable predicate (e.g. `sub is_flaggable`); not a
  public interface.

## Constraints
- Core-Perl / POSIX only; British spelling; installed-artefact neutrality.
- **One hashed file is modified** — `.cwf/scripts/hooks/stop-stale-status-detector`
  (D6) → refresh its SHA256 in the same commit (`hash-updates.md`). Templates,
  `retrospective-extras.md`, and `t/` are not hash-tracked; `TaskState.pm` and
  `cwf-set-status` are reused unmodified.
- The sweep must remain (user requirement).

## Decomposition Check
- [ ] **Time**: <1 week — no.
- [ ] **People**: one developer — no.
- [ ] **Complexity**: one concern, reuse-first — no.
- [ ] **Risk**: no isolate-worthy component — no.
- [ ] **Independence**: shared contract — no.

**Decision**: No decomposition.

## Validation
- [ ] D1 deletes `f:20` only; `g:20` kept; audit confirms no other non-canonical token.
- [ ] D2 stamp `&&`-chained before `git add {task-dir}/`; survives squash.
- [ ] D5 reuses `status_get`/`status_is_valid`/`_is_closed` (no export, no hardcoded set, no fixtures).
- [ ] D6 hook flags Backlog + non-canonical, not valid non-terminal; testable predicate.
- [ ] Hook SHA256 refreshed in-task; `TaskState.pm` untouched; `cwf-manage validate` OK.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
The reuse-first design held: no new helper, no new public API, no `CWF::TaskState`
change — the exported `status_is_valid` backs the hook, the test, and the sweep. The
`&&`-chained j-stamp and the `is_flaggable` predicate landed as designed (D1–D6).

## Lessons Learned
Designing `is_flaggable` as a small pure predicate (not inline logic in the hook's main
body) is what made it unit-testable via the caller-guarded modulino — the testability
was a design choice, not an afterthought.
