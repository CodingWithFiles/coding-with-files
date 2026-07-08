# Phase skills set own terminal status at checkpoint - Implementation Plan
**Task**: 222 (feature)

## Task Reference
- **Task ID**: internal-222
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/222-phase-skills-set-own-terminal-status
- **Template Version**: 2.1

## Goal
Implement the R2 status-terminality fix with the smallest coherent change set:
delete the redundant `f:20` hint, make `j-retrospective`'s own-status stamp a hard
precondition (reusing `cwf-set-status`), strengthen the Stop hook to catch
non-canonical leaks, and add a reuse-based regression guard — retaining the manual
sweep. **Exactly one hashed file is modified (the hook).**

> **Plan-review REDUCE (5 reviewers) + pre-exec user review.**
> The impl REDUCE dropped the test-only `status_is_terminal` export (public surface
> whose only effect was a hashed-`TaskState.pm` edit); the test calls private
> `CWF::TaskState::_is_closed` fully-qualified. Robustness's "abort on non-zero" is
> enforced by `&&`-chaining (prose can't stop a paste). FR4a is predicate
> assertions (no `File::Temp` fixtures). **User review then decided: keep `g:20`
> (delete `f:20` only), and fold in the hook-strengthening (D6)** — implemented as
> "flag Backlog **+ non-canonical** (`!status_is_valid`)", which catches the
> observed `Design`/`Requirements`/`Planning` leaks *without* firing on valid
> in-progress work, and reuses the already-exported `status_is_valid` (so still no
> `TaskState.pm` edit). Net hashed edits: one (the hook). Mechanical advisories benign.

## Files to Modify
### Primary Changes
- `.cwf/templates/pool/f-implementation-exec.md.template` — delete the line-20
  completion-hint checkbox (`- [ ] Update status to "Implemented" when complete`).
  **`g:20` is kept** (canonical, per user review).
- `.cwf/docs/skills/retrospective-extras.md` — in "Retrospective Checkpoint
  Commit", `&&`-chain a `cwf-set-status {j-file} Finished` **before** `git add
  {task-dir}/ && git commit …`, so a non-zero exit genuinely blocks the commit.
  Add a one-line xref to the existing list-form safety note at `:135`.
- `.cwf/scripts/hooks/stop-stale-status-detector` — **D6**: broaden the flag test
  from `$status eq 'Backlog'` to `$status eq 'Backlog' || !status_is_valid($status)`
  (import `status_is_valid` from `CWF::TaskState`); refactor the decision into a
  small named predicate for testability; generalise the message. **Hash-tracked →
  refresh SHA256 in the same commit.**
- `t/status-terminality.t` — **new**: FR4b template-hygiene scan + the D6 hook
  predicate assertions.
- `t/task-state.t` — add a `subtest` with FR4a terminal-set predicate assertions.

### Supporting Changes
- `.cwf/templates/pool/*.md.template` (remaining nine incl. `g`) — audit; expected no edits.
- `.cwf/security/script-hashes.json` — refresh the hook entry (in-task, per `hash-updates.md`).

*(Exactly one hashed file is modified — the hook; `TaskState.pm` and
`cwf-set-status` are reused unmodified; templates, `retrospective-extras.md`, and
`t/` are not hash-tracked. No named symbol is deleted — no `- **Deletes**:` line.)*

## Implementation Steps
### Step 1: Setup & audit
- [ ] Confirm on `feature/222-…`; re-read `c-design-plan.md` (noting this plan
      revises D5: no export).
- [ ] Grep-audit all ten pool templates' status-context lines; confirm `f:20` and
      `g:20` are the only status hints and no other non-canonical token exists.

### Step 2: Regression guard — RED first (FR4)
- [ ] `t/status-terminality.t` (`use strict; use warnings; use utf8; use
      Test::More;`) — **FR4b**: for each `.cwf/templates/pool/*.md.template`,
      reuse `CWF::TaskState::status_get($path)` for the `**Status**:` token, and
      scan any `Update status to "…"` line with a **global** match (`/…/g`) to
      capture *every* quoted token (`g:20` carries two); assert each via
      `CWF::TaskState::status_is_valid`. Open the hint scan with
      `'<:encoding(UTF-8)'`.
- [ ] `t/task-state.t` — add `subtest 'terminal-set predicate'`: `ok
      CWF::TaskState::_is_closed($_)` for `Finished`/`Skipped`/`Cancelled`; `ok
      !CWF::TaskState::_is_closed($_)` for `Backlog`/`In Progress`. Calls the
      private predicate fully-qualified — single source, no export.
- [ ] `prove -lv t/status-terminality.t` → **RED** (f still names `Implemented`;
      the D6 hook-predicate assertions in Step 4 also start red).

### Step 3: D1 template fix → GREEN
- [ ] Delete the `f:20` completion-hint checkbox only (**keep `g:20`**; apply any
      Step-1 audit fixes). Re-run → template-hygiene GREEN.

### Step 4: D6 strengthen the Stop hook
- [ ] Refactor `stop-stale-status-detector`'s flag decision into a named predicate
      (e.g. `sub is_flaggable { my $s = shift // ''; return $s eq 'Backlog' ||
      !status_is_valid($s) }`); `use CWF::TaskState qw(status_get status_is_valid)`;
      generalise the systemMessage (Backlog *or* non-canonical). Keep `exit 0`
      always.
- [ ] Add the D6 assertions to `t/status-terminality.t`: `is_flaggable` true for
      `Backlog` and `Design`; false for `In Progress` and `Finished`. Re-run → GREEN.
- [ ] Refresh the hook's SHA256 in `script-hashes.json` (in-task, `hash-updates.md`).

### Step 5: D2 j-retrospective stamp (hard precondition)
- [ ] Edit `retrospective-extras.md` "Retrospective Checkpoint Commit" to
      `&&`-chain `cwf-set-status implementation-guide/{task-dir}/j-retrospective.md
      Finished && git add implementation-guide/{task-dir}/ && git commit -m "…"`.
      Add the `:135` list-form-safety xref beside it.

### Step 6: D3 Skipped (documentation only)
- [ ] No `workflow-steps.md` edit (Skipped already defined, 33–47). Record the
      "no committed-leak path under the symlink model; `cwf-set-status … Skipped`
      covers the rare present-file case" rationale in `f-implementation-exec.md`
      Actual Results.

### Step 7: Validate
- [ ] `.cwf/scripts/cwf-manage validate` → OK (the hook hash refresh from Step 4
      must clear it; fix any permission drift on sight via `fix-security`).
- [ ] `prove -l t/` (full suite) → no regressions.

## Folded in per user review (was previously deferred)
- **D6 hook-strengthening** is now in scope (Step 4). The noise concern that caused
  the initial deferral is resolved by flagging only **Backlog + non-canonical**
  (not all non-terminal): the hook inspects `git diff HEAD` phase files, so valid
  in-progress statuses (`In Progress`/`Testing`) on files you are actively editing
  are left alone, while invalid-enum leaks (`Design`/`Requirements`/`Planning`) are
  caught. It reuses the already-exported `status_is_valid`, so no `TaskState.pm`
  edit and no `status_is_terminal` export. Residual "valid non-terminal on a
  committed phase" stays the manual sweep's job (D4).

## Test Coverage
**See e-testing-plan.md** — FR4 automated guard (template scan red-on-seed +
terminal-set + hook-predicate assertions) plus a manual end-to-end check that a
real `j` checkpoint leaves `Status: Finished` via the `&&`-chained stamp.

## Validation Criteria
**See e-testing-plan.md.** AC1 (status-context scan clean, `f:20` hint gone, `g:20`
kept, `Backlog` seed intact); AC2 (j own-status terminal via the precondition
stamp); AC3 (Skipped rationale documented); AC4 (manual sweep retained + hook
strengthened per D6); AC5 (guard red-on-seed/green-on-fix, `validate` OK, hook hash
refreshed in-task).

## Scope Completion
**IMPORTANT**: Complete D1–D6 before marking Finished. Exactly one hashed-file edit
(the hook) with its SHA256 refresh in the same commit; no deferral of in-scope work.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Plan executed with one deviation absorbed at pre-exec review: D6 (hook strengthening)
folded in, g:20's canonical hint kept. Footprint matched the plan — 6 production files,
+137/−29, one hashed edit with its sha256 refreshed in the same commit.

## Lessons Learned
Sequencing the hash refresh into the same edit-commit (not a later step) kept every
checkpoint's `validate` green and avoided any transient sha256 drift the retrospective
would have had to surface.
