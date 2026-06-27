# Plan-time mechanical review gates - Retrospective
**Task**: 213 (chore)

## Task Reference
- **Task ID**: internal-213
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/213-plan-time-mechanical-review-gates
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-27

## Executive Summary
- **Duration**: a–j in one session (estimate ~1 day; well under).
- **Scope**: Delivered as planned — one mechanical helper running two scans (path-existence + symbol-deletion sweep), wired into plan-review as a pre-MAP resolver, language-neutral, shipped under `.cwf/`. Two consolidated backlog items (Task-150 path defect, Task-174 symbol defect) addressed in one pass.
- **Outcome**: Success. 37 targeted + 919 full-suite tests green, `cwf-manage validate` OK, all changeset reviewers clean bar one accepted below-Rule-of-Three advisory.

## Variance Analysis
### Time and Effort
- **Estimated**: ~1 day (chore phases a, d, e, f, g, j).
- **Actual**: single session, under estimate. No phase overran; the d-plan review front-loaded the two corrections that would otherwise have cost exec rework.
- **Variance**: favourable. The `best-practice-resolve` reuse template removed most design uncertainty.

### Scope Changes
- **Additions**: one unplanned fix — the dogfood smoke-test surfaced a markdown `#anchor` false-positive (`-e` failing on `path.md#fragment`); fixed by stripping the fragment before the existence test, with regression TC-11. This boilerplate appears in nearly every plan, so it mattered.
- **Removals**: none. All three a-plan open decisions resolved (OD1 one helper, two checks; OD2 pre-MAP deterministic resolver, not a reviewer-agent edit; OD3 declared `**Deletes**:` convention over heuristic).
- **Impact**: net-positive — the added fix hardened the helper against its single most common input shape.

### Quality Metrics
- **Test Coverage**: all 11 planned cases (TC-1…TC-11) pass; every helper branch exercised (path high/advisory, symbol found/zero-ref/self-excluded, all exit outcomes, anchor-strip, mode 0600). No regressions across 74 files / 919 tests.
- **Defect Rate**: one defect found (anchor false-positive), found by dogfooding before commit, fixed same phase. Zero post-commit defects.
- **Performance**: n/a at this scale (one `git ls-files` + N `git grep` per plan); no benchmark invented.

## What Went Well
- **Plan review paid for itself**: it caught two latent exec bugs before any code — the a-plan assumed `run_quiet` could capture git output (it redirects to `/dev/null`), and that reusing `capture_git` (dies on non-zero) was safe for `git grep` (exit 1 = no-match is the common "safe to delete" case). Both became a custom `capture_git_z` returning `($stdout, $exit)`.
- **Dogfooding caught a real bug**: running the helper on its own d-plan surfaced the anchor false-positive that source tests alone would not have — vindicating the "generate output and grep it" rule.
- **Empirical over cited**: confirmed `git grep -c -z` framing and that `-w` *does* match sigiled symbols (`@CWF_INTERNAL_PREFIXES`) by testing, not by citing docs — the Task-174 case would have been a silent false-negative otherwise.
- **Strong reuse**: `find_git_root`, `scratch_dir`, `atomic_write_text`, `resolve_num`, and the `best-practice-resolve.t` harness all reused; net new surface is one helper + one test.

## What Could Be Improved
- **Measure-twice on library contracts**: the `run_quiet`/`capture_git` misassumptions in a-plan were avoidable with a 2-line read of each helper before drafting. Plan review is a backstop, not a substitute for checking the contract first.
- **Duplication watchpoint**: `read_deletes` duplicates `best-practice-resolve::read_task_tags` (labelled-CSV line parser). This is the 2nd occurrence — **below the Rule of Three** — so accepted-and-recorded, not extracted. Promote to a shared `CWF::Common` parser when a 3rd appears.

## Key Learnings
### Technical Insights
- **The gate is a net, not a proof** — grep-based symbol sweeps over/under-report by design; the value is moving detection from exec to plan-time. The kernel's loud ENOENT (exit 127) remains the runtime backstop for the path class, not something this replaces.
- **Markdown anchors break filesystem existence tests** — any `-e` check on a token drawn from prose must strip a trailing `#fragment` first; the fragment is documentation, not part of the path.
- **`git grep -w` is boundary-correct on sigils** — it checks word boundaries at match edges rather than a naive `\b`, so `@`/`%`-prefixed Perl symbols match without special-casing.

### Process Learnings
- Front-loading library-contract verification into plan review converts would-be exec rework into a cheap plan edit.
- A pre-MAP deterministic resolver (the `best-practice-resolve` shape) is the right integration point for mechanical checks — it keeps determinism out of the LLM reviewers and feeds REDUCE without widening any agent's remit.

### Risk Mitigation Strategies
- R1 (grep precision) mitigated as planned: word-boundary matching + surface-never-block + openly documented tradeoff. The dogfood-caught anchor case is the concrete proof the "surface for adjudication" posture is correct.
- R2 (wrong-root / permission prompts) avoided by reusing `find_git_root`; no inline `git rev-parse`, no `--show-toplevel` worktree trap.

## Recommendations
### Process Improvements
- Keep the output-level dogfood smoke-test mandatory for any helper that consumes prose — it caught what 37 source assertions did not.

### Tool and Technique Recommendations
- When a 3rd labelled-CSV line parser appears, extract a shared `CWF::Common` helper and retro-fit `read_deletes` + `read_task_tags`.

### Future Work
- **Backlogged this task**: "Best-practice tags should trigger on task content, not blanket active-tags" (feature, Medium) — the golang/postgres false-trigger observed in every changeset review here is the motivating evidence.

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge to main
**Blockers**: None identified
**Completion Date**: 2026-06-27
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: `a-task-plan.md`; implementation plan: `d-implementation-plan.md`; testing plan: `e-testing-plan.md`
- Execution: `f-implementation-exec.md` (commit `fa42885`), `g-testing-exec.md` (commit `29e3b0f`)
- Deliverables: `.cwf/scripts/command-helpers/plan-mechanical-check`, `t/plan-mechanical-check.t`, `.cwf/docs/skills/plan-review.md`
