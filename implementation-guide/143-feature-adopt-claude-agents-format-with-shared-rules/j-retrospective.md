# Adopt .claude/agents format with shared rules - Retrospective
**Task**: 143 (feature)

## Task Reference
- **Task ID**: internal-143
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/143-adopt-claude-agents-format-with-shared-rules
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-16

## Executive Summary
- **Duration**: 1 day (session-spanning) — estimate was 2-3 days; under by ~50%
- **Scope**: Original scope (5 agent files + shared-rules + cwf-manage install lifecycle + integrity ledger) shipped intact. Added during exec/test: `scripts/install.bash` analogous edits (gap surfaced during TC-AC1-install) and `create_agent_symlinks` warn-on-stray behaviour (test-plan vs design-plan discrepancy resolved by user direction).
- **Outcome**: Success. 17/20 TCs PASS, 3/20 BLOCKED-ENV (session-cache, not defects). All success criteria from a-task-plan.md met.

## Variance Analysis
### Time and Effort
- **Estimated**: 2-3 days end-to-end.
- **Actual**: Single session (~half a day of active work, plus context-compaction across the planning ↔ exec boundary). The phase chain was: a (~5 min) → b (~30 min, two passes) → c (~20 min, two passes) → d (~15 min, two passes) → e (~10 min, two passes) → f (~30 min) → g (~30 min) → j (this).
- **Variance**: ~50% under. Single-agent execution with planning + exec in one context window, no handoff overhead.

### Scope Changes
- **Additions** (both forced by test-phase findings, both folded into the f/g commits with user direction to retroactively update d-plan):
  - **scripts/install.bash gap-fix**: 21 lines. Original d-plan only edited `cwf-manage`; install.bash is the actual fresh-install entry point and needed analogous `.cwf-agents` wiring (subtree split, subtree add, force-remove, copy-method, post_install symlink call).
  - **create_agent_symlinks warn-on-stray behaviour**: ~17 lines. Test-plan TC-AC1-cleanup-stale expected broader cleanup behaviour than the design's D2 wording / d-plan pseudocode. User picked the middle path (warn-on-stray + die-on-collision).
- **Removals**: None.
- **Impact**: Marginal — both additions fit within a single half-day extension. Scope didn't drift; gaps were surfaced by tests doing their job.

### Quality Metrics
- **Test Coverage**: 20 ACs from b-requirements-plan.md, all mapped to test cases. 17 PASS, 3 BLOCKED-ENV.
- **Defect Rate**: 1 finding from f-phase Security Review (pattern-risk (e), warning only — applied as an inline invariant comment); 0 defects from g-phase tests; 0 escapes.
- **Performance**: N/A (no perf-sensitive surface).

## What Went Well
- **Plan reviewers caught real issues.** D1 (1-file vs 4-file plan-reviewer shape) flipped twice across plan-review passes; the user's final override locked the right shape.
- **Security-review-changeset helper paid off twice.** AC6b contract test confirmed it now covers `.claude/agents/`. f-phase subagent (cat-(e) pattern risk on symlink callsite) caught a real safety-by-invariant issue; fix was a 6-line comment, no logic change.
- **Scratch-repo install/update tests caught the install.bash gap.** Without TC-AC1-install actually running install.bash end-to-end, the missing fresh-install path would have shipped silently. Real-environment tests, not source-level grepping.
- **Warn-on-stray / die-on-collision implementation matched the user's intent first time.** No re-implementation cycles.
- **Single-session execution kept context coherent.** All design decisions, file paths, and test results stayed in working memory; no context-handoff regressions.

## What Could Be Improved
- **Test plan was broader than design at TC-AC1-cleanup-stale.** Pre-exec plan-review should compare test plan's behavioural expectations against the design's literal wording. The user's middle-path resolution worked, but the discrepancy ate one Q&A cycle.
- **Throwaway branch (`feature/143-synthetic-rename`) looked like a real task branch.** Need a naming convention (`wip-test/`, `test-fixture/`) or a stash-equivalent that doesn't pollute `git branch -v`. User flagged it explicitly during testing.
- **Session-restart blind spot.** Agent registry caches at session start; new `.claude/agents/cwf-*.md` files written mid-session aren't discoverable for TC-AC3b/AC5a/AC5b. Either accept BLOCKED-ENV (current path) or build a post-install harness step that re-execs Claude Code.
- **Stash-pop accident during scratch-repo testing.** Mid-test I attempted `git stash push -- <paths>` with paths that didn't exist; a subsequent `git stash pop` reached into an unrelated old stash and merge-conflicted on `BACKLOG.md` + `implementation-guide/84-…`. Recovered cleanly but lost ~5 min and surfaced clearly to the user. Lesson: when stashing partial WD with explicit paths, verify the stash succeeded before doing anything else.
- **Security-review sentinel-line contract is strict; subagents hedge.** Both f-phase and g-phase subagents reached the right conclusion via "prose-then-sentinel" order, triggering the conservative-default `error` classification. The contract works as written but loses signal on cosmetic violations. Worth tightening either the prompt (FIRST LINE must be sentinel) or the classifier (scan for standalone-line sentinel anywhere in body).

## Key Learnings

