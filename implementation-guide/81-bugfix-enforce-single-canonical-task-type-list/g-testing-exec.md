# enforce single canonical task type list across CWF modules - Testing Execution
**Task**: 81 (bugfix)

## Task Reference
- **Task ID**: internal-81
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/81-enforce-single-canonical-task-type-list
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Finished" — all tests pass

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | `supported_types()` returns canonical list | 5 types incl. discovery & feature | Count: 5, has discovery: yes, has feature: yes | PASS |
| TC-2 | Export derived from `%WORKFLOW_FILES` keys | Lists identical | `join(",",@types) eq join(",",@from_hash)` → yes | PASS |
| TC-3 | Unknown type `docs` → violation | ≥1 violation mentioning `docs` | 1 violation, `actual =~ /unknown.*docs/` | PASS |
| TC-4 | Missing type `discovery` → violation | ≥1 violation mentioning `discovery` | 1 violation, `actual =~ /missing.*discovery/` | PASS |
| TC-5 | Exact canonical list → no violations | 0 violations | 0 violations | PASS |
| TC-6 | Template has only canonical types | bugfix,chore,discovery,feature,hotfix | Same; no docs/refactor/test | PASS |
| TC-7 | `cwf-manage validate` catches ghost types | Exit 1, output mentions unknown + missing | 2 violations reported, exit 1 | PASS |
| TC-8 | `prove t/` regression suite | Exit 0, ≥160 tests | Files=17, Tests=162, Result: PASS | PASS |

### Non-Functional Tests
No non-functional requirements for this bugfix.

## Test Failures

**TC-7 initial attempt**: First run passed `$TMPDIR` as git root to `cwf-manage validate`, but `cwf-manage` uses `find_git_root()` internally and ignores any passed argument. Test was adjusted to write ghost-type config to the actual `implementation-guide/cwf-project.json`, run validate, then restore the file. This is the correct approach for end-to-end testing.

## Coverage Report

- `CWF::WorkflowFiles::V21`: 2 new subtests covering `supported_types()` (count, membership, derivation)
- `CWF::Validate::Config`: 5 subtests covering bidirectional validation (exact match, unknown type, missing type, non-array, missing key)
- Full regression: 162 tests across 17 test files — all pass

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 81
**Blockers**: None

## Actual Results
All 8 test cases from e-testing-plan.md passed. The implementation correctly:
- Exports `supported_types()` from `WorkflowFiles::V21` as the single source of truth
- Validates bidirectionally in `Validate::Config` (unknown types and missing types both flagged)
- Rejects ghost types (`docs`, `refactor`, `test`) via `cwf-manage validate`
- Detects missing canonical types (`discovery`) via `cwf-manage validate`

## Lessons Learned
`cwf-manage validate` uses `find_git_root()` internally — end-to-end tests must write
ghost-type config to the actual repo path and restore, not use a temp directory.
The false-OK on first TC-7 attempt was an environment understanding gap, not a code bug.
