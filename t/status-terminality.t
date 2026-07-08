#!/usr/bin/env perl
#
# status-terminality.t - Guard against non-canonical status leaks (Task 222)
#
# Two reuse-based checks, no new production code and no fixtures:
#   FR4b - template hygiene: every status token shipped by a pool template
#          (the **Status**: seed and any `Update status to "..."` hint) is a
#          canonical value per CWF::TaskState::status_is_valid.
#   FR3/D6 - the stop-stale-status-detector hook flags Backlog + non-canonical
#          statuses but leaves valid in-progress / terminal ones alone.
#

use strict;
use warnings;
use utf8;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";

use CWF::TaskState qw(status_get status_is_valid);

#==============================================================================
# FR4b - Pool template status hygiene
#==============================================================================

my $pool = "$FindBin::Bin/../.cwf/templates/pool";
my @templates = sort glob "$pool/*.md.template";
ok(@templates >= 10, "found pool templates (@{[ scalar @templates ]})");

for my $tpl (@templates) {
    (my $name = $tpl) =~ s{.*/}{};

    # Seed status (the **Status**: field the template ships with)
    my $seed = status_get($tpl);
    ok(status_is_valid($seed), "$name: seed status '$seed' is canonical");

    # Any `Update status to "..."` hint line must name only canonical values.
    open my $fh, '<:encoding(UTF-8)', $tpl or die "cannot read $tpl: $!";
    while (my $line = <$fh>) {
        next unless $line =~ /Update status to/;
        while ($line =~ /"([^"]+)"/g) {
            my $token = $1;
            ok(status_is_valid($token),
               "$name: hint token '$token' is canonical");
        }
    }
    close $fh;
}

#==============================================================================
# FR3/D6 - stop-stale-status-detector flag predicate
#==============================================================================

# Load the hook's predicate without running its main body (guarded by `caller`).
my $hook = "$FindBin::Bin/../.cwf/scripts/hooks/stop-stale-status-detector";
do $hook;
die "failed to load $hook: $@" if $@;
ok(main->can('is_flaggable'), 'hook exposes is_flaggable predicate');

ok( is_flaggable('Backlog'),      'flags Backlog (template default)');
ok( is_flaggable('Design'),       'flags Design (non-canonical leak)');
ok(!is_flaggable('In Progress'),  'ignores In Progress (valid, non-terminal)');
ok(!is_flaggable('Finished'),     'ignores Finished (valid, terminal)');

done_testing();
