# Create Design-Alignment Conventions Document - Plan
**Task**: 122 (chore)

## Task Reference
- **Task ID**: internal-122
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/122-create-design-alignment-conventions-document
- **Template Version**: 2.1

## Goal
Add `docs/conventions/design-alignment.md` documenting the audit, naming, reference-update, deprecation, and cross-doc-reference conventions that keep CWF skill/command/script names consistent across the codebase.

## Success Criteria
- [ ] `docs/conventions/design-alignment.md` exists alongside the other convention docs and matches their style/depth
- [ ] Document covers the five topic areas from the backlog entry: naming audit process, naming consistency, reference-update checklist, deprecation process, documentation standards
- [ ] Conventions are grounded in current CWF reality (skills under `.claude/skills/`, helper scripts under `.cwf/scripts/command-helpers/`, templates under `.cwf/templates/pool/`) — no aspirational paths
- [ ] CLAUDE.md "Conventions" section references the new doc the same way it references `commit-messages.md`
- [ ] BACKLOG.md entry for "Create Design-Alignment Conventions Document" is removed (with completion comment)

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None — pure documentation task

## Major Milestones
1. **Survey current reality**: Inventory naming patterns actually in use (skills, helper scripts, commands, templates) and list of files that typically need updating during a rename
2. **Draft the document**: Write `docs/conventions/design-alignment.md` covering the five topic areas
3. **Wire it in**: Add reference from CLAUDE.md and remove the BACKLOG entry

## Risk Assessment
### Medium Priority Risks
- **Drift from reality**: Backlog example checklist references `.claude/commands/` (a v1.0 path) — mechanical copy-paste would bake in stale paths
  - **Mitigation**: Survey current layout first; cite real files only
- **Convention vs aspiration**: Document could prescribe a deprecation process CWF doesn't actually follow today
  - **Mitigation**: Document what CWF *does* (rename + update all refs in one task; no deprecation period because CWF is its own only consumer of these names). Note the rationale rather than inventing a process

### Low Priority Risks
- **Scope creep**: Could expand into "all CWF design conventions"
  - **Mitigation**: Scope strictly to *naming and cross-reference* alignment; defer broader design conventions to separate tasks

## Dependencies
- None

## Constraints
- Follow British spelling per CLAUDE.md
- Match existing convention-doc style (`commit-messages.md`, `perl-git-paths.md`)
- No pseudocode unless the convention is genuinely subtle

## Decomposition Check
- [ ] **Time**: <1 day — no
- [ ] **People**: Single author — no
- [ ] **Complexity**: One concern (naming/reference alignment) — no
- [ ] **Risk**: Documentation-only, fully reversible — no
- [ ] **Independence**: Single deliverable — no

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 122
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met. Doc shipped at 168 lines (slightly over the 80–150 target — see j-retrospective). Both medium-priority risks (drift from reality, convention vs aspiration) mitigated by inventorying actual code before drafting. Single-session completion.

## Lessons Learned
For pure-documentation tasks with concrete prior failures to anchor on, "<1 day" estimates are accurate. The risk-mitigation strategy ("survey current layout first; cite real files only") was load-bearing — without it the doc would have repeated the BACKLOG example's stale `.claude/commands/` path.
