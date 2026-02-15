# Add installation instructions - Plan
**Task**: 60 (chore)

## Task Reference
- **Task ID**: internal-60
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/60-add-installation-instructions
- **Template Version**: 2.1

## Goal
Create an INSTALL.md that enables a human or agent to install CWF into their own repository using either git subtree (with upstream sync) or file copy (static/manual upgrade).

## Success Criteria
- [ ] INSTALL.md exists at repo root with both installation methods documented
- [ ] Prerequisites section covers all system requirements (Perl, git, Claude Code)
- [ ] Git subtree method documented with add, update, and remove instructions
- [ ] Copy method documented as a first-class option with manual upgrade path
- [ ] Post-install verification steps included
- [ ] README.md Installation section updated to reference INSTALL.md

## Original Estimate
**Effort**: 1-2 hours
**Complexity**: Low
**Dependencies**: Task 59 (rebrand) complete — all paths reference `.cwf/` and `cwf-*`

## Major Milestones
1. **INSTALL.md written**: Both methods, prerequisites, verification
2. **README updated**: Installation section points to INSTALL.md
3. **Tested**: Instructions verified against actual file inventory

## Risk Assessment
### Medium Priority Risks
- **File inventory incomplete**: INSTALL.md lists files to copy but misses some
  - **Mitigation**: Use `find` to generate authoritative file lists; verify against actual `.cwf/` and `.claude/skills/cwf-*` contents
- **Subtree path conflicts**: Subtree prefix choice may conflict with existing repo structure
  - **Mitigation**: Document the prefix convention clearly and note potential conflicts

## Dependencies
- CWF rebrand (Task 59) must be complete (it is)
- `/cwf-init` skill must be functional (it is)

## Constraints
- INSTALL.md must be accurate for current file layout — no speculative future paths
- Both methods are first-class; neither is presented as inferior
- Copy method supports static installs and manual upgrades (not just "simple" installs)

## Decomposition Check
- [x] **Time**: No — estimated under 2 hours
- [x] **People**: No — single author
- [x] **Complexity**: No — single deliverable (one file + one edit)
- [x] **Risk**: No — low risk, easily reversible
- [x] **Independence**: No — single unit of work

No decomposition signals triggered.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 60
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
