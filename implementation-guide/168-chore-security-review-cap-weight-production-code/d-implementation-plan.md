# security-review cap weights production over tests - Implementation Plan
**Task**: 168 (chore)

## Task Reference
- **Task ID**: internal-168
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/168-security-review-cap-weight-production-code
- **Template Version**: 2.1

## Goal
Move the 500-line security-review cap from a `wc -l` count in the two exec SKILLs to a
production-weighted line count owned by `security-review-changeset`, so a change that
ships its own test suite is measured on its production lines, not raw diff lines.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Resolved Design Decisions (from a-task-plan Open Questions)
1. **Test-line rule** — consumer-declared patterns, matched by git itself. A
   `security.review.test-paths` array in `cwf-project.json` holds gitignore/git
   pathspec patterns; each is passed to `git diff` as `:(glob,exclude)<pattern>`, so
   **git's own pathspec engine does the matching** — no Perl-side matcher, hence no
   ReDoS surface and no glob→regex code. The repo owns the truth about its own layout
   (as a test runner's config already does); the helper stops hardcoding CWF's Perl
   `t/` convention. **Default unset ⇒ no excludes ⇒ no discount ⇒ today's cap basis**
   (no regression for any repo). CWF self-configures `["t/**"]` (dogfoods the field).
   **Fail-safe direction**: unconfigured / unmatched test layouts count as *production*
   — cap fires *earlier*, never later. Cross-language suffix conventions (`*_test.go`,
   `*.spec.ts`) are expressible as globs (`**/*_test.go`) but not exhaustively pursued;
   the gap is a *coverage* gap (counts as production), never an *unsafe* one. Rejected:
   hardcoded `@TEST_PREFIXES` (parochial — bakes CWF's layout into a shipped tool);
   Perl regex on consumer input (ReDoS hazard feeding a security gate);
   inclusion-reason (a consumer's production script also matches the shebang sniff).
2. **Cap location** — the helper *measures and enforces*, the SKILL *sets the threshold
   and reacts*. New `--max-lines=N` option: the helper computes the production-weighted
   count and, when it exceeds N, exits **2** (new code) with a one-line stderr reason;
   stdout still carries the full diff. `--max-lines` absent ⇒ behaviour unchanged.
   This removes the `wc -l` re-count (single source of truth = helper). **The SKILL
   must capture both stdout and the exit code** and branch: `0` → proceed to the
   subagent; `2` → cap-exceeded error block (short-circuit past the Agent call to
   Step 9); any other non-zero (`1`) → hard-error block (changeset construction
   failed — also covers a malformed `test-paths` pattern git rejects), also
   short-circuiting. Today the SKILL inspects only stdout, so an exit-1 error is
   silently read as an empty "no findings" changeset — this task closes that latent
   gap as a side-benefit of adding exit-code branching.
3. **Weighting shape** — production lines counted at weight 1; test lines weight 0.
   Count via a single
   `git diff --numstat <anchor> -- @included :(glob,exclude)<pat>…` call (added+deleted
   columns summed). Git intersects the positive `@included` paths with the exclude
   globs and reports only surviving files, so there is **no Perl path classification
   and no diff-body parsing** — paths with spaces / renames / quoting cannot
   misclassify. Binary files (`numstat` reports `-`) count as 0. `--numstat`
   inherently excludes context/hunk-header lines the backlog flagged as inflation.
   Rejected for v1: fractional test weight and a separate higher cap (extra knobs,
   no evidence needed; "is 500 right" is explicitly out of scope).

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/security-review-changeset`:
  - Add `--max-lines=N` CLI option (validate `N =~ /^[1-9]\d*$/`, else warn + exit 1 —
    rejects `0` and leading zeros).
  - Read `security.review.test-paths` from `cwf-project.json` (reuse the eval-guarded
    `CWF::Versioning::read_config()` already called on the fallback path; missing /
    unreadable config ⇒ treat as empty list, never fatal). Validate it is an array of
    non-empty strings free of NUL; ignore/skip anything else (defensive — consumer
    input). Build `@exclude = map { ":(glob,exclude)$_" } @test_paths`.
  - Compute production count via
    `capture_git('diff','--numstat',$anchor,'--',@included,@exclude)`, summing the
    added+deleted columns (binary `-` rows → 0). Git owns the matching; a malformed
    pattern makes git fatal ⇒ `capture_git` exits 1 ⇒ SKILL flags for manual review
    (safe fail direction, never a silent discount).
  - Extend the stderr summary to `reviewed N files, M lines (P production), anchor=…`
    — **field order is a hard constraint**: `(P production)` sits between `M lines` and
    `anchor=` so the strict end-anchored assertion at
    `t/security-review-changeset.t:559`
    (`^reviewed 2 files,.+anchor=…, includes uncommitted$`) still matches via its `.+`.
  - When `--max-lines` is set and `P > N`, emit `cap exceeded: P production lines > N`
    to stderr and `exit 2`.
  - Update the header usage/comment block and `print_usage()`. After editing, restore
    working perms to `0700` (hashed-script convention; 0500 validates but breaks
    install-reinstall TC-5).
- `implementation-guide/cwf-project.json` — add `security.review.test-paths: ["t/**"]`
  so CWF dogfoods the field (its own tests live under `t/`). Not hash-tracked (only
  `cwf-*` scripts and `cwf-*.md` commands are) — no hash refresh. It IS a CWF-internal
  reviewed file, so the change appears in its own changeset; expected and harmless.
- `.claude/skills/cwf-implementation-exec/SKILL.md` (Step 8) — pass `--max-lines=500`;
  capture both stdout **and the exit code**; replace the "If >500 lines (count via
  `wc -l`)" bullet with exit-code branching: `exit 2` → append `## Security
  Review\n\n**State**: error\n\nerror: <helper stderr reason line>\n` and proceed to
  Step 9; other non-zero (`1`) → append an `error: changeset construction failed
  (<helper stderr>)` block and proceed to Step 9. No `wc -l`. The cap message is
  sourced from the helper's stderr (no re-authored 500-line string in the SKILL); the
  only literal `500` is the `--max-lines=500` threshold itself.
- `.claude/skills/cwf-testing-exec/SKILL.md` (Step 8) — identical change, `{phase}` =
  testing, `--phase=testing`.
- `.cwf/docs/skills/security-review.md` — add a short subsection under "Pathspec
  coverage" documenting the production-weighted cap: production count = added+deleted
  over included files minus `security.review.test-paths` (gitignore/git pathspec
  patterns, matched via `:(glob,exclude)`); default unset ⇒ no discount; the
  `--max-lines` contract and exit-2 signal; the fail-safe direction and the
  cross-language coverage limitation. Reference the helper as source of truth.

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `sha256` entry for
  `security-review-changeset` in the **same commit** as the source edit (hash-updates
  convention; helper confirmed present in the manifest. SKILL.md and
  security-review.md are NOT hash-tracked — no entries to refresh). Pre-refresh:
  `git log --oneline <last-hash-set-commit>..HEAD -- .cwf/scripts/command-helpers/security-review-changeset`.
- `t/security-review-changeset.t` — new subtests (see Test Coverage).

## Implementation Steps
### Step 1: Setup
- [ ] On branch `chore/168-…`; confirm baseline `bcf37b4` and clean tree.
- [ ] Re-read the resolved design decisions above.

### Step 2: Helper — production-weighted count + cap
- [ ] Parse `--max-lines=N` (`N =~ /^[1-9]\d*$/`, else warn + exit 1).
- [ ] Add `sub test_path_excludes` — eval-guarded `read_config()`; pull
      `security.review.test-paths`; validate array-of-non-empty-strings (NUL-free);
      return `map { ":(glob,exclude)$_" } @valid` (empty list if absent/unreadable).
- [ ] Add `sub count_production_lines($anchor, \@included, \@exclude)` — return 0 if
      `@included` empty; else sum added+deleted columns of
      `capture_git('diff','--numstat',$anchor,'--',@included,@exclude)` (binary `-`
      rows → 0). Git does the matching; no Perl path classification.
- [ ] Extend the stderr summary with `(P production)` in the pinned field position.
- [ ] When `--max-lines` set and `P > N`: warn `cap exceeded: P production lines > N`
      and `exit 2` (stdout already printed).

### Step 3: SKILL wiring + self-config
- [ ] Update Step 8 in both exec SKILLs per Files-to-Modify (pass `--max-lines=500`,
      branch on exit code, drop `wc -l`).
- [ ] Add `security.review.test-paths: ["t/**"]` to `implementation-guide/cwf-project.json`.

### Step 4: Documentation
- [ ] Add the cap subsection to `security-review.md`.
- [ ] Update the helper's header comment + `print_usage()` for `--max-lines`.

### Step 5: Tests + hash + validation
- [ ] Add subtests (Test Coverage below); run `prove -v t/security-review-changeset.t`;
      re-confirm `:559` (strict end-anchor) still passes.
- [ ] Refresh `security-review-changeset` hash (sha256sum → edit manifest); restore
      working perms to 0700.
- [ ] `cwf-manage validate` clean (modulo the pre-existing install-manifest.json 0444
      finding, which this task does not touch).
- [ ] Output-level smoke check: run the helper with `--max-lines` on a real
      task-shaped diff and confirm the summary/exit code; re-read both rewritten
      Step 8 blocks to confirm the exit-code branching is unambiguous (SKILL is
      LLM-executed prose — this is its only "test").

## Test Coverage
**See e-testing-plan.md for the complete test plan.** Sketch (subtests set
`security.review.test-paths` in the synthetic repo's `cwf-project.json` where needed):
- TC-CAP1: production-only diff > N, no `test-paths` configured → exit 2.
- TC-CAP2: task-166 shape — small production + large `t/` diff, `test-paths: ["t/**"]`
  → exit 0, P (production-only) under cap.
- TC-CAP3: `--max-lines` absent → never exits 2 regardless of size (back-compat).
- TC-CAP4: stderr summary reports `(P production)`; context/header + excluded test
  lines not counted.
- TC-CAP5: invalid `--max-lines` → exit 1 — non-integer AND `0`/leading-zero
  (`--max-lines=0`, `--max-lines=007`).
- TC-CAP6: binary production file (`numstat` `-`) contributes 0.
- TC-CAP7: malformed `test-paths` pattern git rejects (e.g. `../escape`) → helper
  exits 1 (no silent discount), per the safe fail direction.

## Validation Criteria
**See e-testing-plan.md.** Headline: all a-task-plan success criteria met; existing
14 subtests still green (incl. the strict-anchored `:559`); `wc -l` no longer appears
in either exec SKILL Step 8; both Step 8 blocks branch on the helper exit code.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.
No deferral anticipated — single helper + two skills + one doc + tests, all in scope.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 168
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Implemented as planned (commit `21c4b78`); deviations: none. See `f-implementation-exec.md`.

## Lessons Learned
`git diff --numstat` first-two-columns parse sidesteps path-quoting misclassification; delegating glob matching to git removed all in-house matcher code. See `j-retrospective.md` § Technical Insights.
