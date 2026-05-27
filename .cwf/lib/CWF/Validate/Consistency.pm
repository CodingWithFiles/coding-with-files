package CWF::Validate::Consistency;
#
# CWF::Validate::Consistency - Cross-file consistency checks
#
# Checks, across the whole task hierarchy (every nesting depth):
#   - task directory names match the **Task** number recorded in their files
#   - the git branch is consistent with active tasks, judged by the task
#     hierarchy (an active ancestor of the current branch's task is fine;
#     siblings and off-chain tasks are not)
#   - a task in a terminal status has no descendant still active (the
#     parent/child completeness asymmetry)
#
# Usage:
#   use CWF::Validate::Consistency qw(validate);
#   my @violations = validate($git_root);
#

use strict;
use warnings;
use utf8;
use Exporter 'import';
use CWF::MarkdownParser qw(extract_field);
use CWF::TaskState qw(status_get);
use CWF::TaskPath qw(get_parent get_depth parse_dirname version_compare);

our @EXPORT_OK = qw(validate);

my %TERMINAL_STATUSES = map { $_ => 1 } qw(Finished Skipped Cancelled);

# True iff $anc_num is an ancestor of $node_num, by exact-equality walk of the
# get_parent chain (structurally rejects numeric near-misses: 1 vs 11,
# 1.1 vs 1.10). Built from the dotted-number string, not a node-pointer walk,
# so a missing intermediate directory does not break the chain.
sub _is_ancestor {
    my ($anc_num, $node_num) = @_;
    my $p = get_parent($node_num);
    while (defined $p) {
        return 1 if $p eq $anc_num;
        $p = get_parent($p);
    }
    return 0;
}

# Build a node record for one task directory. Scans its direct .md files for the
# recorded branch (first **Branch**), activity (any recognised non-terminal
# status), completeness (a status was seen and none was non-terminal), and the
# inline **Task**-vs-directory violations.
sub _build_node {
    my ($path, $dir_num, $dir_name) = @_;
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
                "Update **Task**: $fnum to **Task**: $dir_num in $file to match directory name $dir_name");
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

# Recursively collect task nodes under $dir. Directory entries are sorted per
# level (matching the prior flat `sort @task_dirs`, so a flat repo's **Task**
# violation order is unchanged). A symlinked entry is skipped BEFORE the -d test
# (which stat-follows), keeping traversal inside implementation-guide/.
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
        my $node = _build_node($full, $num, $e);
        next unless $node;
        push @$nodes, $node;
        push @$violations, @{ $node->{task_violations} };
        _collect_nodes($full, $nodes, $violations);   # nested subtasks
    }
}

# validate($git_root)
# Returns: list of violation hashrefs
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

    # Completeness pass: a complete node must have no active descendant.
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

my $TASK_REF_SECTION_RE = qr/^## Task Reference/;

sub _extract_fields {
    my ($file) = @_;

    my $task_num = extract_field($file, $TASK_REF_SECTION_RE, qr/^-?\s*\*\*Task\*\*:\s*(\S+)/);
    my $branch   = extract_field($file, $TASK_REF_SECTION_RE, qr/^-?\s*\*\*Branch\*\*:\s*(\S+)/);
    my $status   = status_get($file);

    return (
        ($task_num ne 'Unknown' ? $task_num : undef),
        ($branch   ne 'Unknown' ? $branch   : undef),
        ($status   ne 'Unknown' ? $status   : undef),
    );
}

sub _current_branch {
    my ($git_root) = @_;
    my $branch = `git -C "$git_root" rev-parse --abbrev-ref HEAD 2>/dev/null`;
    chomp $branch;
    return $branch || undef;
}

sub _violation {
    my ($file, $field, $actual, $expected, $fix) = @_;
    return {
        category => 'CONSISTENCY',
        file     => $file,
        field    => $field,
        actual   => $actual,
        expected => $expected,
        fix      => $fix,
    };
}

1;
