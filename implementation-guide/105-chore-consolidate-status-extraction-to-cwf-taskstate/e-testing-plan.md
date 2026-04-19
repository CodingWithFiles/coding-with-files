# Consolidate Status Extraction to CWF::TaskState - Testing Plan
**Task**: 105 (chore)

## Task Reference
- **Task ID**: internal-105
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/105-consolidate-status-extraction-to-cwf-taskstate
- **Template Version**: 2.1

## Goal
Verify that the generalised `MarkdownParser::extract_field()` produces identical results for all existing callers, that `TaskState` correctly layers on top, and that all 4 duplicated parsing loops are eliminated.

## Test Strategy
### Test Levels
- **Unit Tests**: Extended `t/markdownparser.t` — existing 7 subtests for `extract_status` (unchanged) plus new subtests for `extract_field` and `find_field_line`
- **Integration Tests**: `cwf-manage validate` — exercises both Validate modules with real task files
- **Regression Tests**: Full `prove t/` suite — confirms no breakage across all callers

### Test Coverage Targets
- **Critical Path**: 100% — all existing subtests pass unchanged, new `extract_field` subtests pass
- **Regression**: Full test suite green
- **Elimination**: `in_code_block` parsing loop exists only in MarkdownParser.pm

## Test Cases

### Functional Test Cases

- **TC-1**: `extract_field` works for non-status fields
  - **Given**: A wf file with `## Task Reference` section containing `**Task**: 105 (chore)` and `**Branch**: chore/105-slug`
  - **When**: `extract_field($file, qr/^## Task Reference/, qr/^\*\*Task\*\*:\s*(.+?)\s*$/)` and same for Branch
  - **Then**: Returns `105 (chore)` and `chore/105-slug` respectively

- **TC-2**: Existing status extraction behaviour preserved
  - **Given**: `t/markdownparser.t` subtests rewritten to use `extract_field` with status-specific regexes
  - **When**: `prove t/markdownparser.t`
  - **Then**: All 7 scenarios produce identical results to former `extract_status`

- **TC-3**: Validate::Workflow bug fix — config-driven validation
  - **Given**: Modified `Validate::Workflow` using `TaskState::status_is_valid()`
  - **When**: Process wf files with `**Status**: Implemented` and `**Status**: To-Do`
  - **Then**: `Implemented` returns a violation; `To-Do` does not

- **TC-4**: Full test suite + `cwf-manage validate` regression
  - **Given**: All changes applied
  - **When**: `prove t/` and `.cwf/scripts/cwf-manage validate`
  - **Then**: All tests pass, no WORKFLOW violations

- **TC-5**: Parsing loop consolidation verified
  - **Given**: All changes applied
  - **When**: `grep -rn 'in_code_block' .cwf/lib/`
  - **Then**: Only hits in `MarkdownParser.pm` — zero in TaskState, Validate::Workflow, Validate::Consistency

## Test Environment
### Setup Requirements
- Standard Perl 5.14+ with Test::More (core module)
- Existing `t/` test infrastructure (tempdir fixtures)
- Real `implementation-guide/cwf-project.json` for config-driven validation

### Automation
- `prove t/` runs full suite
- `cwf-manage validate` runs validation checks

## Validation Criteria
- [ ] TC-1: `extract_field` works for non-status fields
- [ ] TC-2: All 7 status extraction scenarios produce identical results via `extract_field`
- [ ] TC-3: `Implemented` rejected, `To-Do` accepted (bug fix verified)
- [ ] TC-4: Full `prove t/` + `cwf-manage validate` clean
- [ ] TC-5: `in_code_block` parsing loop only in MarkdownParser.pm

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
