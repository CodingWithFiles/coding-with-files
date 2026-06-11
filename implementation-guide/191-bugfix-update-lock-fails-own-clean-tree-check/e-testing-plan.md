# update lock fails own clean-tree check - Testing Plan
**Task**: 191 (bugfix)

## Task Reference
- **Task ID**: internal-191
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/191-update-lock-fails-own-clean-tree-check
- **Template Version**: 2.1

## Goal
Verify that `check_clean_tree` ignores `.cwf/.update.lock` (breaking the self-block)
while still reporting every other dirty path, with no regression to the existing
`cwf-manage` behaviour.

## Test Strategy
### Test Levels
- **Unit Tests** (primary): direct calls to `main::check_clean_tree($dir)` in the
  existing harness `t/cwf-manage-check-clean-tree.t`, which loads `cwf-manage` via
  `do()` and overrides `die_msg` so failure paths are catchable via `eval{}`.
  Each test builds a throwaway git repo with `make_baseline_repo()` (already in the
  file) — no production state touched.
- **Regression**: the full `cwf-manage-*.t` set plus `prove -r t/` to confirm the
  shared-constant refactor and pathspec change break nothing else.
- Integration/system/acceptance: not warranted. The end-to-end updater path
  (`t/cwf-manage-update-end-to-end.t`) already commits its tree clean before
  `update`; this fix only changes which paths the pre-flight check ignores, and the
  unit level exercises that decision directly and more cheaply.

### Test Coverage Targets
- **Critical path** (the fix): 100% — both the lock-excluded-clean case and the
  exclusion-is-exact case are covered (TC-4, TC-5).
- **Regression**: existing TC-1..TC-3 keep passing; whole `t/` suite green.

## Test Cases
### Functional Test Cases (new subtests in `t/cwf-manage-check-clean-tree.t`)

- **TC-4 — lock-only tree is clean** (the bug reproducer)
  - **Given**: a `make_baseline_repo()` (committed, no `.gitignore`) with an
    untracked `.cwf/.update.lock` present and no other changes
  - **When**: `main::check_clean_tree($dir)` is called
  - **Then**: it returns without dying (`is($@, '', ...)`)
  - **Pre-fix**: FAILS — the lock surfaces as `?? .cwf/.update.lock` and the check dies
  - Sketch:
    ```perl
    subtest 'TC-4: tree dirty only by .cwf/.update.lock -> returns without dying' => sub {
        plan tests => 1;
        my $dir = make_baseline_repo();
        open my $lfh, '>', "$dir/.cwf/.update.lock" or die $!; close $lfh;
        eval { main::check_clean_tree($dir) };
        is($@, '', 'lock-only tree treated as clean');
    };
    ```

- **TC-5 — exclusion is exact, not over-broad** (the safety guard)
  - **Given**: a baseline repo with BOTH an untracked `.cwf/.update.lock` and an
    untracked real path `.cwf/notes.md`
  - **When**: `main::check_clean_tree($dir)` is called
  - **Then**: it dies, the message lists `notes.md`, and the message does **not**
    mention `.update.lock`
  - **Pre-fix**: the `unlike(... .update.lock ...)` assertion FAILS (the lock is
    listed); that assertion is what proves the exclusion is exact
  - Sketch:
    ```perl
    subtest 'TC-5: lock + real dirty path -> dies, lists real path only' => sub {
        plan tests => 3;
        my $dir = make_baseline_repo();
        open my $lfh, '>', "$dir/.cwf/.update.lock" or die $!; close $lfh;
        open my $nfh, '>', "$dir/.cwf/notes.md" or die $!; print $nfh "scratch\n"; close $nfh;
        eval { main::check_clean_tree($dir) };
        like($@,   qr{Working tree has uncommitted changes}, 'dies on the real dirty path');
        like($@,   qr{notes\.md},                            'lists the real untracked path');
        unlike($@, qr{\.update\.lock},                       'lock excluded from the dirty list');
    };
    ```

### Non-Functional Test Cases
- **Security (exclusion scope)**: TC-5's `unlike` assertion is the security check —
  it proves only the exact lock path is hidden and no sibling dirty path can slip
  through the clean-tree gate. No separate suite needed.
- **Integrity**: `cwf-manage validate` must report `validate: OK` after the source
  edit + same-commit hash refresh + perms restored to recorded `0700`.
- Performance/usability/reliability: not applicable to a one-pathspec change.

## Test Environment
### Setup Requirements
- Perl with `Test::More` (core); `git` on `PATH`. No network, no production config.
- All fixtures are `tempdir(CLEANUP => 1)` git repos created by `make_baseline_repo()`.

### Automation
- Single file: `prove t/cwf-manage-check-clean-tree.t`
- Targeted regression: `prove t/cwf-manage-*.t`
- Full suite: `prove -r t/`

## Validation Criteria
- [ ] TC-4 and TC-5 added; TC-4 (and TC-5's `unlike`) demonstrably fail pre-fix
- [ ] TC-1..TC-5 all pass post-fix
- [ ] `prove -r t/` green (no regression)
- [ ] `cwf-manage validate` → `validate: OK` (hash refreshed, perms at 0700)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
TC-4 and TC-5 added to `t/cwf-manage-check-clean-tree.t` exactly as specified.
Both demonstrably fail pre-fix (TC-4 dies on the lock; TC-5's `unlike` fails) and
pass post-fix. TC-1..TC-5 green; full suite 726 tests green; `validate: OK`. See
g-testing-exec.md for the recorded run.

## Lessons Learned
TC-5's `unlike`/`like` pair turned the over-broad-exclusion risk into an enforced
regression check. See j-retrospective.md.
