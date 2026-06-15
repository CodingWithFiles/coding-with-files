#!/usr/bin/env perl
#
# skill-anchor-drift.t — Task 204. Drift + coverage guard for the repo-root anchor
# block copied into every CWF skill's first Bash action.
#
#   TC-5a (form):     every skill that invokes .cwf/scripts/ contains EXACTLY ONE
#                     byte-identical copy of the canonical anchor block.
#   TC-5b (coverage): in each such skill the anchor appears BEFORE the first
#                     .cwf/scripts/ reference — so a skill that silently loses its
#                     anchor (a missing block, not a drifted one) is caught.
#
# Scope: .claude/skills/*/SKILL.md only. NOT tmp-paths.md / update-cwf-skill-docs.sh,
# which deliberately use the variable-assignment (no-cd) form and would false-positive.
#
use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use FindBin;

my $REPO   = File::Spec->rel2abs("$FindBin::Bin/..");
my $SKILLS = "$REPO/.claude/skills";

# The byte-identical canonical anchor block (the fenced bash body).
my $CANON = <<'SH';
# Anchor to the MAIN repo root so relative .cwf/ paths resolve from any cwd
# (worktree-safe via --git-common-dir; tolerant when not yet in a git repo).
gcd=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [ -n "$gcd" ]; then r=$(cd "$(dirname "$gcd")" && pwd); [ "$PWD" = "$r" ] || cd "$r"; fi
SH

opendir(my $dh, $SKILLS) or do { plan skip_all => "no skills dir"; };
my @all = sort grep { -f "$SKILLS/$_/SKILL.md" } readdir $dh;
closedir $dh;

sub slurp { open(my $fh, '<:encoding(UTF-8)', $_[0]) or return undef; local $/; <$fh> }

# Skills that actually invoke .cwf/scripts/ (the surface the anchor protects),
# excluding the non-CWF test fixture skill.
my @referencing;
for my $s (@all) {
    next if $s eq 'test-cwf-skill';
    my $c = slurp("$SKILLS/$s/SKILL.md");
    next unless defined $c;
    push @referencing, [$s, $c] if index($c, '.cwf/scripts/') >= 0;
}

plan tests => 2 + @referencing * 2;

ok(scalar(@referencing) >= 20,
   'found the expected CWF skills invoking .cwf/scripts/ (>= 20): got ' . scalar(@referencing));

# Sanity: the non-CWF fixture skill must NOT be anchored (exclusion is real).
{
    my $c = slurp("$SKILLS/test-cwf-skill/SKILL.md") // '';
    ok(index($c, $CANON) < 0, 'test-cwf-skill is not anchored (correctly excluded)');
}

for my $r (@referencing) {
    my ($s, $c) = @$r;
    my $n = () = ($c =~ /\Q$CANON\E/g);
    is($n, 1, "TC-5a $s: exactly one byte-identical anchor block");
    # First-action position is computed over the ENTRY flow only: the
    # "## Scope & Boundaries" section is descriptive/fallback metadata (it names
    # the helper and the "If blocked: Call workflow-manager control" fallback,
    # reached only AFTER entry once the anchor has already run), so strip it before
    # locating the first use. Marker: the 17 skills with the universal first action
    # use `context-manager location`; the 3 without it anchor above their first
    # .cwf/scripts/ invocation.
    (my $body = $c) =~ s/\n## Scope & Boundaries\b.*?(?=\n## )//s;
    my $marker = (index($body, 'context-manager location') >= 0)
        ? 'context-manager location'
        : '.cwf/scripts/';
    my $ai = index($body, $CANON);
    my $fi = index($body, $marker);
    ok($ai >= 0 && $ai < $fi,
       "TC-5b $s: anchor present before the skill's first action ($marker)");
}

done_testing();
