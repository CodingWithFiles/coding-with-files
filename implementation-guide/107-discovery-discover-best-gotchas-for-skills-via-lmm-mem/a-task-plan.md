# Discover best gotchas for skills via LMM memory analysis - Plan
**Task**: 107 (discovery)

## Task Reference
- **Task ID**: internal-107
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/107-discover-best-gotchas-for-skills-via-lmm-mem
- **Template Version**: 2.1

## Goal
Query LMM conversation memory to identify the most common and impactful failure modes per CWF skill, then produce ranked backlog items for adding gotchas sections to skill definitions.

## Success Criteria
- [ ] All 19 CWF skills queried via LMM semantic search for failure patterns
- [ ] Failure modes ranked by frequency and impact per skill
- [ ] Backlog items created for skills with actionable gotchas (target: top 3-5 skills)
- [ ] Each backlog item includes specific gotchas text ready to add to SKILL.md

## Original Estimate
**Effort**: 1 session
**Complexity**: Medium
**Dependencies**: LMM memory MCP server with ingested CWF conversation history

## Major Milestones
1. **Query LMM**: Search for corrections, rework, and user frustration per skill
2. **Analyse patterns**: Rank failure modes by frequency and impact
3. **Produce backlog items**: Draft gotchas sections and create backlog entries

## Risk Assessment
### Medium Priority Risks
- **Insufficient LMM data**: Some skills may have too few conversation records to identify patterns
  - **Mitigation**: Supplement with MEMORY.md error patterns and implementation-guide retrospectives
- **False positives**: One-off issues mistaken for recurring patterns
  - **Mitigation**: Require 2+ occurrences before classifying as a gotcha

## Dependencies
- LMM memory MCP server operational with CWF project data ingested

## Constraints
- Discovery output only — no code changes to SKILL.md files in this task
- Gotchas must be specific and verified, not speculative

## Decomposition Check
- [x] **Time**: No — 1 session
- [x] **People**: No — single person
- [x] **Complexity**: No — single concern (research + analysis)
- [x] **Risk**: No — discovery only, no code changes
- [x] **Independence**: No — sequential query → analyse → output

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 107
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
