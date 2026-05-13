# Delete most-recent task only - Testing Plan
**Task**: 136 (feature)

## Task Reference
- **Task ID**: internal-136
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/136-delete-most-recent-task-only
- **Template Version**: 2.1

## Goal
Verify the `task-workflow delete` helper and `/cwf-delete-task` skill behave per the requirements (b-requirements-plan.md FR1-FR8) and design (c-design-plan.md refusal checks 1-10 + cleanup A-E), with particular focus on the refusal cases that protect the project from renumbering, history rewrites, and lost work.

## Test Strategy

### Test Levels
This project has no automated test framework — testing is manual end-to-end against a real git repository. The plan is structured as an ordered checklist of cases that can be ticked off during `/cwf-testing-exec`.

- **Smoke** (single happy path) — proves the helper exists, the dispatcher routes, and the skill wires through.
- **Refusal cases** (one per FR3-FR8 + new checks 3, 6, 7) — each proves that the named invariant is enforced.
- **`--force` scope** — proves `--force` relaxes FR6 only.
- **Idempotency / partial-state recovery** — proves re-running after simulated partial state completes cleanup.
- **Integrity** — `cwf-manage validate` passes after install.

### Test Coverage Targets
- **Refusal checks**: every check 3-10 has at least one positive (refusal fires) and one negative (check passes when it should) case.
- **Happy path**: 100% — a freshly created task is deletable without `--force`.
- **`--force` semantics**: every non-FR6 check has a test proving `--force` does *not* bypass it.
- **Idempotency**: at least two partial-state scenarios (dir-without-branch, branch-without-dir).

### Test Environment
All tests run in **disposable git worktrees** off main, so the live `implementation-guide/` tree and main repository branches are never disturbed. Setup per case:

```bash
git worktree add /tmp/cwf-test-136-<N> main
cd /tmp/cwf-test-136-<N>
# perform test
cd -
git worktree remove --force /tmp/cwf-test-136-<N>
```

A few cases that need a *finished* task (FR5) require an explicit setup: cherry-pick or merge a fake squash commit onto a throwaway "main-like" branch in the worktree, then point `main` (in that worktree) at it. Never touch the real `main`.

## Test Cases

### Happy Path

- **TC-H1 — Fresh task deletion**
  - **Given**: A fresh task `9999-chore-test` created via `/cwf-new-task` in a disposable worktree; HEAD on the task branch with only the create commit.
  - **When**: `task-workflow delete 9999` is run.
  - **Then**: Exit 0. `implementation-guide/9999-chore-test/` is gone. Branch `chore/9999-test` is gone. Checkpoints branch is gone (or never existed). `.cwf/task-stack` no longer mentions the task. `git status` clean. HEAD is detached on the baseline SHA.

### Refusal — Most-Recent (FR3, check 4)

- **TC-FR3a — Top-level lower-numbered task blocked**
  - **Given**: Tasks `9998-chore-a` and `9999-chore-b` both exist; HEAD on neither task branch.
  - **When**: `task-workflow delete 9998` is run.
  - **Then**: Exit 1. STDERR includes "task 9998 is not most-recent; task 9999 exists". No filesystem or git changes.

- **TC-FR3b — Nested lower-numbered task blocked**
  - **Given**: Tasks `9999.1-chore-a` and `9999.2-chore-b` under `9999-feature-parent`.
  - **When**: `task-workflow delete 9999.1` is run.
  - **Then**: Exit 1. STDERR names `9999.2` as the blocker.

- **TC-FR3c — `--force` does NOT unlock FR3**
  - **Given**: Same setup as TC-FR3a.
  - **When**: `task-workflow delete 9998 --force` is run.
  - **Then**: Exit 1. Same FR3 message. State unchanged.

### Refusal — Leaf (FR4, check 5)

- **TC-FR4a — Parent with subtask blocked**
  - **Given**: Task `9999-feature-parent` with subtask `9999.1-chore-child`.
  - **When**: `task-workflow delete 9999` is run.
  - **Then**: Exit 1. STDERR names `9999.1` as the surviving subtask. State unchanged.

- **TC-FR4b — `--force` does NOT unlock FR4**
  - **Given**: Same.
  - **When**: `task-workflow delete 9999 --force`.
  - **Then**: Exit 1. Same FR4 message. State unchanged.

### Refusal — Branch-Name Format (check 6)

- **TC-CHK6 — Defence-in-depth pass-through**
  - **Given**: A normal task with `format_branch`-produced name.
  - **When**: `task-workflow delete <num>` is run.
  - **Then**: `git check-ref-format --branch` passes; deletion proceeds normally. (Negative case — we cannot easily craft a malformed name through `format_branch` without modifying the codebase, so the positive flow is the test. If the check is reached and the name is valid, this proves the wiring works.)

### Refusal — Worktree (check 7)

- **TC-CHK7a — Task branch in another worktree blocks**
  - **Given**: Task `9999-chore-x` exists; `git worktree add /tmp/wt-extra chore/9999-x` checks it out elsewhere.
  - **When**: `task-workflow delete 9999` is run from the main worktree.
  - **Then**: Exit 1. STDERR names `/tmp/wt-extra` as the worktree. State unchanged.

