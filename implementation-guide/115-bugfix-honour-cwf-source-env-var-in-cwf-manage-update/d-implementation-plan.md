# Honour CWF_SOURCE env var in cwf-manage update - Implementation Plan
**Task**: 115 (bugfix)

## Task Reference
- **Task ID**: internal-115
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/115-honour-cwf-source-env-var-in-cwf-manage-update
- **Template Version**: 2.1

## Goal
Add `resolve_source` helper to `.cwf/scripts/cwf-manage`, route `cmd_update` and `cmd_list_releases` through it, update logging and the help block, and cover the helper with a new subtest file.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `.cwf/scripts/cwf-manage` — add `resolve_source` sub; modify `cmd_update`, `cmd_list_releases`, `cmd_help`, and the file-header comment block to honour and document `CWF_SOURCE`.

### Supporting Changes
- `t/cwf-manage-resolve-source.t` — new file. Subtests for `resolve_source` covering env-set, env-empty, env-unset, file-empty, file-missing, and both-missing cases. Follows the existing harness pattern from `t/cwf-manage-list-releases.t` (`do $SCRIPT` + `main::sub_name`). Local-overrides `main::die_msg` to convert `exit 1` into a catchable `die`, so failure paths can be asserted with `eval {} ; like $@`.

No changes to: `read_version_file`, `write_version_file`, `cmd_status`, `cmd_rollback`, validation modules, install.bash, `.cwf/version` schema.

## Implementation Steps

### Step 1: Setup
- [ ] Confirm task branch is checked out and clean (`git status`)
- [ ] Re-read approved design (`c-design-plan.md`) — especially Decisions 1, 3, 4 and the Edge cases list

### Step 2: Test first (TDD)
- [ ] Create `t/cwf-manage-resolve-source.t` with the harness pattern from `t/cwf-manage-list-releases.t:15-28`
- [ ] In the test file, after `do $SCRIPT`, override `*main::die_msg = sub { die "[CWF] ERROR: @_\n" };` so failure cases are catchable via `eval`
- [ ] Add subtests covering every edge case from the design's helper interface (see Test Coverage below for the full list)
- [ ] Run `prove t/cwf-manage-resolve-source.t` — expect failures (helper does not exist yet)

### Step 3: Add the helper
- [ ] Add a new section header `# --- Source resolution ----...---` after the `# --- Version file ---` block (i.e. after `write_version_file`, before `# --- Ref resolution ---`)
- [ ] Add `sub resolve_source` exactly as shown in "Code Changes — Helper" below
- [ ] Run `prove t/cwf-manage-resolve-source.t` — all subtests pass

### Step 4: Wire into `cmd_list_releases`
- [ ] Replace line 124 (`my $source = $v{cwf_source} or die_msg(...)`) with the two-element-list call shown below
- [ ] Update line 127 to include the `(from: $origin)` suffix
- [ ] Run `prove t/cwf-manage-list-releases.t` — must still pass (existing subtests are pure-function and unaffected)

### Step 5: Wire into `cmd_update`
- [ ] Replace line 201 with the two-element-list call shown below
- [ ] Update line 208 (`log_msg("Cloning CWF source...")`) to include source and origin
- [ ] Verify lines 232–236 are untouched: `cmd_update` must continue to *not* write `cwf_source` back to `.cwf/version` (Decision 2)

### Step 6: Update help and header documentation
- [ ] Add an `Environment:` block to `cmd_help`'s heredoc, between the `Commands:` and `Examples:` sections
- [ ] Add a one-line `# Environment:` entry to the file-header comment block (lines 6–11) mirroring `scripts/install.bash:10–15`

