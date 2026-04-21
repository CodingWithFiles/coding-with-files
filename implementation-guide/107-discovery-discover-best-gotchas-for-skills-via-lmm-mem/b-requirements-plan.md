# Discover best gotchas for skills via LMM memory analysis - Requirements
**Task**: 107 (discovery)

## Task Reference
- **Task ID**: internal-107
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/107-discover-best-gotchas-for-skills-via-lmm-mem
- **Template Version**: 2.1

## Goal
Define what the discovery must produce and how to verify it is complete and useful.

## Functional Requirements

### Core Features
- **FR1**: Query LMM memory for each of the 19 CWF skills, searching for corrections, rework, user frustration, and repeated mistakes
- **FR2**: Cross-reference LMM findings with existing sources: MEMORY.md error patterns, implementation-guide retrospectives (j-retrospective.md files)
- **FR3**: Rank failure modes per skill by frequency (2+ occurrences required) and impact (rework cost)
- **FR4**: Produce backlog items for top 3-5 skills, each including draft gotchas text ready to paste into SKILL.md

### Data Sources
- **Primary**: LMM semantic search (conversation history)
- **Secondary**: MEMORY.md "Recurring Process Errors" section
- **Tertiary**: Implementation-guide `j-retrospective.md` files (lessons learned, recommendations)

## Non-Functional Requirements

### Quality (NFR1)
- Each gotcha must be specific and verified (not speculative)
- Each gotcha must reference the source conversation or task where it was observed
- Minimum 2 occurrences before classifying as a pattern

### Scope (NFR2)
- Discovery output only — no SKILL.md modifications in this task
- Backlog items are the deliverable, not code changes

## Constraints
- LMM data availability — some skills may have insufficient conversation history
- Skills with <3 conversation records should be noted as "insufficient data" rather than forced

## Acceptance Criteria
- [ ] AC1: All 19 CWF skills queried (or noted as insufficient data)
- [ ] AC2: Each identified gotcha references 2+ source occurrences
- [ ] AC3: Top 3-5 skills have backlog items with draft gotchas text
- [ ] AC4: Gotchas are actionable (specific scenario + what goes wrong + how to avoid)

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 107
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
