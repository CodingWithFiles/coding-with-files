# changeset omits untracked files from git diff - Implementation Plan
**Task**: 194 (bugfix)

## Task Reference
- **Task ID**: internal-194
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/194-changeset-omits-untracked-files-from-git-diff
- **Template Version**: 2.1

## Goal
Implement changeset omits untracked files from git diff following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/security-review-changeset` — add untracked-file
  enumeration + intent-to-add + END-block restore; widen the dirty suffix; update the
  header comment block.

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the sha256 for the edited helper, in **this
  task's exec commit** (hash-updates convention). Restore the helper's working perms to the
  RECORDED value (0500) after editing — do not leave it at a bumped mode.
- `t/security-review-changeset.t` — new subtests (detailed in e-testing-plan.md).

## Policy note — Perl core-only
This change uses **only core Perl**: `system`, `%SIG`, `fork`/`exec` (already used), and the
existing `capture_git`. No new `use` of any non-core module (notably **no `use POSIX`** —
the simplified `system`-based reset is what lets us avoid it). Honours the project core-only
constraint.

## Implementation Steps
All line numbers are against the helper at baseline `a4b71df`; re-confirm before editing.

### Step 1: Cleanup machinery, co-located **below** the `my $PROG` decl (line ~86)
Placement matters: the `END` block's `warn` references `$PROG`, a `my` lexical declared at
line ~86, and the block closes over `@UNTRACKED_TO_RESET`/`$MAIN_PID`. Put all three —
the two decls and the `END` block — together, **below** line 86, so every name is in scope.
- [ ] `my @UNTRACKED_TO_RESET;` (file lexical) — paths the END block must reset.
- [ ] `my $MAIN_PID = $$;` captured before any `fork` — the forked-child guard.
- [ ] Install signal handlers (see Step 3a) and the `END` block here.

### Step 2: `list_untracked_files()` sub (near `list_changed_files`, ~line 432)
- [ ] Add sub with **no parameters**:
      `capture_git('ls-files', '--others', '--exclude-standard', '-z')`, `split /\0/`,
      `grep { length }`. Mirrors `list_changed_files` parsing (NUL-split, `-z`).
- [ ] Returns `()` on empty output (the `return () unless length $out` guard pattern).

### Step 3: The END-block restore (place AFTER `$MAIN_PID`/`@UNTRACKED_TO_RESET` decls so
they are in scope; END runs regardless of textual position)
- [ ] `END { ... }` body:
  - `return unless $$ == $MAIN_PID;`  (no-op in any forked child — `git_check` forks and
    its child can reach `exit 127`, line ~331, which would otherwise run this END)
  - `return unless @UNTRACKED_TO_RESET;`
  - `local $? = $?;` — actually save/restore explicitly: `my $saved = $?;` … `$? = $saved;`
    at the end, so the reset never alters the process exit code (the load-bearing `exit 2`
    cap value, lines 247-251).
  - Run reset **best-effort, non-fatal, shell-free** via list-form
    `system('git', 'reset', '-q', '--', @UNTRACKED_TO_RESET)`. List-form `system` invokes
    no shell (so the paths cannot be shell-interpreted) and forks+execs in C (so it does
    NOT run Perl END blocks — no END recursion, no `POSIX::_exit` needed here). `-q`
    silences success output; a rare failure prints to stderr, which is acceptable
    diagnostic noise. Do **not** call `capture_git`/`git_check` (both `exit 1` on failure →
    would `exit` from inside END and clobber the exit code). `warn` at most on non-zero.
  - NOTE the mandatory `--` before `@UNTRACKED_TO_RESET` (option-injection invariant).

> **Key correctness interaction**: introducing this END block means it will also fire on
> `git_check`'s forked-child `exit 127` path (line ~331). The `$$ == $MAIN_PID` guard is
> what makes that a no-op — so `git_check` needs **no** change. The PID guard is therefore
> load-bearing for both our own cleanup correctness and for not perturbing `git_check`.
> No `use POSIX` is required (the simplified `system`-based reset above avoids the manual
> fork that would have needed `POSIX::_exit`).
- [ ] **Pin the invariant in code (security review F5)**: add a one-line comment at the
      `git_check` fork site (line ~327) noting that its child must not run the cleanup END
      block and that the `$$ == $MAIN_PID` guard is what protects it — so a future edit to
      `git_check` (second fork site, or switching to `POSIX::_exit`) does not silently break
      the guard.

### Step 3a: Signal handlers so an interrupt still restores (robustness review F1)
Perl `END` blocks run on `exit`/`die` but **not** on an un-handled `SIGINT`/`SIGTERM`
(confirmed: signal-killed process skips END). Without a handler, Ctrl-C or a timeout-kill in
the window between `git add -N` and normal exit leaves the user's index polluted with
intent-to-add entries.
- [ ] When `@untracked` is non-empty (i.e. once we are about to mutate the index), install
      `$SIG{INT} = $SIG{TERM} = sub { exit(130); };`. Calling `exit` runs the `END` block,
      which performs the reset. `%SIG` is core Perl. Keep the handler scoped to the
      mutating path — do not change default signal behaviour for runs with no untracked
      files.

### Step 4: Wire untracked enumeration into the main flow (around lines 172-220)
- [ ] After `my @changed = list_changed_files($anchor);` (line 172), keep computing the
      tracked-dirty flag from the EXISTING `git_check('diff', '--quiet', 'HEAD')` (line 189)
      **before** any `-N`. Rename the captured rc var if clearer, but do not move the probe
      after `-N`.
- [ ] `my @untracked = list_untracked_files();`
- [ ] `if (@untracked) { @UNTRACKED_TO_RESET = @untracked; <install SIG handlers, Step 3a>;
      capture_git('add', '-N', '--', @untracked); }` — populate the reset list AND install
      the signal handlers BEFORE the `add` so an interrupt or failure mid-`add` still gets
      reset by END. (capture_git on `add -N` returns rc=0 per probe; a non-zero would
      `exit 1` via capture_git, after which END still fires because the list is populated.)
- [ ] `my @included = (@changed, @untracked);` (replaces `my @included = @changed;` at
      line 178). No dedup — disjoint by construction; over-count is the safe direction.
      **Why an explicit concat rather than re-running `list_changed_files` after `-N`**
      (which would itself now enumerate the untracked files): enumeration must stay BEFORE
      `-N` to keep the dirty-probe semantics (Step 5) correct. Leave a code comment so a
      future reader does not "simplify" by reordering and silently double-count.

### Step 5: Widen the dirty suffix (lines 189-192)
- [ ] Change `$dirty_suffix` to fire when the tracked-dirty flag fired **or** `@untracked`
      is non-empty: `my $dirty_suffix = ($dirty_rc == 1 || @untracked) ? ', includes
      uncommitted' : '';`. Keep the `rc >= 2` git-error tolerance (no suffix, don't fail).
      Ensure `@untracked` is computed before this line, or fold the suffix computation just
      after Step 4's enumeration.

