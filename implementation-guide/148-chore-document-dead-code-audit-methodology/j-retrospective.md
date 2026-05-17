# Document Dead Code Audit Methodology - Retrospective
**Task**: 148 (chore)

## Task Reference
- **Task ID**: internal-148
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/148-document-dead-code-audit-methodology
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-17

## Executive Summary
- **Duration**: ~38 min wall-clock from a-task-plan checkpoint (15:41) to g-testing-exec checkpoint (16:19). Original estimate: half-day (~4 hours). Variance: roughly −84% vs. midpoint.
- **Scope**: Delivered as planned across two new docs and two reference-wiring edits. One in-scope hash refresh added during exec phase (d-plan §Supporting Changes was wrong to say "None").
- **Outcome**: Success. Self-test passed both directions on first walk; D6 3-strikes refinement bound not consumed. One follow-up backlog item remains: the comprehensive dead-code audit that this task unblocks. A separate Task 147 hash-rule issue surfaced during a-phase but was orphaned out of this task's linear history — to be addressed as its own urgent very-high-priority task.

## Variance Analysis
### Time and Effort
- **Estimated**: half-day (~4 hours), Low complexity, docs-only.
- **Actual**: ~38 min wall clock for the task itself (six checkpoints across a, d, e, f, g).
- **Variance**: −84%. The estimate priced a heavier methodology design effort; the actual work distilled to a 168-line canonical doc, a 30-line recipes sibling, and two small reference inserts. Plan-review map/reduce (4 parallel subagents during d-phase) caught 17 issues that would otherwise have surfaced as rework — net time saved against the estimate.

