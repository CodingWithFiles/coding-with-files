# Add measure-twice-cut-once gotchas to design-plan and implementation-plan skills - Retrospective
**Task**: 111 (chore)

## Task Reference
- **Task ID**: internal-111
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/111-add-measure-twice-cut-once-gotchas-to-plan-skills
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-22

## Executive Summary
- **Duration**: 1 session (estimated: <1 session — on target)
- **Scope**: Unified two separate backlog items (cwf-design-plan gotcha, cwf-implementation-plan gotcha) into a single shared gotcha under the "measure twice, cut once" theme, matching the user's framing.
- **Outcome**: Gotcha 3 appended byte-identically to both plan skills. 9/9 tests pass. Wording iterated twice with the user (enumeration dropped; "check memories" added; kept generic so it survives future memory backends).

## Variance Analysis
### Scope Changes
- **Additions**: "check memories" clause in gotcha text — added after initial plan review, per user feedback that memory sources (LMM, Claude Code memory, future) are a first-class verification source alongside grep and file reading.
- **Removals**: Enumeration of "paths, utilities, scripts, or interfaces" — dropped after user questioned why that specific list; it was weakly derived from backlog wording and didn't apply evenly to both skills.

### Quality Metrics
- **Test Coverage**: 9/9 manual test cases (2 structural, 2 content, 2 project-neutrality, 3 regression)
- **Defect Rate**: 0 shipped defects. Plan review caught the multi-line formatting inconsistency before implementation.

## What Went Well
- **Plan review ran on a 2-line change** — again. Three parallel Explore agents reported in full. Robustness agent correctly flagged that the proposed multi-line gotcha didn't match the single-line convention of existing gotchas 1 and 2. Fixed before implementation.
- **User caught a cargo-cult enumeration** — the `paths, utilities, scripts, or interfaces` list was derived from backlog wording I hadn't thought critically about. Dropping it tightened the gotcha and removed the mismatch between design-phase and implementation-phase artefacts.
- **User caught generic-vs-specific memory phrasing** — the wording was already generic ("memories") but the user reinforced the reasoning (new memory types may arrive; don't enumerate). The gotcha is now more durable for that.
- **Project-neutrality held** — no "Task NNN" references in gotcha 3 at any point. The Task 110 lesson stuck.
- **Status sweep (Gotcha 1 from cwf-retrospective)** — all 5 prior phases were Finished before retrospective; no stale-status fix needed. First time in 3 tasks the sweep found nothing to do.

## What Could Be Improved
- **Initial wording had two weaknesses, not one** — both the enumeration and the missing "memories" clause. The plan review agents didn't catch either. The improvements agent in particular said "the gotcha is ready for implementation as written" when it wasn't. This is a limit of map/reduce plan review: the agents evaluate against criteria like "is the architecture simple" and "does it reuse patterns", not "is each word pulling its weight".
- **I pulled the enumeration from backlog wording without critical thought** — the backlog item for cwf-implementation-plan said "paths", "utilities", "scripts"; I copied those into gotcha 3. The plan's own "measure twice, cut once" rule would have told me to question whether that list was load-bearing. I only caught it when the user asked.

## Key Learnings
### Process Learnings
- **Plan review is not a writing review** — the 3 subagents assess structural and pattern concerns, not prose quality. For docstring/gotcha-style tasks where wording matters, expect another round of user feedback after plan review passes.
- **Enumerations in rules are suspect** — if a rule lists specific examples, each example is a commitment. Either the enumeration is exhaustive (rare) or it's illustrative (weak). "Verify assumptions against the codebase" is stronger than any list of artefact types.
- **"Single shared gotcha for two skills" can be right even when the two skills have different concerns** — the user's framing ("these are in effect the same thought") was correct; the backlog's two items were different expressions of one underlying rule.

## Recommendations
### Process Improvements
- **For any gotcha text going into an installable SKILL.md, invite the user to review the exact wording before the implementation-exec step.** Plan review catches format/structural issues; the user catches which words are doing real work.

### Future Work
- **Remaining gotcha backlog items**:
  - `Add Gotchas to cwf-implementation-exec Skill` — High priority, separate from this task's scope (git status before commit; grep+output after rename/rebrand)
- **TaskCreate-based forcing function for skill steps** — still the strongest next lever to prevent step-skipping (noted in Tasks 109 and 110 retrospectives).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-04-22

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
