# Split workflow-steps into per-anchor docs - Retrospective
**Task**: 176 (chore)

## Task Reference
- **Task ID**: internal-176
- **Branch**: chore/176-split-workflow-steps-into-per-anchor-docs
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-02

## Executive Summary
- **Duration**: one session (estimate ~0.5 day, Low complexity). On estimate.
- **Scope**: As planned — split the 10 phase sections of `.cwf/docs/workflow/workflow-steps.md` into per-anchor files under `workflow-steps/`, repoint the 8 skill references to single-`Read` plain paths, and reduce `workflow-steps.md` to a table of contents. No scope drift.
- **Outcome**: Success. The `sed`/`awk` section-extraction that halted skills on a permission prompt is structurally eliminated — phase guidance is now a single `Read` of a single self-contained file. Verified end-to-end by this very retrospective: the skill's Step 5 read `workflow-steps/retrospective.md` directly.

## Variance Analysis
### Time and Effort
Chore step set (a, d, e, f, g, j). All phases completed in one session, on estimate. No requirements/design phases (chore); design decisions D1–D4 were recorded inline in `d-implementation-plan.md`.

### Scope Changes
- **Additions**: None.
- **Removals**: None. The two execution sections (unreferenced by any skill today) were still given their own files (D1) so the split is uniform and future-linkable.
- **Decisions confirmed at review**: D2 (keep Status Values + Version Differences inline in the ToC, leaving 12 `#status-values` referrers untouched), 10-file split, and disambiguated `implementation-planning.md` / `testing-planning.md` filenames — all approved before exec.

### Quality Metrics
- **Test coverage**: TC-1..TC-8 all PASS (file existence, content-preservation, up-links, reference resolution, dangling-anchor sweep, status-values integrity, ToC links, regression). `cwf-manage validate` clean; `installmanifest-integrity.t` 6/6.
- **Defects**: None in the product. One verification-harness false negative (see below).

## What Went Well
- **Pre-exec sweep caught hidden scope.** A repo-wide `git grep` before planning revealed the change surface was bigger than the 8 skills: `#status-values` had 12 referrers (templates + 2 docs) and a whole-file reference in `checkpoint-commit.md`. Surfacing these in the plan prevented dangling references.
- **The split incidentally fixed two already-broken anchors.** `cwf-implementation-plan` and `cwf-testing-plan` referenced `#implementation` / `#testing`, which never resolved to the real `## Implementation Planning` / `## Testing Planning` headers. Plain file paths removed the latent breakage.
- **Content-preservation was machine-checked.** Rather than eyeballing, a Perl checker asserted each new file's body is a verbatim substring of the baseline section — turning "I copied it carefully" into a test.
- **Packaging risk was retired by reading the installer, not assuming.** Both install paths copy `.cwf/` recursively, so the new subdir ships with no manifest edit.

## What Could Be Improved
- **The content-check harness anchored on `HEAD`, which moved.** On the testing-phase re-run, TC-2/TC-3 flashed red because the checker diffed against `HEAD` — by then the post-rewrite ToC — instead of the task baseline `91d0b4c`. The product was correct; the harness was pointed at the wrong commit. A verification script that compares "before vs after" should pin the *baseline SHA* explicitly, never the moving `HEAD`.

## Key Learnings
### Technical Insights
- **Markdown anchors are a false affordance for the Read tool.** A `file.md#anchor` reference reads as "fetch this section" but the Read tool ignores the fragment, so agents improvise extraction (`sed`, or `grep`+`Read`) — the exact friction this task removed. One-file-per-anchor makes the cheapest path the only path needed.
- **Keep reference data that has many referrers inline.** Splitting `#status-values` would have rippled into 12 files for no gain; keeping it in the now-short ToC preserves every referrer and still avoids over-reading.

### Process Learnings
- **Verification scripts are code and need the same "what am I comparing against?" rigour as the change.** Pin the baseline commit.
- **Dogfooding validated the change within the same task.** The retrospective skill read the relocated guidance file directly — the feature proved itself before merge.

## Recommendations
### Process Improvements
- When writing a before/after content-diff helper, parameterise the baseline SHA from `a-task-plan.md`'s recorded **Baseline Commit**, not `HEAD`.

### Tool and Technique Recommendations
- Consider, as future housekeeping, repointing the two *exec* skills (`cwf-implementation-exec`, `cwf-testing-exec`) and the whole-file `checkpoint-commit.md` reference at the new per-anchor files now that `implementation-execution.md` / `testing-execution.md` exist. Not required (those skills don't currently link phase guidance), so not done here.

### Future Work
- None required. Optional follow-up noted above; not backlogged as it is discretionary.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-02

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Plan/impl/test docs: this task directory (`a`, `d`, `e`, `f`, `g`).
- Checkpoint commits: `c3deb39` (a), `c63146e` (d), `0fe99b1` (e), `b69aedd` (f), `de43889` (g).
