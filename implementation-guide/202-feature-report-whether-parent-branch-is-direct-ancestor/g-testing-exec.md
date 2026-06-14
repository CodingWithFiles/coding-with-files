# report whether parent branch is direct ancestor - Testing Execution
**Task**: 202 (feature)

## Task Reference
- **Task ID**: internal-202
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/202-report-whether-parent-branch-is-direct-ancestor
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md (TC-1…TC-9) and confirm no
regression in the full suite.

## Test Environment
- New test file `t/taskpath-parent-branch-ancestry.t` (Tier C). Each case builds
  a throwaway git repo via `CWFTest::Fixtures::create_git_repo` plus a local
  `build_repo` helper that lays down a nested parent (`1-feature-parent`) + child
  (`1.1-bugfix-child`) under `implementation-guide/`, then shapes git history.
- `parent_branch_ancestry` and the `context-manager hierarchy` subprocess are
  both invoked with cwd set to the synthetic repo (restored after), since they
  resolve the base dir and run git relative to cwd.
- The fixture helper was kept **local to the test file** (not added to
  `Fixtures.pm`): only one test file needs it, so per the e-plan's own
  ">1 file" guidance and the brevity principle it stays local.
- `JSON::PP` (core) used as the real parser for TC-8.

## Test Results

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | parent branch is ancestor of HEAD | `1` | `1` | PASS |
| TC-2 | HEAD == parent branch tip (own ancestor) | `1` | `1` | PASS |
| TC-3 | parent branch diverged from HEAD | `0` | `0` | PASS |
| TC-4 | top-level task (no parent) | `undef` | `undef` | PASS |
| TC-5 | parent branch absent | `undef` | `undef` | PASS |
| TC-6 | prefix-collision decoy (`feature/1-foo` vs absent `feature/1-foobar`) | `undef` | `undef` | PASS |
| TC-7 | unborn HEAD (merge-base errors) | `undef` | `undef` | PASS |
| TC-8 | `hierarchy 1.1 --format=json` via JSON::PP — field is a JSON boolean, all 7 pre-existing fields present | valid + additive | valid + additive | PASS |
| TC-9 | markdown line present for parented task, absent for top-level | line / no-line | line / no-line | PASS |

TC-6 confirms the exact-match `rev-parse --verify refs/heads/<branch>` guard does
not false-positive on a sibling branch sharing a name prefix — the reason the
design declined to reuse the `branch_exists` glob. TC-7 exercises the
`rc ∉ {0,1}` branch by leaving the parent branch present but HEAD unborn (via
`git checkout --orphan`), so `merge-base` errors rather than the existence guard
short-circuiting.

### Non-Functional Tests
- **Security (NFR3)**: all cases use hyphenated slugs routed through the list-form
  `run_quiet`; no shell evaluation occurs. No metacharacter slug is reachable in
  practice (`generate_slug` bounds the charset), so this is covered behaviourally
  rather than fuzzed — consistent with the e-plan.
- **Reliability (NFR4)**: TC-8 asserts every pre-existing JSON field is still
  present and the field is additive; the `hierarchy` exit code is unchanged (the
  full suite, incl. `statusaggregator`/`contextinheritance` consumers, stays
  green).

## Coverage Report
- Tri-state branches (`1` / `0` / `undef`): 100% — every row of the c-design
  edge-case table has a case.
- New file: `t/taskpath-parent-branch-ancestry.t` — 9 subtests, all PASS.
- Full suite: **67 files, 807 tests, all pass** (`prove -l -j4 t/`), up from
  66/798 at the f-phase baseline (+1 file, +9 tests; no regressions).
- `cwf-manage validate` → OK.

## Test Failures
None. (During authoring, TC-8 briefly failed on a `plan tests` miscount —
11 assertions declared as 10 — corrected; all assertions themselves passed.)

## Security Review

**State**: no findings

## Security review — Task 202 testing-exec (`t/taskpath-parent-branch-ancestry.t`)

The reviewable new executable surface in this changeset is the test file `t/taskpath-parent-branch-ancestry.t`. The production-code changes are byte-identical to the already-reviewed implementation-exec phase; the task-doc files, `.claude/settings.json` reserialisation, and hash-manifest refresh carry no new executable content. Review focused on the test harness.

### (a) Bash injection / unsafe command construction
The test's `git` helper uses list form throughout: `system('git', '-C', $repo, @a)`, and the two pipe-opens use list-form `open ... '-|', 'git'/$CM, ...`. No shell is invoked. The only string-form `system` is the constant `git --version` probe — benign. The underlying `create_git_repo` fixture uses shell-form `system("git -C '$repo' ...")`, safe here because `$repo` is a machine-generated `File::Temp` path; pre-existing and out of scope.

### (b) Untrusted-input / git-output handling
git output is read only in `default_branch`/`run_hier`, consuming controlled output (a self-created branch name; the helper's JSON/markdown) — not arbitrary path lists, so the NUL-split concern does not apply. No untrusted input flows in.

### (c) Unsafe filesystem / path operations
Each `build_repo` creates an isolated `tempdir(CLEANUP => 1)`; all `make_path` targets are rooted under that fresh tempdir. No `/tmp` literal, fixed path, symlink follow, or `..` traversal. CLEANUP rmtree fires only in the parent — and the production `run_quiet` under test uses `POSIX::_exit` so a forked child cannot trigger that cleanup against the parent's tempdir.

### cwd manipulation — load-bearing for this Tier C harness
`anc` saves cwd, `chdir`s, runs inside `eval`, restores cwd **before** re-throwing — restored on both success and exception. `run_hier` restores cwd on pipe-open failure and after a die-free slurp/close. No helper `chdir`s into a path it then deletes while inside it; all git mutation is `-C $repo`-scoped to the throwaway tempdir. The harness cannot touch the live repo or any path outside its tempdir.

### (d) Command / shell execution surface
Subprocess surface is the real `context-manager` and `git`, both list-form; `$CM` derives from `$FindBin::Bin`, not input. No eval-string, qx, or shell pipeline.

### (e) Privilege / permission changes
None — no chmod/chown/umask/setuid; writes only inside the tempdir.

### Environment-variable handling
Reads no env vars directly; inherits `TMPDIR`/`PATH` as every other fixture does. No env var influences a security-critical path.

### Prompt-injection surface
None — only self-authored names/paths feed the helper; output asserted by structure, not echoed downstream. Task-doc files are inert templates.

### Conclusion
Well-contained Tier C harness: isolated auto-cleanup tempdirs, list-form git/subprocess calls, cwd save/restore on every chdir (the exception-sensitive `anc` correctly guarded by eval). No unsafe temp handling, cwd escape, injection, privilege, or env-var concern. No actionable security findings.

```cwf-review
state: no findings
summary: Tier C test harness is contained — isolated CLEANUP tempdirs, list-form git/subprocess calls, cwd save/restore on every chdir; no escape to the real repo or filesystem, no injection/env/privilege concern. Pre-existing shell-form system() in create_git_repo noted as safe-here (machine-generated tempdir path).
```

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*Consolidated in j-retrospective.md.*