### Step 7: Smoke test
- [ ] `prove t/` — full test suite passes
- [ ] `.cwf/scripts/cwf-manage validate` — passes
- [ ] `.cwf/scripts/cwf-manage help | grep -A2 Environment` — confirms help text updated
- [ ] Manual: `CWF_SOURCE=file:///tmp/nonexistent .cwf/scripts/cwf-manage update 2>&1 | head -3` — confirms log shows `(from: CWF_SOURCE env var)` then fails on the non-existent path
- [ ] Manual: unset `CWF_SOURCE`; `.cwf/scripts/cwf-manage list-releases 2>&1 | head -1` — confirms log shows `(from: .cwf/version)`

### Step 8: Validation
- [ ] All success-criteria checkboxes from `a-task-plan.md` verifiable
- [ ] `.cwf/version` `cwf_source` field unchanged after a (manual) env-driven update against a real local source — manual smoke test, recorded in `g-testing-exec.md`

## Code Changes

### Helper — new sub in `.cwf/scripts/cwf-manage`

Insert after `write_version_file` (line 75), before `# --- Ref resolution ---` (line 77):

```perl
# --- Source resolution -------------------------------------------------------

sub resolve_source {
    my ($v) = @_;
    my $env  = $ENV{CWF_SOURCE};
    my $file = $v->{cwf_source};
    return ($env,  'CWF_SOURCE env var') if defined $env  && $env  ne '';
    return ($file, '.cwf/version')        if defined $file && $file ne '';
    die_msg("No CWF source: CWF_SOURCE unset and cwf_source missing/empty in .cwf/version");
}
```

### `cmd_list_releases` — line 121 onward

**Before** (lines 121–127):
```perl
sub cmd_list_releases {
    my ($git_root, $show_all) = @_;
    my %v = read_version_file($git_root);
    my $source  = $v{cwf_source}  or die_msg("No cwf_source in .cwf/version");
    my $current = $v{cwf_version} // '';

    log_msg("Available releases from $source");
```

**After**:
```perl
sub cmd_list_releases {
    my ($git_root, $show_all) = @_;
    my %v = read_version_file($git_root);
    my ($source, $origin) = resolve_source(\%v);
    my $current = $v{cwf_version} // '';

    log_msg("Available releases from $source (from: $origin)");
```

(Lines 130 and 137 — the `Failed to query remote tags from $source` and `No version tags found at $source` errors — remain unchanged. They already interpolate `$source`, which is now correctly the env-aware value.)

### `cmd_update` — line 195 onward

**Before** (lines 199–210):
```perl
    my %v = read_version_file($git_root);
    my $method = $v{cwf_method} or die_msg("No cwf_method in .cwf/version");
    my $source = $v{cwf_source} or die_msg("No cwf_source in .cwf/version");

    log_msg("Updating CWF (method: $method, ref: $ref)");

    # Clone source to temp dir
    my $tmpdir = tempdir(CLEANUP => 1);
    my $clone_dir = "$tmpdir/cwf-source";
    log_msg("Cloning CWF source...");
    system("git", "clone", "--quiet", $source, $clone_dir) == 0
        or die_msg("Failed to clone $source");
```

**After**:
```perl
    my %v = read_version_file($git_root);
    my $method = $v{cwf_method} or die_msg("No cwf_method in .cwf/version");
    my ($source, $origin) = resolve_source(\%v);

    log_msg("Updating CWF (method: $method, ref: $ref)");

    # Clone source to temp dir
    my $tmpdir = tempdir(CLEANUP => 1);
    my $clone_dir = "$tmpdir/cwf-source";
    log_msg("Cloning CWF source from $source (from: $origin)...");
    system("git", "clone", "--quiet", $source, $clone_dir) == 0
        or die_msg("Failed to clone $source");
```

Lines 232–236 (`write_version_file` block) are explicitly **not modified** — preserving Decision 2.

### `cmd_help` — usage block

**Before** (within the heredoc, lines 386–394):
```
  validate         Validate config and workflow files; exit non-zero on violations
  help             Show this help message

Examples:
  cwf-manage status
```

