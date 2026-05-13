# Preserve template symlinks in cwf-manage - Implementation Plan
**Task**: 135 (bugfix)

## Task Reference
- **Task ID**: internal-135
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/135-preserve-template-symlinks-in-cwf-manage
- **Template Version**: 2.1

## Goal
Implement the two changes scoped in `c-design-plan.md`: (1) preserve symlinks in `copy_tree`, rejecting absolute or escaping targets; (2) add `CWF::Validate::Templates` and wire it into `cmd_validate`.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- **`.cwf/scripts/cwf-manage`** (~lines 22-38, use block): add `use File::Spec ();` (confirmed missing — grep shows zero imports of File::Spec) and `use CWF::Validate::Templates ();` (siblings use the bare-import pattern, not `require`).
- **`.cwf/scripts/cwf-manage`** (~lines 434-448): patch `copy_tree` callback. Open with explicit `lstat($_)`, add `-l _` branch (with target validation via `_escapes_src`) before `-d _` / file branches.
- **`.cwf/scripts/cwf-manage`** (~line 509-516): wire `CWF::Validate::Templates::validate($git_root)` into the `@all_violations` list in `cmd_validate`.
- **`.cwf/lib/CWF/Validate/Templates.pm`** (NEW): ~80-line module exporting `validate($git_root)`. Walks `.cwf/templates/<T>/` for each `T` in `CWF::WorkflowFiles::V21::supported_types()`, runs the three-part check, returns violation hashrefs with `category => 'TEMPLATES'`. **No `FindBin`/`use lib`**: siblings rely on the parent script's `lib` setup (verified — none of `Config`, `Workflow`, `Consistency`, `Security`, `PerlConventions` import FindBin).

### Supporting Changes
- **`.cwf/security/script-hashes.json`**: add a `lib` entry for `CWF::Validate::Templates`. The `lib` section has mixed `permissions`-present/absent entries (e.g. `CWF::ArtefactHelpers` has it, `CWF::Backlog` does not) — `permissions` is optional in `lib`; omit it for the new entry to match the majority of sibling validators (none of `CWF::Validate::*` modules currently carry it; verify before commit). Workflow: hand-add a stub `{ "path": ".cwf/lib/CWF/Validate/Templates.pm", "sha256": "0" }` to the `lib` section, then run `.cwf/scripts/cwf-manage fix-security` to compute and replace the real hash.
- **`t/validate-templates.t`** (NEW): unit tests for the new validator. Cover: happy path (real installation), each of the three violation fields (`type`, `target`, `pool-name`), and `pool/` entries themselves being ignored. Use `File::Temp::tempdir(CLEANUP => 1)` for fixtures (pattern: see `t/validate-security.t`); tests MUST NOT mutate the real `.cwf/templates/` directory.
- **`t/cwf-manage-update.t`** (extend): add subtests for `copy_tree`. Three new cases — relative symlink preserved verbatim, absolute symlink target dies with "refusing absolute symlink target", escaping relative symlink dies with "refusing escaping symlink target". Decision is to *extend* the existing file rather than spawn `t/cwf-manage-update-symlinks.t`: the new tests still exercise `copy_tree` (which `cwf-manage-update.t` already covers) and the test-file granularity in `t/` is "one file per command/feature", not "one file per concern within a command".

### Out of Scope
- `.cwf/install-manifest.json`: not touched. Templates structure validation is not a manifest concern.
- `cwf-manage fix-security`: not extended to repair template symlinks. The recovery path is `cwf-manage update`, as decided in design Decision 4.
- Bulk re-symlinking of the present (broken) repo state: out of scope for this task. Once the fix lands in upstream and a user runs `cwf-manage update`, their install heals. The CWF source repo (this one) has the correct symlinks already.

## Implementation Steps

### Step 1: Audit symlinks in the source tree
- [ ] Enumerate every symlink under `.cwf/` and `.claude/skills/` in the upstream tree with `git ls-files -s -- .cwf .claude/skills | awk '$1 == "120000"'`. Confirm all targets are relative and resolve within the source tree — this is the precondition for Decision 1a not breaking the legitimate cases.
- [ ] Record findings in `f-implementation-exec.md` under Step 1 actuals.

