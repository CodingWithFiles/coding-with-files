# Research Stop Event Hooks for CWF Quality Improvement - Design
**Task**: 103 (discovery)

## Task Reference
- **Task ID**: internal-103
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/103-research-stop-event-hooks-for-cwf-quality-improvem
- **Template Version**: 2.1

## Goal
Design the structure of the discovery output document — what sections it contains, how the framework is organised, and what format makes it actionable for future implementation tasks.

## Deliverable Structure

The discovery produces a single document: `.cwf/docs/workflow/stop-hooks-framework.md`

### Section 1: Stop Hook Mechanics
Brief reference on how Stop hooks work in Claude Code — what triggers them, what they receive, what they can output, and what it costs in tokens. Not a tutorial; a concise reference for evaluating candidates.

### Section 2: Taxonomy
Categories of Stop hooks by quality dimension. Each category gets:
- **Definition**: What quality property does this category protect?
- **Signal**: What does the hook check for?
- **CWF example**: One concrete hook that would fit this category

Candidate categories (to be validated during research):
- **Structural correctness** — did the output conform to expected format/schema?
- **Completeness** — did the agent finish what it started, or stop mid-task?
- **Consistency** — does the output match the state it claims (status fields vs actual progress)?
- **Waste detection** — did the agent do unnecessary work (files modified then reverted, circular edits)?

### Section 3: Evaluation Checklist
A short (< 20 line) checklist for assessing any candidate hook:
1. What error does this catch? (cite observed occurrence)
2. How often does this error occur? (frequency from history)
3. What does the hook cost? (tokens per stop, estimate)
4. What's the alternative? (manual review, existing tool, nothing)
5. Does this duplicate an existing check? (`cwf-manage validate`, `cwf-status`, rules injection)
6. Verdict: build / defer / skip

### Section 4: Candidate Evaluation
Apply the checklist to 2-3 real candidates. Each gets a one-paragraph assessment and a verdict.

## Research Method

1. Review Claude Code Stop hook documentation (already in system prompt)
2. Review MEMORY.md recurring process errors for patterns a Stop hook could catch
3. Query LMM memory MCP for historical error patterns (corrections, rework, missed steps)
4. Review recent task retrospectives (Tasks 98-102) for error patterns
5. Synthesise into taxonomy and evaluate candidates

## Constraints
- Output is a framework document, not code
- Must fit under 150 lines (NFR1)
- Every candidate must cite observed errors (NFR2)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 103
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
