# suggest fresh install on cwf-manage update failure - Testing Execution
**Task**: 156 (bugfix)

## Task Reference
- **Task ID**: internal-156
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/156-suggest-fresh-install-on-cwf-manage-update-failure
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [ ] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [ ] Verify test environment ready
- [ ] Execute test cases sequentially
- [ ] Record pass/fail for each test
- [ ] Document failures with reproduction steps
- [ ] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

New subtests added to `t/cwf-manage-update-end-to-end.t` (reusing the existing
synthetic-upstream harness). Run: `prove t/cwf-manage-update-end-to-end.t` → 9 subtests, all PASS.

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | Laydown failure (target tag v0.0.2 has a failing `install.bash`) → update fails | `rc != 0`; output has `install.bash laydown failed`, `might want to consider a fresh install`, `CWF_FORCE=1 … bash install.bash`, `INSTALL.md` | All 7 assertions ok | PASS |
| TC-2 | Malformed ref `;rm` (pre-flight guard) | `rc != 0`; `Invalid ref`; **no** `fresh install` | ok | PASS |
| TC-3 | Non-existent well-formed ref `v0.0.99` (fails at `resolve_ref`, pre-laydown) | `rc != 0`; **no** `fresh install` | ok | PASS |
| TC-4 | Static guard: `$update_in_progress = 1` assigned exactly once | count == 1 | ok | PASS |

### Non-Functional Tests
- **Security (no env-var interpolation)**: TC-1 asserts the printed bootstrap command contains the literal `<source-url>` placeholder — PASS. Confirms `$source` (possibly from `$ENV{CWF_SOURCE}`) is not interpolated into a printed command.
- **Usability**: TC-1 confirms the suggestion is phrased "might want to consider", `[CWF]`-prefixed, and names `INSTALL.md` — PASS.
- **Reliability / regression**: full suite `prove -j4 t/` → **46 files, 509 tests, all PASS**. No exit-code or control-flow change; success-path subtests (FR2/FR5/FR6) remain green. `cwf-manage validate` clean (hash refresh).

## Test Failures

None.

## Coverage Report

Both branches of the scoping logic exercised: hint present on a laydown failure (TC-1), hint absent on pre-flight (TC-2) and clone/resolve (TC-3) failures. Single set point verified statically (TC-4). The post-laydown version-file-write region (design Decision 2) shares TC-1's `die_msg`-with-flag-set path; covered per the e-testing-plan rationale rather than a separate brittle forced-write-failure test.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings

Reviewed both files in the testing-phase changeset against threat categories (a)–(e); all clean.

- `.cwf/scripts/cwf-manage` — the production change adds a `$update_in_progress` flag and a `die_msg` branch that prints a static, fully-literal advisory string. No interpolation of user/env/git data into the message: the `CWF_FORCE=1 CWF_REF=<tag> CWF_SOURCE=<source-url>` line uses literal placeholders (the test explicitly asserts `<source-url>` survives un-interpolated, so a future edit that interpolated `$ENV{CWF_SOURCE}` would fail the suite). No new `system`/backtick callsites, no path/`chmod`/`rm` flow. (a),(b),(d) N/A; (c) N/A — the message is a fixed string, not model-bound input.
- `t/cwf-manage-update-end-to-end.t` — new subtests use list-form `system`/`run(cmd => [...])` throughout (via `consumer_manage`/`git_ok`), no single-string shell spawn. The `;rm` and `$(touch pwned)`-style refs are passed as single `@ARGV` elements to `cwf-manage`, never to a shell. `slurp` opens with explicit 3-arg `open` on a fixed `$REPO_ROOT`-derived path. All test inputs are fixture-controlled, not external.

Pattern note (category (e)), advisory only — not a finding: the new `die_msg` advisory hard-codes `bash install.bash`. Safe here because the message is purely informational text shown to a human, never executed. Audit future uses if this string is ever templated with live `$ENV{CWF_SOURCE}`/`$ref` values, where the literal-placeholder invariant would no longer hold.

## Lessons Learned
*To be captured during retrospective*
