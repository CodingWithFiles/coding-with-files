# security-review-changeset blind to uncommitted - Implementation Plan
**Task**: 141 (bugfix)

## Task Reference
- **Task ID**: internal-141
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/141-security-review-changeset-blind-to-uncommitted
- **Template Version**: 2.1

## Goal
Implement the design from c-design-plan.md: drop `..HEAD` from both diff specs in `security-review-changeset`, add the `includes uncommitted` stderr disclosure via list-form `git_check('diff', '--quiet', 'HEAD')`, and add the `TC-Task141-uncommitted` regression test.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `.cwf/scripts/command-helpers/security-review-changeset` — three minimal edits:
  - Line 168: `capture_git('diff', "${anchor}..HEAD", '--', @included)` → `capture_git('diff', "$anchor", '--', @included)`. Drops `..HEAD`.
  - Line 341: `capture_git('diff', '--name-only', '-z', "${anchor}..HEAD")` → `capture_git('diff', '--name-only', '-z', "$anchor")`. Drops `..HEAD`.
  - After line 173 (the existing `warn sprintf(...)` summary): add a follow-up `git_check('diff', '--quiet', 'HEAD')` dirty-check; if it returns 1, append `, includes uncommitted` to the summary line. If it returns ≥ 2 (git error), skip the suffix and continue — fail-quiet-and-degrade per c-design Decision 2.