### Scope Changes
- **Addition (in-task, expected)**: Refreshed `cwf-plan-reviewer-misalignment` sha256 in `.cwf/security/script-hashes.json` during f-phase. d-plan §Supporting Changes incorrectly claimed no hashed file was touched. Caught by post-edit `cwf-manage validate`; fixed in-task as the in-task hash-update convention requires.
- **Orphaned mid-task work**: During a-phase, `cwf-manage validate` fired on pre-existing Task 147 hash drift (`CWF::Backlog`, `backlog-manager`). An attempt was made to fix it in-task and add a BACKLOG entry documenting the rule misapplication, but this conflated two scopes (Task 148's docs-only deliverable vs. a Task 147 follow-up). The fix commit was rebased out of this task's history before squash. The drift remains visible to `cwf-manage validate` as the explicit signal that the issue is unresolved; the next task on the queue is an urgent very-high-priority task to fix the Task 147 bug properly with its own BACKLOG entry, rule documentation, and hash refresh.
- **Removal**: None.
- **Impact**: The in-task hash refresh for the misalignment-agent file proved the convention works. Orphaning the Task 147 side-quest preserves strict-linear-task-history on main (one squashed commit per task).

### Quality Metrics
- **Test coverage**: 10/10 TCs PASS. Both methodology-self-test directions (TC-1, TC-2 false-positive; TC-3 positive control) passed first walk.
- **Defect rate**: 0 bugs. 3 plan deviations recorded (e-plan TC category prediction swap; d-plan supporting-changes claim; recipes doc line count) — none of which broke pass conditions.
- **Performance**: N/A (docs).

## What Went Well
- **Plan review caught real issues before exec**: 17 findings from 4 parallel subagents during d-phase, all addressed in the rewrite. The +30 min spent on review saved measurably more rework.
- **Retrospective-as-fixture-source worked**: Task 51's `j-retrospective.md` had the exact caller detail needed for fixture A and B; git archaeology fallback wasn't needed. Validates the retrospective phase as a load-bearing knowledge artefact.
- **Three-audience framing held**: the canonical/recipes split (D1) kept consumer-facing prose language-agnostic while letting Perl-specific operationalisation live where it belongs. The misalignment-agent reference and i-maintenance bullet are the two shift surfaces (left/right).
- **Strict linear task history preserved**: the Task 147 hash-rule side-quest discovered during a-phase was orphaned out of this branch's pre-squash history rather than absorbed into the Task 148 squash. Keeps main as one-squash-per-task and lets the next very-high-priority task own the Task 147 fix end-to-end.

## What Could Be Improved
- **d-plan §Supporting Changes claim was unverified**: I asserted no hash-tracked file would be touched without actually grepping `script-hashes.json` for the four targets. The misalignment-agent file IS tracked. Caught at first f-phase validate but should have been caught at plan-review time. **Lesson**: any plan asserting "no hash impact" needs a `grep -F "<path>" .cwf/security/script-hashes.json` check in the plan-review checklist.
- **e-plan TC category predictions inverted relative to retrospective evidence**: TC-1 expected category 3 for `workflow_file_mappings()`; actual was category 2. TC-2 expected category 2 for `format_error()`; actual was category 3. Pass conditions ("at least one category surfaces a real caller") still passed, but the prediction was wrong. Indicates the plan was written from memory of the case shape rather than against the retrospective text.
- **Recipes doc landed at 30 lines vs. ~20 target**: under TC-9's 40-line ceiling, but variance from d-plan's stated target. Acceptable but worth noting that minimum-viable-doc estimates skew low.

## Key Learnings
### Technical Insights
- **Category 6 (advertised external surface) carries the load for distinguishing appearance from caller-ness**. The positive control (`_format_uncorrelated()`) had nine appearance sites across CHANGELOG and historical planning docs. Without the "historical mentions are appearance, not advertisement" carve-out in the canonical doc, a naïve auditor following only the 6-category checklist could mis-flag them.
- **Shift-left + shift-right is one methodology with two callers, not two methodologies**. The same caller-category checklist applies whether a reviewer is reading a plan (heuristics deepen the misalignment-agent's existing bullets) or a maintainer is sweeping the working tree.

### Process Learnings
- **Half-day docs estimate is the right floor for a methodology task**. Even at 38 min execution, plan-review burned its share; without it, exec would have hit 17 rework points.
- **Plan-review map/reduce earns its keep on doc-only tasks too**. The improvements review caught the location/path/line-budget issues that a single-pass writer would have shipped.
- **Side-quest commits inside a task branch are tolerable**. `0c9a4e5` (Task 147 follow-up) lives between a and d checkpoints. The squash decision is "keep it as a discrete commit on main, alongside the Task 148 squash" — it documents the misapplication better as a freestanding commit than as a chunk of a 148 squash.

### Risk Mitigation Strategies
- **In-task hash refresh proved the convention**. The friction was the feature: validate fired, the rule got clarified mid-task, the fix landed in-diff. The eventual hash-rule task should be careful not to remove that friction.
- **Retrospective archaeology beats git archaeology**: when historical context is needed, the canonical place to look is the retrospective for the relevant task. Cheaper than `git log -S` walks and more reliable.

## Recommendations
### Process Improvements
- **Add a hash-tracked-file check to plan-review** for any plan whose Files-to-Modify list includes paths under `.cwf/scripts/`, `.cwf/lib/`, `.claude/agents/`, `.claude/hooks/`, `.claude/rules/`, or `.claude/settings*.json`. The check is one grep against `script-hashes.json`. (Distinct from the broader hash-rule clarification BACKLOG item, which is about *when* to update; this is about *whether* a plan should disclose it'll need to.)
- **Plan-time fixture recovery should quote the retrospective**: when a plan references a historical task's evidence, the plan should include a one-line quote with line number, not just a claim about the case. Would have caught the e-plan TC category inversion.

### Tool and Technique Recommendations
- **Declarative-criteria framing for agent-consumed docs is the right default**: Plan-time heuristics in `.cwf/docs/dead-code-audit.md` are phrased as "Flag if …" criteria, not "Do X" instructions. This is the Security S1 recommendation and is now a written-down pattern other agent-referenced docs can match.

### Future Work
- Comprehensive Dead Code Audit for CWF Library Modules (existing BACKLOG entry, now unblocked by this task).
- Urgent very-high-priority task to fix Task 147 hash-rule misapplication properly: refresh the drifted `CWF::Backlog` and `backlog-manager` hashes in-diff, document the in-task hash-update rule explicitly in a convention doc, and capture the retrospective-from-this-task lesson that hash drift across task boundaries should not be smoothed mid-flow by an unrelated task. (Mid-task side-quest attempt on this task was rebased out; the drift remains as the explicit signal.)

## Status
**Status**: Finished
**Next Action**: Suggest merge to user (Step 12 of skill)
**Blockers**: None identified
**Completion Date**: 2026-05-17
**Sign-off**: Claude Opus 4.7

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- **Planning documents**: `implementation-guide/148-chore-document-dead-code-audit-methodology/`
  - a-task-plan.md, d-implementation-plan.md, e-testing-plan.md, f-implementation-exec.md, g-testing-exec.md, j-retrospective.md
- **Implementation commits** (pre-squash, on chore/148 branch after rebase):
  - `b17db7f` Task 148: Complete task plan phase
  - `1d5f118` Task 148: Complete implementation plan phase
  - `451daee` Task 148: Complete testing plan phase
  - `b3c4f69` Task 148: Complete implementation exec phase
  - `bf263b8` Task 148: Complete testing exec phase
  - Retrospective commit replaced via amend after orphaning the 147 side-quest
- **Test results**: g-testing-exec.md — TC-1..TC-10 all PASS
- **Modified / created files** (in the Task 148 squash):
  - `.cwf/docs/dead-code-audit.md` (NEW, 168 lines)
  - `docs/dead-code-audit-perl.md` (NEW, 30 lines)
  - `.claude/agents/cwf-plan-reviewer-misalignment.md` (+4 lines, 37 → 41)
  - `.cwf/templates/pool/i-maintenance.md.template` (+1 line)
  - `.cwf/security/script-hashes.json` (1 sha256 update: misalignment-agent in-task)
