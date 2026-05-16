# default task-workflow baseline-commit to HEAD - Testing Plan
**Task**: 142 (chore)

## Task Reference
- **Task ID**: internal-142
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/142-default-task-workflow-baseline-commit-to-head
- **Template Version**: 2.1

## Goal
Validate that `--baseline-commit` is correctly optional in `template-copier-v2.1`, that HEAD resolution behaves correctly across all three repo states (commit present, empty repo, no repo), and that the SKILL examples no longer trigger shell-substitution permission prompts.

## Test Strategy

### Test Levels
- **Unit**: `CWF::Common::resolve_head_sha` in isolation, under each of the three repo states.
- **Integration**: `template-copier-v2.1` end-to-end — flag omitted, flag present, both with the rendered `a-task-plan.md` inspected.
- **System / smoke**: Live `/cwf-new-task` invocation in this repo verifying no permission prompt fires and the resulting `a-task-plan.md` carries a populated 40-char SHA.

### Test Coverage Targets
- Unit: 100% branch coverage of `resolve_head_sha` (three branches: valid commit, empty repo, no repo).
- Integration: 100% of the two call shapes in `template-copier-v2.1` (explicit value, omitted value).
- Regression: full `prove -r t/` suite passes; no existing test broken by the resolver insertion.
- Security: `.cwf/scripts/cwf-manage validate` passes after hash regen.

## Test Cases

### Functional Test Cases

- **TC-1**: `resolve_head_sha` returns valid SHA inside a repo with at least one commit
  - **Given**: A tempdir prepared with `CWFTest::Fixtures::create_git_repo` (which initialises a repo and creates at least one commit).
  - **When**: Calling `CWF::Common::resolve_head_sha()` with cwd set inside that repo.
  - **Then**: Returns a 40-char lowercase hex string equal to the output of `git rev-parse HEAD` from the same cwd.

- **TC-2**: `resolve_head_sha` returns undef inside an empty repo
  - **Given**: A tempdir with `git init` run but no commits made.
  - **When**: Calling `CWF::Common::resolve_head_sha()` with cwd inside that repo.
  - **Then**: Returns `undef` (the function's contract for unresolvable HEAD; `git rev-parse HEAD` exits non-zero or returns the literal string `HEAD`, neither of which match the 40-char hex regex).

- **TC-3**: `resolve_head_sha` returns undef outside any git repo
  - **Given**: A tempdir with no `git init` and no parent directory under git control.
  - **When**: Calling `CWF::Common::resolve_head_sha()` with cwd inside that tempdir.
  - **Then**: Returns `undef`.

- **TC-4**: `template-copier-v2.1` resolves HEAD when `--baseline-commit` omitted
  - **Given**: cwd is inside the live repo (a real git repo with commits); a tempdir destination is prepared.
  - **When**: Invoking `template-copier-v2.1 --task-type=chore --task-num=999 --description="test" --destination=<tempdir>` (no `--baseline-commit` flag).
  - **Then**: Exit code 0; the rendered `a-task-plan.md` contains a `**Baseline Commit**:` line whose value is a 40-char lowercase hex string matching the current `git rev-parse HEAD`.

- **TC-5**: `template-copier-v2.1` passes through explicit `--baseline-commit` verbatim
  - **Given**: cwd inside a git repo; tempdir destination prepared; a synthetic 40-char SHA `"deadbeef" x 5`.
  - **When**: Invoking `template-copier-v2.1 --task-type=chore --task-num=999 --description="test" --destination=<tempdir> --baseline-commit="deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"`.
  - **Then**: Exit code 0; the rendered `a-task-plan.md` contains exactly `**Baseline Commit**: deadbeefdeadbeefdeadbeefdeadbeefdeadbeef`. No git resolution attempted.

- **TC-6**: `template-copier-v2.1` fails loud when `--baseline-commit` omitted outside a git repo
  - **Given**: cwd is a tempdir not under any git repo.
  - **When**: Invoking `template-copier-v2.1` without `--baseline-commit`.
  - **Then**: Exit code 1; stderr contains `[CWF] ERROR: Could not resolve HEAD as baseline commit.` (the canonical message from the resolver branch); no files written to destination (atomic failure).

### Non-Functional Test Cases

- **TC-7 (Usability)**: Permission-prompt elimination — manual smoke test
  - **Given**: User runs `/cwf-new-task 998 chore "smoke test for 142"` against this updated codebase.
  - **When**: Claude Code executes the SKILL's example invocation block.
  - **Then**: No `Contains shell syntax (string) that cannot be statically analyzed` permission prompt is raised. The task is created; `a-task-plan.md` carries the expected 40-char SHA. (Clean up the throwaway task with `/cwf-delete-task` after.)

- **TC-8 (Security / integrity)**: Hash regen verified
  - **Given**: `template-copier-v2.1` has been modified; `.cwf/security/script-hashes.json` updated by hand with the new digest; `last_updated` bumped.
  - **When**: Running `.cwf/scripts/cwf-manage validate`.
  - **Then**: Exit code 0; no integrity warnings for `template-copier-v2.1` (and `CWF/Common.pm` if it's hashed).

- **TC-9 (Regression)**: Full test suite still green
  - **Given**: All code changes from this task applied.
  - **When**: Running `prove -r t/` from repo root.
  - **Then**: All tests pass; no skips beyond what was already skipped on the baseline commit.

## Test Environment

### Setup Requirements
- Standard repo checkout — no external dependencies.
- `CWFTest::Fixtures` available under `t/lib/` (already present, exports `create_git_repo`).
- POSIX `git`, `sha256sum` available in PATH (already assumed by the project).
- Core Perl only — no CPAN modules introduced (`feedback_perl_core_only`).

### Automation
- All unit and integration tests run under `prove -r t/`.
- Smoke test (TC-7) is manual — runs once by the implementer before commit.
- `cwf-manage validate` (TC-8) runs as part of the checkpoint commit script after the hash regen step.

## Validation Criteria
- [ ] TC-1 through TC-6 (automated) pass under `prove -r t/`
- [ ] TC-7 (manual smoke test) confirms no permission prompt
- [ ] TC-8 confirms integrity validation clean
- [ ] TC-9 confirms no regressions in existing test suite
- [ ] `grep -rn 'git rev-parse HEAD' .claude/skills/cwf-new-task .claude/skills/cwf-new-subtask` returns no matches

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 142
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