### Step 6: Body + count are unchanged code
- [ ] Confirm line 220 `capture_git('diff', "$anchor", '--', @included)` and line 237
      `count_production_lines($anchor, \@included, \@exclude)` now see untracked files via
      intent-to-add. No edits to these calls or to `count_production_lines`/
      `max_lines_exclude_paths` — the whole point of the design is they need none.

### Step 7: Header comment block (lines ~11-72)
- [ ] Update the **"Changeset scope"** block (lines ~19-22) to state untracked, non-ignored
      files are included (via intent-to-add, restored after) and ignored files are excluded
      via `--exclude-standard`.
- [ ] Update the **Output / stderr-suffix prose** (lines ~59-63, the `includes uncommitted`
      description) so it reflects the widened suffix (fires for untracked-only changesets
      too).
- [ ] Note the index is transiently mutated (`add -N`) and restored on every non-`SIGKILL`
      exit (END block + signal handlers).

### Step 8: Tests + hash refresh (see e-testing-plan.md)
- [ ] Add subtests to `t/security-review-changeset.t`.
- [ ] Run full suite; fix to green.
- [ ] Refresh `.cwf/security/script-hashes.json` for the helper; restore helper perms to
      recorded 0500; verify `cwf-manage validate` (or `fix-security` then validate) clean.

## Code Changes
### Before (line 178)
```perl
my @included = @changed;
```
### After (sketch — exact placement per steps above)
```perl
my @untracked = list_untracked_files();
if (@untracked) {
    @UNTRACKED_TO_RESET = @untracked;          # END block resets these
    capture_git('add', '-N', '--', @untracked); # make them diff-visible
}
my @included = (@changed, @untracked);
```
### New sub (near line 432)
```perl
sub list_untracked_files {
    my $out = capture_git('ls-files', '--others', '--exclude-standard', '-z');
    return () unless length $out;
    return grep { length } split /\0/, $out;
}
```
### Cleanup machinery (below the `my $PROG` decl, line ~86)
```perl
my @UNTRACKED_TO_RESET;
my $MAIN_PID = $$;
END {
    return unless $$ == $MAIN_PID;        # no-op in any forked child (incl. git_check's)
    return unless @UNTRACKED_TO_RESET;
    my $saved = $?;                        # preserve load-bearing exit code (e.g. exit 2)
    system('git', 'reset', '-q', '--', @UNTRACKED_TO_RESET);  # shell-free, runs no END
    warn "$PROG: warning: could not restore intent-to-add state\n" if $? != 0;
    $? = $saved;
}
```
List-form `system` needs no `use POSIX` and cannot recurse into END. The `$? = $saved`
restore is what keeps `exit 2` (cap exceeded) intact for the caller.

### Signal handlers (installed in the `if (@untracked)` block, before `add -N`)
```perl
$SIG{INT} = $SIG{TERM} = sub { exit(130); };  # exit() runs END → restores the index
```
`%SIG` is core Perl. Scoped to the mutating path so default signal behaviour is unchanged
for runs with no untracked files.

## Test Coverage
**See e-testing-plan.md for complete test plan.** Cases this implementation must have
covered there:
1. An untracked, non-ignored file appears in the `.out` body (full, all-added) and in the
   production line count.
2. An ignored file (`.gitignore`d) does NOT appear in body or count.
3. Post-run index is clean (untracked file still `??`, no residual intent-to-add) on the
   normal exit path **and** on the cap-exceeded (`exit 2`) path.
4. `exit 2` is still returned when an untracked file pushes the count over `--max-lines`
   (cleanup did not clobber the code).
5. An untracked-only working tree (no tracked changes) renders the suffix
   `, includes uncommitted`.
6. A dash-prefixed untracked filename (e.g. `-rf`) is included and leaves a clean index
   (the `--` option-injection invariant).
7. Existing subtests still pass (no regression in the tracked-only behaviour).

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Decomposition Check
0 signals — single helper, ~40 lines of change plus tests. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective (complete)
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Every numbered step was executed as written; the code sketches in this plan went
in essentially verbatim. The core-only policy was honoured (no `use POSIX`; the
`system`-based reset is what avoided it). The hash refresh landed in the f-phase
commit. No deviations from plan.

## Lessons Learned
The plan's decision to keep the body/count code paths untouched (Step 6) was
validated at exec time — the diff is `+40`-ish lines of new enumeration/cleanup
with zero edits to the security-critical counting logic, which is what kept the
review surface small.
