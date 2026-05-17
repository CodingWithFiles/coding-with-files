# retire bootstraps missing CHANGELOG task entry - Implementation Plan
**Task**: 147 (feature)

## Task Reference
- **Task ID**: internal-147
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/147-retire-bootstraps-missing-changelog-task-entry
- **Template Version**: 2.1

## Goal
Implement the two new `CWF::Backlog` helpers (`resolve_task_title_from_dir`, `bootstrap_changelog_entry`) and the one-branch change to `cmd_retire` per c-design D1-D7.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes

- `.cwf/lib/CWF/Backlog.pm`:
  - Add `use CWF::Common qw(find_git_root)` and `use CWF::WorkflowFiles qw(load_config)` to the existing `use` block (or add to existing `CWF::Common` import if already present — check before editing).
  - Add `@EXPORT_OK` entries: `resolve_task_title_from_dir`, `bootstrap_changelog_entry`.
  - Add private `_load_supported_types()`. Calls `CWF::WorkflowFiles::load_config()` (already cached at the loader level, already git-root-rooted, returns a hashref with `supported-task-types`). Filters each value through `qr/\A[a-z][a-z0-9-]{0,31}\z/` (Security F1 — constrain values that are about to enter a regex alternation). If `load_config` dies → propagate (loud failure — Robustness F2). If the filtered list is empty → die with `[CWF] ERROR: backlog-manager: cwf-project.json has no usable 'supported-task-types' values`. Cache at package scope (`my @_SUPPORTED_TYPES`).
  - Add `_scan_task_dirs($task_num)` (private):
    - Resolve base path: `my $base = find_git_root() . '/implementation-guide'` (Robustness F1).
    - `opendir(my $dh, $base) or die "[CWF] ERROR: backlog-manager: cannot read $base/: $!\n"`.
    - Build regex: `my $types = join('|', map { quotemeta } _load_supported_types()); my $re = qr/\A\Q$task_num\E-(?:$types)-(.+)\z/;`.
    - Filter entries: matching regex AND `!-l "$base/$_"` AND `-d _` (cached stat). Symlink-reject is cosmetic — no I/O on these paths follows — but documented to keep the scan future-proof if a later helper grows to read from inside the matched directory (Robustness F8, Security F5).
    - Return list of matching basenames.
  - Add `resolve_task_title_from_dir($task_num)`:
    1. Defensive: `die_user`-style die if `$task_num !~ /^\d+$/` (Security F2).
    2. Call `_scan_task_dirs`.
    3. On 0 → die with zero-match message (D7).
    4. On >1 → die with multi-match message, single-quoting each basename (D7, Security F4).
    5. On 1 → re-apply the scan regex to extract `<slug>` from the single basename. `(my $title = $slug) =~ tr/-/ /;` (in-place, no `/r` — Robustness F9).
    6. Validate the title unconditionally:
       - non-empty
       - no `:` (would break `^## Task[ \t]+(\d+):` at `Backlog.pm:223`)
       - no control characters: `[\x00-\x08\x0a-\x1f]` (matches `_check_heading_control` at `Backlog.pm:204-213`).
       - The basename arrived pre-decoded under `PERL5OPT=-CDSLA`; any invalid UTF-8 bytes are already U+FFFD-replaced by the time `readdir` returns. The title-validation rules above catch mojibake indirectly (U+FFFD is allowed in titles per `_check_heading_control`'s class, but the parser regex tolerates it — no explicit `utf8::valid` needed; Security F4).
       - Any failure → die with `[CWF] ERROR: backlog-manager: derived title '$title' violates CHANGELOG heading constraints ($bad)`.
    7. Return title.
  - Add `bootstrap_changelog_entry($tree, $task_num, $title)`:
    1. Build the entry hashref directly, matching the parser shape at `Backlog.pm:235-246` exactly:
       ```perl
       my $entry = {
           type             => 'Task',
           task_num         => $task_num + 0,
           title            => $title,
           header_lineno    => undef,
           metadata         => [
               { key => 'Status', value => 'In Progress',       lineno => undef },
               { key => 'Impact', value => 'Task in progress.', lineno => undef },
           ],
           subsections      => [
               { name => 'Retired Backlog Items', lineno => undef, body_raw => [] },
           ],
           body_raw         => [],
           body_before_meta => 0,
       };
       ```
    2. `unshift @{$tree->{entries}}, $entry` (D4, Improvements F3).
    3. Return `$entry`.
    - **Why direct construction, not parse-the-stub**: shape is fixed and fully visible at `Backlog.pm:235-246`; `_serialize_entry` at `:329-366` consumes exactly these keys; no parser-private call (`_parse_tree` is private — Misalignment F5); no preamble guesswork; no parser-error-array gap (Robustness F4). The serialiser then re-emits these in the canonical byte form; round-trip property covered in tests.

- `.cwf/scripts/command-helpers/backlog-manager`:
  - Add `resolve_task_title_from_dir bootstrap_changelog_entry` to the existing `use CWF::Backlog qw(...)` block at `backlog-manager:27-38` (the only such block — Misalignment F7).
  - Replace the `die_user` at the `find_changelog_entry_by_task_num` callsite (currently lines 464-465) with the D6 pattern:
    ```perl
    my ($cl_entry, $cl_idx) = find_changelog_entry_by_task_num($cl_tree, $task);
    unless (defined $cl_entry) {
        my $title = resolve_task_title_from_dir($task);
        $cl_entry = bootstrap_changelog_entry($cl_tree, $task, $title);
    }
    ```
  - No other changes in `cmd_retire`. No changes to other subcommands. No changes to `usage_retire`.

### Supporting Changes

- `t/backlog-bootstrap-changelog.t` (new): directory-scan resolver tests. Uses `File::Temp::tempdir`, `git init`, populates `implementation-guide/N-feature-foo/` and `cwf-project.json`, `chdir` into it, calls `resolve_task_title_from_dir`. Pattern matches `t/backlog-roundtrip-live.t` for fixture handling. End-to-end `cmd_retire` test (which needs `find_git_root` to point inside the tmp dir) also lives here.
- `t/backlog-tree-mutators.t` (add cases): tree-only tests for `bootstrap_changelog_entry`. Pure mutator — no filesystem needed.
- `BACKLOG.md`: add follow-up entry "Unify implementation-guide directory-scan helpers across CWF::Backlog and CWF::TaskContextInference" (c-design D1 Out of Scope). Use `/cwf-backlog-manager` skill.
- No changes to `.cwf/docs/`, `CHANGELOG.md` (until retrospective), or skill files. `cwf-manage validate` post-commit catches any inadvertent format drift.

## Implementation Steps

### Step 1: Read existing test patterns
- [ ] Read `t/backlog-roundtrip-live.t` and `t/backlog-tree-mutators.t` to confirm fixture/Test::More style.
- [ ] Run `prove t/backlog-tree-mutators.t t/backlog-tree-parse.t` to confirm the current suite is green pre-change.

### Step 2: Add `_load_supported_types` + `_scan_task_dirs` + `resolve_task_title_from_dir` to `Backlog.pm`
- [ ] Add imports (`find_git_root`, `load_config`).
- [ ] Add `@EXPORT_OK` entries.
- [ ] Implement `_load_supported_types` (Security F1 strict filter, loud failure).
- [ ] Implement `_scan_task_dirs` (git-root-rooted, symlink-rejecting).
- [ ] Implement `resolve_task_title_from_dir` (full FR4 title validation, D7 errors).
- [ ] Add unit-test cases to the new `t/backlog-bootstrap-changelog.t` covering zero / one / multi-match, slug-with-metacharacters, ASCII edge cases.
- [ ] Run `prove t/backlog-bootstrap-changelog.t`.

### Step 3: Add `bootstrap_changelog_entry` to `Backlog.pm`
- [ ] Implement direct hashref construction + `unshift`.
- [ ] Add tree-mutator test cases to `t/backlog-tree-mutators.t`: empty-tree bootstrap, bootstrap-then-existing-entry-retire, round-trip property (parse → serialise → parse, deep-compare).
- [ ] Run `prove t/backlog-tree-mutators.t`.

### Step 4: Wire into `cmd_retire`
- [ ] Add the two helper names to the `use CWF::Backlog qw(...)` block (no line-number reference; grep for the block).
- [ ] Replace the `die_user` branch at `find_changelog_entry_by_task_num`'s callsite with the D6 four-line pattern.
- [ ] Verify the full file still passes `perl -wc` (covered by `cwf-manage validate` post-commit; no separate compile-check command — per [[feedback_no_perl_c_check]]).

### Step 5: Add end-to-end test
- [ ] Extend `t/backlog-bootstrap-changelog.t` with an end-to-end case: `tempdir → git init → write minimal `cwf-project.json` and `implementation-guide/<N>-feature-foo/` and `BACKLOG.md` with a target entry and empty `CHANGELOG.md` → invoke `backlog-manager retire --exact-title=... --task=N` via `system()` → assert CHANGELOG now contains `## Task N: foo`, the stub metadata, and the appended block. Re-invoke with a second `--id`/`--exact-title` to exercise the existing-entry path. Tmp dir name follows `/tmp/-home-matt-repo-coding-with-files-task-147-<suffix>` per [[tmp-paths]] (Security F6) — use `File::Temp::tempdir(TEMPLATE=>'-home-matt-repo-coding-with-files-task-147-XXXXXX', DIR=>'/tmp', CLEANUP=>1)`.
- [ ] Run `prove t/backlog-bootstrap-changelog.t`.

### Step 6: Run full Backlog test suite + validator
- [ ] `prove t/backlog-*.t` — all green.
- [ ] `backlog-manager validate` — exit 0 against the live BACKLOG/CHANGELOG.

### Step 7: Add BACKLOG follow-up entry
- [ ] Use `/cwf-backlog-manager` to add the "Unify implementation-guide directory-scan helpers" entry (per c-design D1 Out of Scope).

### Step 8: Commit
- [ ] Single checkpoint commit for the implementation step.
- [ ] Commit message follows repo convention (Linux-kernel style, `Co-developed-by:` trailer per `docs/conventions/commit-messages.md`).

## Code Changes

### `cmd_retire` — Before (backlog-manager:464-465)
```perl
my ($cl_entry) = find_changelog_entry_by_task_num($cl_tree, $task)
    or die_user("Task $task has no CHANGELOG entry; create the entry first or pick a different --task");
```

### `cmd_retire` — After
```perl
my ($cl_entry, $cl_idx) = find_changelog_entry_by_task_num($cl_tree, $task);
unless (defined $cl_entry) {
    my $title = resolve_task_title_from_dir($task);
    $cl_entry = bootstrap_changelog_entry($cl_tree, $task, $title);
}
```

### New helpers in `Backlog.pm` — Skeleton (final form during exec)
```perl
# Cached at package scope; loaded lazily on first call to _scan_task_dirs.
my @_SUPPORTED_TYPES;

sub _load_supported_types {
    return @_SUPPORTED_TYPES if @_SUPPORTED_TYPES;
    my $cfg = load_config();  # CWF::WorkflowFiles — git-root-rooted, cached, dies on read/parse failure
    my @raw = @{ $cfg->{'supported-task-types'} // [] };
    @_SUPPORTED_TYPES = grep { /\A[a-z][a-z0-9-]{0,31}\z/ } @raw;
    die "[CWF] ERROR: backlog-manager: cwf-project.json has no usable "
      . "'supported-task-types' values\n" unless @_SUPPORTED_TYPES;
    return @_SUPPORTED_TYPES;
}

sub _scan_task_dirs {
    my ($task_num) = @_;
    my $base = find_git_root() . '/implementation-guide';
    opendir(my $dh, $base)
        or die "[CWF] ERROR: backlog-manager: cannot read $base/: $!\n";
    my @entries = grep { !/^\.\.?$/ } readdir $dh;
    closedir $dh;
    my $types = join('|', map { quotemeta } _load_supported_types());
    my $re = qr/\A\Q$task_num\E-(?:$types)-(.+)\z/;
    # Symlink-reject: cosmetic only (no I/O on these paths follows), kept so a
    # later helper that reads inside the matched dir inherits the discipline.
    return grep { /$re/ && !-l "$base/$_" && -d _ } @entries;
}

sub resolve_task_title_from_dir {
    my ($task_num) = @_;
    die "[CWF] ERROR: backlog-manager: invalid task num '"
      . (defined $task_num ? $task_num : '<undef>') . "'\n"
        unless defined $task_num && $task_num =~ /^\d+$/;
    my @matches = _scan_task_dirs($task_num);
    if (@matches == 0) {
        die "[CWF] ERROR: backlog-manager: cannot bootstrap CHANGELOG entry "
          . "for Task $task_num: no directory matching "
          . "'implementation-guide/$task_num-*/' found\n";
    }
    if (@matches > 1) {
        my $list = join(', ', map { "'$_'" } @matches);
        die "[CWF] ERROR: backlog-manager: cannot bootstrap CHANGELOG entry "
          . "for Task $task_num: multiple directories match ($list); "
          . "manually create '## Task $task_num: <title>' in CHANGELOG.md "
          . "first, then retry\n";
    }
    my $types = join('|', map { quotemeta } _load_supported_types());
    (my $slug = $matches[0]) =~ s/\A\Q$task_num\E-(?:$types)-//;
    (my $title = $slug) =~ tr/-/ /;
    my $bad;
    if    (length($title) == 0)               { $bad = 'empty' }
    elsif ($title =~ /:/)                     { $bad = 'contains :' }
    elsif ($title =~ /[\x00-\x08\x0a-\x1f]/)  { $bad = 'contains control character' }
    if ($bad) {
        die "[CWF] ERROR: backlog-manager: derived title '$title' violates "
          . "CHANGELOG heading constraints ($bad)\n";
    }
    return $title;
}

sub bootstrap_changelog_entry {
    my ($tree, $task_num, $title) = @_;
    my $entry = {
        type             => 'Task',
        task_num         => $task_num + 0,
        title            => $title,
        header_lineno    => undef,
        metadata         => [
            { key => 'Status', value => 'In Progress',       lineno => undef },
            { key => 'Impact', value => 'Task in progress.', lineno => undef },
        ],
        subsections      => [
            { name => 'Retired Backlog Items', lineno => undef, body_raw => [] },
        ],
        body_raw         => [],
        body_before_meta => 0,
    };
    unshift @{$tree->{entries}}, $entry;
    return $entry;
}
```

## Test Coverage
**See e-testing-plan.md for complete test plan.** Summary: 9 ACs mapped to test cases including the bootstrap-path happy path, both error paths (zero / multi-match), title validation failure cases (synthetic dirs with `:`, control chars), round-trip property, dedup re-run, symlink/integer-guard preservation, and slug-with-metacharacter resilience.

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results.** Summary: all 9 ACs pass; `backlog-manager validate` exits 0 on post-bootstrap CHANGELOG; existing test suite unchanged; `cwf-manage validate` (post-commit hook) clean.

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
**Next Action**: /cwf-testing-plan 147
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
