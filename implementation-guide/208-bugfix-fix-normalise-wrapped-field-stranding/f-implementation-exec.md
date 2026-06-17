# Fix normalise wrapped-field stranding - Implementation Execution
**Task**: 208 (bugfix)

## Task Reference
- **Task ID**: internal-208
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/208-fix-normalise-wrapped-field-stranding
- **Template Version**: 2.1

## Goal
Execute the implementation following d-implementation-plan.md and e-testing-plan.md:
the index-walk fold in `_canonicalise_entry_inplace`, the KD3 regression fixture, and
the same-commit hash refresh.

## Actual Results

### Step 1: Setup
- **Planned**: On the task branch; re-read c-design KD1–KD3a.
- **Actual**: Confirmed branch `bugfix/208-fix-normalise-wrapped-field-stranding`; the
  function at `backlog-manager:525-548` matched the d-plan "Before" verbatim.

### Step 2: Core implementation — index-walk fold
- **Planned**: Replace the per-line `for` with an index walk that folds continuation
  lines into the value until a terminator (next field / blank / `---` / EOF).
- **Actual**: Applied exactly as specified in d-plan "After". Left/right-trim per
  continuation, single-space join, seed-empty special case (no leading space). The
  trailing `next` in the field branch retained (load-bearing — d-plan note). Subsection
  `---`-strip loop and `trim_blank_lines` untouched.
- **Deviations**: None.

### Step 3: Testing — KD3 fixture
- **Planned**: Add the wrapped-field subtest matrix (TC-1..TC-7) under the AC18 block.
- **Actual**: Added `$WRAPPED_BACKLOG` fixture plus three subtests in
  `t/backlog-manager.t`:
  - `AC18d (TC-1..TC-5)` — fold terminators (next field, blank+prose, `---`, EOF) and
    the seed-empty single-space edge; asserts no continuation fragment is stranded and
    post-normalise `validate` is clean. 14 assertions.
  - `AC18e (TC-6)` — idempotent re-run byte-identical.
  - `AC18f (TC-7)` — single-line legacy fixture unchanged (inner `while` no-ops).
- **Deviations**: TC-1..TC-7 realised as three grouped subtests (AC18d/e/f) rather than
  seven separate `subtest` blocks — same coverage, fits the existing AC18 naming family.

### Step 4: Hashes & integrity
- **Planned**: Refresh the `backlog-manager` hash in the same commit; `validate` → OK.
- **Actual**: `sha256sum` → `652ef41a…db9d3`; updated `script-hashes.json`
  (was `249ae1cf…c0ca`). `cwf-manage validate` → OK. Working perms 0500 (matches
  recorded ceiling).

### Step 5: Validation
- **Planned**: Exec changeset review (security + best-practice); idempotency re-run.
- **Actual**: `prove -lr t/backlog-manager.t` → 48 tests PASS. `prove -lr t/` → 869
  tests PASS. Idempotency proven by TC-6. Changeset reviews recorded below.

## Test Results
- `prove -lr t/backlog-manager.t`: **PASS** (48 tests).
- `prove -lr t/`: **PASS** (869 tests, 72 files).
- `cwf-manage validate`: **OK**.

## Blockers Encountered
None blocking. One out-of-band issue surfaced and fixed on sight (below).

### Pre-existing permission drift (fixed on sight, not part of this changeset)
The full sweep initially showed failures in `cwf-manage-fix-security.t` (TC-8),
`cwf-manage-update-end-to-end.t`, `security-review-changeset.t` and
`version-records-commit-sha.t`. Two distinct causes, both unrelated to the fold:
1. **Stale `backlog-manager` hash** — expected; cleared by the Step 4 refresh.
2. **Working-tree perm drift** on `.claude/agents/cwf-best-practice-reviewer-changeset.md`
   and `.claude/agents/cwf-plan-reviewer-best-practice.md` (0400, below the recorded
   floor 0444), drift from the v1.1.207 merge. `fix-security` does not raise
   under-permissive files, so restored to recorded 0444 via `chmod` (fix-on-sight).
   Read-bit perms are not version-tracked (git mode `100644`), so this does **not**
   appear in the commit — it is a runtime-state repair only.
After both, `prove -lr t/` is fully green.

## Changeset Reviews (Step 8)
Both reviewers launched in parallel against the same changeset
(`security-review-changeset`: 11 files, 1012 lines, 61 production, anchor `c12b6c9`).
No `warning:` lines emitted by either prep helper.

### Security Review
**State**: no findings

> The changeset is a Perl logic change to `backlog-manager`'s
> `_canonicalise_entry_inplace`, a hash refresh, a BACKLOG entry, the task wf files, and
> a test fixture. Worked through the five FR4 threat categories:
> **(a)** no `system`/`qx`/backtick — pure in-memory string processing; hash refresh
> accompanies the edit per convention. **(b)** no new git/porcelain parsing; regexes are
> anchored, bounded, single-pass (no catastrophic backtracking). **(c)** folded values
> originate from project-authored `BACKLOG.md`, rewritten in place, never routed into LLM
> context or tool selection; no `{arguments}` surface. **(d)** no env-var reads; the
> `chmod 0444` repair is a runtime note, not code in the changeset. **(e)** the
> terminator `last if $next =~ /^\*\*KEY\*\*:/` correctly stops folding at a line that
> looks like a field and promotes it (KD2 boundary contract, not a defect). Pattern note
> (carve-out): the fold collapses continuation text into a single-line value with no
> escaping beyond whitespace trimming — safe here because the sink is an inert
> `### Field: value` heading; the "value is inert display text" invariant is load-bearing
> and must hold at any future sink that feeds a shell/path/LLM-tool-selection.
> `summary: Pure in-memory text fold in backlog-manager; no shell/git/env/LLM surface introduced; hash refresh accompanies the edit per convention.`

### Best-Practice Review
**State**: no findings

> Matched sources are `golang` and `postgres` best-practice corpora (pulled in by the
> repo's `active-tags`). The changeset is Perl + Markdown + JSON only — no Go code, no
> SQL/database layer — so neither corpus has any purchase on the artefacts touched. Both
> sources read without error (not a fail-closed `error`); they are simply not applicable,
> so there are no divergences to report.
> `summary: Listed sources are Go and Postgres best practices; changeset is Perl/Markdown/JSON only — sources read cleanly but are not applicable, no divergences to report.`

**Process note (carried from plan phase):** the only best-practice matches are out-of-domain
(`golang`/`postgres`). Worth considering whether CWF's own Perl-helper tasks should declare a
narrower tag set so `best-practice-resolve` returns 0 and skips this reviewer — a backlog
candidate, not a blocker for 208.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (SC#2 superseded by KD4, user-approved)
- [x] N/A — no b-requirements-plan.md (bugfix template)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
The terminator-driven index walk is the correct shape for hard-wrapping field parsing; a
per-physical-line walk structurally cannot fold continuations. Same-commit hash refresh and
fix-on-sight permission-drift repair both went smoothly. See j-retrospective.md.
