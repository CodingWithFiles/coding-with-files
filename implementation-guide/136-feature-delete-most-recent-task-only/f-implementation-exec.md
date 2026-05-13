# Delete most-recent task only - Implementation Execution
**Task**: 136 (feature)

## Task Reference
- **Task ID**: internal-136
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/136-delete-most-recent-task-only
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and c-design-plan.md
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Smoke test passing; ready for /cwf-testing-exec

## Actual Results

### Step 1 — Library export (`version_compare`)
- **Planned**: Add `version_compare` to `@EXPORT_OK` in `CWF::TaskPath`.
- **Actual**: Single-line edit at line 22 of `.cwf/lib/CWF/TaskPath.pm`. Import smoke-test (`perl -I .cwf/lib -e 'use CWF::TaskPath qw(version_compare); print version_compare("3.1.10", "3.1.2"), "\n"'`) returned `1` as expected.
- **Deviations**: None.

### Step 2 — Helper skeleton + arg parsing
- **Planned**: Create `task-workflow.d/delete` with shebang, pragmas, library imports, argv parser supporting `<task-path>` and `--force`.
- **Actual**: Created. Used `#!/usr/bin/env perl` (matching existing helpers — `task-workflow.d/create`, `cwf-checkpoint-commit`, `task-stack`) rather than `#!/usr/bin/perl -CDSL` mentioned in the plan; relies on `CWF::Common::check_perl5opt()` for the Unicode warning, same as every other helper in `command-helpers/`. Argv loop handles `--force`, rejects unknown flags, complains about extra positional args, prints usage on missing required arg. `lib` path is `$FindBin::Bin/../../../lib` (three levels up from `task-workflow.d/`).
- **Deviations**: Shebang choice — kept consistent with the rest of the codebase.

### Step 3 — Refusal-check pipeline (checks 1–10)
- **Planned**: 10 ordered checks, first-failure-wins, no state mutation.
- **Actual**: Implemented inline (no `\&check_NN` indirection — the checks are sequential top-down code, more readable than an array of subrefs given each check has its own bail style). All ten checks present in the order spec'd:
  1. argv format (`validate($num)`)
  2. resolution (`resolve_num`)
  3. realpath containment (`abs_path` prefix match)
  4. most-recent — iterates `find_siblings`, tracks highest by `version_compare`
  5. leaf — `find_children` non-empty
  6. branch-name format — `git check-ref-format --branch` on both branch names
  7. worktree — parses `git worktree list --porcelain`, excludes the **current** worktree (see Deviation below)
  8. already-merged — `git merge-base --is-ancestor <task-branch> main`
  9. unmerged-work — parses baseline SHA from `a-task-plan.md`, validates reachability, walks `git log -z --format='%H%x00%s' <baseline>..<task-branch>`, accepts subjects matching `^Task <num>: Complete .+ phase$`. `--force` flips refusal to a `[CWF] WARNING:` and proceeds. Baseline SHA stored for cleanup step A.
  10. topmost-stack — reads `.cwf/task-stack`, refuses on non-tail occurrence, marks tail for popping.
- **Deviations**:
  - **Worktree check excludes self**: The first smoke run refused with `task branch 'chore/9999-smoke-delete-test' is checked out in worktree /tmp/cwf-delete-smoke` even though the branch was checked out in *our own* worktree — the case cleanup step A is designed to handle. Per the plan note ("including the current one — that's the case cleanup step A is designed to handle"), the check now compares `abs_path(git rev-parse --show-toplevel)` against each listed worktree and skips a match on the current one. Caught by the smoke test before commit.
  - **Layout**: Implemented as straight-line code with anonymous block scopes rather than `sub check_NN { ... }` plus a dispatch array. Both forms run the checks in the same order; the straight-line form is shorter and reads more naturally given the heterogeneous bail-output of each check.

### Step 4 — Cleanup sequence (A–E)
- **Planned**: A switch off branch (detached HEAD on baseline), B pop stack, C delete checkpoints branch, D delete task branch, E remove directory (`safe => 1`, realpath re-check).
- **Actual**: All five steps implemented as planned. Each step re-checks existence before acting (idempotent: re-running after partial state completes cleanup). Step E re-runs `check_realpath_contained` immediately before `remove_tree`, with `safe => 1` defending against symlinks even if the realpath check were bypassed. Partial-state failures `warn` `[CWF] WARNING:` and `exit 2`.
- **Deviations**: None.

