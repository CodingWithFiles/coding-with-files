# suggest fresh install on cwf-manage update failure - Testing Plan
**Task**: 156 (bugfix)

## Task Reference
- **Task ID**: internal-156
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/156-suggest-fresh-install-on-cwf-manage-update-failure
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for suggest fresh install on cwf-manage update failure.

## Test Strategy
### Test Levels
- **System / end-to-end**: New subtests in `t/cwf-manage-update-end-to-end.t`, reusing the existing `build_upstream` / `install_consumer` / `consumer_manage` harness (synthetic upstream + captured stdout/stderr). This is where the hint presence/absence behaviour is exercised against a real `cwf-manage` running in a consumer repo.
- **Static / structural**: One grep-style assertion that `$update_in_progress = 1` is assigned in exactly one place (locks down "no non-`cmd_update` path sets the flag" — robustness review finding).
- **Integrity**: `t/validate-security.t` (and `cwf-manage validate`) confirm the same-commit `script-hashes.json` refresh is clean.

### Test Coverage Targets
- **Critical path (the scoping)**: both the positive (laydown failure → hint) and the negative (pre-flight + clone/resolve failure → no hint) branches must be asserted. The negatives are load-bearing — they prove the flag scoping.
- **Regression**: existing `cwf-manage-update*.t` and `validate-security.t` pass unchanged.

## Test Cases
### Functional Test Cases (new subtests in `t/cwf-manage-update-end-to-end.t`)
- **TC-1 — laydown failure surfaces the fresh-install hint** (positive)
  - **Given**: a consumer installed at v0.0.1 (working `install.bash`), and an upstream tag v0.0.2 whose `scripts/install.bash` is a failing stub (`#!/usr/bin/env bash\nexit 1`), committed and tagged.
  - **When**: `consumer_manage(update, v0.0.2)` runs — clone + checkout succeed, then the target's `install.bash` exits non-zero (`cmd_update` line 433, flag already set at 406).
  - **Then**: `rc != 0`; output matches `/install.bash laydown failed/`; output **also** matches the hint — `/might want to consider a fresh install/`, `/CWF_FORCE=1 .* bash install\.bash/`, and `/INSTALL\.md/`.

- **TC-2 — malformed ref: no hint** (negative, pre-flight guard)
  - **Given**: a consumer installed at v0.0.1.
  - **When**: `consumer_manage(update, ';rm')` (reuses the FR9 case — rejected by `validate_ref_lexical`, line 367, before the flag is set).
  - **Then**: `rc != 0`; output matches `/Invalid ref/`; output does **not** match `/fresh install/` (`unlike`).

- **TC-3 — non-existent well-formed ref: no hint** (negative, clone/resolve stage)
  - **Given**: a consumer installed at v0.0.1 from a single-version upstream.
  - **When**: `consumer_manage(update, v0.0.99)` — passes lexical validation, clone succeeds, ref resolution fails (`resolve_ref`, ~line 399) **before** the laydown / flag-set at 406.
  - **Then**: `rc != 0`; output does **not** match `/fresh install/` (`unlike`). Confirms clone/checkout-region failures are correctly excluded. (Exact failing message to be confirmed at exec; the assertion is on hint-absence, not on the specific error string.)

- **TC-4 — flag set in exactly one place** (static guard)
  - **Given**: the edited `.cwf/scripts/cwf-manage`.
  - **When**: count occurrences of the assignment `$update_in_progress = 1`.
  - **Then**: exactly one (in `cmd_update`). Guards against a future caller-loop regression mis-firing the hint.

### Coverage note — post-laydown version-file write region (456–464)
Design Decision 2 lists `write_version_file`→`die_msg`:80 and `compute_install_manifest_sha`:463 as also carrying the hint (flag never reset). These reach `die_msg` with `$update_in_progress == 1` via the **identical** code path TC-1 exercises; a forced-write-failure test (e.g. read-only `.cwf/version`) would add brittle harness setup for a mechanically-identical assertion. Covered by TC-1 (hint emission with flag set) + TC-4 (single set point). No separate test — documented here rather than silently dropped.

### Non-Functional Test Cases
- **Security (no env-var interpolation)**: TC-1 asserts the printed bootstrap command contains the **literal** `<source-url>` placeholder (`like($out, qr/<source-url>/)`), proving `$source` (which may derive from `$ENV{CWF_SOURCE}`) is not interpolated into a printed shell command — the FR4(d) guardrail from the design.
- **Usability (message clarity)**: the hint is a suggestion ("might want to consider"), prefixed `[CWF]`, and names `INSTALL.md` — asserted by the TC-1 regex set.
- **Reliability**: no change to exit codes or control flow (additive STDERR only); existing success-path subtests (FR2/FR5/FR6) must remain green.

## Test Environment
### Setup Requirements
- `prove` (Test::More), bash 4+, git — same prerequisites as the existing end-to-end test (skips cleanly if bash <4).
- No external services; upstream/consumer repos are built in `tempdir` fixtures.

### Automation
- Run: `prove t/cwf-manage-update-end-to-end.t t/cwf-manage-update.t t/validate-security.t`.

## Validation Criteria
- [ ] TC-1 through TC-4 pass.
- [ ] Existing end-to-end + update + security tests pass unchanged (regression).
- [ ] `cwf-manage validate` clean after the hash refresh.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**Decomposition check**: No signals triggered.

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-1 through TC-4 implemented and passing; full suite green (509 tests). See g-testing-exec.md.

## Lessons Learned
See j-retrospective.md.