### Technical Insights
- **`.claude/agents/{name}.md` is the right granularity.** The 4-file plan-reviewer shape (one file per column) makes per-column tuning trivial — bake the column's focus into the body, drop the SKILL-side criteria-lookup table entirely. Future per-wf-step / per-reviewer divergence (different sub-skill access, different pre-flight checks) doesn't have to re-shoehorn into one parameterised file.
- **The shared-rules surface inclusion bar matters.** Without "rule must apply to ≥2 agent roles AND have a documented convention/incident", it would have become a dumping ground. Codifying it in the shared-rules file itself (not just in the requirements doc) means future additions get gate-checked.
- **Install lifecycle has THREE entry points, not one.** `install.bash` (fresh install), `cwf-manage update` (in-place update), and `cwf-manage rollback` (revert). Future tasks adding a new staging dir (`.cwf-*`) must edit BOTH install.bash and cwf-manage. A single shared helper (e.g. `lib/install-lifecycle.sh` sourced by both) would reduce maintenance surface.
- **`git diff` doesn't surface untracked files.** When verifying a security-review-changeset contract on new files before commit, use `git add -N` (intent-to-add) so the index entry exists without committing content. Checkpoint commit then makes `-N` irrelevant.

### Process Learnings
- **Plan-review map/reduce caught real issues at every phase.** No phase was a rubber-stamp. The pattern of "write plan → 4 parallel reviewers → REDUCE → user override (if needed)" produced better plans than any single pass would have.
- **User-direction-during-exec is fine when scope changes are surfaced clearly.** Both d-plan additions (install.bash + warn-on-stray) came from test findings, were proposed to the user with options, and got chosen explicitly. No drift.
- **500-line review-cap fires often on legitimate work.** This task hit it twice (f: 538, g: 625). Both times the actual edit-line count was well under cap (399/419), with the rest being hunk headers and context. The cap is a safety net for context-window exhaustion in the subagent; if the cap fires routinely on real PRs, consider tuning it to count edit-lines only or split changesets at the source.
- **Sentinel-line contracts need to be hammered into prompts.** Subagents add preamble even when told not to. Either accept conservative-default `error` on cosmetic miss (current path), or prepend `RESPONSE MUST START WITH SENTINEL LINE; NO PREAMBLE` to the prompt — and live-test the prompt for adherence.

### Risk Mitigation Strategies
- **Smoke-test in a scratch repo, not the source tree.** TC-AC1-install/update/cleanup-stale couldn't have caught the install.bash gap if the test had been source-level grepping. The friction of `git init /tmp/foo && CWF_SOURCE=…` paid for itself.
- **The cat-(e) pattern-risk comment is now self-documenting at the callsite.** Future maintainers reading `create_agent_symlinks` see why the symlink callsite is safe and what invariant must hold for reuse. Cheaper than a backlog item.

## Recommendations

### Process Improvements
- **Add a "test-plan vs design-plan literal" review step.** Before exec, plan-review of test plan should grep design plan for the keywords being tested and surface mismatches. Would have caught the cleanup-stale discrepancy here.
- **Document the session-restart constraint in `.cwf/docs/skills/cwf-agent-shared-rules.md` or `cwf-new-task`.** Anyone adding a new agent should know upfront that smoke-test invocations require a fresh session.
- **Convention for throwaway test branches**: prefix with `wip-test/` or `test-fixture/` so `git branch -v` reads cleanly.

### Tool and Technique Recommendations
- **Adopt the warn+die conflict-check pattern in `create_skill_symlinks`.** Currently die-only on collision (or — actually, I think it's just silently overwrite). Same logic should apply to skills as agents: cwf-* is OUR namespace in both directories. **Tracked as a follow-up backlog item.**
- **Consider an install-lifecycle helper library.** install.bash and cwf-manage duplicate subtree-add/copy/symlink logic. A single sourced bash library would let "add a new .cwf-X staging dir" be a one-edit change.

### Future Work
- **Backlog item: retrofit `create_skill_symlinks` with warn-on-stray + die-on-collision behaviour.** Same logic as `create_agent_symlinks`; deliberate-asymmetry note in this task's d-plan flagged it.
- **Backlog item: install-time `chmod 0444` on data/agents files**, so `cwf-manage validate` is clean immediately after install (currently needs `fix-security`). Pre-existing issue; this task inherits the same path.
- **Backlog item: session-restart smoke-test helper.** Auto-re-exec Claude Code after install/update so newly-installed agents are immediately invocable. Out of scope here; orthogonal to Task 143.
- **Backlog item: tune security-review-changeset 500-line cap or count edit-lines only.** Cap fires routinely on legitimate medium PRs.

## Status
**Status**: Finished
**Next Action**: Suggest merge to user
**Blockers**: None
**Completion Date**: 2026-05-16
**Sign-off**: maintainer (Claude Opus 4.7, session-attributed)

## Archived Materials
- a-task-plan.md (this task dir)
- b-requirements-plan.md (this task dir)
- c-design-plan.md (this task dir)
- d-implementation-plan.md (this task dir; retroactively updated to include install.bash edits)
- e-testing-plan.md (this task dir)
- f-implementation-exec.md (this task dir)
- g-testing-exec.md (this task dir)
- Commits on `feature/143-adopt-claude-agents-format-with-shared-rules` (8 phase commits pre-squash); see checkpoints branch for the per-phase trail post-squash.