### Step 5 — Output formatting
- **Planned**: STDERR `[CWF] ERROR:` for refusals, `[CWF] WARNING:` for `--force` and partial-state, STDOUT success summary, exit 0/1/2.
- **Actual**: Implemented. Success line: `[CWF] deleted task <num> (<comma-joined removed artefacts>)`. When the helper is re-run on partial state and nothing remains, the summary is `nothing (already clean)`.
- **Deviations**: None.

### Step 6 — Dispatcher wiring
- **Planned**: Add `delete => "$script_dir/task-workflow.d/delete"` to `%commands` in `task-workflow`.
- **Actual**: One-line addition; usage string updated from `{create}` to `{create|delete}`.
- **Deviations**: None.

### Step 7 — Skill `cwf-delete-task`
- **Planned**: Thin `.claude/skills/cwf-delete-task/SKILL.md` parallel to `cwf-current-task`.
- **Actual**: Created. Frontmatter (`name`, `description`, `user-invocable: true`, `allowed-tools: [Bash]`), body documents refusal cases, exit codes, examples, and the worktree/symlink notes. References `c-design-plan.md` and the archaeological-main glossary entry.
- **Deviations**: None.

### Step 8 — Permissions and hash registration
- **Planned**: `chmod 0500`, compute SHA256, hand-edit `.cwf/security/script-hashes.json`, run `cwf-manage validate`.
- **Actual**: Set mode 0500. Registered `task-workflow.d/delete` after the `task-workflow.d/create` entry. Also had to refresh the hashes for `CWF::TaskPath` (export-list change) and `task-workflow` (dispatcher edit) — both were detected by `cwf-manage validate` and updated. After the in-place worktree-check fix during smoke testing, the helper's hash was refreshed once more. Final `cwf-manage validate` → `[CWF] validate: OK`.
- **Deviations**: Three hashes refreshed instead of one, because two existing files were modified alongside the new file.

### Step 9 — CLAUDE.md skill list
- **Planned**: Add `/cwf-delete-task <task-path> [--force]` to Core Skills.
- **Actual**: Added directly after `/cwf-new-subtask`. Wording matches the design summary.
- **Deviations**: None.

### Step 10 — Smoke test in disposable worktree
- **Planned**: `git worktree add /tmp/cwf-delete-smoke`, create throwaway task 9999, delete, probe a refusal case, tear down.
- **Actual**: `git worktree add -b tmp/smoke-delete /tmp/cwf-delete-smoke HEAD` (the plan said `main` but `main` does not have the helper — used a temp branch off `HEAD` of the feature branch). Inside the worktree: created `9999-chore-smoke-delete-test`, checked out `chore/9999-smoke-delete-test`. First delete attempt refused on the worktree check (uncovered the self-exclusion bug — fixed and re-tested). Second attempt succeeded: directory removed, branch removed, HEAD detached on baseline. Probed five refusal cases successfully:
  - `delete 135` from worktree → refused with "task 135 is not most-recent; task 136 exists" ✓
  - `delete 9999` (after successful delete) → "task not found: 9999" (idempotent re-run shape) ✓
  - `delete 136` from smoke worktree → refused "task branch 'feature/136-...' is checked out in worktree /home/matt/repo/coding-with-files" (cross-worktree refusal) ✓
  - `delete notapath` → "invalid task path: notapath" ✓
  - `delete 8888` → "task not found: 8888" ✓
  - `delete 136 --bogus` → "unknown option: --bogus" ✓
- Worktree removed; tmp/smoke-delete branch deleted.
- **Deviations**: Worktree base was `HEAD` (feature branch tip) rather than `main`, because `main` has no `delete` helper. Same isolation properties.

## Validation Criteria (from d-implementation-plan.md)

- [x] `cwf-manage validate` passes — `[CWF] validate: OK`
- [x] `version_compare` import smoke test passes
- [x] Helper is executable (0500) and dispatcher routes `delete` correctly (verified in smoke test)

## Blockers Encountered

