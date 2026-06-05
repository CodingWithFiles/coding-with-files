#!/usr/bin/env perl
#
# pretooluse-sandbox-logging.t — behaviour of the R3 observe-only logging hook
# (Task 179). The hook resolves its log path FindBin-relative
# (.cwf/sandbox-violations.log), so each test runs a COPY placed inside a
# tempdir's .cwf/scripts/hooks/ — the log then lands under the tempdir and the
# real repo is never touched.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use JSON::PP;

my $REPO = File::Spec->rel2abs("$FindBin::Bin/..");
my $SRC  = "$REPO/.cwf/scripts/hooks/pretooluse-sandbox-logging";

# Install a runnable copy of the hook in a fresh tempdir; return ($tmp, $hook).
sub install_hook {
    my $tmp = tempdir(CLEANUP => 1);
    make_path("$tmp/.cwf/scripts/hooks");
    my $dst = "$tmp/.cwf/scripts/hooks/pretooluse-sandbox-logging";
    open(my $in, '<:raw', $SRC) or die "open $SRC: $!";
    my $body = do { local $/; <$in> }; close $in;
    open(my $out, '>:raw', $dst) or die "write $dst: $!";
    print $out $body; close $out;
    chmod 0700, $dst;
    return ($tmp, $dst);
}

# Run the hook with $stdin on its STDIN. Returns ($exit, $stdout).
sub run_hook {
    my ($hook, $stdin) = @_;
    my $dir = (File::Spec->splitpath($hook))[1];
    my $in  = "$dir/.stdin";
    my $so  = "$dir/.stdout";
    open(my $fh, '>:raw', $in) or die $!;
    print $fh $stdin; close $fh;
    my $rc = system("$hook <'$in' >'$so' 2>/dev/null");
    open(my $oh, '<:raw', $so) or die $!;
    my $out = do { local $/; <$oh> }; close $oh;
    return ($rc >> 8, $out // '');
}

sub log_path { return "$_[0]/.cwf/sandbox-violations.log" }
sub read_log {
    my ($tmp) = @_;
    my $p = log_path($tmp);
    return undef unless -e $p;
    open(my $fh, '<:raw', $p) or die $!;
    local $/; my $b = <$fh>; close $fh;
    return $b;
}

subtest 'bypass present → one minimal record, no raw command, allows tool' => sub {
    plan tests => 6;
    my ($tmp, $hook) = install_hook();
    my $stdin = JSON::PP->new->encode({
        tool_name  => 'Bash',
        tool_input => { command => 'rm -rf /secret', dangerouslyDisableSandbox => JSON::PP::true },
    });
    my ($exit, $out) = run_hook($hook, $stdin);
    is($exit, 0, 'exit 0');
    is($out, '', 'empty stdout — never blocks the tool call');
    my $log = read_log($tmp);
    ok(defined $log && length $log, 'a record was written');
    my @lines = grep { length } split /\n/, $log;
    is(scalar @lines, 1, 'exactly one JSON line');
    my $rec = JSON::PP->new->decode($lines[0]);
    ok($rec->{dangerouslyDisableSandbox} && $rec->{tool} eq 'Bash' && $rec->{ts},
       'record carries presence flag + tool + timestamp');
    unlike($log, qr{rm|secret}, 'raw command never recorded');
};

subtest 'no bypass flag → no record, allows tool' => sub {
    plan tests => 2;
    my ($tmp, $hook) = install_hook();
    my ($exit, $out) = run_hook($hook,
        JSON::PP->new->encode({ tool_name => 'Bash', tool_input => { command => 'ls' } }));
    is($exit, 0, 'exit 0');
    ok(!defined read_log($tmp), 'no log written for an ordinary call');
};

subtest 'malformed stdin → fail-open (exit 0, no record)' => sub {
    plan tests => 2;
    my ($tmp, $hook) = install_hook();
    my ($exit, $out) = run_hook($hook, '{ not json');
    is($exit, 0, 'exit 0 on garbage stdin');
    ok(!defined read_log($tmp), 'nothing logged');
};

subtest 'log-write failure swallowed (never blocks)' => sub {
    plan tests => 2;
    my ($tmp, $hook) = install_hook();
    # Make the log path un-openable for append: pre-create it as a directory.
    make_path(log_path($tmp));
    my ($exit, $out) = run_hook($hook, JSON::PP->new->encode({
        tool_name  => 'Bash',
        tool_input => { dangerouslyDisableSandbox => JSON::PP::true },
    }));
    is($exit, 0, 'exit 0 despite unwritable log');
    is($out, '', 'still allows the tool call');
};

done_testing();
