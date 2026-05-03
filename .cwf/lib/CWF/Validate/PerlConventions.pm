package CWF::Validate::PerlConventions;
#
# CWF::Validate::PerlConventions - Perl + git path-handling convention checker
#
# Walks .cwf/scripts/ and .cwf/lib/CWF/ and asserts the conventions in
# docs/conventions/perl-git-paths.md:
#
#   - Source-pragma:  every Perl file (script or module) declares 'use utf8;'
#                     unconditionally. Stricter than the bare convention doc:
#                     enforced on all files, regardless of whether non-ASCII
#                     bytes are currently present, so that adding a literal
#                     later cannot silently produce double-encoded output
#                     under PERL5OPT=-CDSL (the Task 115 failure mode).
#   - Git -z:         any script that *captures* output from a path-emitting
#                     git subcommand (status, diff, ls-files, diff-tree,
#                     diff-index) passes -z to that invocation.
#   - Shebang:        any script flagged by the Git -z rule has shebang
#                     '#!/usr/bin/perl -CDSL' so I/O is decoded as UTF-8.
#
# Files in @GRANDFATHERED are exempted from the Git -z and shebang rules
# (but never from the source-pragma rule). The allowlist is hard-coded to
# prevent comment-marker bypass — adding entries requires editing this file
# and is therefore visible in code review.
#
# Usage:
#   use CWF::Validate::PerlConventions qw(validate);
#   my @violations = validate($git_root);
#

use strict;
use warnings;
use utf8;
use Exporter 'import';
use File::Find ();
use File::Spec;

our @EXPORT_OK = qw(validate);

# Files that predate the convention. Each entry is a path relative to git_root.
# Adding to this list is intentionally a source edit — visible in code review.
our @GRANDFATHERED = (
    '.cwf/scripts/hooks/stop-stale-status-detector',
);

# Subtrees to scan, relative to git_root.
our @SCAN_ROOTS = ('.cwf/scripts', '.cwf/lib/CWF');

# Path-emitting git subcommands the convention applies to.
my $PATH_CMDS = qr/status|diff|ls-files|diff-tree|diff-index/;

sub validate {
    my ($git_root) = @_;
    my %allow = map { $_ => 1 } @GRANDFATHERED;
    my @violations;

    for my $root (@SCAN_ROOTS) {
        my $abs = "$git_root/$root";
        next unless -d $abs;
        File::Find::find({
            no_chdir => 1,
            wanted   => sub {
                return unless -f $File::Find::name;
                my $rel = File::Spec->abs2rel($File::Find::name, $git_root);
                _check_file($File::Find::name, $rel, \%allow, \@violations);
            },
        }, $abs);
    }

    return @violations;
}

sub _check_file {
    my ($abs, $rel, $allow, $violations) = @_;

    my $src = _slurp($abs);
    return unless defined $src;

    my ($first_line) = $src =~ /\A([^\n]*)/;
    $first_line //= '';
    my $is_script = $first_line =~ m{\A\#!\S*/(?:env\s+)?perl\b};
    my $is_module = $src =~ /^package\s+CWF::/m;
    return unless $is_script || $is_module;

    my $code = _strip_pod_and_comments($src);

    # Source-pragma: every Perl file must declare 'use utf8;', regardless of
    # whether non-ASCII bytes are currently present. Default-on prevents the
    # latent failure where a future literal silently double-encodes.
    if ($src !~ /^use\s+utf8\s*;/m) {
        push @$violations, _violation(
            $rel, 'use_utf8',
            '(missing)', 'use utf8;',
            "Add 'use utf8;' after 'use strict; use warnings;' in $rel — every CWF Perl file declares the source pragma unconditionally so future non-ASCII literals cannot silently double-encode under PERL5OPT=-CDSL.",
        );
    }

    return if $allow->{$rel};
    return unless $is_script;

    # Git output-capture: scripts only.
    my @captures = _find_git_captures($code);
    for my $cap (@captures) {
        next if _has_z($cap);
        push @$violations, _violation(
            $rel, 'git_z',
            _summarise($cap), 'invocation including -z',
            "Add '-z' to the git invocation in $rel; path-emitting git subcommands must be NUL-separated (see docs/conventions/perl-git-paths.md).",
        );
    }

    if (@captures && $first_line ne '#!/usr/bin/perl -CDSL') {
        push @$violations, _violation(
            $rel, 'shebang',
            $first_line, '#!/usr/bin/perl -CDSL',
            "Change shebang to '#!/usr/bin/perl -CDSL' in $rel — scripts that consume git path output must enable Perl I/O UTF-8 decoding.",
        );
    }

    return;
}

sub _slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or return;
    local $/;
    my $c = <$fh>;
    close $fh;
    return $c;
}

