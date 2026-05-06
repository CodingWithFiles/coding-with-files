# Fix security-review changeset construction - Testing Plan
**Task**: 129 (bugfix)

## Task Reference
- **Task ID**: internal-129
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/129-fix-security-review-changeset
- **Template Version**: 2.1

## Goal
Validate that the new `security-review-changeset` helper closes the three failure modes from the BACKLOG entry, that template + skill changes correctly record baseline commits, and that no existing CWF tests regress.

## Test Strategy

### Test Levels
- **Unit / property** (within `t/security-review-changeset.t`): the shebang sniff, baseline-line parser, trunk validator. Pure-logic where possible; synthetic-FS where not.
- **Integration** (within the same `.t` file, separate subtests): full helper invocation against synthetic git repos covering each bug-report axis.
- **System / dogfood** (during g-testing-exec): the helper is invoked on this very task's own branch via the modified exec SKILL — the changeset construction reviews itself.
- **Regression**: full `prove t/` run after implementation; no prior tests should fail.

### Test Coverage Targets
- **Bug-report axis coverage**: each of the three issues called out in the BACKLOG entry has at least one passing assertion. Hard requirement.
- **Helper code paths**: anchor resolution (baseline-found, baseline-format-bad, no-baseline-fallback), classification rules (CWF-internal-dir include, shebang-include, shebang-exclude, symlink-skip, non-regular-file-skip), trunk resolution (config-field, symbolic-ref, hardcoded-default, validation-reject). Each path has at least one test.
- **Edge cases**: empty filtered changeset; subtask numbers (e.g. `1.1.1`); deleted file in diff (no shebang sniff attempt); binary-with-shebang-prefix excluded from sniff via `-f`/`-l` guards.
- **No coverage target for existing helpers** that this task only lightly touches (`template-copier-v2.1`, exec SKILLs) beyond "regression-clean": `prove t/template-copier-slug-validation.t` and `prove t/templatecopier.t` must still pass after the `--baseline-commit` argument is added.

## Test Cases

### Functional Test Cases (correspond to BACKLOG axes 1-3 + helper internals)

#### TC-F1: Extension-less CWF-internal script is reviewed
- **Given**: a synthetic repo with a CWF-shaped layout. `.cwf/scripts/cwf-foo` is created on the task branch with content `#!/usr/bin/perl\nprint "x";\n` and no `.pl` extension. `a-task-plan.md` records the baseline.
- **When**: the helper runs.
- **Then**: stdout includes the diff hunk for `.cwf/scripts/cwf-foo`. Closes BACKLOG axis (1).

#### TC-F2: Consumer-stack file with shebang is reviewed without CWF-side edits
- **Given**: a synthetic non-CWF-stack repo. `app/main.py` is created on the task branch with `#!/usr/bin/env python3` shebang. No `cwf-project.json` `always-included-paths` override (the task removed that schema). `a-task-plan.md` records the baseline.
- **When**: the helper runs.
- **Then**: stdout includes the diff hunk for `app/main.py`. Closes BACKLOG axis (2).

#### TC-F3: Earlier-task work is excluded when its branch is unmerged
- **Given**: a synthetic repo with `main` → branch `task1` (one extra commit, not merged) → branch `task2` from `main`'s tip. `task2`'s `a-task-plan.md` records baseline = `main`'s tip. A change is made on `task2`.
- **When**: the helper runs on `task2`.
- **Then**: stdout includes only `task2`'s change; nothing from `task1` appears, even though `task1`'s commit is reachable via the workspace. Closes BACKLOG axis (3).

#### TC-F4: Binary blob in CWF-internal dir is included unconditionally
- **Given**: a binary file (`\xff\xfe...\xa3`) at `.cwf/scripts/some-blob` (CWF-internal dir).
- **When**: the helper runs.
- **Then**: stdout includes its diff hunk. (CWF-internal dir rule is unconditional; binary content is not a reason to exclude markdown-skill-adjacent paths.)

#### TC-F5: Binary blob outside CWF dirs is excluded
- **Given**: a binary file at `tools/some-blob` with no shebang.
- **When**: the helper runs.
- **Then**: stdout does not include `tools/some-blob`. Validates the negative path of the shebang sniff.

#### TC-F6: Plain-text file outside CWF dirs is excluded
- **Given**: `notes.txt` outside CWF dirs containing readable text but no shebang.
- **When**: the helper runs.
- **Then**: stdout does not include `notes.txt`.

#### TC-F7: Subtask baseline resolves correctly
- **Given**: synthetic repo with parent task `1` and subtask `1.1`. Subtask's `a-task-plan.md` records its own baseline.
- **When**: the helper runs with `--task-num=1.1`.
- **Then**: subtask's `full_path` is resolved by `CWF::TaskPath::resolve_num`, the subtask's `a-task-plan.md` is read, and the diff is computed from the subtask's recorded baseline. Validates nested-task resolution.

#### TC-F8: Format-unexpected baseline line warns and falls back
- **Given**: a task whose `a-task-plan.md` contains `- **Baseline Commit**: not-a-sha` (deliberately malformed).
- **When**: the helper runs.
- **Then**: stderr contains the warning `Baseline Commit line found but format unexpected; falling back to merge-base`; the helper proceeds via merge-base (does not exit 1).

