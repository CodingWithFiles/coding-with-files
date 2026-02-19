# Harden Install Script with Pre-Flight Checks and Simplify Bootstrap - Testing Execution
**Task**: 75 (bugfix)

## Task Reference
- **Task ID**: internal-75
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/75-harden-install-script-preflight-checks
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify the fix is correct.

## Execution Checklist
- [x] Read e-testing-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Update status to "Finished"

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | Guard fires on empty repo (subtree) | exit=1, "no commits" in stderr | exit=1, error message correct | PASS |
| TC-2 | Guard does not fire with commits (subtree) | Passes guard, continues to clone | Passed guard, proceeded to clone step | PASS |
| TC-3 | Guard does not fire for copy method | Passes guard, continues | Passed guard, proceeded to clone step | PASS |
| TC-4 | README.md one-liner blocks correct | git archive + curl; no sparse-checkout | Correct blocks; grep confirms no sparse-checkout | PASS |
| TC-5 | INSTALL.md one-liner blocks correct | GitHub + non-GitHub sections; no sparse-checkout | Correct sections; grep confirms no sparse-checkout | PASS |
| TC-6 | `cwf-manage validate` passes | `validate: OK` | `validate: OK` | PASS |

### Test Method Notes

TC-2 and TC-3: `source install.bash` triggers `main()` at end of script, which calls
`check_prerequisites()` internally. The key signal is absence of "no commits" error
message — both tests proceeded past the guard to the clone step (which fails in the
test environment due to no network, expected).

## Test Failures

None.

## Coverage Report

- All 6 planned test cases executed and passed
- Guard clause exercised for: empty repo + subtree, committed repo + subtree, empty repo + copy
- Doc changes verified by content inspection and grep for absence of sparse-checkout

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 75
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 test cases passed. Guard clause correctly fires only for subtree method on repos
with no commits. README.md and INSTALL.md show clean one-liner bootstrap blocks.
`cwf-manage validate` passes.

## Lessons Learned
Subshell sourcing of bash scripts is effective for testing individual functions.
TC-2 and TC-3 naturally exercised the "passes guard, continues" path by observing
that the clone step (not the guard) caused failure.
