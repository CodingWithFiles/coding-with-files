# Add gotchas to cwf-implementation-exec skill - Plan
**Task**: 117 (chore)

## Task Reference
- **Task ID**: internal-117
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/117-add-gotchas-to-cwf-implementation-exec-skill
- **Template Version**: 2.1

## Goal
Add execution-phase gotchas to `cwf-implementation-exec/SKILL.md` so the agent
catches two recurring failures during implementation: missed untracked files at
commit time, and stale strings left in generated output after a rename or string substitution.

## Success Criteria
- [ ] `## Gotchas` section added to `cwf-implementation-exec/SKILL.md` (matching the placement and style used in cwf-retrospective, cwf-design-plan, and cwf-implementation-plan)
- [ ] Gotcha covering "always `git status` before commit" included, with rationale
- [ ] Gotcha covering "after rename or string substitution: grep source AND generate sample output artefact" included, with rationale
- [ ] Wording is project-neutral (no "Task NNN" references in installable SKILL.md)
- [ ] No other content changes to the skill file

## Original Estimate
**Effort**: <1 session
**Complexity**: Low
**Dependencies**: Tasks 109, 110, 111 established the gotchas pattern in sibling skills

## Major Milestones
1. **Plan**: Decide final wording for both gotchas (concise, project-neutral, action-oriented)
2. **Implement**: Edit `.claude/skills/cwf-implementation-exec/SKILL.md`
3. **Verify**: Inspect diff, grep for `Task [0-9]+` to confirm project-neutrality

## Risk Assessment
### High Priority Risks
- None

### Medium Priority Risks
- **Risk**: Wording drifts into project-specific references (the bug Task 110 introduced and Task 111 fixed).
  - **Mitigation**: Explicit project-neutrality grep in testing plan; reuse the exact phrasing pattern from existing gotcha sections.
- **Risk**: Gotcha bloat dilutes the forcing function — too many top-of-skill gotchas reduce the impact of the most important ones.
  - **Mitigation**: Stop at the two gotchas from the backlog item. Resist adding adjacent gotchas not explicitly scoped in this task.

## Dependencies
- None external. Existing gotcha sections in sibling skills provide the pattern and structure.

## Constraints
- Installable SKILL.md files must remain project-neutral (no task numbers, no project-internal references).
- Each gotcha: 1–3 sentences stating the rule, the reason, and the action.

## Decomposition Check
- [ ] **Time**: <1 session — no decomposition needed
- [ ] **People**: Single-agent task
- [ ] **Complexity**: One file, two new gotchas — low complexity
- [ ] **Risk**: Low — purely additive documentation change
- [ ] **Independence**: Both gotchas target the implementation-exec phase and share placement; splitting would create churn

No decomposition signals triggered.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered on target: 1 session, 1 file modified (`cwf-implementation-exec/SKILL.md`),
all 5 success criteria met. Wording iterated twice — once via plan review (added
"unstaged"; made source-grep ordering explicit) and once via user review (replaced
"rebrand" with "rename or string substitution").

## Lessons Learned
Same shape as Task 111's gotcha-rollout chore: planning ceremony is proportional
to the precision required of a few sentences, not the line count. User wording
review remains the highest-value gate after plan review for installable-text tasks.
