# Identify deterministic operations still handled by agent - Testing Plan
**Task**: 100 (discovery)

## Task Reference
- **Task ID**: internal-100
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/100-identify-deterministic-ops-handled-by-agent
- **Template Version**: 2.1

## Goal
Verify the audit is complete, correctly classified, and produces actionable output.

## Test Strategy
### Test Levels
- **Completeness**: All 18 skills audited
- **Classification accuracy**: Each candidate correctly passes the deterministic test
- **Output quality**: Findings table is complete, backlog items are actionable

## Test Cases

### Completeness
- **TC-1**: All 18 skills audited
  - **Given**: Findings table in f-implementation-exec.md
  - **When**: Count distinct skills mentioned
  - **Then**: All 18 skills appear (even if some have zero candidates)

### Classification Accuracy
- **TC-2**: No false positives — no candidate requires LLM judgement
  - **Given**: Each candidate in findings table
  - **When**: Apply classification test (same input → same output? zero judgement? script could do it?)
  - **Then**: All three conditions hold for every candidate

- **TC-3**: No obvious false negatives — spot-check 3 skills for missed operations
  - **Given**: 3 randomly selected skills from the audit
  - **When**: Re-read SKILL.md and compare to findings
  - **Then**: No deterministic operations were missed

### Output Quality
- **TC-4**: Findings table has all required columns
  - **Given**: Findings table
  - **When**: Check columns
  - **Then**: Skill, Step, Operation, Category, Frequency, Error-Prone?, Extraction Complexity, Rank all present

- **TC-5**: Top candidates have backlog items
  - **Given**: Top 3-5 ranked candidates
  - **When**: Check for corresponding backlog items
  - **Then**: Each has a drafted backlog item with task type, priority, scope

- **TC-6**: Edge cases documented
  - **Given**: Edge cases section in findings
  - **When**: Check content
  - **Then**: At least 1 partially-deterministic operation documented with reasoning

### Regression
- **TC-7**: cwf-manage validate still passes
  - **Given**: All changes applied
  - **When**: Run `.cwf/scripts/cwf-manage validate`
  - **Then**: Exit 0, "OK"

## Validation Criteria
- [ ] TC-1: All 18 skills covered
- [ ] TC-2: No false positives
- [ ] TC-3: No obvious false negatives
- [ ] TC-4: Table format correct
- [ ] TC-5: Backlog items drafted
- [ ] TC-6: Edge cases documented
- [ ] TC-7: No regressions

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 100
**Blockers**: None

## Actual Results
7 test cases defined covering completeness, accuracy, ranking consistency, backlog quality, edge cases, and cross-skill deduplication.

## Lessons Learned
Testing a discovery task requires validation of completeness and quality, not just functional correctness — the test plan needed to cover audit coverage gaps.
