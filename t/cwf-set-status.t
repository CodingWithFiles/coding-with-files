#!/usr/bin/env perl
#
# cwf-set-status.t - Tests for cwf-set-status helper script
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;

my $SCRIPT = "$FindBin::Bin/../.cwf/scripts/command-helpers/cwf-set-status";

my $CONFIG_JSON = <<'JSON';
{
  "workflow": {
    "status-values": {
      "Backlog": 0,
      "Blocked": 15,
      "To-Do": 0,
      "In Progress": 25,
      "Testing": 75,
      "Finished": 100,
      "Cancelled": 0,
      "Skipped": 100
    }
  }
}
JSON

sub make_fixture {
    my ($status) = @_;
    $status //= 'Backlog';
    my $dir = tempdir(CLEANUP => 1);
    my $cfg_dir = "$dir/implementation-guide";
    make_path($cfg_dir);

    open my $cfh, '>', "$cfg_dir/cwf-project.json" or die "Cannot write config: $!";
    print $cfh $CONFIG_JSON;
    close $cfh;

    my $wf = "$dir/test-file.md";
    open my $fh, '>', $wf or die "Cannot write wf file: $!";
    print $fh <<EOF;
# Test File

## Status
**Status**: $status
**Next Action**: /cwf-testing-exec
**Blockers**: None
EOF
    close $fh;

    return ($dir, $wf);
}

sub slurp {
    open my $fh, '<', $_[0] or die "Cannot read $_[0]: $!";
    my $c = do { local $/; <$fh> };
    close $fh;
    return $c;
}

sub run_script {
    my (@args) = @_;
    my $cmd = join ' ', map { "'$_'" } ($SCRIPT, @args);
    my $output = `$cmd 2>&1`;
    return ($? >> 8, $output);
}

subtest 'TC-F1: successful update' => sub {
    my ($dir, $wf) = make_fixture('Backlog');
    chdir $dir or die "Cannot chdir: $!";

    my ($exit, $out) = run_script($wf, 'In Progress');
    is($exit, 0, 'exit 0 on success');
    like(slurp($wf), qr/\*\*Status\*\*: In Progress/, 'status updated in file');
};

subtest 'TC-F2: idempotent no-op' => sub {
    my ($dir, $wf) = make_fixture('Finished');
    chdir $dir or die "Cannot chdir: $!";

    my $before = slurp($wf);
    my ($exit, $out) = run_script($wf, 'Finished');
    is($exit, 0, 'exit 0 on no-op');
    is(slurp($wf), $before, 'file not modified');
};

subtest 'TC-F3: invalid status' => sub {
    my ($dir, $wf) = make_fixture('Backlog');
    chdir $dir or die "Cannot chdir: $!";

    my ($exit, $out) = run_script($wf, 'Done');
    is($exit, 1, 'exit 1 on invalid status');
    like($out, qr/Invalid status "Done"/, 'error mentions invalid value');
    like(slurp($wf), qr/\*\*Status\*\*: Backlog/, 'file unchanged');
};

subtest 'TC-F4: file not found' => sub {
    my ($dir, $wf) = make_fixture();
    chdir $dir or die "Cannot chdir: $!";

    my ($exit, $out) = run_script('/tmp/no-such-file-cwf-test.md', 'Finished');
    is($exit, 1, 'exit 1 on missing file');
    like($out, qr/No \*\*Status\*\*:/, 'error reports no status field');
};

subtest 'TC-F5: missing arguments' => sub {
    my ($dir, $wf) = make_fixture();
    chdir $dir or die "Cannot chdir: $!";

    my ($exit_none, $out_none) = run_script();
    is($exit_none, 1, 'exit 1 with no args');
    like($out_none, qr/Usage:/, 'prints usage');

    my ($exit_one, $out_one) = run_script($wf);
    is($exit_one, 1, 'exit 1 with one arg');
    like($out_one, qr/Usage:/, 'prints usage');
};

chdir $FindBin::Bin or die;

done_testing();
