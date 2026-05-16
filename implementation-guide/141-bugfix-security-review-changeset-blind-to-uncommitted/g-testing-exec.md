# security-review-changeset blind to uncommitted - Testing Execution
**Task**: 141 (bugfix)

## Task Reference
- **Task ID**: internal-141
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/141-security-review-changeset-blind-to-uncommitted
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Test Results

### Functional Tests

| Test ID                  | Test Case                                                                  | Status | Notes                                                  |
|--------------------------|----------------------------------------------------------------------------|--------|--------------------------------------------------------|
| TC-Task141-uncommitted   | Helper sees staged and unstaged changes (anchored stderr disclosure)       | PASS   | 4 assertions; ok 14 in `t/security-review-changeset.t` |
| TC-F1                    | Extensionless CWF-internal script with shebang is included                 | PASS   | ok 1, regression                                       |
| TC-F2                    | Consumer-stack python file with shebang is included                        | PASS   | ok 2, regression                                       |
| TC-F3                    | Unmerged predecessor branch does not pollute the changeset                 | PASS   | ok 3, regression                                       |
| TC-F4                    | Binary blob under `.cwf/scripts/` is included unconditionally              | PASS   | ok 4, regression                                       |
| TC-F5                    | Binary blob outside CWF dirs is excluded                                   | PASS   | ok 5, regression                                       |
| TC-F6                    | Plain-text notes outside CWF dirs are excluded                             | PASS   | ok 6, regression                                       |
| TC-F7                    | Subtask num resolves into nested directory                                 | PASS   | ok 7, regression                                       |
| TC-F8                    | Malformed Baseline Commit line warns and falls back to merge-base          | PASS   | ok 8, regression                                       |
| TC-NF1                   | Trunk name with `..` is rejected by `check-ref-format`                     | PASS   | ok 9, regression                                       |
| TC-NF2                   | `--task-num` with non-numeric input is rejected up front                   | PASS   | ok 10, regression                                      |
| TC-NF3                   | Symlink path is skipped (does not follow target)                           | PASS   | ok 11, regression                                      |
| TC-NF4                   | FIFO is skipped (does not block on sysread)                                | PASS   | ok 12, regression                                      |
| TC-NF5                   | Helper completes quickly with large working tree but small diff            | PASS   | ok 13, regression                                      |

Helper file total: **14 subtests, all PASS**.

### Regression (full repo)
- `prove t/` → 42 files, **473 tests, all PASS** (was 472; +1 from TC-Task141-uncommitted).
- No existing test required modification.

### Non-Functional Tests
- **Security**: `security-review-changeset --phase=testing` invoked post-checkpoint — recorded in § "Security Review" below. **This task's review is uniquely meaningful**: it ran against the very helper it fixes, and the *fact* that it ran cleanly on a real diff at the f-exec phase (before checkpoint) is the canonical proof the bug is gone.
- **Maintainability**: `grep -rn '\.\.HEAD' .cwf/scripts/command-helpers/security-review-changeset` → 2 hits, both inside historical-context comments documenting the Task 141 change. No live `..HEAD` code references.
- **Reliability**: `cwf-manage validate` → **OK** (SHA bump for `security-review-changeset` is in place; perms unchanged).
- **Performance**: not measured. Change adds one `git_check('diff', '--quiet', 'HEAD')` call per invocation (single git subprocess); manual smoke completed in <1s. No perceptible delta.

### Two-state proof of the fix
Both halves of the design behaviour were directly observed:

1. **Mid-exec, dirty tree** (recorded in `f-implementation-exec.md` § "Step 7"):
   ```
   $ .cwf/scripts/command-helpers/security-review-changeset --phase=implementation
   [stdout: 121-line diff]
   [stderr]: reviewed 2 files, 121 lines, anchor=f833bbf, includes uncommitted
   ```
   Suffix present; in-flight changes visible. **The bug is gone.**

2. **Post-checkpoint, clean tree** (recorded here):
   ```
   $ .cwf/scripts/command-helpers/security-review-changeset --phase=testing
   [stdout: 121-line diff]
   [stderr]: reviewed 2 files, 121 lines, anchor=f833bbf
   ```
   Suffix absent (working tree is clean post-f-checkpoint); same committed changes still visible via the anchor-to-working-tree diff. **Existing behaviour preserved.**

