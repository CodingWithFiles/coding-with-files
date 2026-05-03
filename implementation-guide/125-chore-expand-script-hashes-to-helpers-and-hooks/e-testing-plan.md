# expand script-hashes to helpers and hooks - Testing Plan
**Task**: 125 (chore)

## Task Reference
- **Task ID**: internal-125
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/125-expand-script-hashes-to-helpers-and-hooks
- **Template Version**: 2.1

## Goal
Verify that the 17 newly registered hash entries (12 Perl + 5 POSIX shell) and the 4 perms-drift fixes are accepted by `cwf-manage validate`, that the new coverage test (`t/validate-security-coverage.t`) is a real regression guard, and that no existing test regresses.

## Test Strategy
### Test Levels
- **Unit (`U`)**: `t/validate-security-coverage.t` — pure-Perl `Test::More` suite asserting the manifest covers the inventoried directories.
- **Integration (`I`)**: `cwf-manage validate` end-to-end against the live `.cwf/security/script-hashes.json`; planted-breakage probe.
- **Regression (`R`)**: Full `prove -r t/` across the existing 28 test files.

### Test Coverage Targets
- **Manifest coverage**: 100% of executable files under `.cwf/scripts/command-helpers/**` and `.cwf/scripts/hooks/` registered (Perl AND POSIX shell).
- **Critical paths**: every new entry's SHA256 verified by `cwf-manage validate` (17/17); 4 drift entries pass with corrected `0500` perms.
- **Edge cases**: planted-byte-flip on each tier (top-level Perl, top-level shell, `.d/`, hook) detected.
- **Regression**: zero new failures vs the baseline test count from Task 124 close (267 tests / 28 files; refresh count at start of g-phase).

## Test Cases

### Functional Test Cases

- **TC-U1: Coverage test red before splice**
  - **Given**: `t/validate-security-coverage.t` exists; `.cwf/security/script-hashes.json` has NOT yet had the 12 new entries spliced in.
  - **When**: `prove t/validate-security-coverage.t`.
  - **Then**: All three subtests (TC-C1/C2/C3) FAIL — proves the test is meaningful.

- **TC-U2: Coverage test green after splice**
  - **Given**: 17 new entries + 4 perms updates applied to `script-hashes.json`.
  - **When**: `prove t/validate-security-coverage.t`.
  - **Then**: All three subtests PASS; counts: TC-C1=22 (14 pre-existing + 3 Perl trampolines + 5 shell helpers), TC-C2=7, TC-C3=2.

- **TC-U3: POSIX shell helpers covered**
  - **Given**: 5 shell helpers (`cwf-find-task-numbering-structure`, `cwf-load-{autoload-config,existing-tasks,project-config,status-sections}`) registered.
  - **When**: `prove t/validate-security-coverage.t`.
  - **Then**: Each shell helper is in `%registered`; TC-C1 includes all 5.

- **TC-U4: Symlink defence**
  - **Given**: A test fixture symlink at `t/fixtures/walker-skips-symlinks/some-helper` → `/etc/hostname` (or any file outside the manifest).
  - **When**: Runner walks the fixture directory.
  - **Then**: The symlink is skipped (`-l _` returns true, callback returns early). Walker does not deref. Implemented as a self-contained subtest using `File::Temp::tempdir` so no real symlink lands in `.cwf/scripts/`.

- **TC-I1: `cwf-manage validate` zero violations**
  - **Given**: 17 new entries spliced; their on-disk content unchanged from the time of hash capture; 4 drift entries' recorded perms lowered to `0500`.
  - **When**: `.cwf/scripts/cwf-manage validate`.
  - **Then**: Output contains zero `[SECURITY] sha256` violations and zero `[SECURITY] permissions` violations. The 4 pre-existing perms warnings should be gone.

- **TC-I2: Planted-byte-flip on a top-level trampoline**
  - **Given**: A reversible byte mutation appended to `.cwf/scripts/command-helpers/context-manager` (e.g. trailing `# planted` comment).
  - **When**: `cwf-manage validate`.
  - **Then**: Reports `[SECURITY] sha256` violation citing `context-manager`. Reverting the mutation clears the violation.

- **TC-I3: Planted-byte-flip on a `.d/` subcommand**
  - **Given**: Same mutation pattern on `.cwf/scripts/command-helpers/context-manager.d/hierarchy`.
  - **When**: `cwf-manage validate`.
  - **Then**: Reports `[SECURITY] sha256` for `context-manager.d/hierarchy`. Revert clears.

