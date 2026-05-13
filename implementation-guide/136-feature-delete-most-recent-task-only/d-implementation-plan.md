# Delete most-recent task only - Implementation Plan
**Task**: 136 (feature)

## Task Reference
- **Task ID**: internal-136
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/136-delete-most-recent-task-only
- **Template Version**: 2.1

## Goal
Implement the `task-workflow delete` subcommand and `/cwf-delete-task` skill per the approved design (c-design-plan.md). The work is a single helper script (~250 LOC est.), a small dispatcher edit, a one-line library export, a thin skill SKILL.md, an integrity-hash registration, and a CLAUDE.md skill-list entry.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- **CREATE** `.cwf/scripts/command-helpers/task-workflow.d/delete` — the deletion engine. Implements the 9-check refusal pipeline and 6-step cleanup sequence from c-design-plan.md.
- **CREATE** `.claude/skills/cwf-delete-task/SKILL.md` — thin user-facing skill that parses `<task-path> [--force]` and shells out to the helper.

### Supporting Changes
- **EDIT** `.cwf/scripts/command-helpers/task-workflow` — add `delete => "$script_dir/task-workflow.d/delete"` to the `%commands` hash (one-line addition).
- **EDIT** `.cwf/lib/CWF/TaskPath.pm` — add `version_compare` to the `@EXPORT_OK` list (line 16-23). The function already exists; only the export declaration changes.
- **EDIT** `.cwf/security/script-hashes.json` — register the new `task-workflow.d/delete` helper with its SHA256 and permissions. Done via the standard `cwf-manage` flow; not a hand edit.
- **EDIT** `CLAUDE.md` — add `/cwf-delete-task <task-path> [--force]` to the "Available CWF Skills" section under "Core Skills" (alongside `/cwf-new-task`).

## Implementation Steps

### Step 1: Library export (enabler)
- [ ] Open `.cwf/lib/CWF/TaskPath.pm`.
- [ ] Add `version_compare` to `@EXPORT_OK` (currently lines 16-23).
- [ ] Verify the function definition at the bottom of the file is unchanged.
- [ ] Run `perl -I .cwf/lib -e 'use CWF::TaskPath qw(version_compare); print version_compare("3.1.10", "3.1.2"), "\n"'` to confirm it imports cleanly and returns `1`.

### Step 2: Helper script — skeleton + arg parsing
- [ ] Create `.cwf/scripts/command-helpers/task-workflow.d/delete` with the canonical Perl shebang (`#!/usr/bin/perl -CDSL`) and headers matching `task-workflow.d/create` style.
- [ ] `use strict; use warnings; use utf8;` plus `FindBin`, `Cwd qw(abs_path)`, `File::Path qw(remove_tree)`.
- [ ] `use CWF::Common qw(check_perl5opt);` and call `check_perl5opt()`.
- [ ] `use CWF::TaskPath qw(validate resolve_num find_siblings find_children format_dirname format_branch branch_exists version_compare);`
- [ ] Parse `@ARGV` for `<task-path>` and optional `--force`. Reject unknown flags. Print usage to STDERR and exit 1 on missing required arg.
- [ ] Resolve `$base_dir` via `find_base_dir()`; resolve `$task = resolve_num($num)`; if any fail, emit a specific error.

