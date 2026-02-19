# Add Re-Execution Guidance to Implementation and Testing Exec Skills - Testing Plan
**Task**: 76 (bugfix)

## Task Reference
- **Task ID**: internal-76
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/76-add-re-execution-guidance-to-exec-skills
- **Template Version**: 2.1

## Goal
Verify that `re-execution.md` covers all required sections and that both exec skill
files reference it at the correct location.

## Test Strategy
- **Code review**: Read all three files and verify content against design
- **Structure checks**: Confirm reference placement is between Step 5 and Step 6
- **Regression**: First-execution (Pass 1) flow unaffected — reference is conditional

## Test Cases

### TC-1: `re-execution.md` exists and covers all four sections
- **Given**: Implementation complete
- **When**: Read `.cwf/docs/skills/re-execution.md`
- **Then**: File contains all four sections: Detection, Core Rule (no reverts),
  Commit Naming (`Task N: Pass 2: …`), Doc Handling (append `## Pass N Results`)

### TC-2: `re-execution.md` explicitly prohibits commit reverts
- **Given**: File exists
- **When**: Inspect Core Rule section
- **Then**: Contains explicit "do NOT" for `git reset`, `git revert`, and amending
  prior checkpoint commits

### TC-3: `cwf-implementation-exec` SKILL.md references `re-execution.md`
- **Given**: Implementation complete
- **When**: Read `.claude/skills/cwf-implementation-exec/SKILL.md`
- **Then**: Reference to `re-execution.md` appears between Step 5 and Step 6,
  conditional on `f-implementation-exec.md` already having results

### TC-4: `cwf-testing-exec` SKILL.md references `re-execution.md`
- **Given**: Implementation complete
- **When**: Read `.claude/skills/cwf-testing-exec/SKILL.md`
- **Then**: Reference to `re-execution.md` appears between Step 5 and Step 6,
  conditional on `g-testing-exec.md` already having results

### TC-5: Pass 1 flow unchanged — reference is conditional
- **Given**: Both SKILL.md files edited
- **When**: Inspect the re-execution check wording
- **Then**: Wording is conditional ("if … already has results") — an agent on a
  fresh task would not be directed to read the doc

### TC-6: Non-blocker rule documented
- **Given**: `re-execution.md` exists
- **When**: Read the doc
- **Then**: Explicit statement that old exec file results alone are not a blocker

## Validation Criteria
- [ ] TC-1: All four sections present in `re-execution.md`
- [ ] TC-2: Explicit no-revert rule documented
- [ ] TC-3: `cwf-implementation-exec` SKILL.md has conditional reference at correct location
- [ ] TC-4: `cwf-testing-exec` SKILL.md has conditional reference at correct location
- [ ] TC-5: Reference is conditional (Pass 1 unaffected)
- [ ] TC-6: Non-blocker rule documented

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 76
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 test cases passed via content review. No runtime infrastructure needed.

## Lessons Learned
Content-review tests (grep + read) are sufficient for documentation changes —
no need for runtime test harnesses.
