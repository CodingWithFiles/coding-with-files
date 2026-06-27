# classify auto-discover review outputs - Testing Plan
**Task**: 214 (chore)

## Task Reference
- **Task ID**: internal-214
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/214-classify-auto-discover-outputs
- **Template Version**: 2.1

## Goal
Pin both modes of `security-review-classify`: the byte-identical stdin contract (regression) and the new `--dir`/`--phase` discovery mode (happy path + edge cases), plus an empirical no-prompt acceptance check.

## Test Strategy
### Test Levels
- **Unit / harness tests** (`t/security-review-classify.t`, Perl `Test::More`): the bulk of coverage. Discovery-mode cases create a `File::Temp::tempdir` of fixture `*-review-output-<phase>.out` files, invoke the helper, and assert stdout lines / stderr warnings / exit code.
- **Regression**: the existing stdin TC-C* cases must continue to pass unchanged (proves the parser extraction into `classify_text()` is behaviour-preserving).
- **Acceptance (manual, one-off)**: run the literal discovery invocation in a real session and confirm it raises **no** permission prompt under the existing allowlist entry; run `cwf-manage validate`.

### Test Coverage Targets
- **Critical paths**: both modes' success paths — 100%.
- **Edge cases**: phase-scoping exclusion, symlink/non-regular skip, per-file open failure, zero matches, arg errors — each has a case.
- **Regression**: every pre-existing stdin case green; full `t/` suite green.

## Test Cases
### Functional Test Cases (extend `t/security-review-classify.t`)
- **TC-R1 (regression, stdin)**: existing stdin TC-C1..TC-C* unchanged.
  - **Given**: a fixture fed on stdin (no args).
  - **When**: `security-review-classify < fixture`.
  - **Then**: exactly one canonical token; exit 0 — byte-identical to pre-change output.

- **TC-D1 (discovery happy path)**: mixed states, sorted.
  - **Given**: a tempdir with `best-practice-review-output-implementation-exec.out` (findings), `security-review-output-implementation-exec.out` (no findings), `improvements-review-output-implementation-exec.out` (error).
  - **When**: `security-review-classify --dir <tmp> --phase implementation-exec`.
  - **Then**: three lines in lexical filename order — `best-practice: findings`, `improvements: error`, `security: no findings`; exit 0.

- **TC-D2 (phase scoping)**: other-phase and changeset files ignored.
  - **Given**: the TC-D1 dir plus `security-review-output-testing-exec.out` and `security-review-changeset-implementation-exec.out`.
  - **When**: `--phase implementation-exec`.
  - **Then**: only the three `-review-output-implementation-exec.out` lines; the testing-exec and `-changeset-` files contribute nothing.

- **TC-D3 (zero matches)**:
  - **Given**: an empty dir (or one with only non-matching files).
  - **When**: `--dir <tmp> --phase implementation-exec`.
  - **Then**: empty stdout; one `[CWF] WARNING:` line on stderr naming dir+phase; exit 0.

- **TC-D4 (symlink / non-regular skip)**:
  - **Given**: a real `security-review-output-implementation-exec.out` plus a **symlink** `improvements-review-output-implementation-exec.out → <regular file>` and a **subdir** `robustness-review-output-implementation-exec.out/`.
  - **When**: discovery on that dir.
  - **Then**: only the `security:` line; the symlink and subdir are skipped (pins the `-f && ! -l` decision — `-f` alone would wrongly include the symlink).

- **TC-D5 (open failure → error line)**:
  - **Given**: a matched regular file made unreadable (`chmod 0`, skip the case if run as root where the mode is bypassed).
  - **When**: discovery.
  - **Then**: `<reviewer>: error` line + an `[CWF] WARNING:` stderr line; the reviewer is **not** silently dropped; exit 0.

- **TC-D6 (arg errors)**:
  - **Given**: invocation with `--dir` but no `--phase` (and vice-versa), and an unknown flag.
  - **When**: each invoked.
  - **Then**: exit 1 with usage on stderr (the unknown-flag case pins the preserved rejection).

### Non-Functional Test Cases
- **No-prompt acceptance**: in a live session, the literal `security-review-classify --dir <scratch> --phase implementation-exec` matches `Bash(.cwf/scripts/command-helpers/security-review-classify:*)` and runs without a blocking permission prompt — the task's core motivation.
- **Determinism**: TC-D1 output order is stable across runs (lexical sort).
- **Integrity**: `cwf-manage validate` OK after the same-commit hash refresh.

## Test Environment
### Setup Requirements
- Perl core only (`Test::More`, `File::Temp`) — no non-core modules (portability constraint).
- Fixtures built in-test via `File::Temp::tempdir(CLEANUP => 1)`; no real scratch dir touched.
- TC-D5 root-skip guard (mode bits are advisory under root).

### Automation
- Runs under the existing `t/` harness (`prove`); no CI changes needed.

## Validation Criteria
- [ ] TC-R1 + all pre-existing stdin cases pass unchanged.
- [ ] TC-D1..TC-D6 pass.
- [ ] Full `t/` suite green (no regressions elsewhere).
- [ ] `cwf-manage validate` OK (hash refreshed same commit).
- [ ] No-prompt acceptance confirmed in a live session.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All validation criteria met: TC-R1 (stdin regression) + TC-D1..TC-D6 pass (30 assertions), full `t/` suite 931 green, `cwf-manage validate` OK, no-prompt acceptance confirmed live. See g-testing-exec.md for the results table.

## Lessons Learned
Refresh a hashed file's recorded sha256 in the same step as the edit — a full-suite run before the refresh flashes four integrity tests red transiently. See j-retrospective.md.
