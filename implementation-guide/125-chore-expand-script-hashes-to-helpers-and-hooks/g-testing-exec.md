# expand script-hashes to helpers and hooks - Testing Execution
**Task**: 125 (chore)

## Task Reference
- **Task ID**: internal-125
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/125-expand-script-hashes-to-helpers-and-hooks
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

### Functional Tests

| Test ID | Test Case                                            | Expected                                       | Actual                                                                                                                                          | Status | Notes |
|---------|------------------------------------------------------|------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|--------|-------|
| TC-U1   | Coverage test RED before splice                      | TC-C1/C2/C3 fail with 17 unregistered          | 8 fail in TC-C1, 7 in TC-C2, 2 in TC-C3 (total 17 missing); TC-U4 passed                                                                        | PASS   | Run during f-phase before manifest splice |
| TC-U2   | Coverage test GREEN after splice                     | All 4 subtests PASS; counts 22/7/2             | TC-C1: 22 hits + 1 sentinel ok; TC-C2: 7 + 1; TC-C3: 2 + 1; TC-U4: 2 — `All tests successful`                                                   | PASS   | Run during f-phase after manifest splice |
| TC-U3   | POSIX shell helpers covered                          | All 5 shell helpers in TC-C1                   | All 5 (`cwf-find-task-numbering-structure`, `cwf-load-{autoload-config,existing-tasks,project-config,status-sections}`) in 22-hit TC-C1         | PASS   | Subsumed by TC-U2 |
| TC-U4   | Walker skips symlinks                                | Real file present, symlink absent              | Self-contained `tempdir` subtest: real-file ok, link-file skipped                                                                               | PASS   | Inline subtest in coverage test |
| TC-I1   | `cwf-manage validate` zero violations                | 0 sha256 + 0 permissions                       | `[CWF] validate: OK` — pre-existing 4 perms warnings cleared                                                                                    | PASS   | Run during f-phase Step 4 |
| TC-I2   | Planted-byte-flip on top-level Perl trampoline       | `[SECURITY] sha256` cites file; revert clears  | Flip on `context-manager` → `[SECURITY] /home/matt/.../context-manager` + `1 violation(s)`; `git checkout` → `[CWF] validate: OK`               | PASS   | |
| TC-I3   | Planted-byte-flip on `.d/` subcommand                | `[SECURITY] sha256` cites file; revert clears  | Flip on `context-manager.d/hierarchy` → `[SECURITY] /home/matt/.../context-manager.d/hierarchy` + `1 violation(s)`; revert → OK                 | PASS   | |
| TC-I4   | Planted-byte-flip on hook                            | `[SECURITY] sha256` cites file; revert clears  | Flip on `stop-stale-status-detector` → `[SECURITY] /home/matt/.../stop-stale-status-detector` + `1 violation(s)`; revert → OK                   | PASS   | |
| TC-I5   | Planted-byte-flip on POSIX shell helper              | `[SECURITY] sha256` cites file; revert clears  | Flip on `cwf-load-project-config` → `[SECURITY] /home/matt/.../cwf-load-project-config` + `1 violation(s)`; revert → OK                          | PASS   | Confirms shell scripts get the same integrity guarantee as Perl |

### Non-Functional Tests

| Test ID | Test Case                              | Expected                                                | Actual                                                                                                                                          | Status | Notes |
|---------|----------------------------------------|---------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|--------|-------|
| TC-NF1  | Synthetic-file probe                   | Coverage test fails citing unregistered file; removing restores green | Dropped `probe-unregistered` (chmod 0700, unregistered) → `Failed test 'registered: .cwf/scripts/command-helpers/probe-unregistered'`; remove → All tests successful | PASS   | Demonstrates the regression-guard behaviour |
| TC-NF2  | Determinism                            | Failure messages byte-identical between runs            | `prove -r t/` twice; only diffs are pre-existing `templatecopier.t` tempdir name + CPU-timing summary line; coverage-test output byte-identical | PASS   | Sorted iteration in walker; no flakiness |
| TC-NF3  | No new attack surface                  | No new `system`/`exec`/`qx//`/`eval STRING`/refresh-hashes | f-phase diff: manifest data + test file using `Test::More`/`File::Find`/`JSON::PP` only; no shell-out, no eval, no end-user refresh facility    | PASS   | Manual review |
| TC-R1   | No regression in baseline suite        | 28 files + 1 = 29; pass count ≥ baseline + 4 subtests   | 29 files / 271 tests / All tests successful (baseline 28/267, delta +1 file +4 subtests, exactly as predicted)                                  | PASS   | |

## Test Failures
None.

## Coverage Report
- Manifest coverage of `.cwf/scripts/command-helpers/**` and `.cwf/scripts/hooks/`: 100% (TC-C1 22 + TC-C2 7 + TC-C3 2 = 31 files, all registered).
- Tier coverage by planted-byte-flip: top-level Perl, `.d/` subcommand, hook, POSIX shell helper — all 4 tiers verified.
- Symlink defence verified by self-contained subtest.

## Validation Criteria Status (from e-testing-plan.md)
- [x] TC-U1 RED before splice; TC-U2 GREEN after — counts 22/7/2 confirmed
- [x] TC-U3 GREEN — all 5 shell helpers covered
- [x] TC-U4 GREEN — symlinks skipped
- [x] TC-I1 reports 0 violations total
- [x] TC-I2/I3/I4/I5: planted-flip detected on each tier; revert clears
- [x] TC-NF1 demonstrates regression-guard behaviour
- [x] TC-NF2 shows deterministic output
- [x] TC-NF3 confirms no new attack surface
- [x] TC-R1: zero regressions

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings: empty changeset (the only files touched on this branch — `.cwf/security/script-hashes.json` and `t/validate-security-coverage.t` — are outside the security-review pathspec; manifest data and test files are not security-review surface)

## Lessons Learned
`printf '\n# planted\n' >> path && cwf-manage validate && git checkout -- path` is a clean planted-byte-flip recipe — no scratch script needed, no risk of leaving the file modified, and the validate output is captured verbatim in the test record. Re-runnable by anyone reading the g-exec doc.