### Step 2: Add `CWF::Validate::Templates`
- [ ] Create `.cwf/lib/CWF/Validate/Templates.pm`. Skeleton (canonical shape — mirror `CWF::Validate::Config`):
  ```perl
  package CWF::Validate::Templates;
  #
  # CWF::Validate::Templates - Validate task-type template symlink structure
  #
  # Checks that every entry under .cwf/templates/<type>/ (for each
  # supported task type) is a symlink resolving exactly to the
  # corresponding entry in .cwf/templates/pool/. Catches the
  # symlink-resolution bug in cwf-manage update (regular file where
  # symlink expected) and hand-edit errors (wrong pool target,
  # dangling link, escaping target).
  #
  # Returns a list of violation hashrefs, each with keys:
  #   category, file, field, actual, expected, fix
  #
  # Usage:
  #   use CWF::Validate::Templates qw(validate);
  #   my @violations = validate($git_root);
  #

  use strict;
  use warnings;
  use utf8;
  use Exporter 'import';
  use CWF::WorkflowFiles::V21 qw(supported_types);

  our @EXPORT_OK = qw(validate);

  sub validate {
      my ($git_root) = @_;
      my @violations;
      for my $type (supported_types()) {
          my $dir = "$git_root/.cwf/templates/$type";
          next unless -d $dir;                       # absent type-dir is out of scope
          opendir(my $dh, $dir)
              or die "[CWF] Validate::Templates: cannot opendir $dir: $!\n";
          for my $name (sort readdir($dh)) {
              next if $name eq '.' || $name eq '..';
              my $path = "$dir/$name";
              my $rel  = ".cwf/templates/$type/$name";
              lstat($path);
              if (!-l _) {
                  push @violations, _v($rel, 'type',
                      (-d _ ? 'directory' : 'regular file'),
                      "symlink to ../pool/$name",
                      "Re-run 'cwf-manage update' to restore symlinks, or 'ln -sfn ../pool/$name .cwf/templates/$type/$name'.");
                  next;
              }
              my $link = readlink($path)
                  // die "[CWF] Validate::Templates: readlink $path failed: $!\n";
              # Single pattern check: anything other than the exact form
              # "../pool/<name>" is a violation. This subsumes:
              #   - wrong basename within pool/  ("../pool/other.template")
              #   - subdirectory within pool/   ("../pool/sub/<name>")
              #   - escape outside pool/         ("../../etc/passwd")
              #   - absolute target              ("/etc/passwd")
              # The diagnostic actual/expected fields tell the user
              # exactly which malform appeared.
              my $expected_link = "../pool/$name";
              if ($link ne $expected_link) {
                  # Distinguish "dangling" (target doesn't exist when resolved
                  # relative to $dir) from "wrong target" (target exists but
                  # is not the expected pool entry) so the user gets a
                  # clearer hint.
                  my $resolved = "$dir/$link";
                  my $field    = (-e $resolved) ? 'pool-name' : 'target';
                  my $hint     = ($field eq 'target')
                      ? "Re-run 'cwf-manage update'."
                      : "Re-symlink: 'ln -sfn ../pool/$name .cwf/templates/$type/$name'.";
                  push @violations, _v($rel, $field,
                      $link, $expected_link, $hint);
              }
          }
          closedir $dh;
      }
      return @violations;
  }

  sub _v {
      my ($rel, $field, $actual, $expected, $fix) = @_;
      return { category => 'TEMPLATES', file => $rel,
               field => $field, actual => $actual,
               expected => $expected, fix => $fix };
  }

  1;
  ```
- [ ] Verify against `.cwf/docs/conventions/perl-git-paths.md` — file declares `use utf8;`, no shell-out.
- [ ] Note on the change from the design's three-part check: the implementation collapses checks (2) "target exists" and (3) "pool-name match" into a single exact-pattern check `$link eq "../pool/$name"`. This subsumes the escape and absolute-target detection (review finding) without losing diagnostic specificity — `actual`/`expected` strings tell the user precisely what diverged, and the `field` value still distinguishes "dangling" from "wrong target". The `type` check (1) is unchanged.

### Step 3: Wire validator into `cmd_validate`
- [ ] In `.cwf/scripts/cwf-manage`, add `use CWF::Validate::Templates ();` after the existing `use CWF::Validate::PerlConventions  ();` at line 37 (siblings use the bare-import pattern; do NOT use `require`).
- [ ] In `cmd_validate` (~line 509), add `CWF::Validate::Templates::validate($git_root),` to the `@all_violations` list. Diff is one line.

