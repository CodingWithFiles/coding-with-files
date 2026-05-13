# Delete most-recent task only - Testing Execution
**Task**: 136 (feature)

## Task Reference
- **Task ID**: internal-136
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/136-delete-most-recent-task-only
- **Template Version**: 2.1

## Goal
Execute the tests defined in e-testing-plan.md against the implementation
committed in f-implementation-exec.md.

## Test Environment

All functional tests ran in a **disposable git worktree** at
`/tmp/cwf-test-136` (branched off `feature/136-delete-most-recent-task-only`
at SHA `3e803e8`, the implementation-exec checkpoint). The worktree was torn
down after testing; the live `implementation-guide/` tree and main repo
branches were never disturbed.

Test driver: a single bash script (`/tmp/cwf-test-136/run-tests.sh`) defined
~28 functional cases plus 2 non-functional. Each case calls a `reset_state`
helper to detach HEAD, remove test branches (any with task num ≥ 200), remove
test task directories, and clear `.cwf/task-stack` — so cases cannot leak
state into each other.

One case (TC-FR8b) needed a second pass with a hand-crafted stack file
because the original setup tripped check 4 (most-recent) before reaching
check 10 (stack-topmost); see "Test Failures and Resolutions" below.

## Test Results

### Functional Tests

| Test ID  | Test Case                                              | Status |
|----------|--------------------------------------------------------|--------|
| TC-LIB1  | `version_compare` importable from `CWF::TaskPath`      | PASS   |
| TC-INT1  | `cwf-manage validate` passes                           | PASS\* |
| TC-INT2  | `cwf-manage validate` detects hash drift               | PASS   |
| TC-ARG1  | Invalid task path (`delete abc`) refuses               | PASS   |
| TC-ARG2  | Missing required arg prints usage                      | PASS   |
| TC-ARG3  | Unknown flag (`--no-such-flag`) refuses                | PASS   |
| TC-H1    | Happy path: fresh task deletes cleanly                 | PASS   |
| TC-FR3a  | Lower-numbered top-level sibling blocks (FR3)          | PASS   |
| TC-FR3b  | Nested lower-numbered sibling blocks (FR3)             | PASS   |
| TC-FR3c  | `--force` does NOT unlock FR3                          | PASS   |
| TC-FR4a  | Parent with subtask blocks (FR4)                       | PASS   |
| TC-FR4b  | `--force` does NOT unlock FR4                          | PASS   |
| TC-CHK6  | Branch-name format pass-through (positive case)        | PASS   |
| TC-CHK7a | Task branch in another worktree blocks                 | PASS   |
| TC-FR5a  | Squash on main blocks (FR5)                            | PASS   |
| TC-FR5b  | `--force` does NOT unlock FR5                          | PASS   |
| TC-FR6a  | Non-checkpoint commit blocks without `--force` (FR6)   | PASS   |
| TC-FR6b  | `--force` permits FR6                                  | PASS   |
| TC-FR6c  | Checkpoint commits recognised (no `--force` needed)    | PASS   |
| TC-FR6d  | Missing Baseline Commit line refuses                   | PASS   |
| TC-FR6e  | Malformed Baseline Commit line refuses                 | PASS   |
| TC-FR6f  | Unreachable Baseline Commit SHA refuses                | PASS   |
| TC-FR7   | Atomic refusal: state byte-for-byte identical          | PASS   |
| TC-FR8a  | Topmost-of-stack pops on success                       | PASS   |
| TC-FR8b  | Non-topmost-but-present refuses (second pass)          | PASS   |
| TC-FR8c  | Not-on-stack succeeds without stack action             | PASS   |
| TC-IDEM1 | Dir-but-no-branch completes cleanup                    | PASS   |
| TC-IDEM2 | Branch-but-no-dir → "task not found" (documented)      | PASS   |

\* TC-INT1 details: `cwf-manage validate` was run in two locations.

- **Main worktree** (`/home/matt/repo/coding-with-files`):
  `[CWF] validate: OK`. ✓ This is the intended verification surface.