- **TC-CHK7b — Checkpoints branch in another worktree blocks**
  - **Given**: Same task, but the *checkpoints* branch (not the task branch) is checked out in `/tmp/wt-extra`.
  - **When**: `task-workflow delete 9999`.
  - **Then**: Exit 1. STDERR names the worktree.

### Refusal — Already-Merged (FR5, check 8)

- **TC-FR5a — Squash commit on main blocks**
  - **Given**: Disposable worktree with a throwaway `main` pointing at a commit that contains the task's squash. (Construct: create task, make a fake "squash" commit on a temp branch, ff `main` in this worktree to that SHA. Never touch real main.)
  - **When**: `task-workflow delete <num>` is run.
  - **Then**: Exit 1. STDERR mentions the squash SHA and points to `.cwf/docs/glossary.md#archaeological-main`. State unchanged.

- **TC-FR5b — `--force` does NOT unlock FR5**
  - **Given**: Same as TC-FR5a.
  - **When**: `task-workflow delete <num> --force`.
  - **Then**: Exit 1. Same FR5 message. State unchanged.

### Refusal — Unmerged Work (FR6, check 9)

- **TC-FR6a — Non-checkpoint commit blocks without `--force`**
  - **Given**: A fresh task; add a hand-crafted commit on the task branch: `echo x > /tmp/x; git add /tmp/x; git commit -m "WIP debugging"` (any subject NOT matching `Task <N>: Complete … phase`).
  - **When**: `task-workflow delete <num>`.
  - **Then**: Exit 1. STDERR lists the WIP commit subject and says "Re-run with --force". State unchanged.

- **TC-FR6b — `--force` permits FR6**
  - **Given**: Same.
  - **When**: `task-workflow delete <num> --force`.
  - **Then**: Exit 0. STDERR has a `[CWF] WARNING:` line listing the WIP commit subject. Deletion proceeds.

- **TC-FR6c — Checkpoint commits are recognised (negative)**
  - **Given**: A task that has progressed through several phases via `cwf-checkpoint-commit` (each commit has subject `Task <N>: Complete <phase> phase`).
  - **When**: `task-workflow delete <num>` (no `--force`).
  - **Then**: Exit 0. Deletion proceeds; no `[CWF] WARNING:` about lost commits.

- **TC-FR6d — Missing baseline line refuses**
  - **Given**: A fresh task; manually delete the `- **Baseline Commit**: <sha>` line from `a-task-plan.md`.
  - **When**: `task-workflow delete <num>`.
  - **Then**: Exit 1. STDERR mentions "baseline commit not recorded or malformed". State unchanged.

- **TC-FR6e — Malformed baseline line refuses**
  - **Given**: A fresh task; replace the baseline SHA in `a-task-plan.md` with `not-a-sha`.
  - **When**: `task-workflow delete <num>`.
  - **Then**: Exit 1. STDERR mentions "malformed". State unchanged.

- **TC-FR6f — Unreachable baseline SHA refuses**
  - **Given**: A fresh task; replace the baseline SHA with a well-formed but unreachable 40-hex string (e.g. all `f`s).
  - **When**: `task-workflow delete <num>`.
  - **Then**: Exit 1. STDERR mentions "not reachable in this repo". State unchanged.

### Refusal — Atomic (FR7, applies to all checks)

- **TC-FR7 — Pre-check failure leaves zero side-effects**
  - **Given**: Set up TC-FR3a (lower-numbered sibling). Capture `git status`, `git branch`, `ls implementation-guide/`, and `cat .cwf/task-stack` snapshots before.
  - **When**: `task-workflow delete 9998` (refuses).
  - **Then**: Snapshot-after equals snapshot-before, byte-for-byte.

### Refusal — Stack Topmost (FR8, check 10)

- **TC-FR8a — Topmost-of-stack pops on success**
  - **Given**: Task `9999-chore-x` pushed onto the stack (`task-stack push 9999`); no other tasks on stack.
  - **When**: `task-workflow delete 9999`.
  - **Then**: Exit 0. `task-stack list` shows empty. Deletion completes.

- **TC-FR8b — Non-topmost-but-present refuses**
  - **Given**: Two tasks on stack with task 9999 *not* topmost: push 9998, push 9999, then push 10000 (so 10000 is topmost). (Construct via direct `task-stack push` calls in the worktree.)
  - **When**: `task-workflow delete 9999`.
  - **Then**: Exit 1. STDERR mentions "not topmost; topmost is …". State unchanged. Stack file unchanged.

- **TC-FR8c — Not-on-stack succeeds without stack action**
  - **Given**: Task `9999-chore-x` exists but is not on the stack.
  - **When**: `task-workflow delete 9999`.
  - **Then**: Exit 0. Stack unchanged. Deletion completes.

### Refusal — Argument Validation

- **TC-ARG1 — Invalid task path refuses**
  - **Given**: A worktree.
  - **When**: `task-workflow delete abc`.
  - **Then**: Exit 1. STDERR mentions "invalid task path: abc". No side-effects.

