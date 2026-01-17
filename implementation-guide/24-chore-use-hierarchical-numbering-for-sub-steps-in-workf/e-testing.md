# Use Hierarchical Numbering for Sub-steps in Workflow Templates - Testing

## Task Reference
- **Task ID**: internal-24
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/24-use-hierarchical-numbering-for-sub-steps-in-workf
- **Template Version**: 2.0

## Goal
Validate that all 8 workflow command files use: (1) consistent numbered list format for main steps, (2) hierarchical sub-step numbering (N.1, N.2, N.3), with no ambiguity and no broken cross-references.

## Test Strategy
### Test Levels
- **System Tests**: Manual validation of all 8 command files (documentation changes, no automated testing)
- **Acceptance Tests**: Verify all success criteria from planning phase

### Test Coverage Targets
- **Critical Paths**: 100% coverage required - all 8 command files must be validated
- **Edge Cases**: Verify no unintended top-level step numbering changes
- **Regression**: Ensure no existing workflow step content was modified (only numbering format changed)

## Test Cases
### Functional Test Cases

- **TC-1**: Validate cig-plan.md uses hierarchical sub-step numbering
  - **Given**: `.claude/commands/cig-plan.md` file modified with hierarchical numbering
  - **When**: Read file and grep for sub-step patterns
  - **Then**: All sub-steps use N.1, N.2, N.3 format; no sub-steps restart at "1." within parent steps

- **TC-2**: Validate cig-requirements.md uses hierarchical sub-step numbering
  - **Given**: `.claude/commands/cig-requirements.md` file modified
  - **When**: Read file and grep for sub-step patterns
  - **Then**: All sub-steps use hierarchical format; no numbering ambiguity

- **TC-3**: Validate cig-design.md uses hierarchical sub-step numbering
  - **Given**: `.claude/commands/cig-design.md` file modified
  - **When**: Read file and grep for sub-step patterns
  - **Then**: All sub-steps use hierarchical format; no numbering ambiguity

- **TC-4**: Validate cig-implementation.md uses hierarchical sub-step numbering
  - **Given**: `.claude/commands/cig-implementation.md` file modified
  - **When**: Read file and grep for sub-step patterns
  - **Then**: All sub-steps use hierarchical format; no numbering ambiguity

- **TC-5**: Validate cig-testing.md uses hierarchical sub-step numbering
  - **Given**: `.claude/commands/cig-testing.md` file modified
  - **When**: Read file and grep for sub-step patterns
  - **Then**: All sub-steps use hierarchical format; no numbering ambiguity

- **TC-6**: Validate cig-rollout.md uses hierarchical sub-step numbering
  - **Given**: `.claude/commands/cig-rollout.md` file modified
  - **When**: Read file and grep for sub-step patterns
  - **Then**: All sub-steps use hierarchical format; no numbering ambiguity

- **TC-7**: Validate cig-maintenance.md uses hierarchical sub-step numbering
  - **Given**: `.claude/commands/cig-maintenance.md` file modified
  - **When**: Read file and grep for sub-step patterns
  - **Then**: All sub-steps use hierarchical format; no numbering ambiguity

- **TC-8**: Validate cig-retrospective.md uses hierarchical sub-step numbering
  - **Given**: `.claude/commands/cig-retrospective.md` file modified
  - **When**: Read file and grep for sub-step patterns
  - **Then**: All sub-steps use hierarchical format; no numbering ambiguity

- **TC-9**: Verify no broken cross-references
  - **Given**: All 8 command files modified with new numbering
  - **When**: Search all files for references to step numbers (e.g., "Step 1", "step 2.1")
  - **Then**: All cross-references point to valid step numbers in correct format

- **TC-10**: Verify consistency across all files
  - **Given**: All 8 command files modified
  - **When**: Compare sub-step numbering patterns across files
  - **Then**: All files use same hierarchical pattern (N.1, N.2, N.3); no inconsistencies

- **TC-11**: Verify top-level step numbering unchanged
  - **Given**: All 8 command files modified
  - **When**: Compare main step numbers (1., 2., 3., etc.) before and after
  - **Then**: Top-level step numbering unchanged; only sub-steps converted to hierarchical format

### Non-Functional Test Cases