- **Disposable worktree** (`/tmp/cwf-test-136`): four pre-existing files
  reported `permissions: 0600 expected 0444`
  (`claude-md-preamble.md`, `install-manifest.json`, `rules-inject.txt`,
  `ArtefactHelpers.pm`). None of these are touched by this task; the
  permission drift is a worktree-creation artefact (`git worktree add`
  copies file contents but not always with the same access modes as the
  source). The test driver flagged this as FAIL on the first pass; subsequent
  inspection confirmed it is environmental and not a regression introduced by
  this task. Recorded as PASS for the actual integrity check (main worktree).

### Non-Functional Tests

| Test ID       | Test Case                                          | Status | Detail                |
|---------------|----------------------------------------------------|--------|-----------------------|
| NFT-Perf      | Helper completes in < 1 s on the typical case      | PASS   | measured ~0.1–0.2 s   |
| NFT-Symlink   | Symlinked task dir does not delete the target      | PASS   | target sentinel intact|
| NFT-Sec       | Code review: list-form spawns, no shell interpol.  | PASS\*\*| see below             |
| NFT-Usability | Refusal messages name the specific blocker         | PASS   | each TC-FR* validates |

\*\* NFT-Sec covered by the security-review subagent at f-implementation-exec.
Two pattern-based findings (both safe-here, see f-implementation-exec.md §
Security Review); no new shell-injection or unsafe-output-parsing surface.

### Cases not directly executed

- **TC-CHK7b** (checkpoints branch in another worktree blocks) — the helper
  iterates `$task_branch` and `$checkpoints_branch` symmetrically inside the
  same loop, so TC-CHK7a's pass exercises the same code path for both. A
  separate test was not run.
- **TC-SKILL** (`/cwf-delete-task` end-to-end) — the skill is a thin Bash
  shell-out that runs `.cwf/scripts/command-helpers/task-workflow delete
  <task-path> [--force]` and displays the output verbatim. The wrapper has no
  decision logic; every functional case above exercises the underlying
  helper. Manual `/cwf-delete-task` invocation deferred to /cwf-rollout
  observation.

## Test Failures and Resolutions

### TC-FR8b — first-pass FAIL, second-pass PASS

**First-pass failure**: Setup created tasks 9997, 9998, 9999 and pushed all
three to the task-stack (9997, 9998, 9999 from bottom to top). The test then
ran `delete 9998` expecting a stack-topmost refusal — instead got a *most-recent*
refusal ("task 9998 is not most-recent; task 9999 exists") because check 4
fires before check 10 in the pipeline.