### Supporting Changes
- `t/security-review-changeset.t` — add one new subtest (`TC-Task141-uncommitted`) per c-design Validation. Test scaffolding (`make_synthetic_repo`, `run_helper`, `git_in`, `git_capture`) already supports the new case; no helper extraction needed.
- `.cwf/security/script-hashes.json` — regenerate the `security-review-changeset` entry by hand (Task-135 surface-don't-smooth policy). One SHA, one `last_updated` bump.
- `BACKLOG.md` — `backlog-manager retire --exact-title='security-review-changeset blind to uncommitted work' --task=141 --note='...'` during j-retrospective.
- `CHANGELOG.md` — Task 141 entry during j-retrospective.

## Implementation Steps

### Step 1: Setup
- [ ] Confirm baseline: `prove t/security-review-changeset.t` is green on `f833bbf` (Task 140's tip, now main). Should be 19 tests.
- [ ] Re-read c-design-plan.md Decision 1, Decision 2, and the "Behavioural notes on the widened diff window" section.

### Step 2: Restructure summary emission for conditional suffix
- [ ] In `security-review-changeset` main flow (around lines 159-176), compute the `$dirty_suffix` *once* near the start of the summary block, then append it to both the empty-changeset summary (line 161) and the non-empty summary (line 172). Keeps the dirty-check single-call (cheap) and the two summary sites consistent.

### Step 3: Add the dirty-check + disclosure
- [ ] Add (just before the `if (!@included)` test at line 160):
  ```perl
  my $dirty_rc = git_check('diff', '--quiet', 'HEAD');
  my $dirty_suffix = $dirty_rc == 1 ? ', includes uncommitted' : '';
  # dirty_rc == 0: clean; rc >= 2: git error — skip suffix, don't fail
  # (the primary diff has already succeeded; disclosure is informational)
  ```
- [ ] Update the empty-changeset `warn` at line 161 to interpolate `$dirty_suffix`.
- [ ] Update the non-empty `warn sprintf` at line 172-173 to append `$dirty_suffix`.
- [ ] Run focused test: `prove t/security-review-changeset.t` — no existing case breaks (committed-state tests will see `$dirty_suffix = ''`).

### Step 4: Drop `..HEAD` from both diff specs
- [ ] Edit line 168: `"${anchor}..HEAD"` → `"$anchor"` in the `capture_git('diff', ...)` call.
- [ ] Edit line 341 (inside `list_changed_files`): same change in the `capture_git('diff', '--name-only', '-z', ...)` call.
- [ ] Update the `list_changed_files` block comment at line 336-338 to: `# git diff --name-only -z <anchor> → list of paths (anchor to working tree, includes staged + unstaged).`
- [ ] Update the file-header stderr-contract comment (around line 30, currently `#   stderr: one-line summary 'reviewed N files, M lines, anchor=<sha7>',`) to document the new optional disclosure suffix, e.g. `#   stderr: one-line summary 'reviewed N files, M lines, anchor=<sha7>[, includes uncommitted]',`
- [ ] Run `prove t/security-review-changeset.t` — all 19 existing tests should still pass (the new behaviour is a strict superset for committed-state inputs).

### Step 5: Add `TC-Task141-uncommitted` regression test
- [ ] At the bottom of `t/security-review-changeset.t` (before `done_testing()` at line 513), add a new `subtest 'TC-Task141-uncommitted: helper sees staged and unstaged changes' => sub { ... }`:
  - `my ($repo, $main_sha, $branch, $task_dir) = make_synthetic_repo(baseline => '__MAIN__');`
  - On the task branch, create **two separate files** in `.cwf/scripts/` so the diff hunks are distinguishable (a single twice-edited file produces a *combined* diff where both edits appear in one hunk and the two `like` assertions can't independently prove staged vs unstaged were both picked up):
    - `.cwf/scripts/staged-script` containing `#!/usr/bin/perl\nprint "STAGED_141";\n` — `git_in($repo, 'add', '.cwf/scripts/staged-script')` (staged, not committed).
    - `.cwf/scripts/unstaged-script` containing `#!/usr/bin/perl\nprint "UNSTAGED_141";\n` — do NOT `git add` (working-tree-only).
  - Call `run_helper($repo)`.
  - **Assert 1**: `is($rc, 0, 'helper exits 0')`.
  - **Assert 2a**: `like($out, qr{staged-script}, 'staged-only file appears in diff')` — proves index-side changes are picked up.
  - **Assert 2b**: `like($out, qr{unstaged-script}, 'working-tree-only file appears in diff')` — proves working-tree changes are picked up. Two distinct file paths in the diff = independent proof that both halves are scanned.
  - **Assert 3**: `like($err, qr{^reviewed 2 files,.+anchor=[0-9a-f]{7}, includes uncommitted$}m, 'stderr summary anchors disclosure to summary line')` — anchored regex ensures the suffix lands on the summary line, not in some `--verbose` body.
- [ ] Run `prove t/security-review-changeset.t` — now 20 tests, all green.

### Step 6: Regenerate script hash
- [ ] Run `.cwf/scripts/cwf-manage fix-security` to surface the new `Actual:` hash for `security-review-changeset` (refuses to overwrite — that's the point).
- [ ] Edit `.cwf/security/script-hashes.json` by hand: replace the `security-review-changeset` SHA with the printed `Actual:` value; bump `last_updated` to today's date.
- [ ] Run `.cwf/scripts/cwf-manage validate` — expect OK.

### Step 7: Validation gate
- [ ] `prove t/` (full suite) — expect 473 PASS (was 472 + 1 new test).
- [ ] **Canonical end-to-end smoke**: run `.cwf/scripts/command-helpers/security-review-changeset --phase=implementation` on this branch *before* the f-checkpoint commit. Expected:
  - stdout: non-empty diff containing the uncommitted edits to `security-review-changeset` and `t/security-review-changeset.t`.
  - stderr: `reviewed N files, M lines, anchor=f833bbf, includes uncommitted`.
  - **The fix succeeds iff this works on first try.** Record the stderr line in f-implementation-exec.md as evidence.

## Code Changes

### Before — `security-review-changeset` (lines 159-176)
```perl
my $short = substr($anchor, 0, 7);
if (!@included) {
    warn "reviewed 0 files, 0 lines, anchor=$short\n";
    if ($opt{verbose}) {
        # nothing to print
    }
    exit 0;
}

my $diff = capture_git('diff', "${anchor}..HEAD", '--', @included);
my $line_count = ($diff =~ tr/\n//);
print $diff;

warn sprintf("reviewed %d files, %d lines, anchor=%s\n",
             scalar @included, $line_count, $short);
if ($opt{verbose}) {
    warn "  $_\n" for @included;
}
exit 0;
```

### After
```perl
my $short = substr($anchor, 0, 7);
my $dirty_rc = git_check('diff', '--quiet', 'HEAD');
my $dirty_suffix = $dirty_rc == 1 ? ', includes uncommitted' : '';
# dirty_rc == 0: clean; rc >= 2: git error - skip suffix, don't fail.
# The primary diff has already succeeded; the disclosure is informational.

if (!@included) {
    warn "reviewed 0 files, 0 lines, anchor=$short$dirty_suffix\n";
    exit 0;
}

my $diff = capture_git('diff', "$anchor", '--', @included);
my $line_count = ($diff =~ tr/\n//);
print $diff;

warn sprintf("reviewed %d files, %d lines, anchor=%s%s\n",
             scalar @included, $line_count, $short, $dirty_suffix);
if ($opt{verbose}) {
    warn "  $_\n" for @included;
}
exit 0;
```

### Before — `list_changed_files` (lines 339-345)
```perl
sub list_changed_files {
    my ($anchor) = @_;
    my $out = capture_git('diff', '--name-only', '-z', "${anchor}..HEAD");
    return () unless length $out;
    my @paths = split /\0/, $out;
    return grep { length } @paths;
}
```

### After
```perl
sub list_changed_files {
    my ($anchor) = @_;
    my $out = capture_git('diff', '--name-only', '-z', "$anchor");
    return () unless length $out;
    my @paths = split /\0/, $out;
    return grep { length } @paths;
}
```

## Test Coverage
**See e-testing-plan.md for complete test plan.**

Net change: 1 new subtest (`TC-Task141-uncommitted`); 0 existing tests modified.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results.**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

No scope cuts anticipated. The c-design-plan's three discarded options ((b) warn-only, (c) doc-only, and the rejected `--committed-only` flag) are documented as deliberate non-implementations; nothing else is deferred.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 141
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