# Strip POD blocks (=head1 ... =cut) and #-comments, preserving the shebang
# and string literals well enough for the regex-based checks below. This is
# heuristic, not a full Perl parser — good enough for an audit-grade check.
sub _strip_pod_and_comments {
    my ($src) = @_;

    $src =~ s/^=\w+.*?^=cut\s*$//msg;

    my @out;
    my @lines = split /\n/, $src, -1;
    for my $i (0 .. $#lines) {
        my $ln = $lines[$i];
        if ($i == 0 && $ln =~ /\A\#!/) {
            push @out, $ln;
            next;
        }
        # Drop only obvious comments: line starts with optional whitespace
        # then '#'. Inline trailing comments after code are left in place to
        # avoid mangling regex literals like qr/#/, which are rare in our
        # scripts but possible.
        $ln = '' if $ln =~ /\A\s*\#/;
        push @out, $ln;
    }
    return join "\n", @out;
}

# Find captured git invocations of path-emitting subcommands. Returns the
# matched substrings so the caller can run -z presence checks on each.
sub _find_git_captures {
    my ($code) = @_;
    my @hits;

    # qx{...} / qx(...) / qx[...]
    while ($code =~ /(qx\s*\{[^}]*\bgit\s+(?:$PATH_CMDS)\b[^}]*\})/sg) {
        push @hits, $1;
    }
    while ($code =~ /(qx\s*\([^)]*\bgit\s+(?:$PATH_CMDS)\b[^)]*\))/sg) {
        push @hits, $1;
    }
    while ($code =~ /(qx\s*\[[^\]]*\bgit\s+(?:$PATH_CMDS)\b[^\]]*\])/sg) {
        push @hits, $1;
    }

    # Backticks
    while ($code =~ /(`[^`]*\bgit\s+(?:$PATH_CMDS)\b[^`]*`)/sg) {
        push @hits, $1;
    }

    # open ... '-|' ... 'git' ... 'status'|... up to the next ';'. Captures
    # both forms — open(my $fh, '-|', 'git', ...) and the bareword
    # open my $fh, '-|', 'git', ... — by terminating on the statement
    # boundary instead of the closing paren. Either form is valid Perl;
    # bounding on ';' keeps both in scope without a parens-counting parser.
    while ($code =~ /(open\s*\(?[^;]*?['"]-\|['"][^;]*?['"]git['"][^;]*?['"](?:$PATH_CMDS)['"][^;]*)(?=;|\z)/sg) {
        push @hits, $1;
    }

    return @hits;
}

# True if the captured statement contains -z as a token in any quote style.
sub _has_z {
    my ($cap) = @_;
    return 1 if $cap =~ /(?<![\w-])-z(?![\w-])/;
    return 0;
}

# Compress whitespace/newlines so the violation actual-value stays on one line.
sub _summarise {
    my ($s) = @_;
    $s =~ s/\s+/ /g;
    $s =~ s/\A\s+|\s+\z//g;
    return length($s) > 120 ? substr($s, 0, 117) . '...' : $s;
}

sub _violation {
    my ($file, $field, $actual, $expected, $fix) = @_;
    return {
        category => 'CONVENTIONS',
        file     => $file,
        field    => $field,
        actual   => $actual,
        expected => $expected,
        fix      => $fix,
    };
}

1;
