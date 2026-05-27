# hierarchy-aware consistency validation - Implementation Plan
**Task**: 164 (feature)

## Task Reference
- **Task ID**: internal-164
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/164-hierarchy-aware-consistency-validation
- **Template Version**: 2.1

## Goal
Rework `CWF::Validate::Consistency` into a recursive, hierarchy-aware validator per the
approved design: collect nodes at all depths, then run the task-number, directional-branch,
and completeness checks over the in-memory node set.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/lib/CWF/Validate/Consistency.pm` — replace the flat single-level scan with a
  recursive node collection + three in-memory passes; import `CWF::TaskPath` string
  primitives; add `_collect_nodes`, `_build_node`, `_is_ancestor`.

### Supporting Changes
- `.cwf/security/script-hashes.json` — refresh the `sha256` for `Consistency.pm` **in the
  same commit** (`docs/conventions/hash-updates.md`).
- `t/validate-consistency.t` — add hierarchy fixtures and assertions (detail in
  e-testing-plan.md).

## Implementation Steps
### Step 1: Imports and predicate helpers
- [ ] Add `use CWF::TaskPath qw(get_parent get_depth parse_dirname version_compare);`.
- [ ] Add `_is_ancestor($anc_num, $node_num)` — `get_parent`-chain walk, `eq`-tested.

### Step 2: Recursive node collection
- [ ] Add `_collect_nodes($dir)` (recursive): per directory entry, **`-l` skip first**,
      then `-d`, then `parse_dirname` gate; record the task node and recurse into it.
- [ ] Add `_build_node($path, $dir_num)`: scan the dir's direct `.md` files, compute
      `branch` (first `**Branch**`), `active`, `complete`, and the inline `**Task**`-vs-dir
      violations.

### Step 3: Rework `validate($git_root)` into the orchestrator
- [ ] Keep `return () unless -d $ig_dir` (preserves the missing-implementation-guide test).
- [ ] Collect nodes; resolve `current_branch`; identify the leaf (fail-closed on 0 or >1).
- [ ] Branch pass (directional rule) and completeness pass; accumulate and return.

### Step 4: Integrity + perms
- [ ] `sha256sum .cwf/lib/CWF/Validate/Consistency.pm`; update the matching entry in
      `.cwf/security/script-hashes.json` (same commit).
- [ ] Restore working perms to 0700 (`feedback_hashed_script_working_perms`).
- [ ] `.cwf/scripts/cwf-manage validate` → clean (modulo any unrelated pre-existing drift,
      surfaced not silenced). **Note**: this repo has no on-disk subtask dirs, so the live
      `validate` smoke test exercises only the flat path; all hierarchy behaviour is
      covered by synthetic nested fixtures in `t/` (e-testing-plan.md).

### Step 5: Tests
- [ ] Add hierarchy fixtures + assertions per e-testing-plan.md; run full `prove t/`.

## Code Changes

Imports and predicate (ancestor set built from the dotted number string — **not** a
node-pointer walk — so a missing intermediate dir does not break the chain; terminates in
`depth` steps):
```perl
use CWF::TaskPath qw(get_parent get_depth parse_dirname version_compare);