**After**:
```
  validate         Validate config and workflow files; exit non-zero on violations
  help             Show this help message

Environment:
  CWF_SOURCE       Override CWF source repo URL for this invocation
                   (default: cwf_source from .cwf/version)

Examples:
  cwf-manage status
```

### File-header comment — lines 5–12

**Before**:
```
# Usage:
#   cwf-manage status          Show installed version and method
#   cwf-manage list-releases   List available tagged releases
#   cwf-manage update [ref]    Update to ref (default: latest)
#   cwf-manage rollback <ref>  Revert to a previous version
#   cwf-manage help            Show this help
#
```

**After**:
```
# Usage:
#   cwf-manage status          Show installed version and method
#   cwf-manage list-releases   List available tagged releases
#   cwf-manage update [ref]    Update to ref (default: latest)
#   cwf-manage rollback <ref>  Revert to a previous version
#   cwf-manage help            Show this help
#
# Environment:
#   CWF_SOURCE   Override CWF source repo URL (default: cwf_source from .cwf/version)
#
```

### Test file — new `t/cwf-manage-resolve-source.t` (skeleton; full subtests in e-testing-plan)

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

my $SCRIPT = File::Spec->catfile(
    $FindBin::Bin, '..', '.cwf', 'scripts', 'cwf-manage'
);

# Load the script with @ARGV = ('help') to keep main() side-effect-free.
{
    local @ARGV = ('help');
    open(my $saved, '>&', \*STDOUT) or die "Cannot dup STDOUT: $!";
    open(STDOUT, '>', File::Spec->devnull()) or die "Cannot silence STDOUT: $!";
    do $SCRIPT;
    open(STDOUT, '>&', $saved) or die "Cannot restore STDOUT: $!";
}
die "Failed to load $SCRIPT: $@" if $@;

# Override die_msg so failure paths are catchable via eval.
no warnings 'redefine';
*main::die_msg = sub { die "[CWF] ERROR: @_\n" };

# subtests live here — see e-testing-plan.md for the full case list

done_testing();
```

## Test Coverage
**See e-testing-plan.md for the full subtest list and acceptance.**

Summary of cases the new test file must cover (one subtest each):
- env set + file present → returns env value, origin `'CWF_SOURCE env var'`
- env empty + file present → returns file value, origin `'.cwf/version'`
- env unset + file present → returns file value, origin `'.cwf/version'`
- env empty + file empty → dies with the documented message
- env unset + file missing key → dies
- env set + file missing key → returns env value (env still wins when file is absent)

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results.**

This task is complete when:
- All subtests in `t/cwf-manage-resolve-source.t` pass
- Existing tests (`prove t/`) still pass
- `cwf-manage validate` passes on the modified script
- Manual smoke tests in Step 7 produce the expected log lines
- `.cwf/version` `cwf_source` field is unchanged after a successful env-driven update

### Plan-review summary
Three parallel Explore subagents reviewed for Improvements / Misalignment / Robustness.

**Findings**: No actionable changes. All three reviews concluded the plan is sound:
- **Improvements**: helper reuses `resolve_*` naming convention; test harness reuses `t/cwf-manage-list-releases.t` pattern; no over-abstraction. No changes.
- **Misalignment**: helper signature, placement, and routing all consistent with design. The `*main::die_msg` symbol-table override is new to `t/` (no existing test overrides `main::` symbols), but uses standard Perl mechanisms with no new test-framework dependencies — accepted as the simplest way to make `exit 1` paths catchable. No changes.
- **Robustness**: All `cwf_source` call sites enumerated and covered (lines 116/124/201; 116 unchanged per Decision 5; rollback inherits via `cmd_update`). Two optional UX hints surfaced (env-aware error in `read_version_file`, env-aware note in `cmd_status`) — both already mitigated by Decision 4's always-log-origin behaviour, both would expand modification surface beyond design scope. Skipped.

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
**Next Action**: /cwf-testing-plan 115
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
