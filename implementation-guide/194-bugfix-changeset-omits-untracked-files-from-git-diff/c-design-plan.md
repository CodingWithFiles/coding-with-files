# changeset omits untracked files from git diff - Design
**Task**: 194 (bugfix)

## Task Reference
- **Task ID**: internal-194
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/194-changeset-omits-untracked-files-from-git-diff
- **Template Version**: 2.1

## Goal
Define how `security-review-changeset` will enumerate untracked, non-ignored files and
fold them into both the rendered changeset body and the `--max-lines` production count,
without eroding the helper's "git owns all path-matching" invariant or its read-only
contract.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Empirical grounding (probe results)
A throwaway repo was used to verify git's behaviour before choosing a mechanism. The
relevant findings (rc = process exit code):

| Probe | Result |
|-------|--------|
| `git ls-files --others --exclude-standard -z` | lists exactly untracked, non-ignored paths (ignored files and ignored dirs correctly omitted) |
| `git diff --no-index --numstat /dev/null F` | works, but **rc=1** ("differences found") and path column renders as `/dev/null => F`; no `:(glob,exclude)` support |
| `git add -N F` then `git diff --numstat <anchor> -- F` | `2 0 F`, **rc=0** — identical shape to existing tracked numstat |
| `git add -N F` then `git diff <anchor> -- F` | full new-file diff body, rc=0 |
| `git add -N F` then numstat with `:(glob,exclude)F` | empty — **exclude pathspecs still apply** |
| `git reset -q -- F` after `-N` | restores F to untracked (`?? F`) |

## Key Decisions
### Decision 1 — Mechanism: intent-to-add (`git add -N`) + guaranteed reset
- **Decision**: Enumerate untracked non-ignored files with
  `git ls-files --others --exclude-standard -z`, mark them with `git add -N -- <paths>`,
  append them to `@included`, let the **existing** `git diff <anchor> -- @included` and
  `count_production_lines` render and count them, then unconditionally
  `git reset -q -- <paths>` to restore the index.
- **Rationale**:
  - Preserves the core invariant — git, not Perl, owns diff rendering, numstat counting,
    and `:(glob,exclude)` discounting. Probe confirms all three keep working after `-N`.
  - Minimal new code: untracked files flow through the unchanged body/count code paths;
    the only additions are enumerate → `-N` → reset.
  - No exit-code special-casing. `git add -N`/diff/numstat all return rc=0, so the
    existing `capture_git` (dies on non-zero) needs no change.
- **Trade-offs**: transiently mutates the index (intent-to-add entries). Mitigated by a
  guaranteed restore (see Decision 2). The working tree is never touched, and
  intent-to-add carries no content, so even an un-restored entry loses no data and is
  cleared by a plain `git reset`.

### Decision 2 — Restore via a single `END {}` cleanup block (authoritative), non-fatal and PID-guarded
- **Decision**: Record the exact list of paths passed to `git add -N` in a package-scoped
  array, plus the **main process PID** captured at startup. Install **one** `END {}` block
  (no inline reset, no `eval` wrapper) that, only when `$$ == $MAIN_PID` and the list is
  non-empty, restores via a **best-effort** `git reset -q -- <those paths>`.
  - **`END {}`, not `eval {}`**: the helper exits through `capture_git`/`git_check`, which
    call `exit 1` directly, plus `exit 2` (cap) and `exit 1` (write failure). Perl `END`
    blocks run on `exit` **and** `die`; an `eval {}` wrapper catches `die` only and would
    silently miss every `exit` branch — the exact hazard this guards. So `eval` is rejected.
  - **Single mechanism, no inline primary**: `END` already covers success, `exit 1`,
    `exit 2`, and `die`, so an additional inline reset would be redundant belt-and-braces.
    One mechanism, one place.
  - **Best-effort, must not clobber the exit code**: the cleanup must NOT route through
    `capture_git`/`git_check` (both `exit 1` on git failure — calling `exit` from inside an
    `END` during an already-failing exit would mask the load-bearing exit code, e.g.
    `exit 2` = cap exceeded). It saves and restores `$?`, runs `git reset` via a direct
    `system(...)` with output suppressed, and at most `warn`s on failure — never `exit`s or
    `die`s. A failed reset leaves only content-free intent-to-add residue (tolerable, see
    trade-offs). This is the correct inverse of "surface, never smooth": the residue is
    recoverable and carries no security signal, so degrading quietly is right.
  - **PID guard (forked-child safety)**: `git_check` forks and its child bails with
    `exit 127` on `exec` failure (lines ~320-335). Without a guard, the `END` reset would
    fire inside that forked child. The `$$ == $MAIN_PID` check makes `END` a no-op in any
    child. (Mirrors the recorded `POSIX::_exit`-in-forked-child incident class — inherited
    `END` blocks must not act in children.)
- **Trade-offs**: `END`-block restore cannot cover `SIGKILL`. Accepted — no process can,
  the residue is a content-free intent-to-add entry recoverable with `git reset` (same
  class as the scratch-dir residue the helper already tolerates).

