# review all changed files not just cwf-internal - Design
**Task**: 174 (bugfix)

## Task Reference
- **Task ID**: internal-174
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/174-review-all-changed-files-not-just-cwf-internal
- **Template Version**: 2.1

## Goal
Define the edits that make `security-review-changeset` emit the full diff over all changed files, keep the production-weighted cap test-aware, and purge CWF-internal-only framing from every living document.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Root Cause
The helper interposes a classification loop (lines 172–182) between
`list_changed_files` and diff emission. Only paths that are CWF-internal
(`@CWF_INTERNAL_PREFIXES` / `%CWF_INTERNAL_FILES`) or carry a recognised
script shebang (`looks_like_script` against `$SCRIPT_INTERPRETER_RE`) reach
`@included`; everything else is dropped. The emitted diff and the cap count
both operate over `@included`, so a consumer's non-script application source
is invisible to the review. The classifier is an inverted filter: it was
written for CWF dogfooding its own (`.cwf/`-script) development and never
generalised to consumer repos.

## Key Decisions

### D1 — Review the full diff over all changed files
- **Decision**: Delete the classification layer entirely. Replace `@included`
  with the full changed-files list from `list_changed_files`. Remove
  `@CWF_INTERNAL_PREFIXES`, `%CWF_INTERNAL_FILES`, `$SCRIPT_INTERPRETER_RE`,
  `is_cwf_internal()`, `looks_like_script()`, and the `for my $path (@changed)`
  classification loop.
- **Mechanics**: `my @included = @changed;` (keep the name `@included` to
  minimise downstream churn — the emit/empty-check/count sites are unchanged).
  The empty-changeset branch (`!@included`) still fires only on a genuinely
  empty diff. Emitted diff stays `git diff $anchor -- @included`, now over all
  files. `looks_like_script`'s symlink/non-regular-file/DoS guards are no longer
  reachable — they guarded a content sniff we no longer perform; `git diff`
  itself does not read working-tree file contents unsafely, so dropping them is
  net-neutral for the DoS surface.
- **Rationale**: A security gate must see every line the task ships. Removal,
  not reconfiguration — there is no defensible scope narrower than "the diff".
- **Trade-offs**: Larger changesets now reach the `--max-lines` cap (exit 2)
  where they previously passed empty. That is the gate working, not regressing
  (see a-task-plan Risk 1). Behaviour is strictly *wider*, never narrower.

### D2 — Cap and test-path exclusion unchanged in mechanism, now correctly scoped
- **Decision**: No change to `count_production_lines` or `test_path_excludes`.
  With `@included` now the full set, the production count is
  `added+deleted over all changed files − security.review.test-paths globs` —
  exactly the requirement: test code is **reviewed** (in the emitted diff) but
  **not counted** toward the cap.
- **Rationale**: The cap machinery was already correct; it was only ever fed a
  pre-filtered list. Feeding it the full list makes it do what its docs claim.
- **Trade-offs**: None — pure consequence of D1.

### D3 — Purge CWF-internal-only framing from all living documents
- **Decision**: Sweep the living-document set (historical `implementation-guide/*`
  task files are immutable records — excluded; rewriting them would falsify
  project history). Edit:
  1. **`.cwf/scripts/command-helpers/security-review-changeset`** (header lines
     6, 19–23; the Output block at **line 42** — `stdout: filtered git diff
     output` → drop "filtered", it is now the full diff; comment blocks at
     69–98, 168–171, 457–458) — describe "all changed files" + the cap; drop
     classification narrative.
  2. **`.cwf/docs/skills/security-review.md`** — rename § "Pathspec coverage"
     → § "Changeset coverage"; replace the three classification rules and the
     CWF-internal "Known limitations" bullets (shebang-less / library-file /
     `source`d-script / uncommon-interpreter — all now moot) with
     "the full diff over all changed files is reviewed". Reword line 26's
     "single source of truth for **what counts as security-relevant**" →
     "single source of truth for **changeset construction (anchor + cap)**".
     Also update the third cross-reference at **line 137** (`the git diff output
     produced per § "Pathspec coverage"`) so the rename does not dangle.
     Leave the § "Classification (deterministic, …)" heading at line 167 — it is
     about the *verdict* classifier `security-review-classify`, not file
     selection (confirmed by two reviewers), so it is unaffected.
  3. **`.claude/skills/cwf-implementation-exec/SKILL.md:52`** and
     **`.claude/skills/cwf-testing-exec/SKILL.md:46`** — replace
     "applies CWF-internal-dir + shebang-sniff classification per § Pathspec
     coverage" with "emits the full diff over all changed files and enforces the
     production-weighted cap per § Changeset coverage". Update the
     "§ Pathspec coverage" reference earlier in each Step 8 to "§ Changeset
     coverage". Exit-code branches (0-empty / 0-nonempty / 2 / other) are
     unchanged and correct.
  4. **`.claude/agents/cwf-security-reviewer-changeset.md`** (reference at
     **line 16**) — update the `{changeset}` input description's "§ Pathspec
     coverage" reference to "§ Changeset coverage". No behavioural change to the
     prompt.
- **Rationale**: User requirement — no living document may state or imply the
  review is CWF-internal-only.
- **Trade-offs**: Renaming the section touches the agent file (hash-tracked).
  Accepted: an honest section name outweighs avoiding one extra hash refresh.

