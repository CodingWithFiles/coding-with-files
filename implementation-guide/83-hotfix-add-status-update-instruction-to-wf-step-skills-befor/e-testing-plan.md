# Add status update instruction to wf step skills before checkpoint commit - Testing Plan
**Task**: 83 (hotfix)

## Task Reference
- **Task ID**: internal-83
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/83-add-status-update-instruction-to-wf-step-skills-befor
- **Template Version**: 2.1

## Goal
Verify that `checkpoint-commit.md` now contains a clear status-update step as its first instruction, correctly positioned before staging.

## Test Strategy
### Test Levels
- **Manual inspection**: Read the updated file and verify structure — sufficient for a single doc edit
- No automation needed

### Test Coverage Targets
- **Critical path**: New step present and numbered correctly (step 1)
- **Regression**: Existing steps 1-4 preserved, renumbered to 2-5
- **Usability**: Wording unambiguous — clearly refers to the current phase's workflow file

## Test Cases
### Functional Test Cases

- **TC-1**: New step is present and is step 1
  - **Given**: `checkpoint-commit.md` has been edited
  - **When**: File is read
  - **Then**: Step 1 instructs setting `**Status**: Finished` in the current phase file before staging

- **TC-2**: Existing steps renumbered correctly
  - **Given**: `checkpoint-commit.md` has been edited
  - **When**: All numbered steps are read
  - **Then**: Steps 2-5 match the original steps 1-4 content (Stage, Commit, Rationale, Validate)

- **TC-3**: Wording is unambiguous
  - **Given**: Step 1 text
  - **When**: Read in isolation (as an LLM would see it mid-skill)
  - **Then**: It is clear the instruction applies to the *current phase's* workflow file, not other files

### Non-Functional Test Cases
- **Usability**: Instruction fits naturally into the existing doc style (imperative heading, brief body)

## Test Environment
### Setup Requirements
- No special setup — file inspection only

### Automation
- None

## Validation Criteria
- [ ] TC-1: Step 1 sets Status: Finished before staging
- [ ] TC-2: Steps 2-5 match original steps 1-4
- [ ] TC-3: Wording unambiguous

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 83
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
