# security-review cap weights production over tests - Testing Execution
**Task**: 168 (chore)

## Task Reference
- **Task ID**: internal-168
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/168-security-review-cap-weight-production-code
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status

## Test Results

Command: `prove -v t/security-review-changeset.t` → **21 subtests, all PASS** (14 pre-existing + 7 new).

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-CAP1 | production-only diff > cap, no test-paths | exit 2, `cap exceeded`, diff on stdout | exit 2; stderr `cap exceeded: 30 production lines > 10`; diff present | PASS |
| TC-CAP2 | small prod + large `t/` diff, `test-paths:["t/**"]` | exit 0, production < raw, production ≤ cap | exit 0; `t/big.t` in changeset; production < raw and ≤ 20 | PASS |
| TC-CAP3 | no `--max-lines` on a 200-line diff | exit 0, never caps | exit 0; no `cap exceeded` | PASS |
| TC-CAP4 | mixed prod(4 lines) + `t/` diff, large cap | `(4 production)`, raw > 4 | stderr `(4 production)`; raw line count > 4 | PASS |
| TC-CAP5 | `--max-lines=abc`, `=0`, `=007` | each exit 1, `invalid --max-lines` | all three exit 1 with the validation message | PASS |
| TC-CAP6 | large binary + 3-line text under `.cwf/scripts/` | exit 0, `(3 production)` (binary→0) | exit 0; stderr `(3 production)` | PASS |
| TC-CAP7 | `test-paths:["../escape"]` (outside-repo) | exit 1, no silent discount | exit 1; no `cap exceeded` | PASS |

### Regression (pre-existing)

| Test ID | Result | Note |
|---------|--------|------|
| TC-F1–F8, TC-NF1–NF5, TC-Task141 | PASS | All 14 unchanged. The strict end-anchored summary assertion at `:559` still matches via its `.+` (the new `(P production)` field sits between `M lines` and `anchor=`). |

### Non-Functional Tests
- **Reliability / fail-safe**: TC-CAP7 confirms a bad consumer pattern fails to `exit 1` (git fatal), never a silent discount — the production count cannot be shrunk by malformed config to let an over-cap diff slip review.
- **Back-compat**: TC-CAP3 confirms absent `--max-lines` never caps (behaviour identical to pre-task).
- **Performance**: TC-NF5 (pre-existing) still passes — one extra `git diff --numstat` is bounded by diff size, not repo size.
- **Integrity**: `cwf-manage validate` reports only the pre-existing `install-manifest.json` 0600-vs-0444 finding (see below); the refreshed `security-review-changeset` hash validates cleanly.
- **Output-level smoke**: helper run on this task's own diff → `reviewed 6 files, 491 lines (149 production)`, exit 0 — the change ships its own ~340-line test suite yet stays well under the 500 cap on production weight, demonstrating the fix.

## Test Failures

No failures in scope.

**Out-of-scope, pre-existing** — full-suite `prove t/` surfaces one unrelated failure:
- `t/cwf-manage-fix-security.t` TC-1 ("clean install → no-op") fails because the live repo's `.cwf/install-manifest.json` is committed at perms `0600` (last touched by Task 167 at baseline `bcf37b4`), so `cwf-manage fix-security` repairs it to `0444` and reports "repaired 1 file" instead of "repaired 0". This is the standing "Install-time chmod 0444" backlog item. Task 168 touches none of `install-manifest.json`, `cwf-manage`, or `t/cwf-manage-fix-security.t` (verified via `git log bcf37b4..HEAD -- <those paths>` → empty). Not caused by, and out of scope for, this task.

## Coverage Report
All seven a-task-plan / e-testing-plan validation criteria exercised: the three exit codes (0/1/2), the `P > N` boundary, `--max-lines` validation incl. `0`/leading-zero, test-path exclusion via git `:(glob,exclude)`, binary→0, context/header exclusion (numstat), and the malformed-pattern fail-safe.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 168
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

I have the full picture. Let me reason through the five threat categories.

## Review reasoning

This is the testing-phase (g) review of Task 168. The production surface is the modified helper `security-review-changeset`; the testing-phase artefact is `t/security-review-changeset.t`. I reviewed both, the doc subsection, the two SKILL Step-8 rewrites, and the committed `cwf-project.json`.

### (a) Bash injection / unsafe command construction