### Step 3: Refusal-check pipeline (checks 1-9)
- [ ] Implement each check as its own `sub check_NN { ... }` returning `(0, $error_message)` on failure or `(1, undef)` on pass.
- [ ] Order them in a `@checks = (\&check_01_args, \&check_02_resolve, …, \&check_09_stack)` array; iterate and bail on first failure.
- [ ] Check 1 (args): already covered by argv parsing — leave the sub as a no-op or fold into argv.
- [ ] Check 2 (resolve): bail with "task not found" if `$task` is undef.
- [ ] Check 3 (realpath containment): compare `abs_path($task->{full_path})` against `abs_path($base_dir)` as string prefix.
- [ ] Check 4 (most-recent): iterate `find_siblings($num)`, accumulate the highest sibling by `version_compare`. If the highest is `> $num`, bail naming that single highest sibling (don't list all higher siblings — the highest is the actionable blocker).
- [ ] Check 5 (leaf): call `find_children($num)`; bail if non-empty.
- [ ] Check 6 (branch-name format) — *hoisted from cleanup step C per plan review*: compute `$task_branch = format_branch(...)` and `$checkpoints_branch = "$task_branch-checkpoints"`. Run `system('git', 'check-ref-format', '--branch', $_)` on each. Bail with "[CWF] ERROR: branch name failed git check-ref-format: <name>" on non-zero. Cheap and prevents partial-state during cleanup.
- [ ] Check 7 (worktree): `git worktree list --porcelain` and parse `^branch refs/heads/(.+)$` lines. Bail if either the task branch or checkpoints branch is checked out in any worktree (including the current one — that's the case cleanup step A is designed to handle, but if HEAD is detached or on a *different* worktree's branch, we want to refuse cleanly).
- [ ] Check 8 (already-merged): only if `branch_exists($task_branch)`; run `system('git', 'merge-base', '--is-ancestor', "$task_branch", 'main')`. If exit is 0 (is-ancestor): bail naming the squash sha (`git rev-parse $task_branch`) and pointing to `.cwf/docs/glossary.md#archaeological-main`.
- [ ] Check 9 (unmerged work): only if `branch_exists($task_branch)`:
  - **Parse baseline SHA**: read `<task-dir>/a-task-plan.md` line by line; match `^- \*\*Baseline Commit\*\*:\s+([0-9a-f]{40})\s*$` (note the leading `- ` list marker — this is the literal format `template-copier-v2.1` writes). On no match: bail "baseline commit not recorded or malformed in a-task-plan.md; cannot determine FR6 anchor — refusing to delete". This mirrors the parsing in `.cwf/scripts/command-helpers/security-review-changeset`.
  - **Validate reachability**: `system('git', 'rev-parse', '--verify', '--quiet', "$baseline_sha^{commit}")`. On non-zero: bail "baseline commit <sha> not reachable in this repo — refusing to delete".
  - **Walk commits**: `open my $fh, '-|', 'git', 'log', '-z', '--format=%H%x00%s', "$baseline_sha..$task_branch"` (list-form, no shell). Read all output, split on `\0`, iterate by 2-element strides (sha, subject, sha, subject, …).
  - For each commit, accept if subject matches `/^Task \Q$num\E: Complete .+ phase$/`. Collect non-checkpoint subjects.
  - If non-empty and `--force` not set: bail with "task branch has <N> non-checkpoint commit(s) that would be lost: <subject list>. Re-run with --force to delete anyway." With `--force`: write the list as `[CWF] WARNING:` to STDERR and proceed.
- [ ] Check 10 (stack): read `.cwf/task-stack` (allow missing). If target dirname appears in any line except the last, bail. If it equals the last line, set `$pop_stack = 1`.

### Step 4: Cleanup sequence (steps A-E)

Branch-name validation moved to refusal check 6 (per plan review). Cleanup now has 5 steps.

- [ ] A (switch off task branch): `git rev-parse --abbrev-ref HEAD`, compare to `$task_branch`; if match, `system('git', 'checkout', '--detach', $baseline_sha)`.
- [ ] B (pop stack): if `$pop_stack`, `system('.cwf/scripts/command-helpers/task-stack', 'pop')`; on non-zero, `warn "[CWF] WARNING: task-stack pop failed; rerun to complete cleanup\n"` and `exit 2`.
- [ ] C (delete checkpoints branch): if `branch_exists($checkpoints_branch)`, `system('git', 'branch', '-D', $checkpoints_branch)`. Skips harmlessly if already gone.
- [ ] D (delete task branch): if `branch_exists($task_branch)`, `system('git', 'branch', '-D', $task_branch)`. Skips harmlessly if already gone.
- [ ] E (remove task directory): re-verify realpath containment immediately before destruction; `remove_tree($full_path, { safe => 1, error => \$err })`. On `$err`: `warn "[CWF] WARNING: failed to remove task directory: <details>; rerun to complete cleanup\n"` and `exit 2`.

### Step 5: Output formatting
- [ ] Errors written via `warn` to STDERR with `[CWF] ERROR: ` prefix (matches `cwf-checkpoint-commit`, `cwf-manage`).
- [ ] Warnings (partial state, `--force` use) via `warn` with `[CWF] WARNING: ` prefix.
- [ ] Success summary via `print` to STDOUT: `[CWF] deleted task <num> (<list of removed artefacts>)`.
- [ ] Exit codes per design CLI section: 0 success, 1 refusal, 2 partial-state.

### Step 6: Dispatcher wiring
- [ ] Edit `.cwf/scripts/command-helpers/task-workflow`. In the `%commands` hash, add `delete => "$script_dir/task-workflow.d/delete"`. Verify the dispatcher's `die "Unknown subcommand"` falls through correctly for any other value.

### Step 7: Skill SKILL.md
- [ ] Create `.claude/skills/cwf-delete-task/SKILL.md`. Frontmatter:
  ```yaml
  ---
  name: cwf-delete-task
  description: Delete the most-recent task (reverse of /cwf-new-task). Refuses non-most-recent, already-merged, or non-leaf tasks. Use --force to bypass the unmerged-work check only.
  user-invocable: true
  allowed-tools:
    - Bash
  ---
  ```
- [ ] Body: brief usage, argument parsing rules, one-line description of each refusal case, command to invoke (`.cwf/scripts/command-helpers/task-workflow delete <task-path> [--force]`), reference to `c-design-plan.md` for full design. Follow the shape of `.claude/skills/cwf-current-task/SKILL.md`.

### Step 8: Permissions and hash registration

`cwf-manage` does **not** have a "register new helper" subcommand — `script-hashes.json` is hand-edited and `cwf-manage validate` verifies it post-hoc. (Plan review caught the vague "look up the exact subcommand" wording — corrected here.)

- [ ] `chmod 0500 .cwf/scripts/command-helpers/task-workflow.d/delete`.
- [ ] Compute the SHA256: `sha256sum .cwf/scripts/command-helpers/task-workflow.d/delete | awk '{print $1}'`.
- [ ] Open `.cwf/security/script-hashes.json`. Find the entry for `task-workflow.d/create` under the `scripts` section. Add an entry directly after it with the same structure:
  ```json
  "task-workflow.d/delete" : {
    "path" : ".cwf/scripts/command-helpers/task-workflow.d/delete",
    "permissions" : "0500",
    "sha256" : "<computed-sha>"
  }
  ```
- [ ] Run `.cwf/scripts/cwf-manage validate`. **This step is mandatory** — the implementation phase is not complete until validate passes. (A missing or wrong entry will be reported here as an integrity violation.)

### Step 9: CLAUDE.md
- [ ] Edit `CLAUDE.md`. Under "Available CWF Skills → Core Skills" (around line 24-29), add a line: `- /cwf-delete-task <task-path> [--force] - Delete the most-recent task (reverse of /cwf-new-task)`.

### Step 10: Smoke test (manual, before testing phase)

Run the smoke test in a **disposable git worktree** so the live `implementation-guide/` tree and main repo branches stay untouched. This avoids the trap of "smoke test created task 999 → 999 is now the most-recent → real next task collides or fails".

- [ ] `git worktree add /tmp/cwf-delete-smoke main` and `cd` into it.
- [ ] Create a throwaway task: `/cwf-new-task <next-free-num> chore "smoke test for delete"` (or use a very high number like `9999`).
- [ ] Run `.cwf/scripts/command-helpers/task-workflow delete <num>` — expect exit 0, branch and directory removed, stack cleaned.
- [ ] Manually probe a refusal case from the live worktree (without modifying it): attempt to delete an existing not-most-recent task and confirm the FR3 message. Don't actually delete — just observe the refusal output.
- [ ] Clean up the worktree: `git worktree remove /tmp/cwf-delete-smoke`. Proceed to `/cwf-testing-plan` for the formal test plan.

Note: the cleanup sequence is idempotent. If the smoke test exits 2 (partial state), re-run the same delete command — it completes any leftover cleanup.

## Code Changes

### `.cwf/lib/CWF/TaskPath.pm` (Step 1)

**Before** (lines 16-23):
```perl
our @EXPORT_OK = qw(
    normalize validate build_glob find_base_dir get_parent get_depth
    resolve_num resolve_branch resolve_path resolve
    format_dirname parse_dirname format_branch parse_branch
    task_exists branch_exists
    find_parent find_children find_siblings find_ancestors find_descendants
    find_first_free
);
```

**After**:
```perl
our @EXPORT_OK = qw(
    normalize validate build_glob find_base_dir get_parent get_depth
    resolve_num resolve_branch resolve_path resolve
    format_dirname parse_dirname format_branch parse_branch
    task_exists branch_exists
    find_parent find_children find_siblings find_ancestors find_descendants
    find_first_free version_compare
);
```

### `.cwf/scripts/command-helpers/task-workflow` (Step 6)

**Before** (lines 10-12):
```perl
my %commands = (
    create => "$script_dir/task-workflow.d/create",
);
```

**After**:
```perl
my %commands = (
    create => "$script_dir/task-workflow.d/create",
    delete => "$script_dir/task-workflow.d/delete",
);
```

### `.cwf/scripts/command-helpers/task-workflow.d/delete` (Steps 2-5)

Pseudostructure (not actual code — the implementation phase writes the real thing):
```
shebang + use pragmas + library imports
sub usage { ... }
sub die_err { warn "[CWF] ERROR: $_[0]\n"; exit 1 }
sub warn_partial { warn "[CWF] WARNING: $_[0]\n"; exit 2 }

# argv parsing → ($num, $force)
# resolve task → $task hashref
# compute $task_branch, $checkpoints_branch, $full_path, $dirname

# refusal pipeline (10 checks, first-fail-wins)
# Order matters: cheapest first; validation that prevents partial-cleanup
# (branch-name format, worktree) before the destructive-decision checks.
for my $check (
    \&check_realpath,         # 3 — symlink-escape
    \&check_most_recent,      # 4 — FR3
    \&check_leaf,             # 5 — FR4
    \&check_branch_name_fmt,  # 6 — git check-ref-format (hoisted from cleanup)
    \&check_worktree,         # 7 — git worktree list
    \&check_already_merged,   # 8 — FR5
    \&check_unmerged_work,    # 9 — FR6 (+ baseline SHA parse/validate)
    \&check_stack,            # 10 — FR8
) {
    my ($ok, $err) = $check->(...);
    die_err($err) unless $ok;
}

# cleanup A-E (each step idempotent, partial failure → exit 2)
cleanup_switch_off_branch();
cleanup_pop_stack() if $pop_stack;
cleanup_delete_checkpoints_branch();
cleanup_delete_task_branch();
cleanup_remove_directory();

print "[CWF] deleted task $num (...)\n";
exit 0;
```

### `.claude/skills/cwf-delete-task/SKILL.md` (Step 7)

Follows the shape of `cwf-current-task/SKILL.md`: frontmatter + `## Your task` + a single sentence directing the agent to call the helper via Bash and display the output verbatim. No retry logic in the skill — the helper owns all decision-making.

## Test Coverage
**See e-testing-plan.md for complete test plan**

Key surfaces the test plan must cover:
- Every refusal check (FR3-FR8) — happy path + each refusal case.
- `--force` permits FR6 only; does not unlock FR3, FR4, FR5, FR7, FR8.
- Idempotent re-run after simulated partial-state (delete dir then re-run; delete branch then re-run).
- Stack pop only on topmost; refusal on non-topmost.
- Worktree pre-check refuses cleanly.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

In addition, before marking f-implementation-exec finished:
- [ ] `cwf-manage validate` passes (script-hashes registration is correct).
- [ ] `perl -I .cwf/lib -e 'use CWF::TaskPath qw(version_compare); ...'` smoke test passes.
- [ ] The helper is executable (`0500`) and the dispatcher routes `delete` correctly.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned file changes landed: helper, skill, dispatcher edit, TaskPath export, hash registration, CLAUDE.md entry. See f-implementation-exec.md for step-by-step actual vs planned. One implementation deviation: self-worktree exclusion logic in check 7 was added after smoke-test caught a refusal that should have been allowed.

## Lessons Learned
The plan's step ordering (helper → skill → integration) worked well — each step was independently testable. Plan did not anticipate that the smoke test would catch a real bug; in retrospect, treating smoke-test as a planned step (not a tail-end sanity check) is the right shape for destructive-CLI work.