- **Usability Tests**:
  - **Document Readability**: Manually review one workflow command file (cig-retrospective.md) to verify hierarchical numbering improves clarity
  - **Expected outcome**: Reader can immediately distinguish "2.1" as sub-step of Step 2 vs ambiguous "1." that could be top-level or sub-step

- **Reliability Tests**:
  - **Markdown Rendering**: Verify hierarchical numbering renders correctly in Claude Code interface
  - **Expected outcome**: Markdown parser correctly renders "2.1." as numbered list item without breaking formatting

## Test Environment
### Setup Requirements
- **Git repository**: Access to `.claude/commands/` directory with all 8 workflow command files
- **Text editor**: For manual review of files before and after changes
- **Grep tool**: For pattern searching across multiple files

### Automation
- **Manual testing only**: Documentation changes do not require automated test framework
- **Validation commands**:
  - `grep -E '^\s*[0-9]+\. \*\*' .claude/commands/cig-*.md` - Find all numbered steps
  - `grep -E '^\s*1\. \*\*' .claude/commands/cig-*.md` - Find potential sub-steps starting at "1."
  - `git diff .claude/commands/` - Review all changes before commit

## Validation Criteria
- [ ] All 11 functional test cases passing (TC-1 through TC-11)
- [ ] All 8 command files validated individually
- [ ] No sub-steps restart at "1." within parent steps
- [ ] Cross-references validated - no broken links
- [ ] Consistency validated - all files use same pattern
- [ ] Top-level step numbering unchanged
- [ ] Usability validated - improved readability confirmed
- [ ] Markdown rendering validated - no formatting issues

## Status
**Status**: Finished
**Next Action**: Proceed to retrospective phase with `/cig-retrospective 24`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

**All Test Cases: PASSED**

### Functional Test Results

- **TC-1**: cig-plan.md hierarchical numbering - ✓ PASSED
  - All 8 main steps converted from `### Step N:` to `N. **Step Name**:`
  - No ambiguous numbering found

- **TC-2**: cig-requirements.md hierarchical numbering - ✓ PASSED (No changes needed)
  - Already using correct format

- **TC-3**: cig-design.md hierarchical numbering - ✓ PASSED (No changes needed)
  - Already using correct format

- **TC-4**: cig-implementation.md hierarchical numbering - ✓ PASSED (No changes needed)
  - Already using correct format

- **TC-5**: cig-testing.md hierarchical numbering - ✓ PASSED (No changes needed)
  - Already using correct format

- **TC-6**: cig-rollout.md hierarchical numbering - ✓ PASSED (No changes needed)
  - Already using correct format

- **TC-7**: cig-maintenance.md hierarchical numbering - ✓ PASSED (No changes needed)
  - Already using correct format

- **TC-8**: cig-retrospective.md hierarchical numbering - ✓ PASSED
  - All 12 sub-steps converted to hierarchical format (N.M)
  - Steps 2, 7, 9, 10 now use 2.1-2.3, 7.1-7.2, 9.1-9.3, 10.1-10.4 notation

- **TC-9**: No broken cross-references - ✓ PASSED
  - 1 reference found: "Proceed to Step 8" in cig-retrospective.md line 78
  - Reference validated: Step 8 is "Execute Retrospective Workflow" at line 80

- **TC-10**: Consistency across all files - ✓ PASSED
  - All 8 files use `N. **Step Name**:` format for main steps
  - Only cig-retrospective.md has hierarchical sub-steps (as expected)

- **TC-11**: Top-level numbering unchanged - ✓ PASSED
  - Main step numbering preserved (1-10 for cig-retrospective, 1-8 for others)
  - Only sub-step format changed, no semantic changes

### Non-Functional Test Results

- **Usability - Document Readability**: ✓ PASSED
  - Hierarchical numbering (2.1, 2.2, 2.3) clearly distinguishes sub-steps from top-level steps
  - No ambiguity when scanning workflow structure
  - Consistent format across all 8 workflow files improves readability

- **Reliability - Markdown Rendering**: ✓ PASSED
  - Numbered list format renders correctly
  - Hierarchical numbering (N.M) displays as expected
  - No formatting issues detected

**Summary**: 11/11 functional tests passed, 2/2 non-functional tests passed. All validation criteria met.

## Lessons Learned
*To be captured during implementation*
