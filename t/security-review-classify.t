#!/usr/bin/env perl
#
# security-review-classify.t - Unit tests for
# .cwf/scripts/command-helpers/security-review-classify
#
# Feeds synthetic subagent-output fixtures to the classifier on stdin and
# asserts the canonical token printed on stdout. These are the deterministic
# acceptance evidence for the Task 162 misclassification fix.
#
use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempfile);
use FindBin;

my $HELPER = "$FindBin::Bin/../.cwf/scripts/command-helpers/security-review-classify";

# Run the classifier with $input on stdin. Returns ($token, $exit).
sub classify {
    my ($input) = @_;
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh, ':raw';
    print $fh $input;
    close $fh;
    my $out = `'$HELPER' < '$path'`;
    my $exit = $? >> 8;
    $out =~ s/\n\z// if defined $out;
    return ($out // '', $exit);
}

# Convenience: a clean cwf-review block with the given state.
sub block {
    my ($state) = @_;
    return "```cwf-review\nstate: $state\n```\n";
}

# ----- TC-C1: the core bug fix — clean verdict after heavy prose -----------
{
    my $input = join("\n",
        ("Reviewing the changeset for FR4(a-e) concerns.") x 1,
        "",
        "Category (a) bash injection: no single-string system() calls; all spawns",
        "use list form. Category (b): git output consumed with -z. Category (c):",
        "{arguments} is parsed by helper scripts, free-text is advisory. Category",
        "(d): no new env vars. Category (e): no copy-risky patterns introduced.",
        "",
        "Conclusion: the diff is clean.",
        "",
    ) . block('no findings');
    my ($tok, $exit) = classify($input);
    is($tok, 'no findings', 'TC-C1: clean verdict after heavy reasoning prose');
    is($exit, 0, 'TC-C1: exit 0');
}

# ----- TC-C2 / TC-C3: findings / error states -----------------------------
{
    my ($tok) = classify("Some prose.\n" . block('findings'));
    is($tok, 'findings', 'TC-C2: state: findings -> findings');
}
{
    my ($tok) = classify("Some prose.\n" . block('error'));
    is($tok, 'error', 'TC-C3: state: error -> error');
}

# ----- TC-C4: markdown tolerance around the block --------------------------
{
    my $input = "**Bold heading**\n\n> a blockquoted note `with code`\n\n"
              . block('no findings')
              . "\n_trailing italic prose_\n";
    my ($tok) = classify($input);
    is($tok, 'no findings', 'TC-C4: surrounding markdown noise tolerated');
}

# ----- TC-C5 / TC-C6: empty / prose-only -> error --------------------------
{
    my ($tok, $exit) = classify('');
    is($tok, 'error', 'TC-C5: empty stdin -> error');
    is($exit, 0, 'TC-C5: exit 0 even for error token');
}
{
    my ($tok) = classify("Lots of analysis but no verdict block at all.\n");
    is($tok, 'error', 'TC-C6: prose only, zero blocks -> error');
}

# ----- TC-C7: invalid state value -> error ---------------------------------
{
    my ($tok) = classify(block('clean'));
    is($tok, 'error', 'TC-C7: invalid state value (clean) -> error');
}

# ----- TC-C8: empty/whitespace state -> error (not silently dropped) -------
{
    my ($tok) = classify("```cwf-review\nstate:   \n```\n");
    is($tok, 'error', 'TC-C8: whitespace-only state -> error');
}

# ----- TC-C9: unterminated fence -> error ----------------------------------
{
    my ($tok) = classify("```cwf-review\nstate: no findings\n");
    is($tok, 'error', 'TC-C9: unterminated fence -> error');
}

# ----- TC-C10 / TC-C11: two valid blocks -> error --------------------------
{
    my ($tok) = classify(block('no findings') . "between\n" . block('no findings'));
    is($tok, 'error', 'TC-C10: two valid blocks (same state) -> error');
}
{
    my ($tok) = classify(block('no findings') . "between\n" . block('findings'));
    is($tok, 'error', 'TC-C11: two valid blocks (conflicting) -> error');
}

# ----- TC-C12: echoed non-token example safeguard --------------------------
{
    # Echoed worked example alone -> error (placeholder never validates).
    my ($tok) = classify(block('<no findings|findings|error>'));
    is($tok, 'error', 'TC-C12a: echoed example alone -> error');
}
{
    # Echoed example alongside exactly one real valid block -> the real state.
    my $input = "Here is the format I will use:\n"
              . block('<no findings|findings|error>')
              . "\nAnd my actual verdict:\n"
              . block('no findings');
    my ($tok) = classify($input);
    is($tok, 'no findings', 'TC-C12b: echoed example + one real block -> real state');
}

# ----- TC-C13: case / whitespace normalisation -----------------------------
{
    my ($tok) = classify("```cwf-review\nState:  NO FINDINGS \n```\n");
    is($tok, 'no findings', 'TC-C13: case + whitespace normalised');
}

# ----- TC-C14: --help -------------------------------------------------------
{
    my $out = `'$HELPER' --help`;
    my $exit = $? >> 8;
    like($out, qr/Usage:/, 'TC-C14: --help prints usage');
    is($exit, 0, 'TC-C14: --help exit 0');
}

done_testing();
