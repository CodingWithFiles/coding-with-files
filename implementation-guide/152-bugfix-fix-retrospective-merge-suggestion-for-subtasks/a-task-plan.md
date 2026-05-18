# fix retrospective merge suggestion for subtasks - Plan
**Task**: 152 (bugfix)

## Task Reference
- **Task ID**: internal-152
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/152-fix-retrospective-merge-suggestion-for-subtasks
- **Baseline Commit**: f1a2a84a905e80d3ea1ffff4975daa81168a09c9
- **Template Version**: 2.1

## Goal
Make the `/cwf-retrospective` Step 12 merge suggestion target the correct parent (parent task branch for subtasks, trunk for top-level tasks) and apply the `sleep 1 && git` prefix to the suggested command so users can paste it directly into Claude Code's Bash tool.

## Success Criteria
- [ ] For a top-level task (e.g. `152`), the suggested command is `sleep 1 && git checkout main && git merge --ff-only bugfix/152-…` (trunk taken from `cwf-project.json` if set, else `main`)
- [ ] For a subtask (e.g. `20.2`), the suggested command targets the parent task's branch (e.g. `git checkout feature/20-… && git merge --ff-only feature/20.2-…`), not `main`
- [ ] All three known stale sites updated to the new wording: `.claude/skills/cwf-retrospective/SKILL.md`, `.cwf/docs/skills/retrospective-extras.md`, `.cwf/docs/workflow/versioning-standard.md`
- [ ] Final search confirms zero remaining `git checkout main && git merge --ff-only` strings outside of historical task/BACKLOG/CHANGELOG entries
- [ ] No regression to the "Never execute merge" rule — the change is wording/derivation only, not behaviour

## Original Estimate
**Effort**: ~½ day
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Design**: Decide where the parent-branch derivation lives (inline in skill prose vs. a small helper). Pin the trunk-resolution fallback chain.
2. **Implementation**: Update the three sites with the new wording / derivation rule and the `sleep 1 && git` prefix.
3. **Verification**: Grep for stale strings; render a dry-run example for one top-level and one subtask task path.

## Risk Assessment
### High Priority Risks
- **Risk 1**: The skill produces a wrong parent-branch name (e.g. wrong slug) and the user pastes a `git checkout` against a non-existent branch.
  - **Mitigation**: Derive the parent branch from the on-disk parent task *directory* (`implementation-guide/.../<parent-num>-<type>-<slug>/`), not by string-munging the task number — the directory name is the source of truth for `<type>-<slug>` and matches the branch name created by `/cwf-new-task`.

### Medium Priority Risks
- **Risk 2**: A future change to branch-naming convention re-introduces the same hardcoding.
  - **Mitigation**: Keep the derivation in one place (skill prose pointing to a single rule, or a tiny helper) so a future rename touches one site.

## Dependencies
- None external. All edits are within `.claude/skills/` and `.cwf/docs/`.

## Constraints
- Behavioural rule unchanged: the skill still only *suggests* the merge; it never executes it.
- Stay within the existing wf step skill convention — no new helper script unless design phase shows the inline rule is too fiddly.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: <1 day — no decomposition
- [x] **People**: Single-author edit — no decomposition
- [x] **Complexity**: Single concern (one suggestion string in 3 docs) — no decomposition
- [x] **Risk**: Low risk, easily reversible — no decomposition
- [x] **Independence**: Trivially atomic — no decomposition

No decomposition signals triggered.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 152
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
