# backlog-manager double-encodes non-ASCII @ARGV - Testing Execution
**Task**: 137 (bugfix)

## Task Reference
- **Task ID**: internal-137
- **Branch**: bugfix/137-backlog-manager-double-encodes-non-ascii-argv
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify the implementation from d-implementation-plan.md.

## Test Results

### Functional Tests

| Test ID | Test Case                                                | Expected           | Actual             | Status   | Notes |
|---------|----------------------------------------------------------|--------------------|--------------------|----------|-------|
| TC-F1   | `backlog-manager add` UTF-8 argv round-trip              | Clean UTF-8 bytes  | Clean UTF-8 bytes  | PASS     | New file `t/backlog-manager-argv-utf8.t`; child spawned with `delete $ENV{PERL5OPT}` so shebang is sole `-C` source. Regression verified by temporarily reverting `backlog-manager` shebang to `-CDSL` — test failed with mojibake (`ÃÂ¢ÃÂÃÂ`), then restored and test passed again. |
| TC-F2   | `backlog-manager normalise` preserves non-ASCII          | Bytes preserved    | Bytes preserved    | PASS     | Same file, second subtest. |
| TC-F3   | Validator accepts `-CDSLA` shebang                       | No shebang viol.   | No shebang viol.   | PASS     | Implicitly covered by all 7 existing fixture subtests (TC-U3/U4/U4b/U4c/U4d/U5/U6) — every fixture uses `-CDSLA` and validates clean for the shebang rule. |
| TC-F4   | Validator rejects `-CDSL` shebang                        | 1 shebang viol.    | 1 shebang viol.    | PASS     | New subtest `TC-U3c` in `t/validate-perl-conventions.t`. Asserts `field=shebang` and `expected=#!/usr/bin/perl -CDSLA`. |
| TC-F5   | All 11 affected scripts have new shebang                 | All `-CDSLA`       | All `-CDSLA`       | PASS     | `head -1` of each of the 11 scripts shows `#!/usr/bin/perl -CDSLA`. |
| TC-F6   | No `-CDSL$` shebang remains under `.cwf/`                | 0 matches          | 0 matches          | PASS     | `grep -rln '^#!/usr/bin/perl -CDSL$' .cwf/` → 0 hits. |
| TC-F7   | `cwf-manage validate` exit 0                             | Exit 0             | `[CWF] validate: OK` | PASS   | No `SECURITY` or `PERL_CONVENTIONS` violations. |
| TC-F8   | Convention doc no longer claims `-CDSL` decodes argv     | Doc updated        | Not executed       | DEFERRED | Doc updates (perl-git-paths.md, SKILL.md, INSTALL.md, Common.pm, security-review.md) were explicitly scoped out of Task 137 mid-execution. Tracked by Very-High backlog item "Re-align Perl-Script Convention to Task-27 Form and Anchor in CLAUDE.md". |

### Non-Functional Tests

| Test ID | Test Case                  | Expected | Actual                                    | Status |
|---------|----------------------------|----------|-------------------------------------------|--------|
| TC-NF1  | `prove -r t/` exit 0       | Exit 0   | 42 files, 461 tests, all PASS             | PASS   |
| TC-NF2  | `cwf-manage validate` ex 0 | Exit 0   | `[CWF] validate: OK`                      | PASS   |

## Test Failures
None.

## Deferral Note (TC-F8)
TC-F8 verifies that documentation in `docs/conventions/perl-git-paths.md` no longer carries the false claim that `-CDSL` decodes `@ARGV`. During f-phase execution we discovered the documentation drift is wider than one file (SKILL.md, INSTALL.md, Common.pm warn-string, security-review.md, plus the convention doc itself) and explicitly deferred all of it to a follow-up task to keep Task 137 minimal. The deferral is captured in `f-implementation-exec.md` § "Scope (minimal, post-discovery)" and in the Very-High backlog entry "Re-align Perl-Script Convention to Task-27 Form and Anchor in CLAUDE.md". TC-F8 is intentionally not executed in this task.

## Regression-detection demonstration
To prove TC-F1 is not a vacuous pass, the `backlog-manager` shebang was temporarily reverted to `-CDSL` and the test re-run:
- With `-CDSL`: TC-F1 failed; 5 of 7 byte assertions reported mojibake; the diagnostic dump shows `ÃÂ¢ÃÂÃÂ` where `→` should be.
- Restored to `-CDSLA`: TC-F1 passes; `cwf-manage validate` returns OK (script bytes restored, hash unchanged).

This confirms the test is sensitive to the specific fix being tested.

## Coverage Report
- TC-F1 covers the user-reported bug (CWF-internal `backlog-manager` invocation path with non-ASCII argv).
- TC-F2 guards the read/write path of `normalise` against the same regression.
- TC-F4 closes the validator-rule loop (rule is now positively reject-`-CDSL` and accept-`-CDSLA`).
- TC-F5/F6/F7 cover the full set of 11 scripts touched by the fix.
- Total new test subtests: 3 (TC-F1, TC-F2 in new file; TC-U3c in existing file).
- Total tests in suite: 461 (was 458 before this task).

## Security Review

**State**: no findings

no findings. The test changeset correctly validates UTF-8 handling via isolated exec with explicit environment control, and the validator test correctly enforces the `-CDSLA` shebang requirement for scripts consuming git output.

Note: the prescribed helper `security-review-changeset --phase=testing` returned an empty changeset because it diffs `anchor..HEAD` over committed history; the g-phase work was uncommitted at review time. The subagent reviewed the new test file `t/backlog-manager-argv-utf8.t` and the new `TC-U3c` subtest in `t/validate-perl-conventions.t` directly.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None
