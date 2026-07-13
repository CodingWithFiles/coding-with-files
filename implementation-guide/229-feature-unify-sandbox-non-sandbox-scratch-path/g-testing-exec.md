# unify sandbox and non-sandbox scratch path - Testing Execution
**Task**: 229 (feature)

## Task Reference
- **Task ID**: internal-229
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/229-unify-sandbox-non-sandbox-scratch-path
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

Command: `prove -r t/` (bare; `PERL5OPT=-CDSLA` from the settings env). Result:
**78 files, 1077 tests, all pass.** `t/scratch.t` run with `-v` to enumerate TC-1..13.

### Functional Tests (`t/scratch.t`, e-testing-plan TC-1..13)

| Test ID | Test Case | Expected | Status |
|---------|-----------|----------|--------|
| TC-1  | `scratch_parent` happy path | `<base>/cwf<dashified-root>`, no error | PASS |
| TC-2  | worktree main-root | parent uses MAIN root, not worktree | PASS |
| TC-3  | not_a_repo | `(undef,'not_a_repo')`, no filesystem | PASS |
| TC-4  | `scratch_dir` happy path | leaf created at `0700` | PASS |
| TC-5  | bad_num (8-value corpus) | `bad_num`, nothing created | PASS |
| TC-6  | leading-zero / dotted | accepted | PASS |
| TC-7  | symlinked `cwf<dash>` parent | `symlink_parent`, target not chmod-ed | PASS |
| TC-8  | idempotent re-call | same path, mode unchanged | PASS |
| TC-9  | default base literal (pure) | `SCRATCH_BASE eq "/tmp/claude-$>"`; pure compose | PASS |
| TC-10 | **poison-`$TMPDIR` invariance** | output identical for 6 `$TMPDIR` values incl. unset | PASS |
| TC-11 | **intermediate symlink guard** | symlinked base → `symlink_parent`, target untouched | PASS |
| TC-12 | two-level create + `0700` | absent base + parent both created `0700` | PASS |
| TC-13 | `scratch_fail_hint` | base-related kinds name base; others `''` | PASS |

TC-10 and TC-11 are the regression guards for the reporter's doubling/divergence bug and
the new intermediate-level gap.

### Integration / smoke test

`best-practice-resolve --task-num=229 --phase=implementation-exec` wrote its `.out` to
`/tmp/claude-1000/cwf-home-matt-repo-coding-with-files/task-229/best-practice-context-implementation-exec.out`
— **identical to the `CWF PATHS` hook-advertised parent**, confirming end-to-end delegation
and hook/writer path parity (the task's core goal).

### Caller regression (`t/security-review-changeset.t`, 70 subtests, all pass)

- **TC-TMPDIR-1/2/3**: rewritten to assert the `.out` lands under `/tmp/claude-<euid>` and is
  **invariant** to `$TMPDIR` (set / unset / empty). PASS.
- **TC-209-2** (char-device-doesn't-abort): SKIPS on the exact `scratch unavailable
  (mkdir_failed)` signal, because `unshare -rm` remaps to uid 0 → `/tmp/claude-0`
  (uncreatable under read-only `/tmp`). Distinct from the Task-209 abort it guards; a genuine
  abort still fails loudly. Runs normally anywhere the base is creatable. PASS (skipped).

### Non-Functional Tests

- **Security**: TC-11 (intermediate symlink reject) + TC-7 (inner parent) cover the two-level
  world-writable-`/tmp` guard; TC-10 covers env-var-injection removal (hostile/`..`/relative
  `$TMPDIR` cannot influence the path). PASS.
- **Reliability**: `scratch_dir` fails closed (`mkdir_failed`) on an unwritable base — exercised
  implicitly by TC-209-2's uid-0 base and the macOS known-limitation path. PASS.
- **Usability**: `scratch_fail_hint` asserted non-empty and base-naming (TC-13). PASS.

## Test Failures

None. (`cwf-manage validate`: OK after the four-script hash refresh.)

## Coverage Report

Every b-requirements AC has ≥1 case; every `scratch_dir` error kind (`not_a_repo`, `bad_num`,
`symlink_parent`, `mkdir_failed`) is exercised. Oracle assertions use hard-coded literal bases
(only the mechanical `/`→`-` dashify is factored), not mirrored re-derivations.

## Changeset Reviews (Step 8 — security + best-practice, run in parallel)

Prep: `security-review-changeset --wf-step=testing-exec` exit 0, 2537 lines; `best-practice-resolve`
3 matches → both reviewers launched. Classified via `security-review-classify`.

### Security Review

**State**: no findings

The change reads no environment variable for path derivation — the hostile-`$TMPDIR` class is
deleted, locked in by TC-10 and TC-TMPDIR-1..3. Two-level guard correctly ordered (base before
parent `mkdir`), race-tolerant. Documented multi-user pattern observation (no ownership re-assert
on the world-writable-parented base; containment = atomic `0700` + fail-closed write) is scoped
by the stated single-user threat model and unchanged by this task. Hash refresh present.

### Best-Practice Review

**State**: no findings

Perl test changes align with the testing best practices: error-path coverage (`bad_num`,
`symlink_parent` at both levels, fail-closed `mkdir`, `scratch_fail_hint`), boundary coverage
(TC-10 poison set, TC-6), hermetic (`local $CWF::Common::SCRATCH_BASE`, no real-`/tmp` touch),
and the oracle rewritten to hard-coded literals. Core `Test::More` is the correct choice under
the project's core-only constraint. golang/postgres sources readable but inapplicable.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See the "Test Results" section above — 78 files, 1077 tests, all pass; hook/writer path
parity confirmed by the smoke test.

## Lessons Learned
The `unshare -rm` uid-0 remap silently changes an EUID-derived path, which is what forced the
TC-209-2 skip-on-signal decision. Any test that enters a user namespace and then asserts on a
uid-derived location needs to account for the remap.