# True iff $anc_num is an ancestor of $node_num, by exact-equality walk of the
# get_parent chain (structurally rejects numeric near-misses: 1 vs 11, 1.1 vs 1.10).
sub _is_ancestor {
    my ($anc_num, $node_num) = @_;
    my $p = get_parent($node_num);
    while (defined $p) {
        return 1 if $p eq $anc_num;
        $p = get_parent($p);
    }
    return 0;
}
```

Node record builder (keeps the existing `_extract_fields`/`status_get` semantics; `active`
ignores undefined status exactly as the current code does at `:69`):
```perl
sub _build_node {
    my ($path, $dir_num) = @_;
    opendir my $tdh, $path or return undef;
    my @md = sort grep { /\.md$/ && -f "$path/$_" } readdir $tdh;
    closedir $tdh;

    my ($branch, $active, $saw_status) = (undef, 0, 0);
    my @task_violations;
    for my $md (@md) {
        my $file = "$path/$md";
        my ($fnum, $fbranch, $fstatus) = _extract_fields($file);
        if (defined $fnum && $fnum ne $dir_num) {
            push @task_violations, _violation(
                $file, '**Task**', $fnum, $dir_num,
                "Update **Task**: $fnum to **Task**: $dir_num in $file to match directory $dir_num");
        }
        $branch //= $fbranch if defined $fbranch;
        if (defined $fstatus) { $saw_status = 1; $active = 1 unless $TERMINAL_STATUSES{$fstatus}; }
    }
    return {
        num   => $dir_num, path => $path, branch => $branch,
        active => $active, complete => ($saw_status && !$active) ? 1 : 0,
        task_violations => \@task_violations,
    };
}
```

Recursive collection (lexical `sort` per level — matches the prior `sort @task_dirs`, so a
flat repo's violation order is byte-identical, FR5/AC5):
```perl
sub _collect_nodes {
    my ($dir, $nodes, $violations) = @_;
    opendir my $dh, $dir or return;
    my @entries = sort readdir $dh;
    closedir $dh;
    for my $e (@entries) {
        next if $e eq '.' || $e eq '..';
        my $full = "$dir/$e";
        next if -l $full;          # symlink skip BEFORE -d (which stat-follows)
        next unless -d $full;
        my ($num) = parse_dirname($e);
        next unless defined $num;  # node-gate: only real task dirs
        my $node = _build_node($full, $num);
        next unless $node;
        push @$nodes, $node;
        push @$violations, @{ $node->{task_violations} };
        _collect_nodes($full, $nodes, $violations);   # nested subtasks
    }
}
```

Orchestrator (`validate`) — leaf id + the two passes:
```perl
sub validate {
    my ($git_root) = @_;
    my $ig_dir = "$git_root/implementation-guide";
    return () unless -d $ig_dir;

    my (@nodes, @violations);
    _collect_nodes($ig_dir, \@nodes, \@violations);

    my $current = _current_branch($git_root);

    # Leaf = the unique node recording the current branch; 0 or >1 => fail closed.
    my @leaves = grep { defined $_->{branch} && defined $current
                        && $_->{branch} eq $current } @nodes;
    my $leaf = (@leaves == 1) ? $leaves[0] : undef;

    # Branch pass (directional): flag active nodes off the leaf's ancestry chain.
    for my $n (@nodes) {
        next unless $n->{active} && defined $n->{branch} && defined $current;
        next if $n->{branch} eq $current;                       # on its own branch
        next if $leaf && _is_ancestor($n->{num}, $leaf->{num}); # ancestor of leaf
        push @violations, _violation(
            "$n->{path}/", '**Branch**', $n->{branch}, $current,
            "Task $n->{num} has active files but **Branch**: $n->{branch} does not match "
          . "current branch $current. Either checkout the task branch or update the Branch field.");
    }

    # Completeness pass (FR4): a complete node must have no active descendant.
    for my $c (@nodes) {
        next unless $c->{complete};
        my @active_desc = grep { $_->{active} && _is_ancestor($c->{num}, $_->{num}) } @nodes;
        next unless @active_desc;
        my ($near) = sort { get_depth($a->{num}) <=> get_depth($b->{num})
                            || version_compare($a->{num}, $b->{num}) } @active_desc;
        push @violations, _violation(
            "$c->{path}/", '**Status**', "complete (task $c->{num})",
            "active descendant $near->{num}",
            "Task $c->{num} is complete but descendant $near->{num} is still active — "
          . "reopen $c->{num} or finish $near->{num}.");
    }

    return @violations;
}
```
`_extract_fields`, `_current_branch`, `_violation`, `$TERMINAL_STATUSES`, and the
`$TASK_REF_SECTION_RE` constant are **unchanged** and reused.

Implementation notes (from plan review):
- `_build_node`'s `opendir … or return undef` and `_collect_nodes`' `next unless $node`
  keep the existing `:45` "skip an unreadable dir" parity — a deliberate choice, not a new
  silent-failure. Recursion makes it skip the subtree too; acceptable for an advisory
  read-only validator (no behaviour change vs today's flat scan).
- `task_violations` on the node record is **collection-only**: `_collect_nodes` drains it
  into `@violations` immediately; it is not read afterwards.
- The completeness tiebreak keeps `get_depth` as the primary key even though
  `version_compare` alone would pick the same nearest descendant (every descendant shares
  `$c`'s prefix). This is deliberate: it states the design's "nearest = smallest depth"
  contract literally rather than relying on `version_compare`'s segment-count behaviour.

## Plan Review Outcomes (Step 8)
Four parallel reviewers (improvements, misalignment, robustness, security). No blocking
findings; all approved. Applied as notes above; carried into e-testing-plan.md:
- **Guards must be asserted, not assumed** (robustness): the test plan must cover a
  top-level node (num `1`, no parent → `get_parent` immediate-`undef`, no warnings under
  `use warnings`), a complete leaf with no descendants → zero completeness violations, and
  a malformed/missing-status descendant under a complete node → no manufactured violation.
- **Fixtures must be nested** (robustness/misalignment): the repo has no on-disk subtask
  dirs today, so every hierarchy assertion uses synthetic fixtures with child dirs
  physically nested inside parent dirs (the canonical layout per design).
- **Reuse/minimalism confirmed** (improvements/misalignment): three-file blast radius, all
  four `TaskPath` imports consumed, `_is_ancestor` has two callsites, `parse_dirname`
  consolidates the dirname grammar (retires the inline `:41` regex). No changes needed.
- **Security**: no new shell/env/prompt surface; `-l`-before-`-d` ordering is load-bearing
  and correct; `_current_branch` backtick reuse is safe (`$git_root` is git-resolved).

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

The `Consistency.pm` hash refresh is part of the implementation commit — not deferred to
retrospective (`hash-updates.md`).

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Implemented as planned; the Perl written in this plan applied near-verbatim. One
tightening: `_build_node` takes a third arg (dir basename) so the `**Task**` fix message
is byte-identical to pre-change output (FR5).

## Lessons Learned
Writing the full implementation in the plan made exec mechanical — the only deltas were
the byte-identical-message tightening and the perms-scope correction, both improvements.