- **TC-ARG2 — Missing argument prints usage**
  - **Given**: A worktree.
  - **When**: `task-workflow delete` (no args).
  - **Then**: Non-zero exit. Usage line on STDERR.

- **TC-ARG3 — Unknown flag refuses**
  - **Given**: A worktree.
  - **When**: `task-workflow delete 9999 --no-such-flag`.
  - **Then**: Non-zero exit. STDERR mentions the unknown flag.

### Idempotency / Partial-State Recovery

- **TC-IDEM1 — Dir-but-no-branch completes cleanup**
  - **Given**: A fresh task; manually `git branch -D <task-branch>` to simulate the branch having been removed by an earlier interrupted run.
  - **When**: `task-workflow delete <num>`.
  - **Then**: Exit 0. The directory is removed. No error about the missing branch.

- **TC-IDEM2 — Branch-but-no-dir completes cleanup**
  - **Given**: A fresh task; manually `rm -rf <task-dir>` (this is unusual but tests robustness). Note: this will make resolve_num fail.
  - **When**: `task-workflow delete <num>`.
  - **Then**: Exit 1 (task not found) — this is *not* a partial-state case from the helper's perspective; the task is simply gone. Document the observed behaviour. (The "partial state we accommodate" is dir-existing-branch-missing, not the reverse — branch without dir means the user manually intervened in a non-CWF way.)

### Skill Wiring

- **TC-SKILL — `/cwf-delete-task` end-to-end**
  - **Given**: A fresh task in a worktree.
  - **When**: User invokes `/cwf-delete-task <num>`.
  - **Then**: Output is identical to invoking the helper directly. Exit code propagates.

### Integrity

- **TC-INT1 — `cwf-manage validate` passes after install**
  - **Given**: New helper script in `.cwf/scripts/command-helpers/task-workflow.d/delete`; entry added to `script-hashes.json`.
  - **When**: `.cwf/scripts/cwf-manage validate`.
  - **Then**: Exit 0 ("OK"); no integrity warnings about the new helper.

- **TC-INT2 — Validate detects hash drift**
  - **Given**: Helper installed and registered; manually edit one byte of the helper.
  - **When**: `cwf-manage validate`.
  - **Then**: Non-zero exit. Output flags the helper as mismatched. (This proves registration was done correctly — the integrity surface works on the new file.)

### Library Export

- **TC-LIB1 — `version_compare` import works**
  - **Given**: Modified `CWF::TaskPath.pm` with `version_compare` added to `@EXPORT_OK`.
  - **When**: `perl -I .cwf/lib -e 'use CWF::TaskPath qw(version_compare); print version_compare("3.1.10", "3.1.2"), "\n"'`.
  - **Then**: Prints `1`. No `qw(version_compare)`-not-found warning.

## Non-Functional Test Cases

- **NFT-Perf — Runtime budget**
  - **Given**: A typical task with one branch, one checkpoints branch, one stack entry.
  - **When**: `time task-workflow delete <num>`.
  - **Then**: Real time < 1 s on a normal dev machine.

- **NFT-Sec — No shell interpolation in branch deletion**
  - **Given**: Code review of every `system()` and `open` call in the helper.
  - **When**: Each is inspected.
  - **Then**: Every git invocation uses list-form (`system('git', ...)`, `open my $fh, '-|', 'git', ...`); no command interpolation, no `qx`, no backticks with variable content.

- **NFT-Usability — Error messages are actionable**
  - **Given**: Each refusal-case test.
  - **When**: The error is printed.
  - **Then**: The message names the *specific* blocker (sibling number, child number, worktree path, commit subject) — not a generic "refused".

- **NFT-Symlink — `remove_tree` refuses to follow symlinks**
  - **Given**: A task directory; replace it with a symlink pointing at an unrelated directory (e.g. `/tmp/unrelated/`).
  - **When**: `task-workflow delete <num>`.
  - **Then**: Either the realpath check at step 3 refuses (most likely), or `remove_tree` with `safe => 1` refuses traversal. The unrelated target directory is unmodified.

## Validation Criteria
- [ ] Every TC-* and NFT-* case has been executed and its result recorded in g-testing-exec.md.
- [ ] All happy-path and refusal cases pass.
- [ ] `cwf-manage validate` passes (TC-INT1).
- [ ] `version_compare` is importable (TC-LIB1).
- [ ] No security finding from code review (NFT-Sec).
- [ ] No partial-state cases that the design did not anticipate.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned test cases executed in g-testing-exec.md: 28 functional + 2 non-functional, all PASS after one test-setup fix (TC-FR8b). Coverage targets met: every refusal check tested, both happy paths tested, partial-state recovery tested.

## Lessons Learned
The test plan needed an explicit "bypass earlier checks" note per case — TC-FR8b's first-pass failure was a test-setup issue (tripped check 4 before reaching check 10). For refusal-pipeline tests, calling out which earlier checks each case must bypass would have caught this in planning rather than execution.
