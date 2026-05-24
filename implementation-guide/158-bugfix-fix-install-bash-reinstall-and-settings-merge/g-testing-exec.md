# Fix install.bash reinstall and settings-merge - Testing Execution
**Task**: 158 (bugfix)

## Task Reference
- **Task ID**: internal-158
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/158-fix-install-bash-reinstall-and-settings-merge
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md and verify implementation from d-implementation-plan.md.

## Execution Checklist
- [x] Read e-testing-plan.md and d-implementation-plan.md thoroughly
- [x] Verify test environment ready
- [x] Execute test cases sequentially
- [x] Record pass/fail for each test
- [x] Document failures with reproduction steps
- [x] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

All TC-1..TC-7 from e-testing-plan.md are implemented as subtests of the new
`t/install-bash-reinstall.t` (self-contained copy of the Task-155 fixture-server
harness). Each was confirmed RED against unfixed code during f-phase, then GREEN
after the fixes. Full run: `prove t/install-bash-reinstall.t` → 7/7 subtests pass.

### Functional Tests

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | item 1, reported bug — reinstall with `.cwf-agents` absent | clean reinstall; all 4 dirs present+tracked; index==HEAD | as expected (11 assertions, incl. rules-inject sanity guard) | PASS |
| TC-2 | item 1, failure path — tracked-dir `git rm` fails (fake-git shim) | install aborts via `die`, `[CWF] ERROR: ...git rm failed for tracked` | as expected | PASS |
| TC-3 | item 1, edge — mixed tracked/untracked pre-state | reinstall succeeds; untracked stale file removed; clean index | as expected | PASS |
| TC-4 | item 2, happy path — settings-merge on fresh install | `.claude/settings.json` has `env.PERL5OPT=-CDSLA` + Bash allowlist, no `/cwf-init` caller | as expected | PASS |
| TC-5 | item 2, failure path — merge helper exits non-zero | install aborts; `.cwf/version` NOT written; no success log | as expected | PASS |
| TC-6 | item 2, guard — merge helper absent | `-x` guard skips; install completes; version written | as expected | PASS |
| TC-7 | item 3 — doc lists every helper prefix | doc enumerates all 9 `@CWF_INTERNAL_PREFIXES` incl. `.claude/agents/` | as expected | PASS |

### Non-Functional Tests
- **Reliability**: TC-1 reinstall is deterministic; the fake-git shim (TC-2) makes the failure-path test root-independent (no perms trick).
- **Regression**: full Perl suite `prove -r t/` → **516 tests, 47 files, all pass**. The Task-155 e2e (`t/cwf-manage-update-end-to-end.t`) now exercises the new `post_install` settings-merge call during install and still passes — the merge runs cleanly against the laid-down `.cwf`.
- **Integrity**: `cwf-manage validate` → `[CWF] validate: OK`. Neither edited file (`scripts/install.bash`, `.cwf/docs/skills/security-review.md`) is hash-tracked, so no `script-hashes.json` refresh — as planned.
- **Sanity (rules-inject)**: TC-1 asserts `.cwf/rules-inject.txt` non-empty after a reinstall — guards the rejected Option A (the file ships populated in the subtree).

## Test Failures

None. (During development, an initial TC-1/TC-3 assertion used `git status --porcelain == ''`, which wrongly expected a clean *working tree*; corrected to `git diff --cached --name-only == ''` since post_install leaves expected untracked artefacts. Documented in f-implementation-exec.md Step 1.)

## Coverage Report

All three reported items covered by both the happy path and the failure/edge paths the fixes turn on (the failure paths are what the removed `|| true` previously swallowed). Out of scope per e-testing-plan: SIGKILL-during-rename atomicity, interactive prompt branches.

## Security Review

**State**: error

**Classifier note**: The `cwf-security-reviewer-changeset` subagent was invoked
on the testing-phase changeset (369 lines: `scripts/install.bash`,
`.cwf/docs/skills/security-review.md`, and the now-tracked new test
`t/install-bash-reinstall.t`, included via its `#!/usr/bin/env perl` shebang).
As in the f-phase, the subagent prefaced its verdict with analysis, violating
the sentinel-first contract; per the three-tier rule this falls through tier-1
(no first-line sentinel) and tier-2 (no `^\d+[.)]` numbered list, no literal
phrase "actionable finding") to the **conservative `error` default**. Recorded
as `error` rather than silently downgrading. **Substantively the review is
clean**: "no findings" — the new file is pure test scaffolding (list-form
`system`/`run(cmd => [...])` throughout, no single-string shell invocation;
`local`-scoped test-internal env vars in `do_install`; tempdir-derived paths).
One non-blocking category-(e) pattern note: the TC-2 git-shim and `$REAL_GIT`
originate from `command -v git` on the test's own PATH, so the single
interpolation into a generated shell script is safe here (test-controlled
value); audit only if `$REAL_GIT`/`$upstream` ever became externally influenced.
Recurring tooling observation (for retrospective): the reasoning-model reviewer
does not reliably honour the sentinel-first contract, so the deterministic
classifier defaults to `error` on otherwise-clean reviews. User to adjudicate.

Verbatim subagent output:

> I have the full test file. Let me analyze it against the threat model. The test uses a PATH-prepended fake-git shim (TC-2), env-var handling in `do_install`, `$REAL_GIT` interpolation into a shim script, and `file://$upstream` URL construction.
>
> **(a) Bash injection / unsafe command construction**: All `system()` calls use list-form (`system('cp', '-rp', ...)`, `run(cmd => ['git', '-C', $dir, @args])`). No single-string `system`. The shim file interpolates `$REAL_GIT` into a bash script written to disk, but `$REAL_GIT` derives from `command -v git` on the test's own PATH — not user/git-output controlled — and is written via list-form, not executed through a shell at construction time. Safe.
>
> **(b) Perl consuming git output without `-z`**: The test reads git output (`ls-files`, `diff --cached --name-only`) and checks it with `length`/equality — it does not newline-split paths to operate per-file. No `-z` violation of consequence.
>
> **(c) Prompt injection**: No `{arguments}` or LLM-context flow. N/A.
>
> **(d) Unsafe env-var handling**: `do_install` sets `CWF_SOURCE`/`CWF_METHOD`/`CWF_REF`/`CWF_FORCE`/`PATH` via `local $ENV{...}` — all test-internal, `local`-scoped. Safe.
>
> **(e) Pattern-based risks**: The `$REAL_GIT` interpolation into a generated shell script and the `PATH` prepend are safe here; test scaffolding, not a reusable production helper.
>
> no findings
> The new test `t/install-bash-reinstall.t` uses list-form `system`/`run(cmd => [...])` throughout, `local`-scoped test-internal env vars in `do_install`, and tempdir-derived paths; the TC-2 git-shim and `$REAL_GIT` value originate from `command -v git` on the test's own PATH, so the one interpolation into a generated shell script is safe here because the value is test-controlled — audit future reuse only if `$REAL_GIT`/`$upstream` ever became externally influenced.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See the "Test Results" section above. 7/7 subtests pass; full suite (516 tests)
+ `cwf-manage validate` green.

## Lessons Learned
A test assertion (`git status --porcelain == ''`) initially encoded the wrong
invariant — a clean *working tree* rather than a clean *index*. post_install
legitimately leaves untracked artefacts; corrected to `git diff --cached`.
