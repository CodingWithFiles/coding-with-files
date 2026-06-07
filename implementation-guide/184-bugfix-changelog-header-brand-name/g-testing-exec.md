# changelog header brand name - Testing Execution
**Task**: 184 (bugfix)

## Task Reference
- **Task ID**: internal-184
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/184-changelog-header-brand-name
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

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| TC-1 | Stale intro fires CHANGELOG-005 | `has_rule` true, severity warning, line 1 | All three asserted true | PASS | `t/backlog-tree-validate.t` subtest `TC-VAL-CHANGELOG-005` (ok 1–3) |
| TC-2 | Canonical intro silent | CHANGELOG-005 not present | Silent | PASS | same subtest (ok 4) |
| TC-3 | Body-only "(CIG)" silent (intro-scoping) | CHANGELOG-005 does not fire | Silent | PASS | same subtest (ok 5) — proves scan bound to `$tree->{intro}` |
| TC-4 | Severity is warning (default) | severity=warning; non-strict validate exits 0 | warning; CLI exit 0 with `[CWF] WARN … [CHANGELOG-005]` | PASS | unit ok 2 + `t/backlog-manager.t` CLI subtest ok 1–3 |
| TC-5 | `--strict` escalates (CLI) | exit non-zero; reported as error | exit 1; `[CWF] ERROR … [CHANGELOG-005]` | PASS | `t/backlog-manager.t` CLI subtest ok 4–5 (generic promotion, no rule-specific code) |
| TC-6 | Header corrected | line 3 canonical; full stale literal absent | line 3 = `Coding with Files (CWF)`; full literal `Code Implementation Guide (CIG)` matches nowhere | PASS | smoke grep |
| TC-7 | Live validate clean | `cwf-manage validate` OK; CHANGELOG-005 silent on CWF's own file | `[CWF] validate: OK` | PASS | line 3 now canonical → rule self-silent |
| TC-8 | No regressions | full `prove t/` green | 698 tests, all pass | PASS | `Files=58, Tests=698 … Result: PASS` |

### Non-Functional Tests
- **Reliability**: TC-3 guards the one real failure mode (false positive on historical body entries). Confirmed — the live `CHANGELOG.md` body retains `(CIG)` fragments at lines 2245 and 2854, and the intro-scoped rule correctly ignores them (TC-7 OK).
- **Security**: no new attack surface (read-only in-memory scan; no writes/exec/env). Exec-phase security review returned `no findings`; the same diff is unchanged at testing-exec (see Security Review below). Integrity intact — `cwf-manage validate` OK after the `Backlog.pm` sha256 refresh.
- **Usability**: the warning message names the canonical string `Coding with Files (CWF)`, confirmed verbatim in TC-4/TC-5 CLI output.

## Test Failures

None. All TC-1..TC-8 passed on first execution in this phase.

(One environmental working-tree permission-drift issue on `.claude/agents/cwf-security-reviewer-changeset.md` was found and fixed-on-sight during the f phase — see f-implementation-exec.md "Blockers Encountered". It is not a test failure of this task's changes and is not committable read-bit drift.)

## Coverage Report

Every branch of the new `CHANGELOG-005` block is exercised: fires (TC-1/TC-4/TC-5), silent-canonical (TC-2), silent-body-only (TC-3), severity (TC-4), strict-escalation (TC-5). No new uncovered code. Regression coverage: existing CHANGELOG-001..004 and the full 698-test suite unaffected (TC-8).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

## Security Review — testing-exec (Task 184)

I read the changeset at `/tmp/-home-matt-repo-coding-with-files-task-184/security-review-changeset-testing-exec.out` and the canonical threat model in `.cwf/docs/skills/security-review.md`. This testing-exec changeset is the cumulative task diff: the already-reviewed production change (`CWF/Backlog.pm` `CHANGELOG-005` check + `script-hashes.json` refresh + `CHANGELOG.md:3` data fix), the backlog entry, the six task-doc files, and — the testing-exec-specific surface — two extended test files (`t/backlog-manager.t`, `t/backlog-tree-validate.t`).

### (a) Bash injection / unsafe command construction
The two new subtests invoke only pre-existing harness helpers (`make_isolated`, `run_bm`) and pass them fixed literal arguments (`'validate'`, `'--strict'`). `run_bm` builds a shell string but `quotemeta`/`_shell_quote`s every interpolated value, and is unchanged by this changeset. Fixture data is written via list-form `open`, never interpolated into a command. Clean.

### (b) Perl helpers consuming git/user output without `-z` / input validation
No new git-porcelain consumption. `parse_and_validate_changelog` parses in-memory byte strings; `make_isolated` runs `git init` in list form. No NUL-splitting concern, no untrusted-string-to-backtick flow. Clean.

### (c) Prompt injection via user-supplied strings
No new `{arguments}` substitution surface. Test output is `Test::More` diagnostics, not LLM context. (Noted: `f-implementation-exec.md` embeds the prior review's `cwf-review` block as reviewed data; the deterministic classifier reads only the single emitted block, so no verdict confusion.) Clean.

### (d) Unsafe environment-variable handling
No env-var reads introduced; scratch space via `File::Temp::tempdir(CLEANUP => 1)`. Clean.

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)
The production `CHANGELOG-005` check remains intro-scoped with a literal `index` against a constant needle (TC-3 asserts the invariant). `run_bm`'s shell-string pattern is safe here (allowlisted literal flags + `_shell_quote`); audit future uses passing attacker-derived argv. Correctness properties, not security exposures.

No actionable security concerns.

```cwf-review
state: no findings
summary: testing-exec adds read-only test fixtures/assertions over the reviewed CHANGELOG-005 intro check; no new shell/git/env/untrusted-LLM-flow surface
```

## Lessons Learned
*To be captured during retrospective*
