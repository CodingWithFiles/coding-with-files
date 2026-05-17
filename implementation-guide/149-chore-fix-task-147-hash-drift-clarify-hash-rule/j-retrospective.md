# Fix Task 147 hash drift, clarify hash rule - Retrospective
**Task**: 149 (chore)

## Task Reference
- **Task ID**: internal-149
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/149-fix-task-147-hash-drift-clarify-hash-rule
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-17

## Executive Summary
- **Duration**: ~17 min wall-clock from a-task-plan checkpoint (16:43) to g-testing-exec checkpoint (17:00). Original estimate: ~1 hour. Variance: roughly −72%.
- **Scope**: Delivered exactly as planned — two hash refreshes + one new convention doc + four consumer wires. No additions, no removals. The misalignment-agent permission violation was explicitly excluded in a-plan §Constraints and remains as documented Future Work.
- **Outcome**: Success. 13/13 testing TCs PASS first-walk. The in-task hash-update convention is now codified in a single source of truth (`.cwf/docs/conventions/hash-updates.md`) that the implementation-exec SKILL, retrospective SKILL, `CLAUDE.md`, and `design-alignment.md` all link.

## Variance Analysis
### Time and Effort
- **Estimated**: ~1 hour, Low complexity, chore (a/d/e/f/g/j only).
- **Actual**: ~17 min wall-clock across five exec-phase checkpoints (a, d, e, f, g). Plan-review map/reduce during d-phase added measurable time but caught a load-bearing baseline error before it would have triggered the f-exec STOP rule.
- **Variance**: −72%. The estimate priced uncertainty around the convention doc shape (length, sections, framing); the actual doc came in at 49 lines, the consumer wiring took two anchor-based Edits, and validate cleared cleanly first try.

### Scope Changes
- **Additions**: None.
- **Removals**: None.
- **Impact**: Strict scope adherence — the misalignment-agent permission violation was named in a-plan §Constraints and stayed out of scope. The d-plan added a Step 9 explicit STOP-condition for unexpected validate output specifically to prevent a "while we're here" temptation to absorb it.

