# Discover best gotchas for skills via LMM memory analysis - Implementation Plan
**Task**: 107 (discovery)

## Task Reference
- **Task ID**: internal-107
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/107-discover-best-gotchas-for-skills-via-lmm-mem
- **Template Version**: 2.1

## Goal
Execute the 4-phase research methodology from c-design-plan.md and produce backlog items.

## Files to Modify

### Output (discovery deliverables)
- `f-implementation-exec.md` — Research findings, per-skill analysis, ranked results
- `BACKLOG.md` — New backlog items for skills with actionable gotchas (added during retrospective)

### Read-Only (data sources)
- MEMORY.md "Recurring Process Errors" section
- `implementation-guide/*/j-retrospective.md` — Lessons learned across all tasks
- LMM memory via MCP tools (semantic search, text search)

## Implementation Steps

### Step 1: LMM Queries
- [ ] Run 2-3 broad semantic searches for CWF skill failure patterns
- [ ] Identify which skills surface most frequently
- [ ] Run targeted follow-up queries for top 3-5 skills
- [ ] Read MEMORY.md error patterns and grep retrospectives for cross-reference

### Step 2: Analysis and Ranking
- [ ] Compile all findings per skill
- [ ] Filter: require 2+ distinct occurrences
- [ ] Rank by impact, select top 3-5 skills

### Step 3: Draft Backlog Items
- [ ] Write gotcha text per selected skill (scenario + failure + avoidance)
- [ ] Format as BACKLOG.md entries per c-design-plan.md template
- [ ] Record all findings in f-implementation-exec.md

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 107
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
