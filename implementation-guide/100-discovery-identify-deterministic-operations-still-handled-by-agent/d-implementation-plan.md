# Identify deterministic operations still handled by agent - Implementation Plan
**Task**: 100 (discovery)

## Task Reference
- **Task ID**: internal-100
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/100-identify-deterministic-ops-handled-by-agent
- **Template Version**: 2.1

## Goal
Execute the audit: read all 18 SKILL.md files, identify deterministic operations, produce findings table and backlog items.

## Files to Read (not modify)
### Skills to Audit
All 18 files in `.claude/skills/cwf-*/SKILL.md`

### Reference (existing scripts — out of scope)
- `.cwf/scripts/command-helpers/` — baseline of what's already extracted

## Files to Create/Modify
### New Sections in f-implementation-exec.md
- Findings table with all candidates
- Backlog items for top candidates

### Modified
- `BACKLOG.md` — add top candidate items (during retrospective, per convention)

## Implementation Steps

### Step 1: Read All Skills and Identify Candidates
- [ ] Read each of the 18 SKILL.md files
- [ ] For each workflow step within each skill, apply the classification test:
  1. Given the same inputs, does it always produce the same output?
  2. Does it require zero LLM judgement?
  3. Could a bash/perl script do it with zero ambiguity?
- [ ] Record each candidate in the findings table

### Step 2: Categorise and Score
- [ ] Assign category to each candidate (JSON manipulation, file creation, status update, checkpoint commit, argument parsing, validation, git operations)
- [ ] Score each on three axes (frequency 1-3, error-proneness 1-3, extraction complexity 1-3)
- [ ] Calculate rank = frequency × error-proneness / extraction complexity

### Step 3: Draft Backlog Items
- [ ] Select top 3-5 candidates by rank
- [ ] Write backlog item for each with: task type, priority, scope, rationale

### Step 4: Document Edge Cases
- [ ] List operations that are partially deterministic (deterministic check, but judgemental response)
- [ ] Note why these are excluded or included

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 100
**Blockers**: None

## Actual Results
Implementation plan delivered: systematic audit of all 18 skills, 24 candidates catalogued, 5 backlog items drafted for follow-up tasks.

## Lessons Learned
10 of 18 skills had zero unique candidates — confirms existing helper scripts already cover most deterministic operations well.
