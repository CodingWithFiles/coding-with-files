# Add installation instructions - Testing Execution
**Task**: 60 (chore)

## Task Reference
- **Task ID**: internal-60
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/60-add-installation-instructions
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Finished" when all pass

## Test Results

| Test ID | Test Case | Status | Notes |
|---------|-----------|--------|-------|
| TC-1 | INSTALL.md exists at repo root | PASS | |
| TC-2 | Contains both installation methods | PASS | Method 1: Git Subtree, Method 2: File Copy |
| TC-3 | Contains prerequisites section | PASS | Mentions Perl, Git, Bash, Claude Code |
| TC-4 | All `.cwf/` paths exist in repo | PASS | `.cwf/task-stack` is runtime-created, expected absent |
| TC-5 | Skill dir references match actual | PASS | 18 actual skill dirs, INSTALL.md references `cwf-init` and `cwf-*` glob |
| TC-6 | No stale `.cig/` references | PASS | Zero matches |
| TC-7 | Git subtree add syntax valid | PASS | Two `subtree add` commands with `--prefix`, source, branch, `--squash` |
| TC-8 | Copy commands reference correct paths | PASS | `.cwf` and `.claude/skills/cwf-*` match repo layout |
| TC-9 | README references INSTALL.md | PASS | Line 54: linked |
| TC-10 | README Installation section is concise | PASS | 9 lines (down from 12) |
| TC-11 | Verification steps are actionable | PASS | 4 concrete commands |

**Result: 11/11 PASS**

## Test Failures
None.

## Additional Validation (from external repo testing)

Two manual installation tests were performed against an external repo:

1. **File copy method**: Worked. Permissions issue caught by security check (documented in Troubleshooting). Template copier warnings observed (known bug, in BACKLOG).
2. **Git subtree method (original single-prefix)**: Hit `.cwf/.cwf/` nesting issue. Led to rewrite using two-split approach. Two-split method verified in `/tmp/cwf-subtree-test` — install and update both work cleanly.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 60
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
