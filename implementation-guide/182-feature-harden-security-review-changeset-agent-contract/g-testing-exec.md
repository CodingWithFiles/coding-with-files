# Harden security-review-changeset agent contract - Testing Execution
**Task**: 182 (feature)

## Task Reference
- **Task ID**: internal-182
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/182-harden-security-review-changeset-agent-contract
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status when in progress / complete

## How to run
```
PERL5OPT=-CDSLA prove t/security-review-changeset.t
```
Result: **All tests successful. Files=1, Tests=35.** (35 subtests, 0 failures, 0 unexpected skips.)

## Harness changes (per e-testing-plan §"Harness changes")
- `run_helper` now injects `--wf-step=implementation-exec` unless the caller passes its own `--wf-step` (the helper now requires the flag). Added `run_helper_raw` (no injection) for the missing-flag rejection case.
- New helpers parse the **confirmation line** rather than re-deriving the path (robust to git's symlink-resolved root, e.g. macOS `/private/tmp`): `out_path`, `confirm_count`, `changeset_of` (reads the `.out` file). An `END` block removes the main-tree-namespaced `.out` dirs, which live outside each synthetic repo's `tempdir` and so are not reaped by `CLEANUP=>1`. Verified: no `/tmp` litter after a run.

## Test Results

### Functional / regression (existing cases migrated stdout→.out)
| Test ID | What it covers | Status |
|---------|----------------|--------|
| TC-F1..F8 | path-independent inclusion, consumer files, unmerged-predecessor isolation, binary, subtask, malformed-baseline fallback | PASS (diff assertions now read `changeset_of($out)`) |
| TC-GUARD1a/1b | symlink reviewed without deref / FIFO non-blocking | PASS |
| TC-NF1/NF2 | trunk `..` rejected / `--task-num` injection rejected | PASS |
| TC-NF5 | O(diff) not O(repo) with 200-file diff | PASS |
| TC-Task141-uncommitted | staged + unstaged changes seen | PASS |
| TC-CAP1 | over-cap → exit 2; **now** diff in `.out` + confirmation printed before exit 2 (also covers AC7) | PASS |
| TC-CAP2/CAP4/CAP6/CAP8/CAP9 | production-weighting, binary=0, unconfigured/legacy test-paths | PASS (unchanged — stderr-only) |
| TC-CAP3 | **re-purposed**: absent `--max-lines` now defaults to 500; sub-500 diff passes | PASS |
| TC-CAP5/CAP7 | invalid `--max-lines` / malformed exclude-pattern → exit 1 | PASS |
| TC-WIDEN1 | consumer source reviewed + counts as production | PASS |
| TC-EMPTY1 | **migrated**: empty diff → 0-line `.out` + count-0 confirmation (no empty-stdout reliance); covers AC4.3 | PASS |

### New cases (AC1–AC8)
| Test ID | AC | What it covers | Status |
|---------|----|----------------|--------|
| TC-WFSTEP-REJECT | AC1/AC2 | `--phase`, `--wf-step=bogus`, `--wf-step=../escape`, missing → exit 1, no confirmation line | PASS |
| TC-WFSTEP-ACCEPT | AC2 | `--wf-step=design-plan` accepted; filename carries the step | PASS |
| TC-DEFAULTCAP | AC3 | >500 production → default cap fires (exit 2); `--max-lines=100000` override lifts it | PASS |
| TC-OUTFILE | AC4 | `.out` at 0600 in a 0700 dir; stdout carries no diff lines | PASS |
| TC-CONFIRM | AC5 | exactly one confirmation line; count == newline count of the file | PASS |
| TC-TRUNCATE | AC4.2 | re-run fully replaces prior `.out` (no stale content, smaller count) | PASS |
| TC-SYMLINK | AC4.2 | pre-planted symlink replaced; referent unmodified (no write-through) | PASS |
| TC-WORKTREE | AC4.1 | `.out` resolves to main-tree namespace from a linked worktree (identical path) | PASS |
| TC-DOCS | AC6 | four sites carry new invocation; no `--phase`/`--max-lines=500`/inline `{changeset}` | PASS |
| TC-VALIDATE | AC8 | `cwf-manage validate` clean (exit 0); neither script nor agent flagged | PASS |

### Non-Functional Tests
- **Performance** (TC-NF5): completes < 5s with a 200-file diff. PASS.
- **Security** (TC-NF1/NF2/SYMLINK/WFSTEP-REJECT): trunk/task-num/wf-step gating and symlink no-write-through all verified. PASS.
- **Reliability** (TC-WFSTEP-REJECT/CAP5/CAP7): error paths exit 1 with no partial confirmation. PASS.

## Test Failures
One during development, fixed: TC-WIDEN1 assertion 2 still read `$out` (stdout) instead of `changeset_of($out)` after the file-output migration — a missed migration site. Corrected; suite then fully green.

## Coverage Report
Every acceptance criterion AC1–AC8 (incl. AC4.1/4.2/4.3, AC6.1/6.2, AC7) has ≥1 dedicated case; all pre-existing subtests migrated and green (no regression). TC-SYMLINK / TC-WORKTREE ran (not skipped) on this Linux environment.

## Deviations from e-testing-plan
- **TC-EMPTY** (AC4.3) and **TC-CAP-WRITES-FILE** (AC7) were planned as separate new cases; each is identical in scenario to a migrated case, so they were consolidated rather than duplicated: AC4.3 is covered by the migrated **TC-EMPTY1**, and AC7 by the migrated **TC-CAP1** (which now asserts the `.out` write + confirmation-before-exit-2). No coverage lost.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- Migrating stdout→file assertions is exactly the "rebrand needs an output-level smoke-test" lesson: a source-level reasoning pass missed one site (TC-WIDEN1); running the suite caught it. Always run, don't reason about, the migrated assertions.
- Parsing the helper's own confirmation line for the `.out` path (rather than re-deriving it in the test) sidesteps the macOS `/private/tmp` symlink-resolution divergence for free — the test consumes the contract the same way the agent does.

## Security Review

**State**: no findings

Reviewed the testing-exec changeset (cumulative diff; focus on the new `t/security-review-changeset.t` material) against threat categories (a)–(e).

- **(a) Command construction**: every spawn is list-form — `system('git','-C',$dir,@args)`, `open(my $fh,'-|',$prog,@args)`, `exec($HELPER,@args)`. No `system($string)`/`qx{$interpolated}`. The forked child uses `POSIX::_exit(127)` on exec failure, so inherited `END`/`File::Temp` CLEANUP blocks do not run in the failed child. Fixture content is written via Perl `open`/`print`, never the shell.
- **(b) git/output handling**: harness captures whole-blob stdout for assertion; the only parsed value is the helper's own confirmation line via the anchored regex `^security-review-changeset: wrote \d+ lines to (.+)$`. No newline-splitting of git file lists.
- **(c) Prompt injection**: n/a — fixtures never reach LLM context; TC-DOCS reads the four real files read-only.
- **(d) Env vars**: none read for security-critical operations; paths derive from `tempdir()`/`$FindBin::Bin`.
- **(e) Pattern risks**: the END-block `unlink`/`rmdir` acts only on the path the trusted helper-under-test reported (not attacker-influenced) and removes the file/empty-dir it created. TC-SYMLINK is hermetic and actively proves the helper's no-write-through property (referent unmodified, `.out` becomes a regular file). TC-WORKTREE uses raw `git worktree` only as a disposable in-`tempdir` fixture — outside the scope of CWF's operator-facing worktree-process prohibition; no persistent-CWD data-loss risk.

Conclusion: no unsafe command construction, no unsafe env-var handling, no prompt-injection surface; the `/tmp` cleanup is bounded to the helper's own output path.

```cwf-review
state: no findings
summary: Test-suite spawns are all list-form; END-block /tmp cleanup acts only on the trusted helper's own reported path; symlink/worktree fixtures are hermetic and the symlink case proves no-write-through.
```
