# Add Gotchas to cwf-retrospective Skill - Implementation Plan
**Task**: 109 (chore)

## Task Reference
- **Task ID**: internal-109
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/109-add-gotchas-to-cwf-retrospective-skill
- **Template Version**: 2.1

## Goal
Add three gotcha warnings near the top of the cwf-retrospective SKILL.md to prevent the most
recurring errors in CWF history: stale status fields, executing merges, and skipping the
retrospective entirely.

## Files to Modify
### Primary Changes
- `.claude/skills/cwf-retrospective/SKILL.md` — Add gotchas section after frontmatter, before "Scope & Boundaries"

## Implementation Steps
### Step 1: Add Gotchas Section
- [ ] Insert a `## Gotchas` section between the frontmatter (`---`) and `## Scope & Boundaries`
- [ ] Add three numbered gotchas:

**Gotcha 1 — Stale status fields**: Before writing j-retrospective.md, run
`workflow-manager status {task_num} --workflow` and fix any non-terminal statuses.
Note that the stop-stale-status-detector hook catches Backlog-only; this sweep
catches In Progress too. (6+ occurrences: Tasks 65, 67, 81, 84, 98, 103.)

**Gotcha 2 — Never execute merge to main**: Step 10 says "Suggest Merge" — output
the merge command for the user to run, never execute it yourself. (Caused problems
at Tasks 81, 84.)

**Gotcha 3 — Don't skip the retrospective**: After testing-exec (g), complete all
remaining workflow phases before starting new work. (Task 98 jumped to creating
Task 99; Task 84 backfilled wf files retrospectively.)

### Step 2: Fix Step 10 Wording
- [ ] Review Step 10 in SKILL.md — currently says "Primary: Merge to main →" with the
      actual command inline, which reads as an instruction to execute rather than suggest
- [ ] Replace with wording that mirrors retrospective-extras.md's "Suggest Merge" heading:
      `**Primary**: Suggest merge to user (do not execute):`

## Validation Criteria
- [ ] Gotchas section is between frontmatter and Scope & Boundaries
- [ ] Three gotchas present with correct task-number citations
- [ ] Step 10 reads "Suggest merge to user (do not execute)" — no phrasing that reads as an instruction to run
- [ ] No other sections disturbed

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Both steps executed as planned. Plan review subagents caught Gotcha 3 phase sequence error
and prompted concrete Step 10 wording — both applied before implementation.

## Lessons Learned
Plan review found a real bug even on a trivial plan. Don't skip it.