### Decision 3 — Rejected: `git diff --no-index`
- **Rejected** because it operates outside the repo and so (a) does **not** honour the
  `:(glob,exclude)` exclude pathspecs — forcing a Perl-side re-implementation of exclude
  matching, breaking the helper's central invariant; (b) returns rc=1 on differences,
  requiring new exit-code handling in a security-critical helper; (c) emits a
  `/dev/null => F` numstat path column needing bespoke parsing. The read-only benefit does
  not outweigh re-introducing Perl path classification.

## System Design
### Component Overview
- **`list_untracked_files()`** (new sub, **no parameters**): returns untracked, non-ignored
  paths via `git ls-files --others --exclude-standard -z`, NUL-split (per git-path-output
  convention), `grep length`. No `$anchor` arg — listing does not use it, and a speculative
  parameter would mislead a reader into thinking it is load-bearing (unlike the sibling
  `list_changed_files($anchor)`, which genuinely diffs against the anchor). Returns `()` on
  an empty tree.
- **intent-to-add guard** (new, in main flow): given the untracked list, populate the
  package-scoped cleanup list, `git add -N -- @untracked` (note the mandatory `--`
  separator, see invariant below). No-op when the list is empty (skip `add` entirely; the
  `END` block also no-ops on an empty list).
- **`@included`** (existing): becomes `(@changed, @untracked)`. The two sets are disjoint
  by construction (`list_changed_files` reports tracked changes only; `ls-files --others`
  reports untracked only — a path is never both). No dedup is added. Defensive note for the
  implementer: were the invariant ever violated, a duplicate would be double-counted by
  `count_production_lines`, making the cap fire **earlier** — the safe direction
  (over-count, never under-count). Body rendering is unaffected by a duplicate path.
- **`capture_git('diff', ...)` body + `count_production_lines`** (existing, unchanged):
  now see untracked files because they are intent-to-add in the index.

### Data Flow
1. Resolve `$anchor` (unchanged).
2. `@changed = list_changed_files($anchor)` (tracked staged+unstaged — unchanged).
3. Compute the tracked-dirty flag via `git diff --quiet HEAD` **before** any `-N`
   (ordering constraint: `-N` would otherwise flip this rc 0→1).
4. `@untracked = list_untracked_files()`; populate cleanup list; `git add -N -- @untracked`
   (skipped if empty).
4a. Set `$dirty_suffix = ', includes uncommitted'` when **either** the tracked-dirty flag
    fired **or** `@untracked` is non-empty. Rationale: an all-untracked changeset
    demonstrably includes uncommitted content, so the disclosure suffix must fire for it
    too (the prior code only considered tracked changes, which would mislabel such a
    changeset "clean").
5. `@included = (@changed, @untracked)`.
6. Render body `git diff $anchor -- @included` → `.out` (existing code path).
7. `count_production_lines($anchor, \@included, \@exclude)` (existing code path; excludes
   still apply to untracked paths per probe).
8. Cap check / exit (existing).
9. Cleanup backstop runs `git reset -q -- @untracked` on the way out (every exit path).

### Ordering constraint (explicit)
`-N` must happen **after** the `git diff --quiet HEAD` dirty probe (step 3) and the reset
must happen on **all** exit paths including `exit 2` (cap exceeded) and `exit 1` (write
failure) — guaranteed by the single `END` block. This is the one sequencing hazard; the
test plan covers the post-run index state for both the clean-exit and cap-exceeded
branches.

### Named invariant — mandatory `--` separator (option-injection defence)
Every git invocation that takes the untracked paths as arguments — `git add -N`,
`git diff`, `git reset` — MUST place `--` before the pathspecs. An untracked file named
e.g. `-rf` or `--foo` arrives verbatim from `git ls-files --others -z`; without `--` git
would parse it as an option (FR4(e) option-injection). The `--` is load-bearing, not
cosmetic. The test plan pins this with a dash-prefixed untracked filename asserting a
clean post-run index and correct inclusion.

## Constraints
- Read-only contract: index/working tree restored on every non-`SIGKILL` exit.
- Core-Perl only; NUL-separated path parsing (`-z`).
- No Perl path classification — git remains the sole matcher.
- Hash refresh for the edited helper committed in this task's exec commit
  (hash-updates convention).

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ concerns? No — one concern (untracked-file inclusion) across
      body+count in one file.
- [ ] **Risk**: components needing isolation? No — the one hazard (index restore) is
      handled inline, not separable.
- [ ] **Independence**: separable parts? No — body and count share the same enumeration
      and `-N` step.

**Verdict**: 0 signals. No decomposition.

## Validation
- [x] Mechanism chosen against empirical probe, not assumption
- [x] Invariant ("git owns matching") preserved by chosen mechanism
- [x] Restore-on-all-exit-paths and dirty-suffix ordering hazards identified
- [ ] Plan review (Step 8) completed

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective (complete)
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All three decisions held through implementation unchanged: intent-to-add +
guaranteed reset (Decision 1), single PID-guarded non-fatal END block
(Decision 2), and the rejection of `git diff --no-index` (Decision 3). The
named `--` option-injection invariant and the dirty-probe-before-`-N` ordering
constraint both translated directly into code and tests (TC-6, TC-5). The
disjoint-by-construction `@included` union needed no dedup.

## Lessons Learned
Naming the invariants explicitly in the design ("git owns matching", the `--`
separator, the probe-before-`-N` ordering) made them directly testable — each
became a named test case rather than an implicit assumption a reviewer had to
reconstruct.
