# Group Stop-hook warning by task number - Testing Execution
**Task**: 200 (bugfix)

## Task Reference
- **Task ID**: internal-200
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/200-group-stop-hook-warning-by-task-number
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

New test: `t/stop-uncommitted-changes-warning.t` (core-only subprocess harness —
each case builds a throwaway git repo, plants untracked wf files, runs the hook
by absolute path with cwd = the temp repo, decodes the stdout JSON). All 7 cases
pass; each non-empty case additionally asserts exit 0 + valid JSON (20 assertions).

### Functional Tests

| Test ID | Test Case | Expected `systemMessage` | Status |
|---------|-----------|--------------------------|--------|
| TC-1 | single task, ≤3 files (elision) | `⚠ Uncommitted: a-task-plan.md, c-design-plan.md` (no prefix) | PASS |
| TC-2 | single task, >3 files (flat overflow) | `… a-, b-, c- +5 more` (no prefix, baseline-identical) | PASS |
| TC-3 | two tasks (grouping) | `199: a-…, c-…; 30: f-…` | PASS |
| TC-4 | nested subtask number | `28.1: f-…; 30: a-…` (keyed 28.1, not 28) | PASS |
| TC-5 | multi-task, per-group overflow | `199: a-, c-, d- +1 more; 30: a-…` (no group dropped) | PASS |
| TC-6 | non-task parent dir | `30: a-…; scratch: a-…` (raw key fallback, surfaced) | PASS |
| TC-7 | clean tree | empty stdout, exit 0 | PASS |

Note on ordering: git `status --porcelain` emits records sorted by pathname, so
group/file order is lexicographic by path (e.g. `199` before `30`, `28` before
`30`). The e-testing-plan's "file-plant order controls git-status order" framing
was inaccurate — git sorts regardless of plant order; expectations were written
to match git's sort. No behavioural impact (the hook preserves whatever order git
returns; "first-seen" = git's sorted order).

### Non-Functional Tests
- **Exit-0 invariant**: asserted on every case (incl. TC-7) — PASS.
- **Valid JSON**: every non-empty output decodes via `JSON::PP` to an object with
  a `systemMessage` key — PASS.
- **Portability**: core modules only (`Test::More`, `File::Temp`, `File::Path`,
  `File::Spec`, `FindBin`, `JSON::PP`) — no CPAN deps.

## Test Failures

None.

## Coverage Report

- `prove -v t/stop-uncommitted-changes-warning.t` → 20/20 assertions PASS.
- Full suite `prove -r t/` → Files=64, Tests=782, **Result: PASS** (no regression).
- `.cwf/scripts/cwf-manage validate` → `validate: OK` (sha256 + 0500 perms).

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Writing the subprocess harness surfaced the git-sort-order assumption baked into
the testing plan — driving the hook against a real (throwaway) git tree rather
than mocking the status output is what exposed it. A test that mocked git's
output would have encoded the wrong assumption silently. Confirms the value of
real-subprocess harnesses for leaf scripts whose behaviour depends on a tool's
output ordering.

## Security Review

**State**: no findings

The changeset is the testing-exec phase for Task 200. The core change under review is the new test file `t/stop-uncommitted-changes-warning.t`. Let me reason through the threat categories.

The testing-exec changeset adds one executable test file (`t/stop-uncommitted-changes-warning.t`, new mode 100755) plus the task's wf step markdown (g-testing-exec, j-retrospective, and the earlier a/c/d/e/f docs that landed in the same diff anchor window). The hook change itself and its sha256 refresh were already reviewed at implementation-exec; my focus here is the new test code, which is the only executable surface this phase introduces.

**(a) Bash injection / unsafe command construction.** The test spawns subprocesses two ways. `build_repo` and the git config calls use **list-form** `system('git', '-C', $dir, ...)` — no shell, arguments go straight to execvp, so `$dir` (a `File::Temp` tempdir path) cannot inject. Good. The one place that uses the shell is `run_hook` (line 902):

