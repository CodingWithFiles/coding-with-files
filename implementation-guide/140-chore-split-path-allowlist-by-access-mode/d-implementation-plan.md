# Split path-allowlist by access mode - Implementation Plan
**Task**: 140 (chore)

## Task Reference
- **Task ID**: internal-140
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/140-split-path-allowlist-by-access-mode
- **Template Version**: 2.1

## Goal
Replace `validate_path_allowlist` with two access-mode-specific functions
(`validate_write_path_allowlist`, `validate_read_path_allowlist`) and migrate
all three call sites. The `validate_temp_path_allowlist` variant from the
BACKLOG entry is **deferred** — neither candidate caller (`cwf-checkpoint-commit`,
`security-review-changeset`) writes Perl-side temp files today (verified by
grep), so adding it now would be dead code. Re-open as a separate BACKLOG entry
if a future caller materialises.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `.cwf/lib/CWF/ArtefactHelpers.pm` — Add `validate_write_path_allowlist` (rename of current behaviour) and `validate_read_path_allowlist` (existence + readability check, no prefix list). Remove `validate_path_allowlist`. Update `@EXPORT_OK`.
- `.cwf/scripts/command-helpers/cwf-apply-artefacts:42,208` — Switch import + call to `validate_write_path_allowlist`. Both `source` and `dest` paths are derived from a potentially-tampered manifest, so both keep write-style validation.
- `.cwf/scripts/command-helpers/cwf-claude-settings-merge:20,63` — Switch import + call to `validate_write_path_allowlist`. The path comes from the script-hashes manifest, same threat model.
- `.cwf/scripts/command-helpers/backlog-manager:26,131,304-307` — Switch import + call to `validate_read_path_allowlist`. Drop the `['.cwf/', '.claude/', 'docs/', 'implementation-guide/', 't/']` prefix list. Drop the now-redundant `die_path("body file does not exist: $path") unless -f $path;` follow-up (the validator enforces it). Update the `--body-file` help text at line 131 ("repo-relative path; outside-repo paths rejected.") to reflect the new behaviour, e.g. "any readable file path (absolute or relative)."

### Supporting Changes
- `t/artefacthelpers.t:15-22, 83-111` — Replace `validate_path_allowlist` test block with two blocks (one per new function). Remove the old import.
- `t/backlog-manager-add.t` (or equivalent existing add-flow test) — Add a positive test exercising `--body-file=/tmp/cwf-test-XXXXXX/body.md`. If no current test covers the add+body-file path, add one in `t/backlog-manager-body-file.t`.
- `.cwf/security/script-hashes.json` — Regenerate after script edits via `.cwf/scripts/cwf-manage fix-security`.

## Implementation Steps

### Step 1: Setup
- [ ] Confirm baseline: `prove -v t/artefacthelpers.t t/backlog-manager-*.t` is green on `d3d7b86`.
- [ ] Re-read the BACKLOG entry's "Proposed split" and "Work to do" sections for the canonical wording.

### Step 2: Add new functions to `CWF::ArtefactHelpers`
- [ ] Add `validate_write_path_allowlist($path, \@allowed_prefixes)` — verbatim copy of current `validate_path_allowlist` body.
- [ ] Add `validate_read_path_allowlist($path)` — checks: defined, non-empty, `-f $path`, `-r $path`. No prefix list, no `..` rejection (read-side traversal of a user-chosen file is not a threat the function defends against). Dies with `[CWF] ERROR:` on each failure.
- [ ] Keep `validate_path_allowlist` exported for the moment; do not remove yet.
- [ ] Add to `@EXPORT_OK`.

### Step 3: Add unit tests for the new functions (test-first for new code)
- [ ] In `t/artefacthelpers.t`, add a block for `validate_write_path_allowlist` mirroring the existing `validate_path_allowlist` cases (absolute, `..`, missing prefix, undef, empty, accept).
- [ ] Add a block for `validate_read_path_allowlist`: accepts a freshly-created tempfile (via `File::Temp::tempfile`); rejects undef, empty, non-existent, and (best-effort) unreadable. The unreadable case can `chmod 0000` then restore — skip if running as root (where `-r` is always true).
- [ ] Run `prove t/artefacthelpers.t` — expect green; old function still passes its own tests.

### Step 4: Migrate call sites
- [ ] `cwf-apply-artefacts`: change `use CWF::ArtefactHelpers qw(... validate_path_allowlist)` → `validate_write_path_allowlist`; change call at line 208 accordingly.
- [ ] `cwf-claude-settings-merge`: change import + call at lines 20 and 63.
- [ ] `backlog-manager`: change import + call at line 26 and 304. The new call is `validate_read_path_allowlist($path)` — no second argument. Delete the inline prefix list.
- [ ] Remove the now-redundant `die_path("body file does not exist: $path") unless -f $path;` follow-up in `backlog-manager` (the new validator already enforces `-f`).
- [ ] Update the `--body-file` help text in `usage_add()` at backlog-manager:131 from `"repo-relative path; outside-repo paths rejected."` to `"any readable file path (absolute or relative)."`

### Step 5: Remove the old function
- [ ] Drop `sub validate_path_allowlist { ... }` body and its preceding comment block from `CWF::ArtefactHelpers.pm`.
- [ ] Remove `validate_path_allowlist` from `@EXPORT_OK`.
- [ ] Remove the old `validate_path_allowlist` test block from `t/artefacthelpers.t`.
- [ ] Remove the import in the test file.
- [ ] `grep -rn validate_path_allowlist .cwf/ t/ docs/ .claude/` must return zero hits.

