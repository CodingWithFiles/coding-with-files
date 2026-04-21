# Discover best gotchas for skills via LMM memory analysis - Testing Plan
**Task**: 107 (discovery)

## Task Reference
- **Task ID**: internal-107
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/107-discover-best-gotchas-for-skills-via-lmm-mem
- **Template Version**: 2.1

## Goal
Verify the discovery output meets acceptance criteria: coverage, evidence quality, and actionability.

## Test Strategy

### Test Levels
- **Completeness**: All 19 skills queried or marked insufficient data
- **Evidence quality**: Each gotcha backed by 2+ occurrences
- **Actionability**: Backlog items contain specific, usable gotcha text

## Test Cases

### Functional Test Cases

- **TC-1**: All skills covered
  - **Given**: Research complete (f-implementation-exec.md written)
  - **When**: Count skills with findings + skills marked "insufficient data"
  - **Then**: Total = 19

- **TC-2**: Evidence threshold met (no speculation)
  - **Given**: Gotchas identified in f-implementation-exec.md
  - **When**: Check each gotcha's source references
  - **Then**: Every gotcha cites 2+ distinct occurrences (different tasks or sessions)

- **TC-3**: Backlog items produced
  - **Given**: Analysis complete
  - **When**: Check f-implementation-exec.md for drafted backlog items
  - **Then**: 3-5 backlog items exist with: task-type, priority, draft gotcha text, source reference

- **TC-4**: Gotchas are actionable
  - **Given**: Draft gotcha text in backlog items
  - **When**: Review each gotcha
  - **Then**: Each contains: specific scenario + what goes wrong + how to avoid

## Test Environment

### Setup Requirements
- f-implementation-exec.md populated with research findings
- LMM MCP server accessible for spot-check verification

## Validation Criteria
- [ ] TC-1: 19 skills covered (findings or insufficient data)
- [ ] TC-2: Every gotcha has 2+ source references (no speculation)
- [ ] TC-3: 3-5 backlog items drafted
- [ ] TC-4: All gotchas are actionable (scenario + failure + avoidance)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 107
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
