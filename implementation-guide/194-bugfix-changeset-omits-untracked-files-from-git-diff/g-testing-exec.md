# changeset omits untracked files from git diff - Testing Execution
**Task**: 194 (bugfix)

## Task Reference
- **Task ID**: internal-194
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/194-changeset-omits-untracked-files-from-git-diff
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready (perl Test::More, git on PATH, synthetic repos)
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Finished" when all pass

## Test Results

### Functional Tests
Added as subtests TC-1…TC-7 to `t/security-review-changeset.t` (the existing
integration harness). All pass.

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | Untracked non-ignored file in body + reviewed count | `+++ b/new.txt` hunk, all additions, `reviewed 3 files`, dirty suffix | As expected | PASS |
| TC-2 | `.gitignore`d untracked file excluded; sibling kept | `debug.log` absent, `keep.txt` present | As expected | PASS |
| TC-3 | Index restored after normal exit | `?? new.txt`, no `A `/`AM` residue | As expected | PASS |
| TC-4 | Untracked lines trip cap → exit 2 AND index restored | exit 2, `cap exceeded:`, `.out` written, `?? big.txt` after | As expected | PASS |
| TC-5 | Untracked-only tree renders dirty suffix | `, includes uncommitted`, exit 0 | As expected | PASS |
| TC-6 | Dash-prefixed `-rf` untracked filename (`--` guard) | exit 0, `+++ b/-rf` in body, restored untracked | As expected | PASS |
| TC-7 | No untracked files (no-op regression) | tracked diff rendered, working tree clean afterward | As expected | PASS |

### Non-Functional Tests
- **Index integrity (read-only contract)**: TC-3, TC-4, TC-6 each assert the
  post-run index is restored — covered on the normal-exit, cap-breach (exit 2),
  and dash-prefixed-path branches. PASS.
- **Security (option injection, FR4(e))**: TC-6 is the `--` separator
  regression with a literal `-rf` file. PASS.
- **Exit-code fidelity**: TC-4 confirms the END-block cleanup does not mask
  `exit 2`. PASS.
- **Signal-interrupt restore (manual / best-effort)**: documented manual check
  (see below) — deliberately not a flaky timing-dependent CI subtest.

### Full-suite result
```
prove t/security-review-changeset.t  → Files=1, Tests=42, Result: PASS
prove t/                             → Files=63, Tests=741, Result: PASS
cwf-manage validate                  → OK
```
42 = 35 pre-existing + 7 new. No regression across the whole `t/` tree.

## Test Failures
None in the final run. **One transient harness issue, found and fixed during
this phase** (documented for the retrospective):

- **Symptom**: 8 pre-existing subtests failed on first run of the new code
  (file-count and empty-diff assertions off).
- **Root cause**: `run_helper_raw` wrote its `.helper-stdout`/`.helper-stderr`
  capture files *inside the repo-under-test*. Now that the helper enumerates
  untracked, non-ignored files, it correctly swept those capture files into its
  own changeset — skewing counts and the empty-diff case. (This is the fix
  working, not a defect in the fix.)
- **Resolution**: moved capture files to an out-of-tree `tempdir` (`$CAPTURE_DIR`,
  sequenced per call). All pre-existing tests green again. The security reviewer
  flagged this as a defensive improvement, not a finding.

### Signal-interrupt manual check (TC non-functional)
Performed in a scratch git repo: created an untracked file, started the helper,
and confirmed the `$SIG{INT}/$SIG{TERM}` handler path calls `exit(130)`, which
runs the END block and leaves `git status` free of residual intent-to-add. The
load-bearing guarantee (END restores on `exit`) is also exercised deterministically
by TC-3/TC-4, so the only manual-only portion is the live signal delivery itself.

## Coverage Report
All seven new/changed code branches from d-implementation-plan.md are exercised:
untracked enumeration, intent-to-add, body inclusion, count inclusion,
exclude-standard, widened dirty suffix, `--` invariant, and index restore on
both the exit-0 and exit-2 paths. The signal-handler install is covered
indirectly (handler body = `exit(130)` → same END path as TC-3/TC-4 assert).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
The 8 pre-existing-test failures were the most instructive moment: a behaviour
change that "looks isolated to one helper" can still ripple through shared test
scaffolding. The failures were a true positive (the helper now sees untracked
files) pointing at a latent harness defect (capture files written in-tree), not
a regression in the fix. Reading the failure as signal — not noise to suppress —
led to the right fix in the harness rather than weakening the new assertions.

## Security Review

**State**: no findings

### Security review — Task 194 testing-exec changeset

I reviewed the full testing-exec changeset against the five threat categories in `.cwf/docs/skills/security-review.md`. On top of the implementation-exec diff (helper change + hash refresh, already reviewed) it adds the new material: the test-suite changes in `t/security-review-changeset.t` and the inert workflow-guide markdown (g-testing-exec, j-retrospective).

**(a) Bash injection / unsafe command construction.** No shell command construction in the new test code. The git wrappers the new subtests call — `git_in` (`system('git', '-C', $dir, @args)`) and `git_capture` (`open('-|', 'git', '-C', $dir, @args)`) — are pre-existing and list-form, so no shell parses any path. The new subtests pass only literal arguments. No `system($string)`, no backticks. Clean.

**(b) git output consumed without `-z` / input validation.** New assertions consume `git status --porcelain` via `git_capture` and match anchored regexes. This is test-side porcelain parsing on synthetic, test-authored filenames, not production path-handling — the `-z`/NUL-split convention governs the production helper (satisfied via `list_untracked_files`' `ls-files … -z`). TC-6 even accounts for git's quoting of the `-rf` path. Clean.

**(c) Prompt injection.** No `{arguments}` substitution or LLM-context flow. The markdown guide files are unfilled template scaffolding with no executable content. N/A.

**(d) Unsafe environment-variable handling.** No new env-var consumption. N/A.

**(e) Pattern-based risks.** One observation, a defensive improvement not a defect: the test-harness change moves the helper's stdout/stderr capture files out of the repo-under-test into an out-of-tree `tempdir` (`$CAPTURE_DIR`), keyed by a monotonic `$CAPTURE_SEQ`. Now that the helper enumerates untracked, non-ignored files, capture files written inside `$cwd` would be swept into the helper's own changeset and skew counts — this fix closes a real test-pollution hazard the Task 194 behaviour change introduced. Audit future uses: keep helper-output capture out of any repo the helper runs against.

**Test correctness vs. the security-critical behaviour.** The new subtests give real coverage to the security-load-bearing properties: TC-6 exercises the `--` option-injection guard with a literal `-rf` untracked file and asserts a clean post-run index; TC-3/TC-4 pin the read-only contract on both the normal-exit and the `exit 2` cap-breach paths; TC-2 confirms ignored-file exclusion stays delegated to git's `--exclude-standard`.

No actionable security concerns.

```cwf-review
state: no findings
summary: testing-exec adds only list-form git test helpers + inert guide markdown; new subtests correctly pin the -- option-injection guard and index-restore-on-exit-2; capture-dir moved out of tree to avoid untracked-sweep pollution
```
