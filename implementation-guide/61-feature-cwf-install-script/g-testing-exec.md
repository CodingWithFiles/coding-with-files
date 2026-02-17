# CWF install script and release management - Testing Execution
**Task**: 61 (feature)

## Task Reference
- **Task ID**: internal-61
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/61-cwf-install-script
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

### Test Environment
- Bare clone at `/tmp/cwf-test-source.git` with tags: v0.1.0–v0.2.1 (original), v1.0.0, v2.0.0 (test tags on current branch tip)
- Fresh consumer repos created in `/tmp/` for each test
- Tests use `CWF_REF=feature/61-cwf-install-script` or test tags

### Functional Tests

| Test ID | Test Case | Status | Notes |
|---------|-----------|--------|-------|
| TC-1 | Fresh subtree install | PASS | `.cwf/`, `.cwf-skills/` correct; 18 symlinks in `.claude/skills/`; version file correct |
| TC-2 | Subtree history valid | PASS | Squash commits for `.cwf` and `.cwf-skills` prefixes |
| TC-3 | Blocked without CWF_FORCE | PASS | Exit code 3 |
| TC-4 | CWF_FORCE=1 reinstall | PASS | `.cwf/` and `.cwf-skills/` replaced; symlinks recreated |
| TC-5 | Fresh copy install | PASS | Correct layout, `cwf_method=copy`, perms 700, symlinks present |
| TC-6 | File sets match | PASS | Both `.cwf/` and `.cwf-skills/` identical across methods |
| TC-6a | Symlinks are relative | PASS | Target: `../../.cwf-skills/cwf-init` |
| TC-6b | Existing skills preserved | PASS | `my-custom-skill/SKILL.md` untouched; CWF symlinks coexist |
| TC-6c | Symlinks resolve | PASS | Content via symlink matches content via direct path |
| TC-7 | CWF_REF=latest | PASS | Resolved to v2.0.0 (highest tag) |
| TC-8 | Specific tag (v1.0.0) | PASS | `cwf_ref=v1.0.0` |
| TC-9 | Branch name ref | PASS | `cwf_ref=feature/61-cwf-install-script` |
| TC-10 | Invalid ref | PASS | Exit code 1 |
| TC-11 | Not inside git repo | PASS | Exit code 2 |
| TC-12 | Agent-friendly output | PASS | All lines `[CWF]` prefixed on stderr, no ANSI |
| TC-13 | cwf-manage status (subtree) | PASS | All fields displayed |
| TC-14 | cwf-manage status (copy) | PASS | All fields displayed |
| TC-15 | cwf-manage list-releases | PASS | Sorted descending |
| TC-16 | cwf-manage update (subtree) | PASS | Subtree pull succeeded; symlinks recreated |
| TC-17 | cwf-manage update (copy) | PASS | Files replaced; symlinks recreated |
| TC-18 | cwf-manage rollback | PASS | Rolled back; symlinks valid |
| TC-19 | Rollback without ref | PASS | Error with exit 1 |
| TC-20 | cwf-manage help | PASS | Usage printed |
| TC-21 | Unknown subcommand | PASS | Error with exit 1 |
| TC-22 | INSTALL.md docs | PASS | curl|bash, env vars, cwf-manage all present |
| TC-23 | No stale .cig/ refs | PASS | Zero matches |
| TC-24 | Existing scripts work | PASS | context-manager, task-context-inference both succeed |
| TC-25 | Security hashes valid | PASS | cwf-manage hash matches |

### Summary
- **28/28 PASS**
- TC-6b is the critical new test — validates the entire reason for the redesign (consumer skills preserved)

## Bugs Found During Testing
None. All five bugs from pass 1 were already fixed during the implementation rework.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 61
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 28 test cases executed and passing. No bugs found in pass 2 — the process rework through requirements/design/implementation caught all issues upfront.

## Lessons Learned
- The structured rework process (b → c → d → e → f → g) paid off: zero bugs in pass 2 vs five bugs in pass 1.
- Test environment setup matters: bare clone needs tags pointing to commits with `.cwf/` content.
