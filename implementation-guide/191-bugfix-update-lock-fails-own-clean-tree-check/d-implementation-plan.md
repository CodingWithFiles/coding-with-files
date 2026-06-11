# update lock fails own clean-tree check - Implementation Plan
**Task**: 191 (bugfix)

## Task Reference
- **Task ID**: internal-191
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/191-update-lock-fails-own-clean-tree-check
- **Template Version**: 2.1

## Goal
Implement the approved design: make `check_clean_tree` ignore `.cwf/.update.lock`
via a git exclude pathspec, backed by a shared lock-path constant, without
touching the D8 lock-before-check ordering.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/scripts/cwf-manage` — three edits (see Code Changes):
  1. add file-scoped `my $UPDATE_LOCK_REL = '.cwf/.update.lock';`
  2. `check_clean_tree`: append `":(exclude)$UPDATE_LOCK_REL"` to the `git status` pathspec list
  3. `acquire_update_lock`: build `$path` from `$git_root/$UPDATE_LOCK_REL`

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `sha256` for
  `.cwf/scripts/cwf-manage` (entry at line 220) **in the same commit** as the
  source edit (hash-updates convention). Recorded `permissions` is `0700`; leave
  it unchanged and restore working perms to `0700` after editing.
- `t/cwf-manage-check-clean-tree.t` — add the two regression subtests carried over
  from design (full spec in e-testing-plan.md).

## Implementation Steps
### Step 1: Tests first (red)
- [ ] Add `TC-4` (lock-only → passes) and `TC-5` (lock + real dirty path → still
      dies, lists the real path) to `t/cwf-manage-check-clean-tree.t`
- [ ] Run the test file; confirm `TC-4` **fails** against current code (reproduces
      the self-block). `TC-5` includes a lock-absent assertion
      (`unlike($@, qr/\.update\.lock/)`) that **also fails** pre-fix — that
      assertion is what proves the exclusion is exact, not over-broad. (Exact
      assertion shape pinned in e-testing-plan.md.)

### Step 2: Core implementation (green)
- [ ] Add the `$UPDATE_LOCK_REL` file-scoped lexical
- [ ] Append the exclude pathspec in `check_clean_tree`
- [ ] Re-point `acquire_update_lock`'s `$path` at the constant
- [ ] Run the test file; confirm `TC-1`..`TC-5` all pass

### Step 3: Hash + perms (same commit)
- [ ] Restore working perms: `chmod 0700 .cwf/scripts/cwf-manage`
- [ ] `sha256sum .cwf/scripts/cwf-manage` → update entry at `script-hashes.json:220`
- [ ] `cwf-manage validate` → expect `validate: OK`

### Step 4: Full regression
- [ ] Run the whole `t/` suite (or at least every `cwf-manage-*.t`) — no regressions

## Code Changes
### Change 1 — add the shared constant (near `$update_in_progress`, ~line 46)
```perl
# Repo-relative path of the update lock — single source of truth shared by
# acquire_update_lock (absolutised against $git_root for sysopen) and
# check_clean_tree (passed BARE as a git exclude pathspec, resolved relative to
# -C $git_root). The two MUST stay in sync; a drift re-opens the self-block.
my $UPDATE_LOCK_REL = '.cwf/.update.lock';
```

### Change 2 — `check_clean_tree` (current lines 154-157)
Before:
```perl
    open(my $fh, '-|', 'git', '-C', $git_root,
         'status', '--porcelain', '-z', '--untracked-files=all',
         '--', '.cwf', '.cwf-skills', '.cwf-rules', '.cwf-agents')
        or die_msg("Failed to spawn git status: $!");
```
After:
```perl
    # Exclude CWF's own ephemeral lock: cmd_update creates it (D8 lock-before-
    # check ordering) before this runs, so on installs whose .gitignore lacks the
    # lock line it would otherwise read as a dirty path and block the very update
    # that adds that line. BARE (not absolutised) so git resolves it relative to
    # -C $git_root like the positive pathspecs.
    open(my $fh, '-|', 'git', '-C', $git_root,
         'status', '--porcelain', '-z', '--untracked-files=all',
         '--', '.cwf', '.cwf-skills', '.cwf-rules', '.cwf-agents',
         ":(exclude)$UPDATE_LOCK_REL")
        or die_msg("Failed to spawn git status: $!");
```

### Change 3 — `acquire_update_lock` (current line 256)
Before:
```perl
    my $path = "$git_root/.cwf/.update.lock";
```
After:
```perl
    my $path = "$git_root/$UPDATE_LOCK_REL";
```
Optional tidy (same edit): the sub's doc-comment at line 250 restates the literal
`.cwf/.update.lock` in prose. Reword it to reference the lock generically (e.g.
"on the update lock") so the centralised constant is the only place the path
string lives — closing the latent drift site the constant exists to prevent.

## Test Coverage
Two new subtests in `t/cwf-manage-check-clean-tree.t` (TC-4, TC-5). Existing
TC-1..TC-3 must continue to pass. **See e-testing-plan.md for the complete test plan.**

## Validation Criteria
- All subtests in `t/cwf-manage-check-clean-tree.t` pass (incl. the new TC-4/TC-5).
- `cwf-manage validate` → `validate: OK` (hash refreshed, perms at recorded 0700).
- No regression across the `cwf-manage-*.t` suite.
**See e-testing-plan.md for validation criteria and recorded results.**

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
All three code changes plus the optional doc-comment tidy applied as planned; hash
refreshed to `e84de3eb...` and perms restored to `0700` in the same (f) commit;
`validate: OK`. The robustness reviewer's catch (stale `0500` → `0700` perms value
in the design doc) was corrected before exec.

## Lessons Learned
Pinning exact before/after code blocks in the plan made exec mechanical and
low-risk. See j-retrospective.md.
