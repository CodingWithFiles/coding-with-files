# Update version conventions - Implementation Plan
**Task**: 89 (feature)

## Task Reference
- **Task ID**: internal-89
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/89-update-version-conventions
- **Template Version**: 2.1

## Goal
Implement the CLAUDE.md versioning section and the `cwf-manage list-releases` filtered view.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes
- `CLAUDE.md` — add `## Versioning` section at end
- `.cwf/scripts/cwf-manage` — add `parse_semver`, `filter_releases`; update `cmd_list_releases`, `main`, `cmd_help`

### Supporting Changes
- `t/cwf-manage-list-releases.t` — new test file for `parse_semver` and `filter_releases`

## Implementation Steps

### Step 1: Add `## Versioning` to `CLAUDE.md`
- [ ] Append the section (content specified verbatim in c-design-plan.md)
- [ ] Verify `grep -r "Versioning" .cwf/` returns no matches

### Step 2: Add `parse_semver` to `cwf-manage`
- [ ] Insert after `version_cmp` sub (line ~168)
- [ ] Signature: `parse_semver($tag)` → `(M, m, N)` integers or `()` (empty list = undef in list context)
- [ ] Accept `v\d+\.\d+\.\d+` only; strip leading `v`; return empty list for anything else

### Step 3: Add `filter_releases` to `cwf-manage`
- [ ] Insert after `parse_semver`
- [ ] Signature: `filter_releases($current, @tags)` → sorted list of display tags (excluding current)
- [ ] If current unparseable: return `@tags` minus current (safe fallback, show everything)
- [ ] Bucket logic: `same-minor` / `minor-{x}` / `major-{x}` — keep max per bucket via `version_cmp`
- [ ] Return bucket values sorted descending

### Step 4: Update `cmd_list_releases`
- [ ] Add `$show_all` parameter: `sub cmd_list_releases { my ($git_root, $show_all) = @_; }`
- [ ] `--all` path: existing loop unchanged (sort descending, print all with marker)
- [ ] Default path:
  - Call `filter_releases($current, @sorted_tags)`
  - Build display list: filtered results + current, sort descending
  - Print with ` (installed)` marker on current
  - If hidden count > 0: print blank line + footer
- [ ] Hidden count = `scalar(@sorted_tags) - scalar(@display_list)`

### Step 5: Update `main` dispatch and `cmd_help`
- [ ] `main`: `'list-releases' => sub { my $all = grep { $_ eq '--all' } @ARGV; cmd_list_releases($git_root, $all); }`
- [ ] `cmd_help`: change `list-releases` line to `list-releases [--all]`

### Step 6: Write unit tests
- [ ] Create `t/cwf-manage-list-releases.t`
- [ ] Test `parse_semver`: valid tag, tag without v, 2-part, non-numeric, empty string
- [ ] Test `filter_releases` edge cases (see e-testing-plan.md TC-3 through TC-8):
  - Already on latest → empty filtered list
  - New patch on same minor available
  - Multiple higher minors → one line each
  - Higher major → one line per major
  - Multiple higher majors
  - Non-semver tags in the list → silently excluded from buckets
- [ ] Run: `prove t/cwf-manage-list-releases.t`

### Step 7: Validate
- [ ] `prove t/` — full test suite passes (no regressions)
- [ ] `.cwf/scripts/cwf-manage validate`
- [ ] `grep -r "Versioning" .cwf/` → no matches

## Code Changes

### `parse_semver` (new sub, insert after `version_cmp`)

```perl
sub parse_semver {
    my ($tag) = @_;
    (my $v = $tag) =~ s/^v//;
    my @p = split /\./, $v;
    return () unless @p == 3
        && $p[0] =~ /^\d+$/ && $p[1] =~ /^\d+$/ && $p[2] =~ /^\d+$/;
    return ($p[0]+0, $p[1]+0, $p[2]+0);
}
```

### `filter_releases` (new sub, insert after `parse_semver`)

Uses a closure-based `@rules` array to separate business rules from pipeline mechanics.
`$tm/$tmi/$tp` are declared as outer lexicals so both closures in each rule capture them;
the map iteration mutates them before calling the closures. `@tags` must be pre-sorted
descending — first-seen deduplication then gives the maximum per bucket without an explicit
comparison.

```perl
use List::Util qw(first);

sub filter_releases {
    my ($current, @tags) = @_;   # @tags already sorted descending
    my @cc = parse_semver($current);
    # If current version is not strict semver, show everything except current
    return grep { $_ ne $current } @tags unless @cc;
    my ($cm, $cmi, $cp) = @cc;

    # Outer lexicals captured (and mutated per iteration) by both closures in each rule
    my ($tm, $tmi, $tp);
    my @rules = (
        [ sub { $tm > $cm                                }, sub { "major-$tm"  } ],
        [ sub { $tm == $cm && $tmi > $cmi               }, sub { "minor-$tmi" } ],
        [ sub { $tm == $cm && $tmi == $cmi && $tp > $cp }, sub { 'same-minor' } ],
    );

    my %seen;
    return
        map  { $_->[1] }
        grep { !$seen{ $_->[0] }++ }
        map  {
            ($tm, $tmi, $tp) = parse_semver($_);
            my $rule = first { $_->[0]->() } @rules;
            $rule ? [ $rule->[1]->(), $_ ] : ();
        }
        grep { $_ ne $current && parse_semver($_) }
        @tags;
}
```

### `cmd_list_releases` (replace existing)

```perl
sub cmd_list_releases {
    my ($git_root, $show_all) = @_;
    my %v = read_version_file($git_root);
    my $source  = $v{cwf_source}  or die_msg("No cwf_source in .cwf/version");
    my $current = $v{cwf_version} // '';

    log_msg("Available releases from $source");

    my @lines = `git ls-remote --tags "$source" 'v*' 2>/dev/null`;
    die_msg("Failed to query remote tags from $source") if $?;

    my @tags;
    for (@lines) {
        chomp;
        push @tags, $1 if m{refs/tags/(v[^\^]+)$};
    }
    die_msg("No version tags found at $source") unless @tags;

    my @sorted = reverse sort { version_cmp($a, $b) } @tags;

    if ($show_all) {
        for my $tag (@sorted) {
            my $marker = ($tag eq $current) ? ' (installed)' : '';
            printf "  %s%s\n", $tag, $marker;
        }
        return;
    }

    # Filtered default view
    my @filtered  = filter_releases($current, @sorted);
    my %shown     = map { $_ => 1 } @filtered;
    my @display   = sort { version_cmp($b, $a) }
                        (@filtered, ($shown{$current} ? () : $current));
    my $hidden    = scalar(@sorted) - scalar(@display);

    for my $tag (@display) {
        my $marker = ($tag eq $current) ? ' (installed)' : '';
        printf "  %s%s\n", $tag, $marker;
    }
    if ($hidden > 0) {
        printf "\n  Run 'cwf-manage list-releases --all' to see all %d releases.\n",
               scalar @sorted;
    }
    return;
}
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 89
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 7 steps executed. parse_semver implemented with single regex (cleaner than plan's
split approach). filter_releases implemented with closure-based @rules pipeline.
Bug found during TC-2: plan's s/^v// accepted no-v-prefix tags; fixed with regex.

## Lessons Learned
When strict prefix enforcement is needed, capture directly with /^v(\d+)\.(\d+)\.(\d+)$/
rather than stripping and re-parsing. The plan code had a latent bug the tests exposed.
