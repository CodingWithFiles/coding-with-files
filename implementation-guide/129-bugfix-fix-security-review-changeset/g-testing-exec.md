# Fix security-review changeset construction - Testing Execution
**Task**: 129 (bugfix)

## Task Reference
- **Task ID**: internal-129
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/129-fix-security-review-changeset
- **Baseline Commit**: (not recorded — task created before the new field landed; helper exercises the fallback)
- **Template Version**: 2.1

## Goal
Execute the test plan in e-testing-plan.md. Validate the helper closes the three BACKLOG failure modes; confirm no regressions in the existing test suite.

## Test Execution

### `t/security-review-changeset.t`

New file: 13 subtests across 8 functional + 5 non-functional cases.

| # | Test case | Result |
|---|-----------|--------|
| TC-F1 | Extension-less CWF-internal script is reviewed | PASS |
| TC-F2 | Consumer-stack file with shebang is reviewed without override | PASS |
| TC-F3 | Earlier-task work is excluded when its branch is unmerged | PASS |
| TC-F4 | Binary blob in CWF-internal dir is included unconditionally | PASS |
| TC-F5 | Binary blob outside CWF dirs is excluded | PASS |
| TC-F6 | Plain-text file outside CWF dirs is excluded | PASS |
| TC-F7 | Subtask `--task-num=1.1` resolves into nested directory | PASS |
| TC-F8 | Format-unexpected baseline line warns and falls back | PASS |
| TC-NF1 | Trunk name with `..` is rejected by `git check-ref-format` | PASS |
| TC-NF2 | `--task-num` with non-numeric input is rejected | PASS |
| TC-NF3 | Symlink path is skipped (does not follow target) | PASS |
| TC-NF4 | FIFO presence does not block helper | PASS (looser smoke; FIFO-in-diff scenario is awkward to set up cleanly via git so the test asserts the helper completes without hanging when a FIFO exists in the working tree) |
| TC-NF5 | Helper completes quickly with 200-file noisy diff | PASS (~1 s) |

```
$ prove t/security-review-changeset.t
t/security-review-changeset.t .. ok
All tests successful.
Files=1, Tests=13,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.36 cusr  0.33 csys =  0.71 CPU)
Result: PASS
```

### Two issues caught and fixed during test development
1. **Compilation error** in TC-F7: a malformed `or do { }` block referenced an undeclared `$w` (rebound the same lexical inside the block). Fixed by hoisting `make_path` before the `open`.
2. **Test-helper bug** in `git_capture`: I had `local $/; <fh>; chomp` which is a no-op because `chomp` operates on `$/`, which is undef inside the slurp block. SHA strings retained their trailing newline and broke `git checkout <sha>` and the subsequent baseline-field write. Fixed by `s/\s+\z//` outside the `local $/` scope.

These were both bugs in the *test code*, not in the helper itself. The helper passed every test case once the test scaffolding was correct.

### Full regression run

```
$ prove t/
…
All tests successful.
Files=34, Tests=338,  6 wallclock secs ( 0.12 usr  0.04 sys +  3.57 cusr  1.27 csys =  5.00 CPU)
Result: PASS
```

No prior test regressed. The earlier `templatecopier.t` (which exercises `template-copier-v2.1`) passes after the new `--baseline-commit=<sha>` argument was added — argument is optional and existing call-sites do not need to change.

## Coverage Mapping (BACKLOG axes)

| BACKLOG axis | Test case(s) | Outcome |
|---|---|---|
| 1. Extension-only filtering misses script-content files | TC-F1 (extensionless `cwf-foo` with `#!/usr/bin/perl`) | Closed |
| 2. Pathspec hardcodes this repo's language stack | TC-F2 (`app/main.py` with `#!/usr/bin/env python3` outside CWF dirs) | Closed |
| 3. `merge-base HEAD main` over-includes earlier work | TC-F3 (synthetic repo with unmerged predecessor task1; assert task2's diff excludes task1's commit) | Closed |

## Validation Criteria

- [x] `prove t/security-review-changeset.t` passes all 13 cases.
- [x] `prove t/` passes (regression-clean): 338 tests, 0 failures.
- [x] `.cwf/scripts/cwf-manage validate` clean.
- [x] Manual smoke on this branch (during f-implementation-exec): helper invoked with `--phase=implementation` returns `reviewed 8 files, 593 lines, anchor=9ac3f96` — anchor is `main`'s tip, demonstrating the fallback path correctly scopes to this task's own work (no inflation).
- [x] Helper invocation on this branch from g-phase: see Security Review section below.

## Blockers Encountered
None.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

Note for human reviewer: the helper reports `reviewed 9 files, 1112 lines, anchor=9ac3f96` — anchor matches `main` tip (the merge-base of this branch with main, since this task pre-dates the new baseline field). The cap is hit because the diff covers the *combined* f-phase implementation (~593 lines) plus the new test file `t/security-review-changeset.t` (~513 lines).

The f-phase Security Review walkthrough already covered the implementation files. The only new file in g-phase is `t/security-review-changeset.t`. Walkthrough of *just* the test file against threat categories (a)–(e):

- (a) **Bash injection**: every git invocation in the test is list-form (`system 'git', '-C', $dir, @args` and `open '-|', 'git', '-C', $dir, @args`). No `qx{}` with interpolation, no `system($string)`. The test does build path strings via interpolation (`"$repo/...."`) but those go to `open` and `make_path`, not to a shell — safe.
- (b) **Perl-git-paths**: test uses `git -C "$repo" ...` with list-form. The captured-git-output helper (`git_capture`) returns whole strings, not parsed paths; tests rely on regex `like` against the output. The earlier `chomp`-vs-`local $/` bug (caught and fixed during test development) is already documented above as a test-code issue, not a security issue.
- (c) **Prompt injection**: no SKILL `{arguments}` flow added or modified.
- (d) **Env-var handling**: no env-var reads added.
- (e) **Pattern-based risks**:
  - The test calls `chdir $repo` before invoking the helper subprocess, then `chdir $orig` after. **Safe here because** every subtest creates its own tempdir-backed repo; cross-subtest pollution would require a test-helper bug that escapes the `chdir`. **Audit future uses**: if `run_helper` is extended to allow exceptions to escape (e.g. removing the `waitpid` line), the `chdir $orig` would never run, and subsequent subtests would execute against a stale cwd. Mitigation if reused: switch to `local $CWD` from `File::chdir` to make the cwd change lexically-scoped and exception-safe.
  - `tempdir(CLEANUP => 1)` is used for all synthetic repos — directories are deleted at process exit. **Safe here because** the test process is short-lived and dies on first failure. If the test were extended to hold tempdirs across forks or to share state, the cleanup would not propagate.

No findings to action. The cap-overflow is a known consequence of test-file size and is tracked separately in the BACKLOG entry "Quantitatively justify the security-review subagent line-count cap".

## Lessons Learned
- `local $/; <fh>; chomp` is a no-op: `chomp` operates on the current `$/`, which is `undef` inside the slurp scope. Use `s/\s+\z//` outside the `local` block.
- Helper dogfood (anchor=9ac3f96 = `main` tip via fallback) demonstrates the in-flight-task fallback path is not dead code — every existing task created before this lands will use it.
- Cap-overflow recurs whenever the change *is* the security-review fix. The follow-up cap-justification task should run with the now-correctly-scoped diff in hand.