### Step 4: Patch `copy_tree`
- [ ] Add `use File::Spec ();` to the `use` block at the top of `.cwf/scripts/cwf-manage` (confirmed missing — `grep -n 'File::Spec' .cwf/scripts/cwf-manage` returns nothing).
- [ ] In `.cwf/scripts/cwf-manage:434-448`, replace the callback body with the "After" version in the "Code Changes" section below.
- [ ] Implement `_escapes_src($entry, $link, $src)` as a top-level helper sub (placed above `copy_tree` so File::Find's callback can call it). Single gate: resolve `$link` relative to `dirname($entry)` and check `abs2rel($resolved, $src)` for either a leading `..` segment or an absolute result. **Fold the absolute-target check inside** this helper — the security review flagged that having a separate `$link =~ m{^/}` check before `_escapes_src` invites future maintenance error (e.g. forgetting one when the other is updated). Use `File::Basename::dirname` (already imported via `use File::Basename;` at the top of cwf-manage) for the entry directory; no need for `splitpath`.
- [ ] Note for the implementer: `File::Spec->canonpath` is purely syntactic and does NOT resolve symlinks in the path itself. For this use case that is fine — the source tree is the upstream clone and trusted not to embed symlinks-in-symlinks; only the symlink *target* is validated. A short comment in `_escapes_src` should state this assumption.

### Step 5: Register new module in `script-hashes.json`
`fix-security` only updates *existing* entries (walks `data->{$section}` map, does not discover new files — verified in `cwf-manage:561-680`). The new module needs a hand-added stub first.

- [ ] Hand-edit `.cwf/security/script-hashes.json` to add to the `lib` section:
  ```json
  "CWF::Validate::Templates" : {
    "path"   : ".cwf/lib/CWF/Validate/Templates.pm",
    "sha256" : "0000000000000000000000000000000000000000000000000000000000000000"
  }
  ```
  (Match the no-`permissions` form used by other `CWF::Validate::*` entries — none of them carry `permissions`.)
- [ ] Run `.cwf/scripts/cwf-manage fix-security`. Confirm `git diff .cwf/security/script-hashes.json` shows only the `sha256` field changing from the placeholder to a real hash.
- [ ] Confirm `cwf-manage validate` is green after the manifest update.

### Step 6: Tests
Use `File::Temp::tempdir(CLEANUP => 1)` for all fixtures (pattern: see `t/validate-security.t`). Tests MUST NOT touch the real `.cwf/templates/` tree.

- [ ] Write `t/validate-templates.t` covering:
  - **Happy path** (against a fixture mirroring `.cwf/templates/{pool,feature}/` with correct symlinks): 0 violations.
  - **`type` violation**: regular file in place of symlink → `field => 'type'`.
  - **`target` violation**: symlink to a non-existent pool entry (e.g. `../pool/nonexistent`) → `field => 'target'`.
  - **`pool-name` violation**: symlink to a wrong-but-existing pool entry (e.g. `../pool/c-design-plan.md.template` where name is `a-task-plan.md.template`) → `field => 'pool-name'`.
  - **Escape attempt**: symlink to `/etc/passwd` or `../../etc/passwd` → expected reported as `pool-name` or `target` (the exact-pattern check rejects both); `actual` field shows the bogus link verbatim. Document the resolution in the test comments.
  - **`pool/` itself ignored**: regular files inside `pool/` do not produce violations (the validator only iterates `supported_types()`, which does not include `pool`).
- [ ] Extend `t/cwf-manage-update.t` with subtests for `copy_tree`. (Decided against `t/cwf-manage-update-symlinks.t` — existing test-file granularity in `t/` is one file per command/feature, not one file per concern within a command.)
  - Source tree containing a relative symlink (e.g. `pool/X` + `feature/X -> ../pool/X`) → `copy_tree` produces a symlink with the same target at the destination (`-l` and `readlink` match).
  - Source tree containing an absolute-target symlink → `copy_tree` dies with the expected `refusing escaping symlink target` message (absolute now folded into `_escapes_src`; assert the message wording matches what `_escapes_src` returns).
  - Source tree containing an escaping relative symlink (`../../etc/foo`) → `copy_tree` dies with the same `refusing escaping symlink target` message.
- [ ] Add a one-line comment in the escape-attempt tests explaining why constructing `../../etc/foo` as a test input is safe: the symlink is never followed, only validated; the temp fixture is cleaned up regardless.

### Step 7: Run existing suite for regressions
- [ ] `prove -rv t/` — every test must pass.
- [ ] `cwf-manage validate` — must pass.
- [ ] Manually inspect: `ls -la .cwf/templates/feature/` shows symlinks. Manually break one (`rm .cwf/templates/feature/a-task-plan.md.template; touch .cwf/templates/feature/a-task-plan.md.template`) → `cwf-manage validate` reports a `TEMPLATES` violation with `field: type`. Repair with `ln -sfn ../pool/a-task-plan.md.template .cwf/templates/feature/a-task-plan.md.template` → `validate` passes again. Then *undo the manual break* before committing.

### Step 8: Documentation
- [ ] No user-facing docs change required (CLI surface unchanged).
- [ ] Code comments: short comment on the `_resolves_outside_src` helper explaining the security purpose. No multi-line docstrings (per project convention).

## Code Changes

### `copy_tree` — Before (`.cwf/scripts/cwf-manage:434-448`)
```perl
sub copy_tree {
    my ($src, $dst) = @_;
    find(sub {
        my $rel = $File::Find::name;
        $rel =~ s/^\Q$src\E//;
        my $target = "$dst$rel";
        if (-d) {
            make_path($target) unless -d $target;
        } else {
            copy($_, $target)
                or die_msg("Failed to copy $_ to $target: $!");
        }
    }, $src);
    return;
}
```

### `copy_tree` — After
```perl
# _escapes_src — single gate for symlink-target safety in copy_tree.
# Returns true if $link (the value of readlink on an entry whose path
# is $entry, walked from source root $src) is either absolute or
# resolves outside $src. Used to refuse upstream symlinks that would
# write out-of-tree references into the installed .cwf/.
#
# Note: File::Spec->canonpath is syntactic only — it does not resolve
# symlinks embedded in the path itself. That is fine here: $src is the
# upstream clone, trusted not to contain symlinks-in-paths; only the
# symlink target value is the untrusted input we are gating.
sub _escapes_src {
    my ($entry, $link, $src) = @_;
    my $entry_dir = File::Basename::dirname($entry);
    my $abs       = File::Spec->rel2abs($link, $entry_dir);
    my $rel       = File::Spec->abs2rel($abs, $src);
    return $rel =~ m{^\.\.(/|\z)} || File::Spec->file_name_is_absolute($rel);
}

sub copy_tree {
    my ($src, $dst) = @_;
    find(sub {
        my $rel = $File::Find::name;
        $rel =~ s/^\Q$src\E//;
        my $target = "$dst$rel";
        lstat($_);
        if (-l _) {
            my $link = readlink($_)
                // die_msg("readlink failed on $_: $!");
            die_msg("refusing escaping symlink target: $_ -> $link")
                if _escapes_src($_, $link, $src);
            symlink($link, $target)
                or die_msg("Failed to create symlink $target -> $link: $!");
        } elsif (-d _) {
            make_path($target) unless -d $target;
        } else {
            copy($_, $target)
                or die_msg("Failed to copy $_ to $target: $!");
        }
    }, $src);
    return;
}
```
Notes:
- The separate `$link =~ m{^/}` check (earlier draft) has been folded into `_escapes_src` via `File::Spec->file_name_is_absolute($rel)` after `abs2rel` — single gate, single failure-message wording, fewer maintenance footguns.
- `File::Basename::dirname` is already imported by cwf-manage (`use File::Basename;` at line 22).
- `File::Spec` must be added to the use block (Step 4 first action).

### `cmd_validate` — Before (`.cwf/scripts/cwf-manage:509-516`)
```perl
my @all_violations = (
    CWF::Validate::Config::validate($git_root),
    CWF::Validate::Workflow::validate($git_root),
    CWF::Validate::Consistency::validate($git_root),
    CWF::Validate::Security::validate($git_root),
    CWF::Validate::Security::validate_install_manifest($git_root),
    CWF::Validate::PerlConventions::validate($git_root),
);
```

### `cmd_validate` — After
```perl
my @all_violations = (
    CWF::Validate::Config::validate($git_root),
    CWF::Validate::Workflow::validate($git_root),
    CWF::Validate::Consistency::validate($git_root),
    CWF::Validate::Security::validate($git_root),
    CWF::Validate::Security::validate_install_manifest($git_root),
    CWF::Validate::PerlConventions::validate($git_root),
    CWF::Validate::Templates::validate($git_root),
);
```
(plus a corresponding `require CWF::Validate::Templates;` or `use CWF::Validate::Templates;` near the other validator imports — match what siblings do)

## Test Coverage
**See e-testing-plan.md for the complete test plan.** Summary: `t/validate-templates.t` for the validator unit, an extension to `t/cwf-manage-update.t` (or a new `t/cwf-manage-update-symlinks.t`) for the `copy_tree` regression and the two refusal paths.

## Validation Criteria
**See e-testing-plan.md for full validation criteria.** At minimum, before marking implementation complete:
- All existing tests pass (`prove -rv t/`).
- New tests pass.
- `cwf-manage validate` passes on this repo.
- Manual break-and-fix smoke test (Step 7) shows the validator catches a regular-file-where-symlink-expected.

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates, marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 135
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
