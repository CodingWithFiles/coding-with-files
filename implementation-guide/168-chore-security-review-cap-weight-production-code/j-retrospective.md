# security-review cap weights production over tests - Retrospective
**Task**: 168 (chore)

## Task Reference
- **Task ID**: internal-168
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/168-security-review-cap-weight-production-code
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-29

## Executive Summary
- **Duration**: single working session (estimated: ~1 day, Medium). On estimate.
- **Scope**: as planned — no additions, no descoping. The one open design question (how to categorise production vs test code deterministically) was resolved during plan review and did not expand the build.
- **Outcome**: success. The exec-phase 500-line security-review cap now measures a production-weighted count owned by the helper; a change that ships its own test suite is no longer falsely capped. All four a-task-plan success criteria met.

## Variance Analysis
### Time and Effort
- **Estimated**: ~1 day (chore: a, d, e, f, g, j). No requirements/design phases.
- **Actual**: one session, no decomposition (0 signals triggered, as predicted).
- **Variance**: none material. The bulk of the effort was the up-front design discussion (categorisation rule), not the code — the implementation itself was one helper + two SKILL edits + one doc + tests.

### Scope Changes
- **Additions**: none.
- **Removals**: none. Fractional test-weighting and a separate higher cap were considered and explicitly rejected in d-implementation-plan (extra knobs, no evidence needed); "is 500 the right number" stayed out of scope.

### Quality Metrics
- **Test coverage**: 7 new subtests (TC-CAP1–7) covering the three exit codes (0/1/2), the `P>N` boundary, `--max-lines` validation (incl. `0`/leading-zero), git `:(glob,exclude)` exclusion, binary→0, and the malformed-pattern fail-safe. 21/21 pass; all 14 pre-existing subtests unchanged (incl. the strict `:559` anchor).
- **Defect rate**: zero defects found in testing. Both phase-f and phase-g security reviews returned `no findings`.
- **Performance**: one extra `git diff --numstat` per run, bounded by diff size not repo size (TC-NF5 unaffected).

## What Went Well
- **The design landed on delegating matching to git.** Consumer-declared `security.review.test-paths` globs matched by git's own `:(glob,exclude)` engine — no Perl path-matching code, hence no ReDoS surface on a security gate and no non-core dependency (Perl core ships no pathspec/glob-string matcher). The Socratic plan-review discussion was where the value was created; it killed three weaker designs (model-labelling, hardcoded prefixes, Perl-native regex).
- **Dogfooding validated the fix on its own diff.** The output-level smoke run reported `6 files, 491 lines (149 production)` — this very task would have nearly tripped the old 500-raw-line cap, but production-weighted it sits at 149. The change demonstrates exactly the false-cap the backlog item described.
- **Fail-safe direction is correct and test-covered.** Unconfigured/unmatched layouts count as production (cap fires earlier, never later); a malformed pattern makes git fatal → exit 1 → SKILL flags for manual review. No config state can silently shrink the count and let an over-cap diff slip review (TC-CAP7).
- **Single source of truth restored.** The cap moved out of two `wc -l` invocations in the SKILLs into the helper; the SKILLs now only set the threshold and branch on the exit code, which also closed a latent gap (an exit-1 error was previously read as an empty "no findings" changeset).

## What Could Be Improved
- **A stray `chmod +x` on the test file leaked a `100644 → 100755` mode change into the f checkpoint.** Caught immediately and amended back to `100644`. Root cause: a bash habit (chmod-and-execute is for `.cwf` scripts, not `prove`-run test files). Worth internalising: `prove` does not need the executable bit.
- **The phase-g security review re-ran on a near-identical changeset.** After the f checkpoint, the g-phase changeset differed only by the absent "includes uncommitted" framing (489 vs 491 lines; same 149 production lines, same code). The gate was honoured, but a byte-identical re-review is largely redundant when the testing phase adds no production logic. Not worth special-casing in the workflow, but noted.

## Key Learnings
### Technical Insights
- **A glob is a regular expression.** The categorisation rule is "a restricted regex notation" only by convention; git pathspec / gitignore globs were chosen because they match how developers conceive file matching *in a git repo*, and because git already ships the matcher. Choosing the notation the host tool already parses removed an entire class of in-house matching code.
- **`git diff --numstat` is the right primitive for a production-weighted count.** It excludes diff context and hunk headers by construction, reports binary files as `-` (counted as 0), and — critically — its first two columns are always plain integers regardless of how the path column is quoted/renamed. Reading only those two columns means path quoting can never misclassify.
- **The repo owns the truth about its own layout.** Hardcoding `t/` baked CWF's Perl convention into a tool shipped to consumer repos. Moving the test-path set into `cwf-project.json` (as a test runner's config already does) makes the cap correct for any consumer and keeps the helper layout-agnostic. Default unset = no discount = no regression.

### Process Learnings
- The "review the plans before we exec" gate worked: the categorisation design was rewritten (Perl classifier → git pathspec) *before* any code was written, so the build was right first time. Front-loading the contentious design decision into plan review is cheaper than discovering it in implementation.

## Recommendations
### Future Work
- **TC-NF4 is a no-op assertion** (`ok(1, ...)`) — its own comments admit the FIFO scenario was too awkward to set up via git, so it no longer exercises the `-f`/`-l` guards it names. Pre-existing (not introduced here). Candidate backlog item: either build the FIFO fixture properly or delete TC-NF4 and rely on TC-NF3 for the symlink guard.
- **Standing item, not this task**: `.cwf/install-manifest.json` is committed at `0600` vs the expected `0444`, which `cwf-manage validate` flags on every checkpoint and which fails `t/cwf-manage-fix-security.t` TC-1 in the full suite. Already tracked as the "Install-time chmod 0444" backlog item.

### Tool and Technique Recommendations
- When a host tool (git, the shell, the test runner) already parses a notation you need to match against, prefer delegating to it over re-implementing the matcher — especially when the input is partly consumer-controlled and the output feeds a security gate.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to main (human decision)
**Blockers**: None identified
**Completion Date**: 2026-05-29
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md` (commit `21c4b78`), `g-testing-exec.md` (commit `0349aa3`)
- Tests: `t/security-review-changeset.t` (TC-CAP1–7)
