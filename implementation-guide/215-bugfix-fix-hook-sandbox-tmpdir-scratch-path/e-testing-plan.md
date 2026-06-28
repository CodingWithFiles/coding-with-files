# fix hook sandbox tmpdir scratch path - Testing Plan
**Task**: 215 (bugfix)

## Task Reference
- **Task ID**: internal-215
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/215-fix-hook-sandbox-tmpdir-scratch-path
- **Template Version**: 2.1

## Goal
Validate the Approach A probe branch in `scratch_parent` across every path, with no regression to the existing `($parent,$err)` behaviour.

## Test Strategy
- **Unit** (primary): extend `t/scratch.t` (already covers `scratch_parent`/`scratch_dir` TC-1..TC-8). New cases localise `$CWF::Common::SANDBOX_TMP_PROBE` to a tempdir so the probe branch is exercised hermetically — never the real shared `/tmp/claude-<uid>`.
- **Regression**: full `prove` suite; TC-1..TC-8 all set `$ENV{TMPDIR}` so they stay on the env branch and must be unchanged.
- **Integrity**: `cwf-manage validate` clean (Common.pm hash refreshed in the same commit).
- **Manual/acceptance**: live sandbox check (already reproduced during task creation).

### Coverage target
Every branch of the new resolver: env-wins, probe-adopted, and all four fall-through-to-`/tmp` paths (absent, non-writable, symlink, empty-var). 100% of the added branch.

## Test Cases (extend t/scratch.t)
All use a real git repo fixture (`create_git_repo`) and assert against the `expected_parent($root, $base)` helper already in the file.

- **TC-9**: `$TMPDIR` set takes precedence over a present probe.
  - **Given**: `$ENV{TMPDIR}` = tempdir S; `local $CWF::Common::SANDBOX_TMP_PROBE` = a different writable tempdir P.
  - **Then**: parent base = S (probe ignored on the env branch).
- **TC-10**: probe adopted when `$TMPDIR` unset and probe is a writable dir.
  - **Given**: `delete local $ENV{TMPDIR}`; probe = writable tempdir P.
  - **Then**: parent = `expected_parent($root, P)`.
- **TC-11**: fall back to `/tmp` when probe path does not exist.
  - **Given**: `$TMPDIR` unset; probe = a non-existent path.
  - **Then**: parent = `expected_parent($root, '/tmp')`.
- **TC-12**: fall back to `/tmp` when probe exists but is not writable (the `-w` degradation path).
  - **Given**: `$TMPDIR` unset; probe = tempdir `chmod 0500`.
  - **Then**: parent base = `/tmp`. **Skip if EUID 0** (root bypasses `-w`).
- **TC-13**: fall back to `/tmp` when probe is a symlink (the `!-l` reject), even to a writable dir.
  - **Given**: `$TMPDIR` unset; probe = a symlink pointing at a writable tempdir.
  - **Then**: parent base = `/tmp` (symlink not adopted). **Skip if symlink unsupported.**
- **TC-14**: fall back to `/tmp` when `$SANDBOX_TMP_PROBE` is the empty string (the `length` guard).
  - **Given**: `$TMPDIR` unset; `local $CWF::Common::SANDBOX_TMP_PROBE = ''`.
  - **Then**: parent base = `/tmp`.

### Regression
- **TC-1..TC-8**: unchanged. Re-run to confirm the probe branch did not alter env-branch behaviour, the worktree main-root rule, `not_a_repo`, `bad_num`, the leaf mode 0700, or the symlink-leaf guard.

## Non-Functional
- **Reliability**: `scratch_parent` stays fail-safe — every non-adopt path resolves to a usable base, never `undef`/die (outside the existing `not_a_repo`).
- **Security**: TC-13 is the defence-in-depth assertion (symlinked probe rejected), parity with the `scratch_dir` leaf guard under the single-user trust model.
- **Performance**: probe adds ≤2 `stat`s per turn on the unsandboxed branch only; no assertion needed (negligible), noted for the record.

## Test Environment
- `prove -lr t/scratch.t` and full `prove` from repo root; `PERL5OPT=-CDSLA`.
- Override seam: `local $CWF::Common::SANDBOX_TMP_PROBE = <tempdir>` per case; `File::Temp` tempdirs with `CLEANUP => 1`.
- Skips: TC-12 when EUID 0; TC-13 when `symlink` unsupported (mirror TC-7's guard).

## Validation Criteria
- [ ] TC-9..TC-14 pass; TC-1..TC-8 still pass.
- [ ] Full `prove` suite green.
- [ ] `cwf-manage validate` clean (Common.pm hash refreshed same commit).
- [ ] Live: `$TMPDIR` unset → `scratch_parent` returns `/tmp/claude-<uid>/cwf-…`.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned cases executed: TC-9..TC-14 (probe branch) plus TC-1..TC-8 regression, 14/14
PASS; full suite 937 PASS; live acceptance with `$TMPDIR` unset confirmed the in-sandbox
writable base. See g-testing-exec.md.

## Lessons Learned
The overridable `$SANDBOX_TMP_PROBE` seam let every probe arm be tested hermetically
without depending on the host's real `/tmp/claude-<uid>`; self-verifying preconditions
(EUID, symlink support) kept TC-12/TC-13 honest rather than silently skipped. See
j-retrospective.md.
