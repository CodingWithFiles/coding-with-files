# Delete most-recent task only - Design
**Task**: 136 (feature)

## Task Reference
- **Task ID**: internal-136
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/136-delete-most-recent-task-only
- **Template Version**: 2.1

## Goal
Design the `task-workflow delete` subcommand and the `/cwf-delete-task` skill that wraps it: an ordered refusal-check pipeline followed by a reverse-of-create cleanup, sharing all hierarchy/branch primitives with the existing create direction.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice
- **Decision**: Add a `delete` subcommand to the existing `task-workflow` dispatcher, implemented as `.cwf/scripts/command-helpers/task-workflow.d/delete` in Perl. Wrap it in a thin `/cwf-delete-task` skill.
- **Rationale**: The create direction already uses exactly this layout (`task-workflow.d/create`). Putting delete next to it gives a single canonical entry point for create/delete and re-uses the dispatcher's argument-passthrough behaviour. A new top-level helper would add naming surface area for no benefit.
- **Trade-offs**: All deletion logic lives in a single executable, which is appropriate given the helper is small. If checks proliferate, an internal module split (e.g. `CWF::TaskDelete::Checks`) could follow — premature now.

### Wf-checkpoint commit detection
- **Decision**: Identify a commit as a "wf-phase checkpoint" by matching its subject against `^Task <num>: Complete <phase> phase$`. The phase-name transformation is identical to `cwf-checkpoint-commit:48` (strip phase letter, strip `.md`, hyphens-to-spaces) — reuse that transformation rather than re-encoding the ten phase names. `<num>` is the target task number.
- **Rationale**: The script already writes a canonical subject for every checkpoint commit. Matching on it avoids inventing a new schema (trailer, note, tag) and stays consistent with how the rest of the system inspects checkpoint history. Reusing the phase-name transformation prevents drift if phase names ever change.
- **Trade-offs**: A user could hand-craft a commit with a matching subject and bypass the FR6 unmerged-work guard. We accept this — `--force` is already the documented escape hatch; a user actively impersonating CWF's commit subject is opting out of the safety net.

### Baseline anchor for FR6 unmerged-work detection
- **Decision**: Read the **Baseline Commit** SHA from the task's `a-task-plan.md` (recorded at create time by `template-copier-v2.1`) and use it as the `git log <baseline>..<task-branch-tip>` anchor for FR6. Do not assume `main`.
- **Rationale**: Each task already records the exact commit SHA it was branched from. Using that SHA is precise regardless of whether main has since moved or the user uses a non-`main` default branch. Anchoring on `main` would mis-classify commits that happen to be on main but were never on the task branch.
- **Trade-offs**: If `a-task-plan.md` is missing or unreadable, FR6 cannot run cleanly — fall back to refusing with a specific error ("baseline commit not found"). Acceptable because a missing baseline means the task is malformed and shouldn't be deleted blindly.

### Default-branch handling for cleanup step A
- **Decision**: When switching off the task branch (cleanup step A), check out the branch recorded as the originating branch for the task. If that isn't recorded anywhere (current `a-task-plan.md` only stores a SHA, not a branch name), check out the baseline commit by SHA in detached-HEAD state. The user can re-attach to whichever branch they want afterwards.
- **Rationale**: Avoids hardcoding `main`. Detached HEAD on the baseline SHA is safe and idempotent.

### Stack-membership check
- **Decision**: Read `.cwf/task-stack` once into a list of dirnames. The target task's dirname (from `format_dirname`) must either be absent entirely *or* be the last line. Any non-tail occurrence is a refusal.
- **Rationale**: The stack stores dirnames, not task numbers (per `task-stack:34-41`), so we compare on dirname. "Topmost-or-absent" is exactly the FR8 semantics with no extra invariants.
- **Trade-offs**: We do not lock the stack file during the *check* (we only lock during the pop, via `task-stack pop`). A concurrent `task-stack push` between check and pop could in principle leave the target no longer topmost. This is a theoretical race in an inherently interactive tool; the pop step will fail gracefully if the stack no longer matches expectations. We do not engineer around it further.

