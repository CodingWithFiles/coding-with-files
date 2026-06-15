#!/usr/bin/env perl
#
# skill-anchor-drift.t — Task 206 migration guard (inverts the original Task-204
# drift guard). The per-skill "anchor the shell" block and the inline
# `${repo_root//\//-}` scratch-derivation snippet were REMOVED in Task 206: each
# carried a `$(...)`/`${...}` expansion that trips a Claude Code permission
# prompt on nearly every call. Paths (cwd, project root, scratch parent) are now
# injected into context by the `userpromptsubmit-context-inject` UserPromptSubmit
# hook, so skills use literal absolute paths. This test pins those prompting
# constructs STAYING removed (e-testing-plan TC-15).
#
#   TC-15a: no SKILL.md contains the "anchor the shell" prose, the gcd=$(...)
#           anchor command, or the inline repo_root// scratch expansion.
#   TC-15b: the two task-creation skills carry the literal injected-scratch
#           mkdir form (the migration positively landed).
#
use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use FindBin;

my $REPO   = File::Spec->rel2abs("$FindBin::Bin/..");
my $SKILLS = "$REPO/.claude/skills";

opendir(my $dh, $SKILLS) or do { plan skip_all => "no skills dir"; };
my @skills = sort grep { -f "$SKILLS/$_/SKILL.md" } readdir $dh;
closedir $dh;

sub slurp { open(my $fh, '<:encoding(UTF-8)', $_[0]) or return ''; local $/; <$fh> }

plan tests => 2 + @skills;

ok(scalar(@skills) >= 20,
   'scanning the expected set of CWF skills (>= 20): got ' . scalar(@skills));

# TC-15a: the removed prompting constructs must not reappear in any skill.
for my $s (@skills) {
    my $c   = slurp("$SKILLS/$s/SKILL.md");
    my $bad = (index($c, 'anchor the shell')     >= 0)   # the prose paragraph
           || (index($c, 'gcd=$(git rev-parse')  >= 0)   # the anchor command
           || (index($c, 'repo_root//')          >= 0);  # the inline scratch derivation
    ok(!$bad, "TC-15a $s: free of the removed anchor block / inline scratch derivation");
}

# TC-15b: the migration landed — task-creation skills create the leaf from the
# injected scratch parent via an all-literal mkdir (no expansion).
{
    my $marker = 'mkdir -m 0700 -p <injected-scratch-parent>/task-<num>';
    my $ok = (index(slurp("$SKILLS/cwf-new-task/SKILL.md"),    $marker) >= 0)
          && (index(slurp("$SKILLS/cwf-new-subtask/SKILL.md"), $marker) >= 0);
    ok($ok, 'TC-15b: cwf-new-task and cwf-new-subtask use the literal injected-scratch mkdir');
}