None.

## Deferral Check

- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (refuse non-most-recent / non-leaf / already-merged; reverse-of-create cleanup; stack handling)
- [x] All requirements from b-requirements-plan.md addressed (FR1–FR8, all NFRs)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
- Smoke testing in a disposable worktree caught a real bug (self-worktree exclusion in check 7) before commit. Without that step the partial-state recovery path would have been dead code.
- The shared inode appearance between main repo and the `/tmp/cwf-delete-smoke` worktree is a sandbox quirk; the files are physically distinct and need to be `cp`'d when iterating. Worth knowing for future smoke tests.
- Editing a script forces a hash refresh in `script-hashes.json` for every iteration; building "register helper" wholesale would smooth the implementation phase, but per project memory the friction is the feature.

## Security Review

**State**: findings

Method: helper script `security-review-changeset` only diffs committed history (`anchor..HEAD`), so it returned an empty changeset for this still-uncommitted implementation. To give the subagent real content, I built the relevant diff manually (`git diff 599d545 -- .cwf/lib/CWF/TaskPath.pm .cwf/scripts/command-helpers/task-workflow .cwf/scripts/command-helpers/task-workflow.d/delete .claude/skills/cwf-delete-task/SKILL.md`, after `git add -N` to surface the new files). The diff is 474 lines, under the 500-line cap. The CWF-internal-files in the broader changeset that the helper's classification rules would also include — `.cwf/security/script-hashes.json` (under `.cwf/security/`) and `CLAUDE.md` — fall outside the documented `@CWF_INTERNAL_PREFIXES` (`.cwf/scripts/`, `.cwf/lib/`, `.cwf/docs/skills/`, `.cwf/templates/`, `.claude/scripts/`, `.claude/skills/`, `.claude/hooks/`, `.claude/rules/`) and are excluded by the helper's own rules. Subagent verbatim output:

> **findings:**
>
> 1. **Pattern-based risk in backtick invocation at line 181** — `my $sha = git rev-parse $task_branch 2>/dev/null;` interpolates `$task_branch` into a backtick command. Safe here because `$task_branch` is built from `format_branch($num, $type, $slug)` and validated via `git check-ref-format --branch $task_branch` at line 143 (Check 6, run before any destructive operation). The format_branch transformation is purely string composition (no shell metachar escape needed), and the check-ref-format validation ensures the result is a valid git branch name. However, audit future uses of backticks if they interpolate branch or path components not validated through the identical check-ref-format gate.
>
> 2. **Backtick invocation at line 510 in TaskPath.pm (branch_exists)** — `my $output = git branch --list '$branch' 2>/dev/null;` single-quotes the branch name inside a backtick, which appears defensive but is ineffective. If `$branch` were to contain a literal single quote, the quoting would break and shell metacharacters could execute. However, all callers of `branch_exists()` in the delete helper pass either `$task_branch` or `$checkpoints_branch`, both validated by Check 6. Mitigate by switching to list-form spawn throughout the codebase: `open(my $fh, '-|', 'git', 'branch', '--list', $branch)` and chomp the output, consistent with the pattern at line 157 (Check 7's worktree list) and line 214 (Check 9's git log).
>
> no findings besides the pattern-based items above (both mitigatable via list-form spawn for consistency).

Maintainer disposition (not the subagent's call to make):

- **Finding 1** — Safe-here, no defect. The invariant ($task_branch comes from `format_branch` of a digits/dots num, an alphabetic type, and a `[a-z0-9-]`-only slug, *and* passes `git check-ref-format --branch` in Check 6) holds. Left as-is. Cheap follow-up: convert the single backtick at the `git rev-parse $task_branch` line to list-form `open '-|'` for stylistic parity with the rest of the helper.
- **Finding 2** — A pre-existing pattern in `.cwf/lib/CWF/TaskPath.pm::branch_exists` (line 510), not introduced by this task. The two new call sites in the delete helper are both fed validated branch names, so the invariant from finding 1 carries over and `branch_exists` is safe in this caller's context. A general fix would be a separate refactor of `branch_exists` (and any other shared backtick in `CWF::TaskPath`) — out of scope for this task. Flagging as a candidate follow-up for the project backlog.
