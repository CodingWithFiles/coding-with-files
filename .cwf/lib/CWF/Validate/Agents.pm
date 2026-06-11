package CWF::Validate::Agents;
#
# CWF::Validate::Agents - Flag the silently-ignored `allowed-tools:` key in
# CWF agent frontmatter.
#
# Claude Code agent definitions (.claude/agents/*.md) gate tool access via the
# `tools:` frontmatter key. Skills and slash-commands use `allowed-tools:`. The
# two are easy to confuse, and Claude Code *silently ignores* `allowed-tools:`
# in an agent file — no parse error, no warning — leaving the agent with the
# FULL tool set instead of the intended restricted one. That is a
# privilege-escalation footgun that fails open. This validator catches it.
#
# Scan target (resolved once per run):
#   - If $git_root/.cwf-agents/ exists (an installed consuming project, where
#     these are the real files and .claude/agents/cwf-*.md are symlinks into
#     them), scan .cwf-agents/cwf-*.md.
#   - Otherwise scan .claude/agents/cwf-*.md (this dev repo: the source files).
# Only one target is scanned, so symlinked duplicates are never double-counted.
# The glob is restricted to the cwf-* namespace: a user's own (non-cwf-) agents
# are not policed.
#
# Detection inspects ONLY the leading YAML frontmatter block (line 1 must be an
# opening `---`, scanned to a closing `---`); an `allowed-tools:` key at line
# start within that block is a violation. Body prose and unterminated blocks
# are never flagged. One violation per file.
#
# Returns a list of violation hashrefs, each with keys:
#   category, file, field, actual, expected, fix
#
# Usage:
#   use CWF::Validate::Agents qw(validate);
#   my @violations = validate($git_root);
#

use strict;
use warnings;
use utf8;
use Exporter 'import';

our @EXPORT_OK = qw(validate);

sub validate {
    my ($git_root) = @_;
    my @violations;

    # Resolve the single scan target. .cwf-agents/ (installed project, real
    # files) takes precedence over .claude/agents/ (dev repo source).
    my $subdir = (-d "$git_root/.cwf-agents")
        ? '.cwf-agents'
        : '.claude/agents';
    my $dir = "$git_root/$subdir";
    return @violations unless -d $dir;

    opendir(my $dh, $dir)
        or die "[CWF] Validate::Agents: cannot opendir $dir: $!\n";
    my @names = sort grep { /^cwf-.*\.md\z/ } readdir($dh);
    closedir $dh;

    for my $name (@names) {
        my $path = "$dir/$name";
        next unless -f $path;
        my $rel = "$subdir/$name";
        push @violations, _scan_file($path, $rel);
    }
    return @violations;
}

# Inspect one file's frontmatter block; return at most one violation.
sub _scan_file {
    my ($path, $rel) = @_;
    open my $fh, '<', $path
        or die "[CWF] Validate::Agents: cannot open $path: $!\n";
    my @lines = <$fh>;
    close $fh;

    # Line 1 must be an opening frontmatter marker, else no frontmatter.
    return () unless @lines && $lines[0] =~ /^---\s*$/;

    # Locate the closing marker first. An unterminated block is not valid
    # frontmatter and is deliberately NOT scanned — falling back to a body
    # scan would reintroduce false positives on prose mentioning the key.
    my $close;
    for my $i (1 .. $#lines) {
        if ($lines[$i] =~ /^---\s*$/) { $close = $i; last; }
    }
    return () unless defined $close;

    # Scan only the lines strictly inside the terminated block.
    for my $i (1 .. $close - 1) {
        return _v($rel) if $lines[$i] =~ /^allowed-tools\s*:/;
    }
    return ();
}

sub _v {
    my ($rel) = @_;
    return { category => 'AGENTS', file => $rel,
             field => 'frontmatter-key', actual => 'allowed-tools:',
             expected => 'tools:',
             fix => "Rename the 'allowed-tools:' key to 'tools:'." };
}

1;
