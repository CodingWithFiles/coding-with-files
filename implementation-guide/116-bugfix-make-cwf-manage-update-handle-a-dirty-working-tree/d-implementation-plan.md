# Make cwf-manage update handle a dirty working tree - Implementation Plan
**Task**: 116 (bugfix)

## Task Reference
- **Task ID**: internal-116
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/116-make-cwf-manage-update-handle-a-dirty-working-tree
- **Template Version**: 2.1

## Goal
Implement the dirty-working-tree pre-check in `cwf-manage update` per c-design-plan.md: a small `check_clean_tree($git_root, @paths)` helper, called from `cmd_update` after `resolve_source` and before `tempdir`/`git clone`. Recipe lives at the call site; helper is terse.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `.cwf/scripts/cwf-manage` — add `check_clean_tree` helper (~20 lines), one call site in `cmd_update`, recipe-emitting wrapper at the call site, header-comment update, `cmd_help` heredoc update.

### Supporting Changes
- `.cwf/security/script-hashes.json` — update `cwf-manage` `sha256` after edits. **Mandatory checklist item per Task 115's retrospective recommendation** ("any task touching `.cwf/scripts/` needs this").
- `t/cwf-manage-check-clean-tree.t` — new test file. Five subtests (TC-1..TC-5) covering clean / dirty-tracked / dirty-untracked / cap-overflow / git-status-fail.

## Implementation Steps

### Step 1: Setup
- [ ] Confirm on `bugfix/116-make-cwf-manage-update-handle-a-dirty-working-tree` branch with clean working tree. (Untracked workflow templates from `/cwf-new-task` scaffold are expected.)
- [ ] Re-read c-design-plan.md Decisions 1–8 before writing code.