### D5 — Reconcile the existing test suite (contract change)
- **Decision**: `t/security-review-changeset.t` (768 lines) encodes the **old**
  classification contract and must be reconciled as part of this task — it is a
  contract change, not a mechanical exec detail. Three groups:
  - **Delete** (they test code D1 removes): the symlink-skip and FIFO/
    non-regular-file guard subtests (exercise `looks_like_script`'s `-l`/`-f`
    guards), and any "noise file (no shebang) excluded" subtest.
  - **Invert** (they assert the now-false *exclusion*): the subtests asserting
    a binary blob / plain-text file *outside* CWF dirs is excluded with
    `reviewed 0 files` (reviewers cite TC-F5, TC-F6, TC-NF5) — rewrite to assert
    the file is **present** in the emitted diff and **counted** in the summary.
  - **Re-justify** (still pass, but for a stale reason): shebang-inclusion and
    CWF-internal-inclusion cases (TC-F2/TC-F4) and the cap subtests — keep, but
    update names/comments so they assert "included because all files are
    included", not "included because shebang/CWF-internal".
  The exhaustive per-subtest mapping is produced in the **e-testing-plan**; the
  design's role is to fix that the suite *must* move with the code and name the
  three reconciliation groups so the testing plan is bounded.
- **Rationale**: The top design priority is Testability; a design claiming
  behaviour is "strictly wider" cannot ship against a suite built on narrowing
  assertions without naming that tension. (Both improvements + misalignment
  reviewers flagged this as the one blocking gap.)
- **Trade-offs**: None — the test work is in scope regardless; D5 just makes it
  explicit and bounded rather than inherited silently by exec.

### D4 — Hash refresh in the same commit (hash-updates convention)
- **Decision**: Of the edited files, **two are hash-tracked** in
  `.cwf/security/script-hashes.json`: the helper and
  `cwf-security-reviewer-changeset.md`. Refresh both hashes in the **same
  commit** as the edits. `security-review.md` and the two SKILL files are
  untracked — no refresh. Per-file `git log` pre-refresh verification per
  the convention.
- **Rationale**: `.cwf/docs/conventions/hash-updates.md` — refresh lands with
  the modification, never as a follow-up that silences `validate`.

## System Design
### Edit-site map (helper)
| Site | Current | After |
|------|---------|-------|
| `@CWF_INTERNAL_PREFIXES`, `%CWF_INTERNAL_FILES` (73–88) | path allowlists | **deleted** |
| `$SCRIPT_INTERPRETER_RE` (90–98) | shebang regex | **deleted** |
| classification loop (172–182) | builds `@included` by filter | `my @included = @changed;` |
| `is_cwf_internal` (457–467) | sub | **deleted** |
| `looks_like_script` (469–516) | sub | **deleted** |
| diff emit (198), empty-check (193), count (206) | over `@included` | unchanged (now full set) |

### Data flow (after)
1. Resolve anchor (baseline-commit → merge-base fallback) — **unchanged**.
2. `list_changed_files($anchor)` → `@changed` (anchor → worktree, `-z`) — **unchanged**.
3. `@included = @changed` — **no filtering**.
4. Empty? → exit 0, `reviewed 0 files`. Else emit `git diff $anchor -- @included`.
5. `count_production_lines($anchor, \@included, \@exclude)` where `@exclude` =
   `test_path_excludes()` → cap check → exit 2 if breached. **Unchanged.**

## Constraints
- Perl core-modules only; `use utf8;`; `-z` git path output. Existing helper complies; edits preserve compliance.
- No change to the helper's CLI surface, exit-code contract, or stderr summary format (`reviewed N files, M lines (P production), anchor=…`).
- Hash refresh co-located with edits (D4).

## Decomposition Check
- [ ] **Time**: <1 day. No.
- [ ] **People**: One. No.
- [ ] **Complexity**: One helper + its doc/SKILL/agent prose + test. No.
- [ ] **Risk**: No high-risk isolation needed. No.
- [ ] **Independence**: Code/doc/test move together. No.

**Conclusion**: 0 signals. No decomposition.

## Validation
- [ ] Design review completed (Step 8 — 4 parallel reviewers; findings applied: D5 + sweep omissions :42/:137/:16)
- [ ] Edit-site map verified against current line numbers at exec time (line refs may drift)
- [ ] Hash-tracked set confirmed before commit (helper + agent file only)
- [ ] **Widening regression test**: a plain consumer source file (e.g. `src/app.js`, no shebang, outside CWF dirs) now reaches `@included`, appears in the emitted diff, and contributes to the production count (e-testing-plan TC).
- [ ] **Empty-`@included` invariant** (highest-consequence): the line-193 guard still short-circuits a genuinely empty diff so a bare `git diff $anchor --` (no pathspec → whole-tree) can never fire. Preserve the guard; assert empty-diff → exit 0, `reviewed 0 files`.
- [ ] **Guard-removal safety**: confirm `git diff $anchor` over a changeset containing a symlink / FIFO neither blocks nor leaks content (evidences D1's "net-neutral DoS" claim rather than asserting it).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design decisions D1–D5 were implemented as specified. D1 (delete classifier,
`@included = @changed`), D2 (cap over production lines minus exclude globs), D3 (doc
sweep across helper/security-review.md/exec SKILLs/agent), D4 (in-commit hash refresh),
D5 (test reconciliation map) all held at exec. The highest-consequence design invariant
— the empty-`@included` guard preventing a bare whole-tree diff — was preserved and is
now asserted by TC-EMPTY1. The D5 map was extended at exec to cover two cross-file test
couplings the design did not enumerate.

## Lessons Learned
The design's edit-site map was accurate for the co-located test but did not enumerate
external references to the deleted `@CWF_INTERNAL_PREFIXES` symbol — design-time symbol
topology is a distinct dimension from design logic. The "DoS net-neutral" claim for
removing the working-tree file reads (symlink/FIFO) was correctly demanded to be
*asserted* (TC-GUARD1a/b) rather than stated. See j-retrospective.md.
