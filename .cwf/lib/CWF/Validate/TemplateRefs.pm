package CWF::Validate::TemplateRefs;
#
# CWF::Validate::TemplateRefs - flag orphaned workflow-template references.
#
# Scans tracked *.md/*.pl/*.pm source for tokens shaped like a workflow
# template filename (a letter a-j, a hyphen, a lowercase phase phrase, then
# the .md suffix) and flags any token that matches no known template name in
# any supported workflow version (v1.0/v2.0/v2.1). This catches references
# orphaned by a template rename, and typos, while NOT false-positiving on
# legitimate backward-compat mentions (those use names that ARE known to some
# version, so they pass).
#
# Why "known to ANY version" rather than "current version only": current
# skills and lib modules deliberately reference older names for backward
# compatibility (e.g. a skill that opens the v2.1 file "or" the v2.0 file).
# A current-only rule would drown in false positives; the same token is both
# a valid back-compat mention and a potential stale reference, separable only
# by intent a linter cannot read. So we only assert the weaker, reliable
# invariant: every template-shaped reference names a real template somewhere.
#
# Scope excludes implementation-guide/ (task instances, not references; also
# holds historical v2.0 task files) and BACKLOG.md/CHANGELOG.md (append-only
# history exempt from reference rules per docs/conventions/cross-doc-references.md;
# they quote deprecated names verbatim as historical record).
#
# Returns a list of violation hashrefs, each with keys:
#   category, file, field, actual, expected, fix
#
# Usage:
#   use CWF::Validate::TemplateRefs qw(validate);
#   my @violations = validate($git_root);
#
use strict;
use warnings;
use utf8;
use Exporter 'import';
use File::Spec;
use CWF::WorkflowFiles ();
use CWF::WorkflowFiles::V20 ();
use CWF::WorkflowFiles::V21 ();

our @EXPORT_OK = qw(validate);

# Template-shaped token, boundary-anchored. The left look-behind rejects the
# tail of a longer hyphenated filename (e.g. "retrospective-extras.md" or a
# "cwf-"-prefixed agent/skill doc), so we never match an embedded substring;
# the right look-ahead rejects trailing filename characters (e.g. ".md5").
my $TOKEN = qr/(?<![A-Za-z0-9-])([a-j]-[a-z][a-z-]*\.md)(?![A-Za-z0-9])/;

sub validate {
    my ($git_root) = @_;
    my %known = _known_names($git_root);
    my @violations;

    for my $rel (_scoped_files($git_root)) {
        my $src = _slurp("$git_root/$rel");
        next unless defined $src;
        my $lineno = 0;
        for my $line (split /\n/, $src, -1) {
            $lineno++;
            while ($line =~ /$TOKEN/g) {
                my $tok = $1;
                next if $known{$tok};
                push @violations, _violation(
                    $rel, "line $lineno", $tok,
                    'a template name known to some workflow version',
                    "Reference a current template name (see .cwf/templates/pool/) or remove the stale reference in $rel.",
                );
            }
        }
    }

    return @violations;
}

# KNOWN = pool basenames + every name reported by the v2.1 and v2.0 file maps
# (over all supported task types) + both sides of the v1.0->v2.0 migration map.
# All sources are derived at runtime; nothing is hard-coded.
sub _known_names {
    my ($git_root) = @_;
    my %known;

    my $pool = "$git_root/.cwf/templates/pool";
    if (opendir my $dh, $pool) {
        while (my $e = readdir $dh) {
            $known{$1}++ if $e =~ /\A(.+)\.template\z/;   # "a-task-plan.md.template" -> "a-task-plan.md"
        }
        closedir $dh;
    }

    # V20 has no supported_types(); reuse V21's (get_workflow_files falls back
    # to the feature set for any type V20 does not enumerate).
    for my $type (CWF::WorkflowFiles::V21::supported_types()) {
        $known{$_}++ for @{ CWF::WorkflowFiles::V21::get_workflow_files($type) };
        $known{$_}++ for @{ CWF::WorkflowFiles::V20::get_workflow_files($type) };
    }

    # workflow_file_mappings() returns an arrayref of {old,new} hashrefs; one
    # entry has an empty 'old' (no v1.0 predecessor), so guard on length.
    for my $m (@{ CWF::WorkflowFiles::workflow_file_mappings() }) {
        $known{$m->{old}}++ if length $m->{old};
        $known{$m->{new}}++ if length $m->{new};
    }

    # Fail-closed: this is an enforcement gate, so a derivation bug that
    # under-populates KNOWN must fail loudly rather than silently pass every
    # reference. Assert a minimum from each era we depend on.
    for my $must (qw(a-task-plan.md f-implementation-exec.md e-testing.md)) {
        die "[CWF] Validate::TemplateRefs: KNOWN set missing '$must'; name derivation is broken — refusing to run (would pass everything).\n"
            unless $known{$must};
    }

    return %known;
}

# Tracked *.md/*.pl/*.pm, excluding task instances and append-only history.
# List-form invocation (no shell); -z because ls-files emits paths.
sub _scoped_files {
    my ($git_root) = @_;
    open my $fh, '-|', 'git', '-C', $git_root, 'ls-files', '-z', '--',
        '*.md', '*.pl', '*.pm',
        ':!implementation-guide', ':!BACKLOG.md', ':!CHANGELOG.md'
        or die "[CWF] Validate::TemplateRefs: cannot run 'git ls-files': $!\n";
    local $/ = "\0";
    my @files;
    while (my $path = <$fh>) {
        chomp $path;                 # drop the trailing NUL ($/)
        push @files, $path if length $path;
    }
    close $fh;
    return @files;
}

sub _slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or return;
    local $/;
    my $c = <$fh>;
    close $fh;
    return $c;
}

sub _violation {
    my ($file, $field, $actual, $expected, $fix) = @_;
    return {
        category => 'TEMPLATE_REFS',
        file     => $file,
        field    => $field,
        actual   => $actual,
        expected => $expected,
        fix      => $fix,
    };
}

1;