- **TC-I4: Planted-byte-flip on a hook**
  - **Given**: Same mutation pattern on `.cwf/scripts/hooks/stop-stale-status-detector`.
  - **When**: `cwf-manage validate`.
  - **Then**: Reports `[SECURITY] sha256` for the hook. Revert clears.

- **TC-I5: Planted-byte-flip on a POSIX shell helper**
  - **Given**: Same mutation pattern on `.cwf/scripts/command-helpers/cwf-load-project-config`.
  - **When**: `cwf-manage validate`.
  - **Then**: Reports `[SECURITY] sha256` for the shell helper — confirms shell scripts get the same integrity guarantee as Perl. Revert clears.

### Non-Functional Test Cases

- **TC-NF1 (Robustness — synthetic-file probe)**
  - **Given**: A throwaway script dropped at `.cwf/scripts/command-helpers/probe-unregistered` (any executable file — Perl, shell, doesn't matter), `chmod 0700`, NOT registered in `script-hashes.json`.
  - **When**: `prove t/validate-security-coverage.t`.
  - **Then**: TC-C1 FAILS with the unregistered file in the message. Removing the probe restores green.

- **TC-NF2 (Determinism)**
  - **Given**: Multiple consecutive runs of `prove -r t/`.
  - **When**: Compare diagnostic output between runs.
  - **Then**: Failure messages are byte-identical (sorted iteration in walker). No order-dependent flakiness.

- **TC-NF3 (No new attack surface introduced)**
  - **Given**: This task's diff vs main.
  - **When**: Manual review of f-implementation-exec changes.
  - **Then**: No new `system()`, `exec()`, `qx//`, `eval STRING`, or untrusted-input paths added; no end-user `refresh-hashes` capability introduced.

- **TC-R1 (No regression in existing suite)**
  - **Given**: Full `prove -r t/` baseline before the f-phase changes (capture file count + pass count at the start of g).
  - **When**: Re-run `prove -r t/` after f-phase.
  - **Then**: Same file count + pass count + 1 new test file (`validate-security-coverage.t`); no new failures.

## Test Environment

### Setup Requirements
- Working tree on branch `chore/125-expand-script-hashes-to-helpers-and-hooks`.
- Perl 5.10+ with `Digest::SHA`, `JSON::PP`, `Test::More`, `File::Find`, `File::Temp` (all core).
- Read access to `.cwf/scripts/command-helpers/**` and `.cwf/scripts/hooks/`.
- `.cwf/scripts/cwf-manage` executable.

### Automation
- Coverage test wired into the existing `prove -r t/` run; auto-executed by the pre-commit hook (`cwf-manage validate` runs after every checkpoint commit).
- Planted-breakage smoke is a one-shot maintainer probe during g-testing-exec, not a permanent harness.

## Validation Criteria
- [ ] TC-U1 RED before splice; TC-U2 GREEN after — proves the test is meaningful (counts: 22/7/2).
- [ ] TC-U3 GREEN — all 5 shell helpers covered.
- [ ] TC-U4 GREEN — symlinks are skipped.
- [ ] TC-I1 reports 0 violations total (sha256 + permissions).
- [ ] TC-I2/I3/I4/I5: planted-flip detected on each tier (top-level Perl, `.d/`, hook, shell helper); revert clears.
- [ ] TC-NF1 demonstrates the regression-guard behaviour.
- [ ] TC-NF2 shows deterministic output.
- [ ] TC-NF3 confirms no new attack surface.
- [ ] TC-R1: zero regressions in the baseline suite.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 13 test cases PASS. RED-before-splice (TC-U1) produced the predicted 8/7/2 fail counts; GREEN-after (TC-U2) produced 22/7/2 hits. Planted-byte-flip on all four tiers (TC-I2/I3/I4/I5) produced `[SECURITY] sha256` violations and reverted cleanly. Synthetic-file probe (TC-NF1) demonstrated regression-guard behaviour. Determinism (TC-NF2): coverage-test output byte-identical between runs. Baseline 28/267 → 29/271, exactly the predicted delta.

## Lessons Learned
The "demonstrate the test is meaningful" requirement (TC-U1) is best executed live during f-phase rather than left as an aspiration. The pre-splice RED count (17 missing) is itself useful evidence that the test exercises the right surface.