### Force-flag scope
- **Decision**: `--force` relaxes FR6 (unmerged work) only. FR3 (most-recent), FR4 (leaf), FR5 (already-merged), FR7 (atomic refusal), and FR8 (stack-topmost) are not affected by `--force`.
- **Rationale**: Each non-FR6 check defends an invariant the user cannot intend to violate (no renumbering, no history rewrite, no stack corruption). Bundling them under a single force flag would invite "just force it" muscle-memory.

### What we deliberately don't do
- No BACKLOG.md / CHANGELOG.md edits. Those are project history; deletion only applies to tasks that were never finished.
- No main-branch operations. Even with `--force`, main is untouched.
- No reflog cleanup. Orphaned commits remain reachable via reflog for the user's recovery convenience.
- No renumbering of any other task. The whole point.

## System Design

### Component Overview

- **`task-workflow.d/delete`** (Perl helper, ~200 LOC est.): the deletion engine. Owns:
  - Argument parsing (`<task-path>` + optional `--force`)
  - Ordered refusal-check pipeline (eight checks, in fixed order)
  - Cleanup sequence (six steps, only after all checks pass)
  - Output: success summary or specific refusal message
- **`task-workflow`** (existing dispatcher): updated to add `delete` to its commands hash, alongside `create`.
- **`/cwf-delete-task`** (skill, SKILL.md only, parallel to `/cwf-current-task`): thin wrapper. Parses user arguments, calls `task-workflow delete <task-path> [--force]`, displays output.
- **Glossary**: `archaeological main` entry (already added during requirements refinement) — supports FR5's refusal message.
- **Reused (most unchanged, one small change)**:
  - `CWF::TaskPath::{validate, resolve_num, find_siblings, find_children, format_dirname, format_branch, branch_exists}` — used as-is.
  - `CWF::TaskPath::version_compare` — currently defined but **not exported**. Add it to `@EXPORT_OK` (line 16-23 of TaskPath.pm) so the delete helper can import it. Trivial change; the function itself is unmodified.
  - Phase-name transformation from `cwf-checkpoint-commit:48` — extract into a small shared sub if needed by both scripts, or duplicate the one-line transformation (it's three regex substitutions; duplication is acceptable per the Rule of Three).
  - `task-stack` helper (subprocess for `pop`, direct file read for membership check).
  - `cwf-manage validate` (run by the existing checkpoint-commit pattern; not invoked by delete itself).

### Refusal-Check Pipeline

Each check is gate-only: fails with a specific error and exit 1; no filesystem or git side-effects until every check passes. The first failing check wins — subsequent checks do not run. All error messages are written to STDERR via `warn` (codebase convention; matches `cwf-checkpoint-commit`, `cwf-manage`, `backlog-manager`).

Checks run in this fixed order (revised during implementation planning: branch-name validation hoisted from cleanup-C to refusal phase so a malformed name cannot cause partial-state cleanup):

1. **Argument validation** — `CWF::TaskPath::validate($num)` must succeed. Fail: "invalid task path: <input>".
2. **Resolution** — `resolve_num($num)` must return a task hashref. Fail: "task not found: <num>".
3. **Realpath containment** — `abs_path($task->{full_path})` must be a string-prefix of `abs_path($base_dir)`. Guards against a symlinked task directory pointing outside `implementation-guide/`. Fail: "task directory resolves outside implementation-guide: <real-path>".
4. **Most-recent (FR3)** — For each sibling returned by `find_siblings($num)`, if `version_compare($sibling->{num}, $num) > 0` track it; report the *highest* one as the blocker. Fail: "task <num> is not most-recent; task <higher-sibling> exists".
5. **Leaf (FR4)** — `find_children($num)` must be empty. Fail: "task <num> has surviving subtasks: <list>".
6. **Branch-name format (defence-in-depth)** — `git check-ref-format --branch <task-branch>` and `… <checkpoints-branch>` must both succeed. Hoisted from cleanup so a malformed name cannot cause partial-state cleanup. Fail: "branch name failed git check-ref-format: <name>".
7. **Worktree** — `git worktree list --porcelain` must not list the task branch or its checkpoints branch. Fail: "task branch is checked out in worktree <path>; remove the worktree before deleting". Run during the refusal phase (not cleanup) so partial-state during cleanup is impossible.
8. **Already-merged (FR5)** — If `branch_exists($task_branch)`, then `git merge-base --is-ancestor <task-branch-tip> main` must exit non-zero. Fail: "task already merged to main (squash commit <sha>); archaeological main is immutable — see .cwf/docs/glossary.md#archaeological-main".
9. **Unmerged work (FR6)** — If `branch_exists($task_branch)`:
   - Read the baseline SHA from `a-task-plan.md`. Match the literal format written by `template-copier-v2.1`: `^- \*\*Baseline Commit\*\*:\s+([0-9a-f]{40})\s*$` (note the leading `- ` list marker). On no match: fail "baseline commit not recorded or malformed in a-task-plan.md; cannot determine FR6 anchor — refusing to delete".
   - Validate reachability: `git rev-parse --verify --quiet <sha>^{commit}` must exit 0. On failure: "baseline commit <sha> not reachable in this repo — refusing to delete".
   - Walk commits with `git log -z --format='%H%x00%s' <baseline-sha>..<task-branch-tip>` (NUL-separated for parsing robustness). Output is a flat NUL-separated stream of alternating `sha`, `subject`, `sha`, `subject`, …; split on `\0` and iterate by 2-element strides.
   - For each commit, accept if subject matches `/^Task \Q$num\E: Complete .+ phase$/`. Reject (collect subject for the error message) otherwise.
   - If any non-checkpoint commits exist and `--force` is not set: fail with "task branch has <N> non-checkpoint commit(s) that would be lost: <subject list>. Re-run with --force to delete anyway."
   - With `--force`: print the same list to STDERR as a warning and proceed. Note: `--force` is consumed by this check only and does not survive into cleanup.
10. **Topmost-stack (FR8)** — Read `.cwf/task-stack`. If the target dirname appears in any line *except the last*, fail: "task <num> is on .cwf/task-stack but not topmost; topmost is <other>". If it appears as the last line, mark for popping in cleanup step B. If it does not appear, no stack action.

### Cleanup Sequence

Runs only after all ten refusal checks pass. Each step re-checks existence before acting, so a re-run after partial state from a prior aborted run completes the cleanup without error. Any partial-state failure mid-cleanup writes a `[CWF] WARNING:` message to STDERR and exits 2; the user re-runs to complete cleanup.

A. **Switch off task branch** — If `git rev-parse --abbrev-ref HEAD` equals the task branch, `git checkout --detach <baseline-sha>` (baseline from `a-task-plan.md`). Detached HEAD on the recorded baseline avoids hardcoding `main`. Required because git refuses to delete the currently-checked-out branch.

B. **Pop stack** — If check 10 marked for popping: `system('.cwf/scripts/command-helpers/task-stack', 'pop')`. Uses flock per existing helper. If `pop` exits non-zero, treat as partial state (exit 2) — the branch and directory have not yet been touched, so re-running succeeds.

C. **Delete checkpoints branch** — If `branch_exists("$task_branch-checkpoints")`: `git branch -D "$task_branch-checkpoints"`.

D. **Delete task branch** — If `branch_exists($task_branch)`: `git branch -D $task_branch`. (Skips harmlessly if the branch was already manually deleted.)

E. **Remove task directory** — Re-verify realpath containment (a final defence-in-depth check immediately before destruction, since git operations in steps A-D can in principle race with filesystem state in pathological setups). Then `File::Path::remove_tree($task->{full_path}, { safe => 1, error => \$err })`. `safe => 1` refuses to follow symlinks — combined with the realpath checks at step 3 and here, gives belt-and-braces protection. On `$err`, exit 2 with the partial-state warning.

**Note on TOCTOU**: An attacker with write access to `.cwf/` between step 3 (or the step F re-check) and the `remove_tree` call could in theory replace the task directory with a symlink. `safe => 1` defangs this even if the realpath check is bypassed: `remove_tree` refuses to traverse symlinks. We accept any residual race as an inherent limitation of an interactive tool — anyone with write access to `.cwf/` already has full repository access.

**Note on FR5 main-immutability**: FR5 checks at refusal time that the task branch is not yet on main. It cannot defend against main being mutated by another process between the check and the deletion. We trust main not to be rewritten during a delete operation. Any future "main immutability" feature (e.g. a hook refusing pushes that drop commits) lives outside this command's responsibility.

### Data Flow

```
/cwf-delete-task 136 [--force]
  └─ Bash: .cwf/scripts/command-helpers/task-workflow delete 136 [--force]
      └─ task-workflow.d/delete
          ├─ Refusal pipeline (10 checks, ordered, first-failure-wins)
          │    │  any fail
          │    └─→ warn "[CWF] ERROR: <reason>", exit 1
          └─ Cleanup (5 steps, A–E)
               │  any fail mid-cleanup
               ├─→ warn "[CWF] WARNING: partial-state <details>", exit 2
               └─→ print "[CWF] deleted task 136 (branch, checkpoints-branch, stack entry, directory)", exit 0
```

## Interface Design

### CLI

```
task-workflow delete <task-path> [--force]

Arguments:
  <task-path>    Hierarchical task number (e.g., "136", "48.1")

Options:
  --force        Permit deletion when the task branch has non-checkpoint
                 commits. Does NOT override other refusal checks.

Exit codes:
  0  Deleted successfully
  1  Refusal check failed (specific reason in error message on STDERR)
  2  Cleanup hit a partial state; re-run to complete (state inspection
     output on STDERR)
```

### Skill: `/cwf-delete-task`

```yaml
---
name: cwf-delete-task
description: Delete the most-recent task (reverse of /cwf-new-task). Refuses non-most-recent, already-merged, or non-leaf tasks.
user-invocable: true
allowed-tools:
  - Bash
---
```

Parses `<task-path> [--force]`, calls the helper, prints its output verbatim. No retry, no fallback.

### Data Models

Reused unchanged from `CWF::TaskPath`. No new schema.

## Constraints
- POSIX-only, Perl core modules only (per project conventions).
- Must use `git ls-files`-style invocations (no `find` / `sed` in helper scripts per project memory).
- Stack manipulation routes exclusively through `task-stack` helper.
- The new helper script is registered in `.cwf/security/script-hashes.json` (handled by the same workflow the create helper went through).

## Decomposition Check
- [ ] **Time**: >1 week? No — ~200 LOC helper + thin skill, 1-2 days.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — refusal pipeline + cleanup are tightly coupled around a single invariant.
- [ ] **Risk**: High-risk components needing isolation? No — risk lives in the refusal checks, which is the feature.
- [ ] **Independence**: Parts separable? No.

No decomposition warranted.

## Validation
- [ ] Refusal-check ordering reviewed (cheapest first, destructive checks last)
- [ ] All FR3-FR8 acceptance criteria map to a check or check pair
- [ ] No code path mutates state before all checks pass
- [ ] All existing primitives (`CWF::TaskPath::*`, `task-stack`) reused rather than reimplemented

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
10-check refusal pipeline and 5-step idempotent cleanup A–E implemented as designed. One design adjustment during implementation: check 6 (branch-name format) was hoisted from inside cleanup A to its own pre-cleanup check, so that a malformed branch name cannot cause partial-state. No other design changes.

## Lessons Learned
Anything that could refuse must refuse before any cleanup step mutates state. The original design placed check 6 inside cleanup; moving it earlier was a one-line change with a meaningful contract improvement. Future refusal-pipeline designs should explicitly classify each check as "pre-cleanup gate" vs "cleanup-internal" — preferring the former whenever feasible.
