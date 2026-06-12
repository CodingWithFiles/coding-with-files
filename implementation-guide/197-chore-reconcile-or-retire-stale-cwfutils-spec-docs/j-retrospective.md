# Reconcile or retire stale .cwf/utils spec docs - Retrospective
**Task**: 197 (chore)

## Task Reference
- **Task ID**: internal-197
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/197-reconcile-or-retire-stale-cwfutils-spec-docs
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-12

## Executive Summary
- **Duration**: ~0.5 day (estimated: <0.5 day; on estimate, ~0% variance)
- **Scope**: As planned, plus one in-scope widening decided at planning time — the backlog named three files; `hierarchy-manager.md` was folded in as the equally-stale fourth. No scope change during execution.
- **Outcome**: Success. Four inert `.cwf/utils/*.md` prototype-era spec docs deleted; `CWF-PROJECT-SPEC.md` and the live skills/helpers are now the uncontested single source of truth. No integrity drift, no dangling live references.

## Variance Analysis
### Time and Effort
- **Estimated** (chore phase set a, d, e, f, g, j):
  - Planning (a): negligible
  - Implementation plan (d): small (the retire-vs-reconcile decision + plan review)
  - Testing plan (e): negligible
  - Implementation exec (f): small
  - Testing exec (g): negligible
  - Total: <0.5 day
- **Actual**: matched estimate. The d-phase plan review was where the time went — it surfaced the second-backlog-item dangling-reference risk that shaped execution.
- **Variance**: ~0%. A subtractive doc change with a well-bounded sweep behaved as predicted.

### Scope Changes
- **Additions**: None during execution. The only widening (`hierarchy-manager.md`) was decided at planning time and recorded in a-task-plan Constraints.
- **Removals**: None.
- **Impact**: None — scope held from plan through exec.

### Quality Metrics
- **Test Coverage**: 5/5 verification test cases passed (TC-1 files gone, TC-2 no functional consumer, TC-3 backlog de-referenced, TC-4 originating item retired, TC-5 `cwf-manage validate` green).
- **Defect Rate**: 0 defects found in testing. Two minor in-flight execution deviations (em-dash rejected by `--note`; residual path token in the first amend) were caught and corrected within the f-phase, not defects in the shipped result.
- **Performance**: N/A (documentation change).

## What Went Well
- **Plan review earned its keep.** The mandatory 4-subagent review (d-phase) independently flagged a second, still-open backlog item (`BACKLOG.md:1272`) citing the to-be-deleted `template-engine.md:41`. Without it, deletion would have left a dangling reference in a live item. The plan was amended before any file was touched.
- **`backlog-manager retire` collapsed two close-out steps into one transaction** — moving the originating item to CHANGELOG and recording the retirement (with a `--note` naming all four files) in a single atomic operation, avoiding a redundant manual CHANGELOG entry.
- **"Retire, not reconcile" was the right call.** Reconciling would have produced four hand-maintained prose specs with no consumer — re-creating the exact drift that produced this task.
- **Both exec-phase security reviews returned `no findings`**, consistent with a purely subtractive, non-executable, non-hash-tracked change.

## What Could Be Improved
- **De-referencing precision.** The first amend of the second backlog item dropped only the `:41` line-number suffix but left the `utils/template-engine` path token, which would have failed TC-3. Caught at validate time and corrected. Lesson: when de-referencing a deleted file, remove the whole `dir/basename` token, not just the line-number suffix.
- **Verification-sweep portability.** The initial TC-2 filter assumed GNU grep prefixes start-path `.` results with `./`; it does not, so the `^\./...` exclusion matched nothing and produced a 32 KB unfiltered dump. Re-run with a bare-prefix filter. Lesson: filter on the bare path prefix.
- **`--note` input constraints undocumented at point of use.** `backlog-manager retire --note` enforces printable-ASCII and rejected an em-dash with no up-front hint. Minor friction; worth keeping in mind that helper free-text fields are ASCII-only.

## Key Learnings
### Technical Insights
- A deleted `.cwf/` file ships its absence to end users via `git read-tree --prefix=.cwf/`; the value of this task is precisely that the prototype design stops being published as current guidance.
- Non-hash-tracked `.md` deletions need no same-commit `script-hashes.json` refresh — `cwf-manage validate` stayed green throughout because none of the four files had hash entries.

### Process Learnings
- **Estimation accuracy**: a well-scoped subtractive change with an explicit sweep estimates reliably (~0% variance here).
- **The reference sweep is the load-bearing safety check** for any deletion. Running it both at plan time and immediately before deletion (Step 1 of d-plan) caught the full consumer set and confirmed inertness twice.

### Risk Mitigation Strategies
- The a-plan's "Wrong reconciliation target" medium risk was retired by committing to *delete* early and requiring a concrete current consumer before reconciling any single file (none existed).
- The a-plan's "Hidden consumer missed by grep" low risk was mitigated by widening the sweep to bare basenames (not just the `utils/` prefix) and relying on git-reversibility as the backstop.

## Recommendations
### Process Improvements
- When a close-out step de-references a deleted artefact from surviving prose, add a verification grep for the *bare path token* (not just the file plus line number) to the test plan — this task's TC-3 is a good template.

### Tool and Technique Recommendations
- Continue using `backlog-manager retire --note` for retire+record in one transaction; it removes a manual CHANGELOG step and keeps the two files consistent.

### Future Work
- The second open backlog item ("Align cwf-extract skill … to grep+read", `BACKLOG.md:1272`) remains open, now with `SKILL.md:48` as its sole awk site. No new follow-up tasks were created by this task.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-12
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`, `d-implementation-plan.md`, `e-testing-plan.md`
- Execution: `f-implementation-exec.md` (commit `685327b`), `g-testing-exec.md` (commit `84f2be0`)
- CHANGELOG: `## Task 197` section (retired backlog item + retirement note)