```perl
my $out = `cd '$dir' && '$HOOK' 2>/dev/null`;
```

This is a backtick (shell) invocation interpolating `$dir` and `$HOOK` inside single quotes. This is the one item worth examining. `$dir` comes from `File::Temp::tempdir(CLEANUP => 1)`, which produces a path under the system temp dir with a randomised `XXXXXXXX` suffix and no single-quote or shell-metachar content; `$HOOK` is a compile-time constant string `"$FindBin::Bin/../.cwf/scripts/hooks/stop-uncommitted-changes-warning"`. So at this callsite the single-quoted interpolation is safe — neither value can contain a `'` to break out of the quoting. This is a category-(e) pattern-risk rather than an actionable finding: safe here because both interpolated values are framework-generated (tempdir) or a literal constant with no quote/metachar content; audit future uses where someone parameterises `run_hook` with a caller- or fixture-supplied path that could contain a single quote or shell metacharacter, at which point the `cd '$dir'` quoting would be breakable. The list-form alternative (e.g. spawning with an explicit cwd via a forked child + `chdir`, or `system` list-form capturing through a temp file) would remove the dependency on the invariant, but for a fixed-input test harness the current form is acceptable.

**(b) Perl consuming git/user output without `-z` / input validation.** The test does not parse git porcelain output itself — it asserts on the hook's stdout JSON, decoded via `JSON::PP->new->decode` (line 910). JSON decoding is structured parsing, not newline-splitting, so the `-z` concern does not apply. The hook under test continues to use `--porcelain -z` + `split /\0/` (unchanged, reviewed at f). No untrusted-string-into-backtick issue beyond the `run_hook` path already covered under (a). `use utf8;` is present; shebang is `#!/usr/bin/env perl`. Clean.

**(c) Prompt injection via user-supplied strings.** No `{arguments}` substitution and no LLM-context flow in a test file. The planted filenames and dir names are all literal string constants authored in the test body (`199-discovery-x`, `28.1-chore-c`, `scratch`, etc.), not user input. No prompt-injection surface.

**(d) Unsafe environment-variable handling.** The test reads no environment variables. Paths derive from `$FindBin::Bin` (script-location constant) and `File::Temp` tempdirs, not from `$ENV`. The `git -C $dir` and `cd '$dir'` targets are framework-generated tempdirs, never env-derived. Not applicable.

**(e) Pattern-based risks.** Covered inline under (a): the `run_hook` shell backtick with single-quoted `$dir`/`$HOOK` interpolation is safe at this callsite because both values are framework-generated/constant and quote-free; flagged so a future reader who parameterises the harness with a less-constrained path knows the `cd '$dir'` quoting is the invariant they'd break. One secondary observation, not a security finding: `File::Spec->splitpath` + `make_path($d)` on a path joined from a literal `$rel` is fine because `$rel` values are all test-authored constants; no traversal concern since nothing user-supplied reaches the path.

**Test-isolation note (not a security finding, but worth recording):** the harness correctly builds a throwaway `File::Temp` repo per case with local `user.email`/`user.name` and never touches the real tree or a production database — consistent with the test-DB-isolation rule. The hook is run by absolute path with cwd set to the temp repo, so the git query sees only planted files. Good hygiene.

Conclusion: no actionable security findings in the testing-exec changeset. The single pattern-risk item — the single-quoted shell interpolation in `run_hook` — is safe at this callsite (tempdir + constant, both quote-free) and is flagged only as an audit-if-reused note, not a defect.

Relevant file:
- `/home/matt/repo/coding-with-files/t/stop-uncommitted-changes-warning.t` (the `run_hook` shell interpolation is at line 902)

```cwf-review
state: no findings
summary: Test harness uses list-form git spawns and JSON-decodes hook output; the one shell-backtick in run_hook interpolates only a File::Temp dir and a constant HOOK path (quote-free), safe-here pattern-risk, not regressed.
```