## Test Failures
None.

## Coverage Report
- **Bug-fix-specific regression**: TC-Task141-uncommitted covers both index-side and working-tree-side changes via two distinct file paths (one staged, one modified-without-`git-add`). Includes content-level assertion (`UNSTAGED_MOD_141`) to prove the working-tree edit's content reaches the diff, not just the file path.
- **Committed-state regression**: 13 existing subtests pass unchanged → confirms the widened diff is a strict superset for clean-tree inputs.
- **Disclosure-suffix shape**: anchored regex `qr{^reviewed 2 files,.+anchor=[0-9a-f]{7}, includes uncommitted$}m` proves the suffix lands on the summary line, not in the `--verbose` body.
- **Error path** (`git diff --quiet HEAD` rc ≥ 2): not directly tested. By design — only reachable from corrupted-repo states that the primary `git diff` would fail on first. Acceptable risk per c-design Decision 2.

## Validation Criteria Roll-up (from e-testing-plan.md)
- [x] `TC-Task141-uncommitted` passes (all 4 assertions).
- [x] TC-F1..F8 and TC-NF1..NF5 pass unchanged.
- [x] `prove t/` → 473 tests PASS.
- [x] End-to-end smoke shows non-empty diff + `includes uncommitted` suffix in stderr — both observed first try (in f-exec).
- [x] `grep '\.\.HEAD' .cwf/scripts/command-helpers/security-review-changeset` shows only documentation references (no live code refs).
- [x] `cwf-manage validate` is OK.
- [x] Security review subagent returns substantive analysis on the real diff (see below).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 141
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

**This is the first sentinel-first compliant subagent response in 6 consecutive exec-phase reviews** (139-f, 139-g, 140-f, 140-g, 141-f all failed sentinel-first; 141-g succeeded). The breakthrough: a heavily-emphasised prompt that opened with "Your VERY FIRST CHARACTER of response must be the letter `n`, `f`, or `e`" and explicitly listed unacceptable opener prose ("Now", "Let me", "I'll", "Looking at..."). This is a concrete data point for the BACKLOG items "Enforce sentinel-first output in security-review subagent prompt" and "Tighten security-subagent prompt for sentinel-line compliance" — character-level discipline in the prompt works where sentence-level discipline does not. Worth folding the working prompt back into `.cwf/docs/skills/security-review.md` § "Exec-phase prompt template" when those BACKLOG items are picked up.

Verbatim subagent output:

```
no findings

The changeset (121 lines) fixes the "blind to uncommitted" bug in `security-review-changeset` by widening the diff window from `${anchor}..HEAD` to `$anchor` (working tree), and adds a comprehensive regression test. Reviewed against threat categories (a)–(e):

**(a) Bash injection**: The diff changes list-form `git` calls and maintains defensive patterns. No shell metachars from user input. Clean.

**(b) Perl input validation**: The helper already uses `-z` (NUL-separation) in `list_changed_files`. The regression test uses hardcoded file paths via `make_path()` and file I/O with open handles. No newline-splitting of git output. Clean.

**(c) Prompt injection**: The helper outputs filtered diffs and stderr summaries. The new `dirty_suffix` (`, includes uncommitted`) is a constant string, not interpolated from user input. Subagent gets a git diff output, not task metadata or user descriptions. Clean.

**(d) Environment-variable handling**: No new env var references. The `git diff` calls remain list-form `capture_git()`, which invokes `execvp` directly. Clean.

**(e) Pattern-based risks**: The disclosure suffix (`, includes uncommitted`) is appended to stderr summaries and is informational only. No invariant-dependent safety. The test validates both index-side (staged) and working-tree-side (unstaged) changes are captured by diffing against HEAD instead of HEAD^1, which is the intended behavioural fix. No reuse anti-patterns.
```

Tier-1 classification (primary sentinel match): `no findings` on the first line. No code action required.

## Lessons Learned
*To be captured during retrospective*
