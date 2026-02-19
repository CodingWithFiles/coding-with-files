# Improve CWF skill initialisation in cwf-init - Plan
**Task**: 70 (feature)

## Task Reference
- **Task ID**: internal-70
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/70-improve-cwf-skill-initialisation-in-cwf-init
- **Template Version**: 2.1

## Goal
Improve `cwf-init` so that newly initialised projects have skill permissions pre-registered, a CLAUDE.md enforcement preamble, and a clear prompt to commit before starting task work.

## Background
Identified during Task 63 external agent testing: agents in fresh repos were prompted on every skill call (no permissions registered), manually followed skill instructions instead of using the `Skill` tool, and skipped the post-init commit. All three are fixable via additions to `cwf-init/SKILL.md`.

## Success Criteria
- [ ] `cwf-init` offers to add all CWF skill permissions to `.claude/settings.json` (asks first, merges with existing, lists what's being added)
- [ ] `cwf-init` generates a CWF enforcement preamble in the project's `CLAUDE.md`
- [ ] `cwf-init` explicitly instructs the agent to commit before starting task work
- [ ] Existing `.claude/settings.json` permissions are preserved (no clobber)
- [ ] `cwf-manage validate` exits 0

## Original Estimate
**Effort**: <1 session
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. Skill permissions step added to cwf-init workflow
2. CLAUDE.md enforcement preamble step added
3. Init commit reminder made explicit

## Risk Assessment
### Medium Priority Risks
- **CLAUDE.md already exists in target project**: The preamble must be prepended, not overwrite the file
  - **Mitigation**: Instruct the skill to read existing CLAUDE.md first, prepend the preamble block, preserve existing content
- **`.claude/settings.json` schema varies**: Different Claude Code versions may have different structures
  - **Mitigation**: Use a safe merge pattern — read existing JSON, add to `permissions.allow` array, write back. If file absent, create minimal structure.

### Low Priority Risks
- **18 skill count may drift**: The BACKLOG says "18 CWF skills" but the count changes as skills are added/removed
  - **Mitigation**: Instruct the skill to list skills dynamically from `.claude/skills/cwf-*/` rather than hardcoding a count

## Dependencies
- None

## Constraints
- Changes are to `cwf-init/SKILL.md` only — no new scripts
- Must not silently modify user files; always ask first for permissions registration

## Decomposition Check
- [ ] **Time**: >1 week? — No
- [ ] **People**: >2 people? — No
- [ ] **Complexity**: 3+ distinct concerns? — Yes (permissions, CLAUDE.md, commit reminder) but all in one file, low risk
- [ ] **Risk**: High-risk? — No
- [ ] **Independence**: Separable? — Yes, but no benefit to splitting

No decomposition needed — three small additions to one skill file.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 70
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