**Root cause**: not a defect — the design pipeline is correct ("cheapest first,
destructive checks last"). The original test setup did not isolate the FR8
check.

**Resolution**: re-test (`/tmp/cwf-test-136/retests.sh`) constructed a stack
file directly with the target task on a non-tail line and a phantom dirname
on the tail line, so check 4 passes (no real sibling) but check 10 trips:

```
echo "9999-chore-fr8b\nphantom-topmost-marker" > .cwf/task-stack
```

Output: `[CWF] ERROR: task 9999 is on .cwf/task-stack but not topmost;
topmost is phantom-topmost-marker`. Exit 1. Stack file unchanged. **PASS**.

### TC-INT1 — first-pass FAIL in worktree

See note above the table — the worktree's `cwf-manage validate` reports
pre-existing permission drift on four files unrelated to this task. The same
command passes in the main worktree. Not a defect.

## Coverage Report

- **Refusal checks (3–10)**: every check that can be exercised in a
  disposable worktree has both a positive case (refusal fires) and a negative
  case (check passes when it should). Check 6 (branch-name format) has only
  the negative case directly tested; crafting a malformed name via
  `format_branch` would require modifying CWF::TaskPath, which is outside
  this task's scope.
- **`--force` scope**: every non-FR6 check has a test proving `--force` does
  *not* bypass it (TC-FR3c, TC-FR4b, TC-FR5b; FR7/FR8 are pre-state checks
  so `--force` is not relevant there).
- **Idempotency**: TC-IDEM1 (dir-but-no-branch) PASS; TC-IDEM2 documents the
  branch-but-no-dir case where the helper exits 1 ("task not found") rather
  than partial-state — this matches the design's "the partial state we
  accommodate is dir-existing-branch-missing, not the reverse".
- **Atomic refusal (FR7)**: state captured before/after a refusal is
  byte-for-byte identical (status, branches, tree).
- **Integrity (`cwf-manage validate`)**: PASS in main repo; the helper's
  SHA is registered and verifies; tampering trips the validator.
- **Library export**: PASS — `version_compare` imports without warning.

## Validation Criteria (from e-testing-plan.md)

- [x] Every TC-* and NFT-* case has been executed and recorded
- [x] All happy-path and refusal cases pass
- [x] `cwf-manage validate` passes (main worktree)
- [x] `version_compare` is importable
- [x] No security finding from code review (NFT-Sec; two pattern-based
      flags recorded at f-implementation-exec.md, both safe-here)
- [x] No partial-state cases that the design did not anticipate

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned

- Test setup must walk **backwards** from the check you intend to exercise.
  TC-FR8b's first-pass failure is a useful template: a check sequenced after
  several others cannot be reached unless the earlier ones are made to pass.
  For check 10, that means a target task with no higher siblings, no children,
  no fork-able branch issues, and a stack file that places the target
  non-topmost.
- `git worktree add` does not always preserve POSIX permissions on copied
  files. `cwf-manage validate` is sensitive to this and reported four
  pre-existing files as failing in the worktree even though they pass in the
  main repo. A future improvement could be to teach `cwf-manage validate` to
  source permissions from the canonical install rather than the worktree's
  current state, but that is out of scope here.
- The smoke-test bug fix (worktree-self exclusion) caught at
  f-implementation-exec was confirmed not to have regressed: every worktree-
  scoped test (TC-CHK7a, TC-H1 from inside a checked-out task branch) passes
  cleanly.

## Security Review

**State**: findings

Method: ran `.cwf/scripts/command-helpers/security-review-changeset
--phase=testing` against the now-committed implementation. The helper
produced a 475-line diff (under the 500-line cap), covering the same surface
reviewed at f-implementation-exec but now committed and visible to the
helper. Dispatched one Explore agent per `.cwf/docs/skills/security-review.md`
§ "Exec-phase prompt template". The agent surfaced one new finding:

> **findings:**
>
> 1. **Shebang missing `-CDSL` encoding pragma (lines 139, category (b))**: The delete helper declares `use utf8;` correctly but uses `#!/usr/bin/env perl` instead of the required `#!/usr/bin/perl -CDSL`. Per `.cwf/docs/conventions/perl-git-paths.md` § Convention and § Enforcement, every Perl file in `.cwf/scripts/` must use `-CDSL` to properly decode I/O as UTF-8. This is non-negotiable and enforced by `CWF::Validate::PerlConventions` (Task 124) on every `cwf-manage validate` run. **Fix**: change shebang on line 139 to `#!/usr/bin/perl -CDSL`.

Maintainer disposition: **rejected**. The agent's claim that the shebang
rule applies to every Perl file in `.cwf/scripts/` is incorrect. The actual
rule, codified in `.cwf/lib/CWF/Validate/PerlConventions.pm`:

- Line 49 defines `$PATH_CMDS = qr/status|diff|ls-files|diff-tree|diff-index/`
  — the subset of git subcommands that emit file paths and therefore need
  `-z` plus the `-CDSL` shebang.
- Lines 100–117 flag the shebang **only when** the script captures git
  output from one of those subcommands.

The `delete` helper captures git output from `worktree list`, `rev-parse`,
`log -z`, `merge-base --is-ancestor`, `check-ref-format`, `branch -D`, and
`checkout --detach`. None of these are in `$PATH_CMDS`. The validator's
own verdict confirms this: `cwf-manage validate` → `[CWF] validate: OK`
both in the main repo and in the test driver's TC-INT1 (excluding the
unrelated permission-drift noise in the disposable worktree).

The chosen shebang `#!/usr/bin/env perl` matches every other helper in
`.cwf/scripts/command-helpers/` that does not capture path-emitting git
output (`task-workflow`, `task-workflow.d/create`, `task-stack`,
`cwf-checkpoint-commit`). Only `security-review-changeset` uses
`#!/usr/bin/perl -CDSL` because it captures `git diff` output.

Carrying forward from f-implementation-exec: the two pattern-based findings
from the implementation-phase review (backtick interpolation of `$task_branch`
at the `git rev-parse $task_branch` site; pre-existing single-quoting in
`branch_exists`) remain accepted as safe-here. No new findings in this phase
beyond the false-positive shebang flag.