### Quality Metrics
- **Test coverage**: 13/13 TCs PASS first-walk. No retest, no plan amendment.
- **Defect rate**: 0 bugs. 1 plan amendment caught by the plan-review subagents during d-phase (Robustness F1 — shared baseline `7500aef` would have over-included Tasks 139/140's commits on backlog-manager and triggered STOP in error). Caught and fixed before any exec.
- **Performance**: N/A.

## What Went Well
- **Plan-review caught the load-bearing baseline error**. The first d-plan draft used a single shared baseline (`7500aef`) across both hashed paths. Robustness subagent F1 surfaced that the assumption was unverified; investigation showed Tasks 139/140 had each touched `backlog-manager` and refreshed the hash in-task, so the shared baseline would have over-included three commits when only one was actually drifted. The fix — per-file baselines `4f47494` for `Backlog.pm` and `f833bbf` for `backlog-manager` — encoded the "per-file, not assumed-shared" lesson into the convention doc itself (`§Pre-refresh verification`).
- **The deferred-hash-drift left visible by Task 148 was the right call**. Validate's persistent `[SECURITY]` lines for `CWF/Backlog.pm` and `backlog-manager` between Task 148 squash and Task 149 start were the explicit unsmoothed signal. Without that friction, this convention doc wouldn't have a concrete historical example, and the failure mode wouldn't have been visible long enough to write a rule for.
- **String-anchor Edits over line numbers held up**. Both SKILL.md insertions used `## Scope & Boundaries` as the post-context anchor. Any future Gotcha insertion will not shift our anchor; line-number-based edits would have rotted on the next neighbouring change.
- **Single-source-of-truth doc placement worked**. `.cwf/docs/conventions/hash-updates.md` (runtime-consumed, alongside `tmp-paths.md` and `subagent-tool-selection.md`) keeps the rule co-located with its primary consumers (the two runtime SKILLs). `CLAUDE.md` and `docs/conventions/design-alignment.md` are pointers, not restatements — no rule-drift surface.

## What Could Be Improved
- **e-plan TC-10 grep regex was too strict**. The pass condition asserted "case-insensitive presence of seven required strings", but the first execution attempt anchored exact-heading matches (`^## Convention$`) and missed `## Carve-out (narrow, invariant-guarded)`. A literal grep on the section heading text would not have worked; the partial-match grep (`grep -ciE`) had to be improvised at test-exec time. Lesson: TC pass conditions that say "case-insensitive grep for these strings" should explicitly call out partial-match semantics.
- **Convention doc landed at 49 lines vs. ~60-70 target**. Same pattern as Task 148's recipes doc (30 vs. ~20 target — under target, not over). Declarative criteria framing keeps prose compact; minimum-viable-doc estimates skew low. Worth noting that under-target on a documentation deliverable is not the failure mode to worry about, but the *target* is the dial to recalibrate.
- **The first d-plan draft's shared-baseline assumption was the textbook "shared-mental-model from glancing at validate output"**. Both hashes appeared in the same validate report, both attributed to Task 147 by commit message — easy to assume a shared baseline without `git log -S` verification. Robustness F1 was the right catch at the right phase; the d-plan ideally would have surfaced this in self-review. Lesson encoded directly into `§Pre-refresh verification`: "per file, not assumed-shared baselines."

## Key Learnings
### Technical Insights
- **Per-file hash baselines are the rule, not the exception**. Two hashed files refreshed in the same commit don't share a "last-set-at" baseline unless they were last set in the same commit. The git query `git log -S "<old-hash>" -- .cwf/security/script-hashes.json` is the authoritative way to find each file's last-hash-set commit; using either file's commit log directly conflates source edits with hash refreshes.
- **The convention doc's load-bearing sentence is "per file, not assumed-shared baselines"**. Without that explicit phrasing, a future task auditing multiple hashed files at once will recreate exactly the assumption Robustness F1 surfaced.
- **Anchor-string Edits over line-number Edits is universally correct for SKILL/agent file edits**. SKILL files are append-prone (Gotchas grow); line numbers shift; anchor text (heading lines) is stable across edits unless the structure itself changes.

### Process Learnings
- **Plan-review map/reduce earned its keep on a docs+config task**. 4 subagents flagged 17 findings across the d-plan; the highest-impact catch (Robustness F1) would have caused an exec-phase STOP. The other 16 findings tightened wording (carve-out invariants, "What NOT to build" principle framing, line-budget) before they shipped.
- **The Task 148 retrospective's "Future Work" entry that named this task was the right structural choice**. Orphaning the Task 147 side-quest out of Task 148's history left the drift visible to validate; the urgent very-high-priority follow-up landed cleanly with its own complete a-j workflow. Pattern to repeat: when a task discovers an unrelated issue, file it as a successor task, don't absorb it.
- **Chore-task workflow (a/d/e/f/g/j only) is the right shape for "fix + codify" work**. Skipping b-requirements-plan and c-design-plan saved the overhead of pseudo-requirements ceremony; the a-plan's success criteria + d-plan's steps were sufficient.

### Risk Mitigation Strategies
- **Explicit STOP conditions in plans prevent scope creep mid-exec**. d-plan Step 9 wrote: "If validate reports ANY sha256 drift beyond the misalignment-agent permission issue, DO NOT refresh further entries in this task". This is the structural defence against the "while we're here, let me clear the validate output" instinct that originally got Task 147 into trouble.
- **The four-invariant carve-out is the structural defence against "dedicated hash-fix task" self-labelling**. Any future task wanting to invoke the carve-out has to satisfy all four conditions verifiably (named entries / per-file `git log` / no other source edits / originating commit named). Self-applied labels don't work.

## Recommendations
### Process Improvements
- **Plan-review checklist gains a "per-file baseline" verification for any task touching multiple hashed paths**. The check is: for each path, `git log -S "<old-hash>" -- .cwf/security/script-hashes.json` should name a single commit; collect the commits per-path and STOP if any pair differs. Task 149's d-plan Step 1 already encodes this; lifting it into plan-review keeps it from being re-derived per task.
- **TC pass conditions that say "grep for strings" should specify partial-match vs. exact-line semantics**. e-plan TC-10 cost one minute at test-exec to improvise the right grep; an explicit `grep -ciE '<strings>'` in the TC body would have made the test self-executing.

### Tool and Technique Recommendations
- **Declarative-criteria framing for agent-consumed convention docs is now a written-down pattern.** Both `dead-code-audit.md` (Task 148) and `hash-updates.md` (Task 149) use "do X when condition Y" rather than "follow these steps" — the framing survives partial reads and prevents the "skill cargo-cults the doc" failure mode.
- **String-anchor Edits over line-number Edits**: this is general enough to lift into a CLAUDE.md note if any future task hits the same insertion-shift problem.

### Future Work
- **Misalignment-agent permission violation (0600 vs 0444)**: explicitly out of scope per a-plan §Constraints. Git tracks only the executable bit, so `chmod 0444` doesn't survive `git checkout`. This needs structural treatment (changing the expected permission in `script-hashes.json`, or rethinking how the perm bit is enforced for read-only-by-design files). A BACKLOG entry will be filed.

## Status
**Status**: Finished
**Next Action**: Suggest merge to user (Step 12 of skill)
**Blockers**: None identified
**Completion Date**: 2026-05-17
**Sign-off**: Claude Opus 4.7

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- **Planning documents**: `implementation-guide/149-chore-fix-task-147-hash-drift-clarify-hash-rule/`
  - a-task-plan.md, d-implementation-plan.md, e-testing-plan.md, f-implementation-exec.md, g-testing-exec.md, j-retrospective.md
- **Implementation commits** (pre-squash, on chore/149 branch):
  - `ada518f` Task 149: Complete task plan phase
  - `440c190` Task 149: Complete implementation plan phase
  - `1a18abe` Task 149: Complete testing plan phase
  - `b5a83ba` Task 149: Complete implementation exec phase
  - `6e398a2` Task 149: Complete testing exec phase
- **Test results**: g-testing-exec.md — TC-1..TC-13 all PASS first-walk
- **Modified / created files** (in the Task 149 squash):
  - `.cwf/security/script-hashes.json` (2 sha256 updates: `CWF::Backlog`, `backlog-manager`)
  - `.cwf/docs/conventions/hash-updates.md` (NEW, 49 lines)
  - `.claude/skills/cwf-implementation-exec/SKILL.md` (+1 Gotcha)
  - `.claude/skills/cwf-retrospective/SKILL.md` (+1 Gotcha)
  - `CLAUDE.md` (+1 Conventions entry)
  - `docs/conventions/design-alignment.md` (+1 cross-reference)
