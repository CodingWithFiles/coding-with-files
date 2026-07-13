# unify sandbox and non-sandbox scratch path - Testing Plan
**Task**: 229 (feature)

## Task Reference
- **Task ID**: internal-229
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/229-unify-sandbox-non-sandbox-scratch-path
- **Template Version**: 2.1

## Goal
Rework `t/scratch.t` for the EUID base: sweep the test seam from `$ENV{TMPDIR}` to
`$CWF::Common::SCRATCH_BASE`, drop the retired probe cases, and add the fix's regression
tests (poison-`$TMPDIR` invariance, two-level intermediate guard, `scratch_fail_hint`).

## Test Strategy
### Test Levels
- **Unit** (`t/scratch.t`): `scratch_parent`/`scratch_dir`/`scratch_fail_hint` in isolation,
  hermetic via `local $CWF::Common::SCRATCH_BASE = tempdir` (no real `/tmp/claude-$>` touch,
  no `$ENV{TMPDIR}` manipulation).
- **Integration/smoke** (exec phase): run `best-practice-resolve` for real and confirm its
  `.out` lands under `/tmp/claude-$>/cwf<dashed-root>/task-229/` (delegation works
  end-to-end).
- **Regression**: full `prove -r t/` green (currently 937 across the suite; the net count
  changes as TC-9..TC-14 go and new cases arrive).

### Test Coverage Targets
- Every AC in b-requirements has ≥1 case; every `scratch_dir` error kind exercised.
- **Oracle discipline**: assert against **hard-coded literal** expected strings built from
  `$>` and the known root — never a mirrored re-derivation (no tautological `expected_parent`).

## Test Cases
### Retained (seam swept `$ENV{TMPDIR}` → `$CWF::Common::SCRATCH_BASE`)
- **TC-1 `scratch_parent` happy path**: Given a git repo and `local $CWF::Common::SCRATCH_BASE
  = $tmp`; When `scratch_parent`; Then it returns `"$tmp/cwf$dashed"` (literal), no error.
- **TC-2 worktree main-root**: from a linked worktree the parent uses the MAIN root (unchanged).
- **TC-3 not_a_repo**: outside a repo → `(undef,'not_a_repo')`, no filesystem.
- **TC-4 `scratch_dir` happy path**: creates `<base>/cwf$dashed/task-206` at mode `0700`.
- **TC-5 bad_num rejects, no FS**: the bad-num corpus → `bad_num`, nothing created.
- **TC-6 leading-zero / dotted** accepted.
- **TC-7 symlinked `cwf<dashed>` parent** rejected → `symlink_parent`, target not chmod-ed.
- **TC-8 idempotent re-call** → same path, mode unchanged.

### New (the fix)
- **TC-9 default base literal (pure)**: Given no override; When reading
  `$CWF::Common::SCRATCH_BASE` and calling `scratch_parent` in a repo; Then the scalar eq
  `"/tmp/claude-$>"` and `scratch_parent` returns `"/tmp/claude-$>/cwf$dashed"` — a pure
  string assertion (no dir creation, safe against real `/tmp`).
- **TC-10 poison-`$TMPDIR` invariance (the regression test)**: Given `local
  $CWF::Common::SCRATCH_BASE = $tmp` and, in turn, `local $ENV{TMPDIR}` ∈ { `/tmp/cwf-x`,
  `/tmp/cwf-x/claude-9`, `/tmp/a/../b`, `tmp` (relative), `''`, unset }; When `scratch_parent`;
  Then the output is **identical** (`"$tmp/cwf$dashed"`) for every `$TMPDIR` value — proving
  `$TMPDIR` is not read and doubling is impossible.
- **TC-11 intermediate symlink guard**: Given `$CWF::Common::SCRATCH_BASE` pre-planted as a
  **symlink** to an attacker dir; When `scratch_dir`; Then `(undef,'symlink_parent')`, the
  link is not followed, and the target is not chmod-ed. (Distinct from TC-7, which symlinks
  the inner `cwf<dashed>` parent.)
- **TC-12 two-level create + 0700**: Given a non-existent `$CWF::Common::SCRATCH_BASE = $tmp/x`
  (base absent); When `scratch_dir`; Then both the intermediate and the `cwf<dashed>` parent
  are created at `0700` and the leaf exists — the off-sandbox "create the base" path.
- **TC-13 `scratch_fail_hint`**: `scratch_fail_hint('mkdir_failed')` and
  `scratch_fail_hint('symlink_parent')` each return a non-empty string naming the base;
  `scratch_fail_hint('bad_num')`, `'not_a_repo'`, `''`/undef → `''`.

### Removed
- **TC-9..TC-14 (old probe cases)** — the `$SANDBOX_TMP_PROBE` env→probe→/tmp branch no
  longer exists; delete rather than adapt.

### Non-Functional Test Cases
- **Security**: TC-11 (intermediate symlink reject) + TC-7 (parent) cover the two-level
  world-writable-`/tmp` guard; TC-10 covers env-var-injection removal (`..`/relative/hostile
  `$TMPDIR` cannot influence the path).
- **Reliability**: `scratch_dir` fails closed (`mkdir_failed`) when the base is unwritable —
  exercised by forcing an unwritable `local $CWF::Common::SCRATCH_BASE` (skip if EUID 0).
- **Usability**: `scratch_fail_hint` wording is asserted non-empty and base-naming (TC-13).

## Test Environment
### Setup Requirements
- Core Perl + `Test::More`, `File::Temp`; `create_git_repo` fixture (existing).
- Hermetic: every case that creates dirs sets `local $CWF::Common::SCRATCH_BASE = tempdir(CLEANUP=>1)`;
  no test writes to the real `/tmp/claude-$>`.

### Automation
- `prove -r t/` (bare; `PERL5OPT=-CDSLA` already in the settings env — do not inline it).

## Validation Criteria
- [ ] TC-1..TC-13 pass; `prove -r t/` fully green
- [ ] TC-10 (poison-`$TMPDIR` invariance) and TC-11 (intermediate symlink) present — the
      two cases that would have caught the reporter's bug and the new guard gap
- [ ] No test manipulates `$ENV{TMPDIR}` to redirect scratch, and none writes to real
      `/tmp/claude-$>`
- [ ] Oracle assertions are hard-coded literals, not mirrored derivations
- [ ] Smoke test: `best-practice-resolve` `.out` lands under
      `/tmp/claude-$>/cwf<dashed-root>/task-229/`
- [ ] `cwf-manage validate` clean after the four-script hash refresh

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
13 planned `t/scratch.t` cases executed, all pass; the seam sweep (`local $ENV{TMPDIR}` →
`local $CWF::Common::SCRATCH_BASE`) completed. Two `security-review-changeset.t` cases needed
unplanned changes because they encoded the old `$TMPDIR`-honouring behaviour.

## Lessons Learned
Test the invariant, not the implementation detail. TC-TMPDIR-1/2/3 asserted "honours
`$TMPDIR`", so a correctness improvement read as a break; re-pointed at "hook and writer
agree" they became stronger guards. Budget for fixture-intent drift when changing behaviour.
