# Add measure-twice-cut-once gotchas to design-plan and implementation-plan skills - Plan
**Task**: 111 (chore)

## Task Reference
- **Task ID**: internal-111
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/111-add-measure-twice-cut-once-gotchas-to-plan-skills
- **Template Version**: 2.1

## Goal
Add a project-neutral "measure twice, cut once" gotcha to cwf-design-plan and
cwf-implementation-plan SKILL.md files, instructing the agent to verify assumptions
against the actual codebase before committing to a plan.

## Success Criteria
- [ ] `## Gotchas` section added/extended in `cwf-design-plan/SKILL.md` with measure-twice gotcha
- [ ] `## Gotchas` section added/extended in `cwf-implementation-plan/SKILL.md` with measure-twice gotcha
- [ ] Gotcha text is project-neutral (no "Task NNN" references)
- [ ] Existing Task 110 gotchas in both files preserved

## Original Estimate
**Effort**: <1 session
**Complexity**: Low
**Dependencies**: Task 110 (gotchas pattern already established in both target files)

## Major Milestones
1. **Plan**: Decide exact gotcha wording (shared or skill-specific) and placement
2. **Implement**: Edit the two SKILL.md files
3. **Verify**: Inspect diffs, confirm project-neutrality

## Risk Assessment
### High Priority Risks
- None

### Medium Priority Risks
- **Risk**: Gotcha bloat dilutes the forcing function — adding too many gotchas at
  the top of each skill reduces the impact of the most important ones.
  - **Mitigation**: One new gotcha per skill. Resist adding skill-specific variants
    beyond the shared "verify assumptions" theme.
- **Risk**: Wording drifts into project-specific references again (Task 110's bug).
  - **Mitigation**: Explicit project-neutrality check in testing plan. Grep for
    `Task [0-9]+` before merge.

## Dependencies
- None external. Task 110 established the gotcha pattern and file structure.

## Constraints
- Installable SKILL.md files must remain project-neutral.
- Keep each gotcha concise — 1-3 sentences stating the rule, the reason, and the action.

## Decomposition Check
- [ ] **Time**: <1 session — no decomposition needed
- [ ] **People**: Single-agent task
- [ ] **Complexity**: Two files, one new gotcha each — low complexity
- [ ] **Risk**: Low — purely additive documentation change
- [ ] **Independence**: The two files could be split but the gotchas share a theme; keeping them in one task preserves wording consistency

No decomposition signals triggered.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered on target: 1 session, 2 files modified, all success criteria met.
Wording iterated twice with user (enumeration removed, "check memories" added).

## Lessons Learned
The "measure twice, cut once" framing was the user's — unified two backlog items
that looked distinct (design-phase assumptions vs implementation-phase assumptions)
into one rule. Shorter and more durable than two skill-specific gotchas.
