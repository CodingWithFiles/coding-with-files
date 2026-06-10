# Sync docs and README with current CWF state - Retrospective
**Task**: 189 (chore)

## Task Reference
- **Task ID**: internal-189
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/189-sync-docs-and-readme-with-current-cwf-state
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-10

## Executive Summary
- **Duration**: ~1 day (estimated: ~1 day; variance ≈ 0).
- **Scope**: Bring user/maintainer docs into agreement with shipped CWF ahead of a
  release. Final scope matched the plan, plus one out-of-scope finding filed to BACKLOG.
- **Outcome**: Success. Six top-level docs corrected/rewritten; all 11 test cases and 5
  non-functional checks passed; `cwf-manage validate` clean; change set is docs-only.

## Variance Analysis
### Time and Effort
- **Estimated** (chore phases): plan + implementation-plan + testing-plan + impl-exec +
  testing-exec + retrospective, ~1 day total.
- **Actual**: ~1 day. Plan/testing-plan were front-loaded during the planning session;
  exec was a single focused pass.
- **Variance**: negligible. The counts-policy (recount at exec, keep brittle numbers out
  of prose) saved rework that hand-copied counts would have caused.

### Scope Changes
- **Additions**:
  - Third BACKLOG item — "Retire residual CIG branding from .cwf code and POD" — surfaced
    by the stale-string sweep. Filed Low (cosmetic, hash-tracked, out of docs scope).
  - README config-example pointer redirected to `CWF-PROJECT-SPEC.md` instead of the
    known-divergent `.cwf/templates/cwf-project.json.template`.
- **Removals**: none descoped from the plan.
- **Impact**: none on timeline; both additions were small and reduced future drift.

### Quality Metrics
- **Test Coverage**: every edited doc covered by ≥1 TC; 100% of documented `/cwf-*`
  commands resolve to real skills; zero stale-string hits in the docs grep set.
- **Defect Rate**: 0 test failures. One plan-assumption defect caught (scratchpad.md
  assumed tracked; it is gitignored) — surfaced, not silently actioned.
- **Performance**: N/A (documentation change set).

## What Went Well
- **Grounding every claim against code** (`%WORKFLOW_FILES`, `Validate::Config`, the
  skills dir) rather than against the prior prose or the planning audit. The audit's
  "perl.md is duplicated" and "5→24 scripts" claims were both wrong; code-grounding
  caught them.
- **Counts-policy** — preferring descriptive phrasing over brittle exact counts — means
  the docs will not silently rot the next time a script or skill is added.
- **Output-level smoke test** confirmed the *generated* artefacts (not just source) are
  clean, honouring the rebrand lesson that source-grep alone is insufficient.
- **Scope discipline**: the docs-only guard held — no hash-tracked `.cwf/**` file was
  touched, so no code+hash change leaked into a docs commit.

## What Could Be Improved
- **Planning assumed scratchpad.md was tracked.** A `git ls-files` check during planning
  would have caught the gitignore and avoided a mid-exec deviation. Cheap to verify file
  tracking state before writing a `git rm` step into a plan.
- **The security-review cap is a poor fit for docs-only change sets.** It weights all
  top-level docs as "production" and trips at 500 lines with zero actual code, forcing an
  `error` state both phases. Functionally harmless here, but noisy; see Recommendations.

## Key Learnings
### Technical Insights
- The config schema in `CWF-PROJECT-SPEC.md` had drifted into near-fiction (enforced
  fields that the validator never checks). The durable fix is to document **against the
  validator** and to label pass-through blocks explicitly as "not validated", so the doc
  cannot re-imply enforcement.
- `DESIGN.md` at *rationale altitude* (the why, pointing onward) avoids becoming a fourth
  verbatim copy of the architecture that then drifts independently.

### Process Learnings
- Estimation was accurate because the audit work was done in the planning phase; exec was
  mechanical. Front-loading the inventory paid off.
- "Surface, don't smooth" applied cleanly to the scratchpad.md deviation: the right move
  was to report the contradiction with the plan, not to delete a file CWF did not create.

### Risk Mitigation Strategies
- The plan's explicit guard against editing hash-tracked files during the stale-string
  sweep prevented the most likely scope error (a tempting one-line `CIG`→`CWF` edit in a
  `.pm` POD block would have pulled a hash change into a docs commit).

## Recommendations
### Process Improvements
- When a plan includes a `git rm`/delete step, verify the target's tracking state
  (`git ls-files`) at plan time.
- Consider whether docs-only change sets should be exempt from, or differently weighted
  by, the security-review line cap (e.g. treat top-level `*.md` as non-production). Until
  then, the exit-2 `error` state on a pure-docs task is expected and benign.

### Tool and Technique Recommendations
- Keep grounding doc counts/claims against code at exec time; keep brittle numbers out of
  prose. This is the single biggest defence against doc rot.

### Future Work
Filed to BACKLOG during this task:
- Reconcile `cwf-project.json` install template and `/cwf-init` output with the validator
  schema (Medium).
- Prune vestigial blocks from the live `implementation-guide/cwf-project.json` (Medium).
- Retire residual CIG branding from `.cwf` code and POD (Low).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-10
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md, d-implementation-plan.md, e-testing-plan.md
- Execution: f-implementation-exec.md, g-testing-exec.md
- Checkpoint commits: phase f `85943e4`, phase g `9f1f4a2` (squashed at retrospective).