### Step 2: Test first (TDD)
- [ ] Create `t/cwf-manage-check-clean-tree.t` mirroring `t/cwf-manage-resolve-source.t` (Task 115). Use:
  - `use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');` — required for `do $SCRIPT` to load `CWF::Common`.
  - `do $SCRIPT` with `local @ARGV = ('help');` and STDOUT silenced (same prologue as Task 115's test, lines 21–35).
  - `*main::die_msg` symbol-table override under `no warnings 'redefine', 'once';` — used here to catch the helper's `die_msg` calls.
  - **Per-subtest fixture**: each subtest creates its own `tempdir(CLEANUP => 1)`, runs `git init -q`, populates `.cwf/version`, then `git add` + `git commit` to establish a baseline. Subtests then introduce dirtiness as needed and call `main::check_clean_tree($tmpdir)`.
- [ ] Subtests (3 total, after `/simplify` reduction):
  - **TC-1** (clean tree): no modifications → call returns without dying.
  - **TC-2** (dirty: tracked + untracked combined): modify `.cwf/version` AND create new `.cwf/notes.md` → dies; `$@` contains `qr{Working tree has uncommitted changes}` AND mentions both `\.cwf/version` and `notes\.md`. Combines what was previously TC-2/TC-3 — same contract, one fixture, one assertion block.
  - **TC-3** (git status fails): call `main::check_clean_tree('/nonexistent/path')` → dies with `qr{Failed to check working tree status}`. Verifies the `$?` exit-code defensive branch from c-design Decision 7.
- [ ] Run `prove t/cwf-manage-check-clean-tree.t` — expect **all subtests fail at undefined-subroutine** (`Undefined subroutine &main::check_clean_tree`). This is the red state.

### Step 3: Add the `check_clean_tree` helper
- [ ] Insert after `sub resolve_source { ... }` (added in Task 115). The helper goes in its own `# --- Working-tree safety ---` block.
- [ ] List-form `open '-|', ...` for git invocation — consistent with the rest of `cwf-manage` (`system("git", "-C", ...)` at lines 224/232/271/277/282).
- [ ] Implementation skeleton:
  ```perl
  # --- Working-tree safety -----------------------------------------------------

  sub check_clean_tree {
      my ($git_root) = @_;

      open(my $fh, '-|', 'git', '-C', $git_root,
           'status', '--porcelain', '-z', '--untracked-files=all',
           '--', '.cwf', '.cwf-skills')
          or die_msg("Failed to spawn git status: $!");
      local $/;
      my $output = <$fh> // '';
      close $fh;
      die_msg("Failed to check working tree status (git status exited non-zero)")
          if $? != 0;

      my @records = grep { length } split /\0/, $output;
      return unless @records;

      my $list = join("\n", map { "  $_" } @records);
      die_msg(<<"END");
  Working tree has uncommitted changes under .cwf, .cwf-skills:
  $list
  Stash or commit them, then re-run:
    git stash
    cwf-manage update [ref]
    git stash pop
  END
  }
  ```
  Note: `die_msg` already prefixes `[CWF] ERROR: ` and appends `\n`, so the heredoc body must not include either.
- [ ] Re-run `prove t/cwf-manage-check-clean-tree.t` — expect **all 3 subtests pass** (green).

### Step 4: Wire into `cmd_update`
- [ ] In `cmd_update` (line 210), insert one line **between line 216 (`resolve_source`) and line 218 (`log_msg("Updating CWF...")`)**.
- [ ] **Before** (current state, post-Task 115):
  ```perl
  my ($source, $origin) = resolve_source(\%v);

  log_msg("Updating CWF (method: $method, ref: $ref)");
  ```
- [ ] **After**:
  ```perl
  my ($source, $origin) = resolve_source(\%v);

  check_clean_tree($git_root);

  log_msg("Updating CWF (method: $method, ref: $ref)");
  ```
- [ ] `cmd_rollback` (lines 257–263) delegates to `cmd_update`, so it inherits the check with no further change.

### Step 5: Update `cmd_help` heredoc (single source of truth for the new behaviour)
- [ ] Add a `Notes:` subsection between `Environment:` and `Examples:` (after line 404):
  ```
  Notes:
    update and rollback refuse to run if the working tree has uncommitted
    changes under .cwf/ or .cwf-skills/. Stash or commit them first.
  ```
- [ ] **Do not** duplicate this into the file-header comment block. The help heredoc is the user-facing source of truth; the file header already documents the commands at a higher level and doesn't need this detail.

### Step 7: Re-hash and validate
- [ ] Compute new sha256 of `.cwf/scripts/cwf-manage` and update `.cwf/security/script-hashes.json`.
- [ ] Run `cwf-manage validate` — expect OK.

### Step 8: Smoke tests
- [ ] Full `prove t/` — expect **all tests pass, no regressions** (baseline 235/235 → 238/238 expected with 3 new subtests).
- [ ] **Manual end-to-end smoke** in a `mktemp -d` fixture with a populated `.cwf/version`:
  - **Scenario A — clean tree, env override**: `CWF_SOURCE=file:///tmp/nonexistent cwf-manage update` → expect `Cloning CWF source from file:///tmp/nonexistent (from: CWF_SOURCE env var)...` (Task 115 behaviour preserved) and a clone failure. No dirty error.
  - **Scenario B — dirty `.cwf/`, env override** (load-bearing, the bug being fixed): `echo dirt >> .cwf/foo.txt && CWF_SOURCE=file:///tmp/nonexistent cwf-manage update` → expect:
    ```
    [CWF] ERROR: Working tree has uncommitted changes under .cwf, .cwf-skills:
      ?? .cwf/foo.txt
    Stash or commit them, then re-run:
      git stash
      cwf-manage update [ref]
      git stash pop
    ```
    No clone attempt. Exit code 1.
  - **Scenario C — dirty file outside scope**: `echo dirt >> README.md && cwf-manage update` → no dirty error; update proceeds.

### Step 9: Validation
- [ ] All a-task-plan.md success criteria checked off.
- [ ] `cmd_rollback` is automatically covered (delegates to `cmd_update`); confirm by reading line 257–263 — no change needed there.
- [ ] No deviation from c-design-plan.md decisions; if a deviation arises, document it in f-implementation-exec.md.

## Code Changes

### Helper — `.cwf/scripts/cwf-manage` (new)
See Step 3 above for the full snippet.

### Call site — `.cwf/scripts/cwf-manage` `cmd_update` (modified)
See Step 4 above for before/after.

### Help text — `.cwf/scripts/cwf-manage` `cmd_help` (extended)
See Step 5 above. Single source of truth — no file-header duplicate.

### Test — `t/cwf-manage-check-clean-tree.t` (new)
Skeleton:
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');

my $SCRIPT = File::Spec->catfile(
    $FindBin::Bin, '..', '.cwf', 'scripts', 'cwf-manage'
);

# Load the script. @ARGV = ('help') keeps main() side-effect-free.
{
    local @ARGV = ('help');
    open(my $saved, '>&', \*STDOUT) or die "Cannot dup STDOUT: $!";
    open(STDOUT, '>', File::Spec->devnull()) or die "Cannot silence STDOUT: $!";
    do $SCRIPT;
    open(STDOUT, '>&', $saved) or die "Cannot restore STDOUT: $!";
}
die "Failed to load $SCRIPT: $@" if $@;

# Override die_msg so failure paths are catchable by eval{} — same pattern
# as t/cwf-manage-resolve-source.t (Task 115).
{
    no warnings 'redefine', 'once';
    *main::die_msg = sub { die "[CWF] ERROR: @_\n" };
}

sub make_baseline_repo {
    my $dir = tempdir(CLEANUP => 1);
    system("git", "-C", $dir, "init", "-q") == 0 or die "git init failed";
    system("git", "-C", $dir, "config", "user.email", "test\@example.com") == 0 or die "git config failed";
    system("git", "-C", $dir, "config", "user.name",  "Test") == 0              or die "git config failed";
    mkdir "$dir/.cwf" or die $!;
    open my $vfh, '>', "$dir/.cwf/version" or die $!;
    print $vfh "cwf_method=copy\ncwf_source=https://example.com/x.git\ncwf_version=v0.0.1\n";
    close $vfh;
    system("git", "-C", $dir, "add", ".") == 0          or die "git add failed";
    system("git", "-C", $dir, "commit", "-q", "-m", "init") == 0 or die "git commit failed";
    return $dir;
}

subtest 'TC-1: clean tree → returns without dying' => sub {
    my $dir = make_baseline_repo();
    eval { main::check_clean_tree($dir) };
    is($@, '', 'no die on clean tree');
};

subtest 'TC-2: dirty tree (tracked + untracked) → dies, lists both' => sub {
    my $dir = make_baseline_repo();
    open my $vfh, '>>', "$dir/.cwf/version" or die $!;
    print $vfh "extra=1\n";
    close $vfh;
    open my $nfh, '>',  "$dir/.cwf/notes.md" or die $!;
    print $nfh "scratch\n";
    close $nfh;
    eval { main::check_clean_tree($dir) };
    like($@, qr{Working tree has uncommitted changes}, 'dies with header');
    like($@, qr{\.cwf/version}, 'mentions tracked-modified path');
    like($@, qr{notes\.md},     'mentions untracked path (--untracked-files=all)');
    like($@, qr{git stash},     'recipe included');
};

subtest 'TC-3: git status fails → dies with check-failure message' => sub {
    eval { main::check_clean_tree('/nonexistent/path') };
    like($@, qr{Failed to check working tree status}, 'dies on git-status failure');
};

done_testing();
```

## Test Coverage
**See e-testing-plan.md for complete test plan.**

Summary:
- Unit (3 subtests): clean / dirty (tracked + untracked) / status-fail.
- Smoke (3 scenarios): clean+env, dirty+env (load-bearing), dirty-outside-scope.
- Regression: full `prove t/` baseline (235 → 238 expected).

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results.**

## Plan Review Summary
**Initial review — 3 parallel Explore subagents (Improvements / Misalignment / Robustness)**:
- *Misalignment / Robustness* — Replaced backtick + `quotemeta` git invocation with list-form `open '-|', 'git', '-C', $git_root, ...`. Shell-safe; addresses BACKLOG "Replace Backtick Operators…" in spirit.
- *Robustness* — Defensive `$? != 0` exit-code check around `git status`.

**Second pass — `/simplify`**: 3 parallel review agents converged on the same simplifications. Applied:
- Helper now calls `die_msg` directly with the **complete** message (header + file list + recipe). Removed the `eval`+raw-`die` wrapper, the asymmetric "raw die not die_msg" contract, and the speculative-future-caller justification. Aligns with `resolve_source` / `read_version_file`.
- Helper signature simplified to `check_clean_tree($git_root)`. `@paths` parameter removed — only one caller, only one set of paths (`.cwf`, `.cwf-skills`).
- Cap-overflow logic removed. Show all dirty entries. Removed ~5 lines of helper code and TC-4.
- Test reduced from 5 subtests to 3 (combined TC-2 + TC-3 into one "dirty tracked + untracked" assertion; dropped TC-4).
- `BAIL_OUT` machinery removed from test fixture — bare `die` is fine.
- File-header comment duplicate removed. `cmd_help` heredoc is the single source of truth.

## Scope Completion
- [ ] Helper added (`check_clean_tree($git_root)`).
- [ ] Call site wired (one new line in `cmd_update`).
- [ ] `cmd_help` heredoc updated (single source of truth — no file-header duplicate).
- [ ] `.cwf/security/script-hashes.json` re-hashed; `cwf-manage validate` OK.
- [ ] Unit (3 subtests) + smoke (3 scenarios) + full regression (235 → 238) all pass.

If any of these is deferred, document in f-implementation-exec.md with rationale and create a follow-up task.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 116
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
