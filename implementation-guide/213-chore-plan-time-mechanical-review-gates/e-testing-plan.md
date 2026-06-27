# Plan-time mechanical review gates - Testing Plan
**Task**: 213 (chore)

## Task Reference
- **Task ID**: internal-213
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/213-plan-time-mechanical-review-gates
- **Template Version**: 2.1

## Goal
Validate the `plan-mechanical-check` helper: both scans reproduce the Task-150 and Task-174
defect classes, the edge cases the plan review surfaced are handled, and the helper degrades
fail-open without ever blocking the workflow.

## Test Strategy
### Test Levels
- **Unit / behavioural** (primary): `t/plan-mechanical-check.t` (Perl `Test::More`, `prove`), driving the helper as a subprocess against `File::Temp` git-repo fixtures — the established CWF pattern (`security-review-changeset.t`, `best-practice-resolve` tests).
- **Regression**: full `prove -r t/` to confirm no existing suite breaks.
- **Integrity**: `cwf-manage validate` (helper is `0500` + hash-tracked; same-commit refresh).

### Fixture approach
Each case builds a throwaway repo with `File::Temp::tempdir(CLEANUP => 1)`, `git init`, a minimal
`implementation-guide/<n>-chore-x/` task dir with the relevant plan file, plus seeded source/test
files, then runs the helper with `--task-num` / `--plan-type` and asserts on the findings `.out`
file, the stdout confirmation line, and the exit code. **Capture cwd before any `eval`/`chdir`** and
restore in an `END`/`local $CWD` guard (per the `File::chdir` discipline) so a failing case cannot
leak cwd into later cases.

### Coverage Targets
- **Critical paths (100%)**: both finding classifications (high-signal/advisory), symbol found vs zero-refs, all three exit outcomes (0-with-findings, 0-clean, 1-resolution-failure).
- **Edge cases**: leading-dash symbol, token-shape rejection, plan-file-absent, self-match exclusion.

## Test Cases
### Functional Test Cases (path check)
- **TC-1 (Task-150 regression — high-signal)**:
  - **Given**: a fixture repo with `.cwf/scripts/cwf-manage` present; a d-plan referencing `` `.cwf/scripts/command-helpers/cwf-manage` `` (wrong dir, same basename).
  - **When**: `plan-mechanical-check --task-num=N --plan-type=implementation`.
  - **Then**: exit 0; findings file contains a high-signal finding naming both the missing referenced path and the existing `<alt>`; confirmation line reports N≥1.

- **TC-2 (advisory — genuine new file)**:
  - **Given**: a d-plan referencing `` `.cwf/scripts/command-helpers/brand-new-thing` `` with no basename match anywhere in the repo.
  - **When**: helper runs.
  - **Then**: exit 0; finding is **advisory** ("confirm new file vs typo"), explicitly *not* high-signal.

- **TC-10 (token-shape rejection)**:
  - **Given**: a plan containing backtick tokens that are a URL (`` `https://x/y` ``), a glob (`` `*.md.template` ``), a pathspec (`` `:!foo/bar` ``), and a regex (`` `/^\d+/` ``).
  - **When**: helper runs (no other path issues).
  - **Then**: exit 0; **zero** path findings from those tokens (all rejected pre-existence-check).

### Functional Test Cases (symbol check)
- **TC-3 (Task-174 regression)**:
  - **Given**: a fixture with `@CWF_INTERNAL_PREFIXES` referenced in two seeded files (e.g. `t/a.t`, `t/b.t`); a d-plan with `- **Deletes**: @CWF_INTERNAL_PREFIXES`.
  - **When**: helper runs.
  - **Then**: exit 0; finding lists both files with line counts; N≥1.

- **TC-4 (zero references — safe delete, exit-1 path)**:
  - **Given**: a d-plan with `- **Deletes**: totally_unused_symbol` and no references anywhere.
  - **When**: helper runs (the underlying `git grep` returns exit 1).
  - **Then**: exit 0; **no** finding for that symbol (exit 1 treated as zero matches, not an error).

- **TC-6 (self-match exclusion)**:
  - **Given**: a d-plan with `- **Deletes**: SomeSym` where the only occurrences of `SomeSym` are in the plan file / task dir itself.
  - **When**: helper runs.
  - **Then**: exit 0; no finding (the task's own `implementation-guide/<dir>` is excluded via pathspec).

- **TC-9 (leading-dash symbol — option-injection guard)**:
  - **Given**: a d-plan with `- **Deletes**: -O` (or `--output`).
  - **When**: helper runs.
  - **Then**: exit 0; `-O` is searched as a literal pattern (`-e`/`--` guard), no `git grep` option error, tally correct.

### Functional Test Cases (contract / lifecycle)
- **TC-5 (clean no-op)**:
  - **Given**: a d-plan with all referenced paths valid and no `**Deletes**` line.
  - **When**: helper runs.
  - **Then**: exit 0; findings file written with 0 findings; confirmation line `plan-mechanical-check: wrote 0 findings to <abs-path>`.

- **TC-7 (resolution failures vs plan-absent)**:
  - **Given/When/Then**:
    - invalid `--task-num` (e.g. `abc`) → exit 1; unknown `--plan-type` → exit 1; missing required arg → exit 1.
    - task dir resolves but the `d-…md` file is absent (phase not reached) → exit 0, 0 findings (fail-open).

- **TC-8 (output location + confirmation format)**:
  - **Given**: any valid run.
  - **When**: helper runs.
  - **Then**: `.out` lives under `<scratch>/task-<num>/plan-mechanical-check-<plan-type>.out` (mode 0600); stdout is exactly one line matching `^plan-mechanical-check: wrote \d+ findings to /.+\n$`.

### Non-Functional Test Cases
- **Reliability / fail-open**: scan-internal git error (exit ≥2) degrades to "no finding for that item", never a non-zero helper exit (covered behaviourally within the symbol cases; assert no `die`).
- **Security**: leading-dash operand cannot become a git option (TC-9); symbol/path values never reach a shell (list-form spawn) — asserted by the absence of shell metacharacter interpretation in a `$(…)`-bearing symbol fixture.
- **Performance**: not a concern at this scale (single plan file, one `git ls-files` + N `git grep`); no benchmark required. Note the absence rather than inventing a target.

## Test Environment
### Setup Requirements
- Perl core only (`Test::More`, `File::Temp`); `git` on PATH; no network, no database.
- Self-contained `File::Temp` repos — never touch the real repo state.

### Automation
- `prove -lr t/plan-mechanical-check.t` (targeted) and `prove -r t/` (full regression), run in g-testing-exec.
- `cwf-manage validate` as the post-commit integrity gate.

## Validation Criteria
- [ ] TC-1…TC-10 all pass.
- [ ] Full `prove -r t/` green (no regressions).
- [ ] Helper is `0500` and present in `script-hashes.json`; `cwf-manage validate` clean.
- [ ] No permission prompt when the helper is invoked via the allowlisted command string.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 213
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned cases executed and passing (37 targeted assertions); TC-11 (markdown anchor) added during exec after the dogfood smoke-test surfaced the false-positive. See `g-testing-exec.md`.

## Lessons Learned
The output-level dogfood smoke-test caught a defect the 37 source assertions did not — keep it mandatory for prose-consuming helpers. See `j-retrospective.md`.
