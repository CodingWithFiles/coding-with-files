# Skip non-regular files in untracked sweep - Implementation Plan
**Task**: 209 (bugfix)

## Task Reference
- **Task ID**: internal-209
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/209-skip-non-regular-files-in-untracked-sweep
- **Template Version**: 2.1

## Goal
Implement the `-f || -l` filter in `list_untracked_files()` per the approved design.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/scripts/command-helpers/security-review-changeset` — filter the return
  of `list_untracked_files()` (currently lines 504–508) to git-indexable types.

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `security-review-changeset`
  `sha256` entry (hashed path; same commit per hash-updates convention).
- `t/security-review-changeset.t` — add the new test cases (see e-testing-plan).

## Implementation Steps
### Step 1: Core change
- [ ] In `list_untracked_files()`, split the result into `@paths`, then return
      `grep { -f $_ || -l $_ } @paths` with a comment explaining the git-indexable
      rationale, the char-device bind-mount trigger, and the `-l`/lstat retention.

### Step 2: Tests (detail in e-testing-plan)
- [ ] Portable regression: an untracked symlink (to `/dev/null` and a dangling
      one) still appears in the changeset — guards the `-l` retention against a
      future bare-`-f` narrowing.
- [ ] Linux-gated: a char-device untracked entry (bind-mounted `/dev/null` via
      `unshare -rm`) no longer aborts the helper; the masked path is absent and a
      sibling regular untracked file is still reviewed. SKIP when `unshare`/
      user-namespace/bind-mount is unavailable.
- [ ] **Red-then-green**: before applying Step 1, confirm the char-device test
      reproduces the abort (helper exits 1) on the unpatched helper, so the test
      is a genuine regression guard, not a vacuous pass. Then apply Step 1 and
      confirm green.
- [ ] Run the full `t/security-review-changeset.t` for no regressions.
- Note: silently dropping the masked path (no warning) is the recorded design
  decision — the entry is harness-injected, not reviewable user content, so it
  is not a "surface, never smooth" omission. See c-design-plan "drop silently".

### Step 3: Hash refresh (same commit as Step 1)
- [ ] `git log --oneline e06185f..HEAD -- .cwf/scripts/command-helpers/security-review-changeset`
      to confirm Task 206 is the last intended hash-set (no unrelated drift).
- [ ] `sha256sum` the edited helper; update its entry in `script-hashes.json`.
- [ ] chmod the helper back to its **recorded** ceiling (0500), not a bumped
      value, before validating (recorded-perms-as-ceiling).
- [ ] `cwf-manage validate` → clean.

## Code Changes
### Before
```perl
sub list_untracked_files {
    my $out = capture_git('ls-files', '--others', '--exclude-standard', '-z');
    return () unless length $out;
    return grep { length } split /\0/, $out;
}
```

### After
```perl
sub list_untracked_files {
    my $out = capture_git('ls-files', '--others', '--exclude-standard', '-z');
    return () unless length $out;
    my @paths = grep { length } split /\0/, $out;
    # Keep only the path types `git add -N` can intent-to-add: regular files
    # (-f) and symlinks (-l). A sandbox harness may bind-mount /dev/null (a char
    # device) over repo-root config dotfiles; git enumerates those as untracked
    # but `git add -N` rejects them ("can only add regular files, symbolic links
    # or git-directories"), aborting the sweep. -l is lstat, so dangling symlinks
    # and symlinks-to-devices are retained (git stores their link text). Sibling
    # stop-stale-status-detector uses a bare -f; this site keeps -l because
    # untracked symlinks must stay reviewable (TC-GUARD1a).
    return grep { -f $_ || -l $_ } @paths;
}
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

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

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
