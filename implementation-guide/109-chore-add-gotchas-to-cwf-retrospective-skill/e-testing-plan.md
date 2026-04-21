# Add Gotchas to cwf-retrospective Skill - Testing Plan
**Task**: 109 (chore)

## Task Reference
- **Task ID**: internal-109
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/109-add-gotchas-to-cwf-retrospective-skill
- **Template Version**: 2.1

## Goal
Verify the three gotchas are correctly placed in SKILL.md and that the Step 10 wording
fix is unambiguous.

## Test Strategy
Manual inspection — this is a documentation-only change to a single markdown file.
No automated tests applicable.

## Test Cases
### Structural Tests
- **TC-S1**: Gotchas section placement
  - **Given**: Modified SKILL.md
  - **When**: Read the file
  - **Then**: `## Gotchas` section appears after frontmatter closing `---` and before `## Scope & Boundaries`

- **TC-S2**: All three gotchas present
  - **Given**: Modified SKILL.md
  - **When**: Grep for gotcha content
  - **Then**: Three numbered gotchas present: stale statuses, merge, skip

- **TC-S3**: Task-number citations
  - **Given**: Gotcha text
  - **When**: Check citations
  - **Then**: Gotcha 1 cites Tasks 65, 67, 81, 84, 98, 103; Gotcha 2 cites Tasks 81, 84; Gotcha 3 cites Tasks 98, 84

### Content Tests
- **TC-C1**: Gotcha 1 mentions stop hook complement
  - **Given**: Gotcha 1 text
  - **When**: Read content
  - **Then**: Mentions that the stop-stale-status-detector hook catches Backlog only, and this sweep also catches In Progress

- **TC-C2**: Step 10 wording is suggest-only
  - **Given**: Modified Step 10 text
  - **When**: Read Step 10
  - **Then**: Contains "Suggest merge to user (do not execute)" — mirrors retrospective-extras.md "Suggest Merge" heading

### Regression Tests
- **TC-R1**: No other sections disturbed
  - **Given**: Modified SKILL.md
  - **When**: Diff against previous version
  - **Then**: Only the new Gotchas section and Step 10 wording changed; all other sections identical

## Validation Criteria
- [ ] TC-S1: Gotchas section correctly placed
- [ ] TC-S2: All three gotchas present
- [ ] TC-S3: Task-number citations correct
- [ ] TC-C1: Stop hook complement mentioned
- [ ] TC-C2: Step 10 wording unambiguous
- [ ] TC-R1: No unintended changes

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
6 test cases defined. All passed during g-testing-exec.

## Lessons Learned
TC-C2 specificity improved by plan review — originally vague "unambiguous", tightened to
expect exact wording.