The helper never invokes a shell. Every git call goes through `capture_git` (`open(my $fh, '-|', 'git', @args)`, list-form) or `git_check` (`exec('git', @args)` after fork). The new `count_production_lines` builds its argument vector as `('diff', '--numstat', $anchor, '--', @$included, @$exclude)` and passes it list-form to `capture_git` — no string interpolation into a command. The exclude pathspecs `:(glob,exclude)$p` are git pathspec syntax, parsed by git's own pathspec engine, not by a shell. `--max-lines` never reaches git at all; it is only ever used in the Perl numeric comparison `$production > $opt{max_lines}` after `/^[1-9]\d*$/` validation. No bash-injection surface in the production code.

The test file uses `system('git', '-C', $dir, @args)` (list-form) and `open(my $fh, '-|', 'git', '-C', $dir, @args)` (list-form), and execs the helper list-form. The `../escape` and `foo;rm -rf /` strings in TC-CAP7/TC-NF2 are passed as single argv elements, never through a shell — they exercise the validation/fail-safe paths, they do not execute. Clean.

### (b) Git/user output handling without `-z` / input validation

`list_changed_files` uses `git diff --name-only -z` and `split /\0/` — correct NUL handling. The new `count_production_lines` reads `git diff --numstat` and splits only on `\t`/`\n`. This is the one place worth scrutinising, because numstat is not NUL-safe by default: a path containing a newline or tab would be C-quoted by git and could shift columns. The code defends against this correctly — it reads only the first two columns (added, deleted), never the path column, and gates each on `/^\d+$/`. A quoted/renamed path that injected stray tabs would at worst produce a malformed third+ column, which is discarded; if it somehow corrupted columns 1-2 the `/^\d+$/` guard skips the row. The inline comment documents this invariant. Handled by construction; acceptable.

`--max-lines` and `--task-num` are both regex-validated before use. `test_path_excludes` reads config defensively: eval-guarded `read_config`, ref-type checks at each nesting level, skips non-scalar entries, undef/empty, and NUL-containing strings. The NUL skip is the right defence — a NUL in a pathspec would truncate the argument.

### (c) Prompt injection

No new `{arguments}` substitution. The helper output (the diff) flows to the subagent as before; this change only reduces what reaches the subagent context (the cap), it adds no new untrusted-string path into LLM context. The `cap exceeded:` stderr line that the SKILL records contains only integers, both regex-validated numerics — no user free-text. The Step-8 rewrites record `**State**: error` with the helper's stderr line, which is numeric-only. No prompt-injection surface introduced.

### (d) Environment-variable handling

No new environment variables are read or consumed by this change. Nothing to audit here.

### (e) Pattern-based risks (safe-here-but-risky-elsewhere)

1. numstat column-skipping is safe here because the path column is never read; audit future reuse where someone adds path-column parsing. `count_production_lines` deliberately ignores numstat's third column to sidestep C-quoting/rename hazards. Safe at this callsite because the function only needs a line sum. If a future maintainer extends the loop to read the path, the naive `split /\t/` would misclassify quoted paths and rename rows. Recommend the inline comment be preserved on any such edit. Not a defect today.

2. The fail-safe direction is correct and verified: a malformed `test-paths` pattern makes git fatal, `capture_git` exits 1, and the SKILL surfaces `error` — never a silent discount. TC-CAP7 (`../escape`) asserts exactly this (exit 1, no `cap exceeded`). Aligns with "surface security issues, never smooth them": a bad config cannot turn the cap into a no-op.

### Testing-phase artefact concerns

The test file builds synthetic repos in `tempdir(CLEANUP => 1)` and never touches the real repo or a production database. The forked child uses `POSIX::_exit(127)` on exec failure, correctly avoiding inherited END blocks. All git/exec calls are list-form. The injection-shaped inputs are confined to argv elements asserting validation/fail-safe behaviour and cannot execute.

One non-security quality note (out of scope for the verdict): TC-NF4 is effectively a no-op assertion (`ok(1, ...)`) — its comments admit the FIFO scenario was too awkward to set up via git, so it no longer exercises the guards it names. This is a pre-existing test-quality gap (not introduced by Task 168), not a security finding; the real symlink guard is covered by TC-NF3.

### Verdict

No actionable security concerns in the diff. New git invocations are list-form, inputs are regex-validated before use, the numstat parser avoids the path-column quoting hazard by construction, the config reader is defensively typed and NUL-guarded, and the fail-safe direction is correct and test-covered.

```cwf-review
state: no findings
summary: List-form git throughout; --max-lines/--task-num regex-validated; numstat parser reads only numeric columns (path-quoting safe); test-paths reader is type/NUL-guarded; fail-safe direction correct and covered by TC-CAP7.
```

## Lessons Learned
The phase-g security review re-ran on a near-identical changeset (489 vs 491 lines, same 149 production). Gate honoured; redundancy noted. TC-NF4 found to be a pre-existing no-op assertion. See `j-retrospective.md`.
