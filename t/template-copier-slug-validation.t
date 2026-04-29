#!/usr/bin/env perl
#
# template-copier-slug-validation.t — Unit tests for slug-length validation
# in template-copier-v2.1's parse_parameters.
#
# Loads template-copier-v2.1 via do(); the script's `main() unless caller();`
# guard prevents top-level execution under the test loader. After load,
# overrides main::die_msg so failure paths are catchable via eval{}.
#
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');

my $SCRIPT = File::Spec->catfile(
    $FindBin::Bin, '..', '.cwf', 'scripts', 'command-helpers', 'template-copier-v2.1'
);

# Load the script. The caller() guard skips main(); only sub definitions are installed.
do $SCRIPT;
die "Failed to load $SCRIPT: $@" if $@;

# Override die_msg so failure paths are catchable. The original calls exit 1,
# which would terminate the test process before assertions could run.
{
    no warnings 'redefine', 'once';
    *main::die_msg = sub { die "[CWF] ERROR: @_\n" };
}

# Helpers --------------------------------------------------------------------

# Build a description that slugifies to exactly $n chars (lowercase ascii + '-').
# generate_slug lowercases, strips non-[a-z0-9 -], collapses ' +' to '-',
# collapses '-+' to '-', strips leading/trailing '-'. So an all-lowercase
# alphanumeric string passes through unchanged in length.
sub desc_of_length {
    my ($n) = @_;
    return 'a' x $n;
}

# Set up parse_parameters args for a given description, with a destination
# already supplied so construct_destination is *not* called (we want to test
# the validation in isolation, not exercise config loading).
sub args_for {
    my ($description, %extra) = @_;
    my $dest = $extra{destination} // '/tmp/template-copier-slug-validation-test-noop';
    return (
        "--task-type=feature",
        "--task-num=999",
        "--description=$description",
        "--destination=$dest",
    );
}

# Tests ----------------------------------------------------------------------

subtest 'TC-test-1: under limit (49 chars) -> no die' => sub {
    plan tests => 1;
    my @args = args_for(desc_of_length(49));
    eval { main::parse_parameters(@args) };
    is($@, '', 'no die for 49-char slug');
};

subtest 'TC-test-2: at limit (50 chars) -> no die' => sub {
    plan tests => 1;
    my @args = args_for(desc_of_length(50));
    eval { main::parse_parameters(@args) };
    is($@, '', 'no die for 50-char slug');
};

subtest 'TC-test-3: just over (51 chars) -> dies' => sub {
    plan tests => 2;
    my @args = args_for(desc_of_length(51));
    eval { main::parse_parameters(@args) };
    like($@, qr{Task slug '.+' is 51 characters; limit is 50}, 'expected error');
    like($@, qr{briefer}i, 'recovery hint mentions "briefer"');
};

subtest 'TC-test-4: well over (100 chars) -> dies, length in message' => sub {
    plan tests => 2;
    my @args = args_for(desc_of_length(100));
    eval { main::parse_parameters(@args) };
    like($@, qr{Task slug '.+' is 100 characters; limit is 50}, 'reports actual length');
    like($@, qr{50}, 'reports the limit');
};

subtest 'TC-test-5: empty after normalising ("!!!") -> dies' => sub {
    plan tests => 2;
    my @args = args_for('!!!');
    eval { main::parse_parameters(@args) };
    like($@, qr{empty slug}i,    'mentions empty slug');
    like($@, qr{'!!!'},          'echoes original description');
};

subtest 'TC-test-6: leading/trailing hyphens stripped -> accepted' => sub {
    plan tests => 2;
    my @args = args_for('---valid-content---');
    eval { main::parse_parameters(@args) };
    is($@, '', 'no die — outer hyphens are stripped, slug is "valid-content"');
    # Sanity: confirm generate_slug actually produces the trimmed form.
    is(main::generate_slug('---valid-content---'), 'valid-content', 'generate_slug strips outer hyphens');
};

subtest 'TC-test-7: error message contents (overlong)' => sub {
    plan tests => 4;
    my @args = args_for(desc_of_length(60));
    eval { main::parse_parameters(@args) };
    like($@, qr{\[CWF\] ERROR:}, 'has [CWF] ERROR: prefix');
    like($@, qr{\b60\b},         'includes actual length (60)');
    like($@, qr{\b50\b},         'includes the limit (50)');
    like($@, qr{briefer|Use a}i, 'includes a recovery hint');
};

subtest 'TC-test-8: atomicity — no filesystem writes on rejection' => sub {
    plan tests => 2;
    my $tmp = tempdir(CLEANUP => 1);

    # Snapshot directory contents before
    opendir(my $dh1, $tmp) or die $!;
    my @before = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh1);
    closedir($dh1);

    my @args = args_for(desc_of_length(80), destination => "$tmp/never-created");
    eval { main::parse_parameters(@args) };
    like($@, qr{Task slug}, 'rejected as expected');

    # Snapshot after
    opendir(my $dh2, $tmp) or die $!;
    my @after = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh2);
    closedir($dh2);

    is_deeply(\@after, \@before, 'tempdir unchanged after rejection');
};

done_testing();