### Non-Functional Test Cases

#### TC-NF1 (Security): Trunk-name with `..` is rejected
- **Given**: in-flight task (no baseline field). `cwf-project.json` has `"trunk": ".."`.
- **When**: the helper runs.
- **Then**: helper exits 1; stderr contains `not a valid git branch reference`. Validates the `git check-ref-format --branch` guard against path-traversal-shaped trunk names.

#### TC-NF2 (Security): `--task-num` with non-numeric input is rejected
- **Given**: helper invoked as `security-review-changeset --task-num=foo/../etc`.
- **When**: it parses arguments.
- **Then**: exits 1 before any FS access; stderr names the validation regex. Validates the defence-in-depth check.

#### TC-NF3 (Reliability): Symlink in changed-files list is skipped
- **Given**: a synthetic repo where the diff includes a path that is a symlink (e.g. to `/dev/null`).
- **When**: the helper applies the shebang sniff.
- **Then**: the path is silently excluded; the helper does not open the symlink target; the helper completes without hanging.

#### TC-NF4 (Reliability): FIFO/non-regular-file is skipped
- **Given**: a synthetic repo with a path that is a FIFO (created via `POSIX::mkfifo` if available, else `Test::More::skip` on platforms without it).
- **When**: the helper applies the shebang sniff.
- **Then**: the path is excluded via `-f` guard; helper does not block on `sysread`.

#### TC-NF5 (Performance): Helper completes in O(diff size), not O(repo size)
- **Given**: a synthetic repo with a 1000-file working tree but only 3 changed files in the diff.
- **When**: the helper runs.
- **Then**: fewer than 10 file-open calls are made (one per changed path, plus a-task-plan.md and possibly cwf-project.json). Asserted via a counter wrapper or by spot-checking elapsed time stays under 2 s on dev hardware.

  Asserting the file-count exactly is fragile; a coarser assertion ("test completes in <2 seconds with 1000-file tree") is sufficient — the design depends on diff-size scaling, not repo-size scaling.

### Tests explicitly NOT written here

- **Threat-model coverage tests** for the security-review subagent itself. The helper's job is to construct the changeset; the subagent's threat model is owned by `.cwf/docs/skills/security-review.md` and tested implicitly when the exec-phase security review runs (g-testing-exec). Adding "subagent finds X" tests would couple this task to the subagent prompt's behaviour, which is out of scope.
- **Existing CWF helpers' regression coverage**. The full `prove t/` regression run is the gate; adding bespoke tests here for `template-copier-v2.1` would duplicate `t/templatecopier.t`.
- **`cwf-manage validate` tests**. The hash-tracking gate is exercised in Step 6 of d-implementation-plan; not a separate test case.

## Test Environment

### Setup Requirements
- POSIX shell (synthetic repos created via `File::Temp::tempdir` and `system 'git', ...`).
- Local `git` binary (CWF dependency anyway).
- Perl 5 with `Test::More`, `File::Temp`, `POSIX` (for `mkfifo` if testing TC-NF4).
- `t/lib/CWFTest/Fixtures.pm` if it exports relevant helpers — confirm the exact exported names while writing the test (`create_git_repo`, `create_task_dir` were named in the misalignment review; verify before relying).

### Automation
- Run via `prove t/security-review-changeset.t` (single-file) and `prove t/` (regression-clean gate).
- No CI integration changes — existing CI runs `prove t/` already.

## Validation Criteria
- [ ] `prove t/security-review-changeset.t` passes all functional and non-functional cases.
- [ ] `prove t/` passes regression-clean (no prior tests fail).
- [ ] `.cwf/scripts/cwf-manage validate` clean after the new helper is hash-tracked.
- [ ] Manual smoke on this branch: `.cwf/scripts/command-helpers/security-review-changeset --phase=testing` returns a changeset whose stderr line shows `anchor=<sha7>` matching the merge-base against trunk (since this task's `a-task-plan.md` was created before the new field — exercises the fallback path).
- [ ] `f-implementation-exec.md` and `g-testing-exec.md` Security Review sections, run on this very branch, produce changeset line-counts bounded by *this task's* delta — not inflated by Task 127/128 or any other unmerged predecessor.

## Decomposition Check
- [ ] **Time**: tests sized at ~half a day; under threshold.
- [ ] **People**: 1.
- [ ] **Complexity**: 8 functional + 5 non-functional cases in one `.t` file. Within scope for a single test.
- [ ] **Risk**: TC-NF3/NF4 (symlink/FIFO) are platform-dependent; gracefully `skip` on non-POSIX rather than fail.
- [ ] **Independence**: cases are independent subtests within one file.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
13 subtests authored (8 functional + 5 non-functional, matrix per c-design KD-6). All PASS. Full `prove t/` regression: 338/338 PASS, no regressions in existing suites. Two test-code bugs caught and fixed during authoring (TC-F7 `$w` compilation, `git_capture` `chomp` no-op under `local $/`); both were test-scaffolding issues, not helper defects.

## Lessons Learned
`local $/; <fh>; chomp` is a no-op — `chomp` operates on the current `$/`, which is `undef` inside the slurp scope. Use `s/\s+\z//` outside the `local $/` block to strip the trailing newline. Pattern worth documenting wherever capture-helpers are written.