### Step 6: Add body-file integration tests
- [ ] In a new file `t/backlog-manager-body-file.t`, reuse the `make_isolated` + `run_bm` helpers from `t/backlog-manager.t:30-71` (extract them to a shared module if duplication crosses the rule-of-three; otherwise copy). Tests:
  - **Positive**: body file under `File::Temp::tempdir(CLEANUP => 1)` (i.e. `/tmp/...`) — `backlog-manager add ... --body-file=$tmp/body.md` exits 0 and BACKLOG.md contains the body.
  - **Negative**: `--body-file=/nonexistent/path` → exits non-zero, stderr matches `/file does not exist/`.
  - **Negative**: `--body-file=$tmp/unreadable.md` with `chmod 0000` → exits non-zero, stderr matches `/not readable/`. Skip if `$> == 0` (root bypasses `-r`).
  - **Negative**: `--body-file=''` → exits non-zero, stderr matches `/empty/`.

### Step 7: Regenerate script hashes
- [ ] Run `.cwf/scripts/cwf-manage fix-security` to refresh `.cwf/security/script-hashes.json` (three scripts edited).
- [ ] Confirm `cwf-manage validate` is OK.

### Step 8: Validation gate (full repo)
- [ ] `prove t/` — all tests green.
- [ ] `.cwf/scripts/command-helpers/security-review-changeset --phase=f --task-num=140` — no new findings.
- [ ] Manual smoke: `.cwf/scripts/command-helpers/backlog-manager add --title='Smoke 140' --task-type=chore --priority=Low --body-file=/tmp/cwf-smoke/body.md` then `backlog-manager delete --exact-title='Smoke 140' --confirm`.

## Code Changes

### Before — `.cwf/lib/CWF/ArtefactHelpers.pm`
```perl
our @EXPORT_OK = qw(
    read_json_file
    atomic_write_json
    atomic_write_text
    validate_path_allowlist
    compute_file_sha256
    read_file_raw
);

# validate_path_allowlist($path, \@allowed_prefixes) -> dies on rejection.
sub validate_path_allowlist {
    my ($path, $allowed) = @_;
    die "[CWF] ERROR: path is undef\n" unless defined $path;
    die "[CWF] ERROR: path is empty\n" unless length $path;
    die "[CWF] ERROR: refusing absolute path: $path\n"
        if $path =~ m{^/};
    die "[CWF] ERROR: refusing path with '..': $path\n"
        if $path =~ m{(?:^|/)\.\.(?:/|$)};
    for my $prefix (@$allowed) {
        return 1 if index($path, $prefix) == 0;
    }
    die "[CWF] ERROR: path does not match any allowed prefix: $path\n";
}
```

### After
```perl
our @EXPORT_OK = qw(
    read_json_file
    atomic_write_json
    atomic_write_text
    validate_write_path_allowlist
    validate_read_path_allowlist
    compute_file_sha256
    read_file_raw
);

# validate_write_path_allowlist($path, \@allowed_prefixes) -> dies on rejection.
# Defends against tampered-input attacks: caller passes a path drawn from
# untrusted data (e.g. JSON manifest) and asserts the destination must lie
# inside one of the allowed prefixes.
sub validate_write_path_allowlist {
    my ($path, $allowed) = @_;
    die "[CWF] ERROR: path is undef\n" unless defined $path;
    die "[CWF] ERROR: path is empty\n" unless length $path;
    die "[CWF] ERROR: refusing absolute path: $path\n"
        if $path =~ m{^/};
    die "[CWF] ERROR: refusing path with '..': $path\n"
        if $path =~ m{(?:^|/)\.\.(?:/|$)};
    for my $prefix (@$allowed) {
        return 1 if index($path, $prefix) == 0;
    }
    die "[CWF] ERROR: path does not match any allowed prefix: $path\n";
}

# validate_read_path_allowlist($path) -> dies on rejection.
# For caller-chosen source paths (e.g. backlog-manager --body-file). The
# invoker already has shell access; restricting where the source may live
# defends against nothing the filesystem doesn't already enforce. Only
# checks: defined, non-empty, exists, readable.
sub validate_read_path_allowlist {
    my ($path) = @_;
    die "[CWF] ERROR: path is undef\n" unless defined $path;
    die "[CWF] ERROR: path is empty\n" unless length $path;
    die "[CWF] ERROR: file does not exist: $path\n" unless -f $path;
    die "[CWF] ERROR: file is not readable: $path\n" unless -r _;
    return 1;
}
```

### Before — `backlog-manager:300-307`
```perl
if (defined $opts{'body-file'}) {
    my $path = $opts{'body-file'};
    eval {
        validate_path_allowlist($path, ['.cwf/', '.claude/', 'docs/', 'implementation-guide/', 't/']);
    };
    die_path($@) if $@;
    die_path("body file does not exist: $path") unless -f $path;
    open(my $fh, '<:encoding(UTF-8)', $path) or die_path("cannot read $path: $!");
```

### After
```perl
if (defined $opts{'body-file'}) {
    my $path = $opts{'body-file'};
    eval { validate_read_path_allowlist($path); };
    die_path($@) if $@;
    open(my $fh, '<:encoding(UTF-8)', $path) or die_path("cannot read $path: $!");
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

The temp-variant deferral above is the **only** scoped-out item; it is documented
in the Goal section, was justified by a grep against the named candidate
callers, and the BACKLOG entry stays open under a refined title.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 140
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
