#!/usr/bin/env perl
#
# tool-check-seed.t — integration tests for the tool-check-seed helper (Task 220),
# the single DRY writer behind /cwf-config and /cwf-init.
#
# The helper is impure: it locates the git root (find_git_root shells out), reads
# and atomically writes the checked-in / project-local settings files, and creates
# parent dirs symlink-safely. So each test builds a hermetic git repo under a
# tempdir with a runnable COPY of the helper, the real .cwf/lib on PERL5LIB, and
# $HOME pinned into the tempdir (so the user-global layer is controllable and the
# real ~/.cwf is never touched). The pure policy (resolve_active / merge_seed) is
# covered in tool-check.t; here we bind the wiring: seed idempotency + no-clobber,
# top-level key preservation, the toggle target + gitignore control, symlink-safe
# writes, and unknown-subcommand rejection.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use JSON::PP;

my $REPO = File::Spec->rel2abs("$FindBin::Bin/..");
my $SRC  = "$REPO/.cwf/scripts/command-helpers/tool-check-seed";

plan skip_all => 'git not available' if system('git --version >/dev/null 2>&1') != 0;

my $CI_REL = '.cwf/tool-check/bash/settings.json';
my $PL_REL = '.cwf/tool-check/bash/settings.local.json';

# Build a hermetic git repo with a runnable helper copy. Returns ($tmp, $helper).
sub mkrepo {
    my $tmp = tempdir(CLEANUP => 1);
    system("git -C '$tmp' init -q") == 0 or die 'git init failed';
    make_path("$tmp/.cwf/scripts/command-helpers", "$tmp/home");

    open(my $in, '<:raw', $SRC) or die "open $SRC: $!";
    my $body = do { local $/; <$in> }; close $in;
    my $helper = "$tmp/.cwf/scripts/command-helpers/tool-check-seed";
    open(my $out, '>:raw', $helper) or die "write $helper: $!";
    print $out $body; close $out;
    chmod 0700, $helper;
    return ($tmp, $helper);
}

# Run the helper with cwd at the repo root, $HOME pinned into the tempdir.
# Returns ($exit, $stdout, $stderr).
sub run_seed {
    my ($tmp, $helper, @args) = @_;
    my $so = "$tmp/.out"; my $se = "$tmp/.err";
    local $ENV{PERL5LIB} =
        "$REPO/.cwf/lib" . (defined $ENV{PERL5LIB} ? ":$ENV{PERL5LIB}" : '');
    local $ENV{HOME} = "$tmp/home";
    my $argstr = join ' ', map { "'$_'" } @args;
    my $rc = system("cd '$tmp' && '$helper' $argstr >'$so' 2>'$se'");
    my $out = do { open(my $o,'<:raw',$so) or die $!; local $/; <$o> } // '';
    my $err = do { open(my $e,'<:raw',$se) or die $!; local $/; <$e> } // '';
    return ($rc >> 8, $out, $err);
}

sub slurp { my ($p) = @_; open(my $fh,'<:raw',$p) or return undef; local $/; <$fh> }
sub read_json { my ($p) = @_; my $b = slurp($p); return undef unless defined $b;
                return scalar eval { JSON::PP->new->decode($b) } }
sub write_json {
    my ($p, $data) = @_;
    make_path(dirname($p));
    open(my $fh,'>:raw',$p) or die "write $p: $!";
    print $fh JSON::PP->new->encode($data); close $fh;
}

# ----- TC-S1: seed is idempotent --------------------------------------------
subtest 'TC-S1: seed twice -> identical checked-in file' => sub {
    plan tests => 3;
    my ($tmp, $h) = mkrepo();
    my ($e1) = run_seed($tmp, $h, 'seed');
    is($e1, 0, 'first seed exits 0');
    my $after1 = slurp("$tmp/$CI_REL");
    my ($e2) = run_seed($tmp, $h, 'seed');
    is($e2, 0, 'second seed exits 0');
    is(slurp("$tmp/$CI_REL"), $after1, 'checked-in file byte-identical after re-seed');
};

# ----- TC-S2: re-seed never clobbers a user-edited starter id (AC6) ---------
subtest 'TC-S2: a user-edited starter rule survives re-seeding, skip reported' => sub {
    plan tests => 3;
    my ($tmp, $h) = mkrepo();
    # Pre-plant a checked-in settings whose no-sed-line-range guidance is edited.
    write_json("$tmp/$CI_REL", { rules => [
        { id => 'no-sed-line-range', regex => 'X', guidance => 'MY OWN WORDS' },
    ] });
    my ($e, $o) = run_seed($tmp, $h, 'seed');
    is($e, 0, 'seed exits 0');
    my $j = read_json("$tmp/$CI_REL");
    my ($edited) = grep { $_->{id} eq 'no-sed-line-range' } @{ $j->{rules} };
    is($edited->{guidance}, 'MY OWN WORDS', 'the user-edited rule is preserved (not overwritten)');
    like($o, qr/already present/, 'the skip is reported to the operator');
};

# ----- TC-S3: preserving RMW keeps unrelated top-level keys -----------------
subtest 'TC-S3: seed preserves a pre-existing unrelated top-level key' => sub {
    plan tests => 2;
    my ($tmp, $h) = mkrepo();
    write_json("$tmp/$CI_REL", { rules => [], '_note' => 'keep me' });
    run_seed($tmp, $h, 'seed');
    my $j = read_json("$tmp/$CI_REL");
    is($j->{_note}, 'keep me', 'the unrelated key survived the read-modify-write');
    ok(scalar(@{ $j->{rules} }) >= 1, 'starter rules were still added');
};

# ----- TC-S4: toggle writes only project-local; gitignore control (AC3) -----
subtest 'TC-S4: off touches only settings.local.json; it is git-ignored' => sub {
    plan tests => 4;
    my ($tmp, $h) = mkrepo();
    # Seed the repo .gitignore with the shipped glob (the security control).
    write_json("$tmp/x", {}); unlink "$tmp/x";
    open(my $gi, '>:raw', "$tmp/.gitignore") or die $!;
    print $gi ".cwf/tool-check/*/settings.local.json\n"; close $gi;

    my ($e) = run_seed($tmp, $h, 'off');
    is($e, 0, 'off exits 0');
    ok(-e "$tmp/$PL_REL",  'project-local settings.local.json was written');
    ok(!-e "$tmp/$CI_REL", 'the checked-in settings.json was NOT created by off');

    # git check-ignore: the local file is ignored (exit 0 == matched).
    my $ci_rc = system("cd '$tmp' && git check-ignore -q '$PL_REL'");
    is($ci_rc >> 8, 0, 'git check-ignore reports settings.local.json as ignored');
};

# ----- TC-S5: seed -> off -> on state transitions ---------------------------
subtest 'TC-S5: effective active tracks on -> off -> on' => sub {
    plan tests => 3;
    my ($tmp, $h) = mkrepo();
    my (undef, $o_seed) = run_seed($tmp, $h, 'seed');
    like($o_seed, qr/effective active:\s*yes/i, 'after seed: effective active yes');
    my (undef, $o_off) = run_seed($tmp, $h, 'off');
    like($o_off, qr/effective active:\s*no/i, 'after off: effective active no');
    my (undef, $o_on) = run_seed($tmp, $h, 'on');
    like($o_on, qr/effective active:\s*yes/i, 'after on: effective active yes');
};

# ----- TC-S6: symlink safety + resulting mode 0600 --------------------------
subtest 'TC-S6: refuses to write through a symlinked target; clean file is 0600' => sub {
    plan tests => 3;
    # (a) target file is a symlink -> refuse, sentinel untouched.
    {
        my ($tmp, $h) = mkrepo();
        my $sentinel = "$tmp/sentinel";
        open(my $sf,'>:raw',$sentinel) or die $!; print $sf "PRECIOUS\n"; close $sf;
        make_path(dirname("$tmp/$PL_REL"));
        symlink($sentinel, "$tmp/$PL_REL")
            or do { pass('symlink unsupported'); pass(); pass(); return };
        my ($e) = run_seed($tmp, $h, 'off');
        isnt($e, 0, 'writing through a symlinked target is refused (non-zero exit)');
        is(slurp($sentinel), "PRECIOUS\n", 'the symlink target is untouched');
    }
    # (b) a clean write lands at mode 0600.
    {
        my ($tmp, $h) = mkrepo();
        run_seed($tmp, $h, 'off');
        my $mode = (stat("$tmp/$PL_REL"))[2] & 07777;
        is($mode, 0600, 'a clean project-local write is mode 0600');
    }
};

# ----- TC-S7: unknown subcommand -> non-zero, usage, no write ---------------
subtest 'TC-S7: unknown subcommand exits non-zero with usage and writes nothing' => sub {
    plan tests => 4;
    my ($tmp, $h) = mkrepo();
    my ($e, $o, $err) = run_seed($tmp, $h, 'bogus');
    isnt($e, 0, 'exit non-zero on an unknown subcommand');
    like($err, qr/unknown subcommand/, 'reports the unknown subcommand on stderr');
    like($err, qr/Usage:/, 'prints usage on stderr');
    ok(!-e "$tmp/$CI_REL" && !-e "$tmp/$PL_REL", 'no settings file was written');
};

# ----- TC-S8: seed after a prior off implies on (F3 ordering) ---------------
subtest 'TC-S8: seed clears a prior project-local off -> effective on' => sub {
    plan tests => 3;
    my ($tmp, $h) = mkrepo();
    run_seed($tmp, $h, 'off');
    my $pl_before = read_json("$tmp/$PL_REL");
    ok(JSON::PP::is_bool($pl_before->{active}) && !$pl_before->{active},
        'precondition: project-local active:false is set');

    my (undef, $o) = run_seed($tmp, $h, 'seed');
    ok(scalar(@{ read_json("$tmp/$CI_REL")->{rules} }) >= 1, 'checked-in rules present');
    like($o, qr/effective active:\s*yes/i, 'the prior off was cleared -> effective on');
};

# ----- TC-S9: a broken user-global layer does not corrupt the state echo ----
# Regression for the robustness finding: effective_active must read layers
# non-fatally, so a symlinked/corrupt ~/.cwf user-global settings file cannot turn
# an already-completed toggle write into a misleading non-zero exit.
subtest 'TC-S9: broken user-global settings -> off still exits 0 and writes' => sub {
    plan tests => 3;
    my ($tmp, $h) = mkrepo();
    # Plant a symlinked user-global settings file (a common dotfiles setup).
    my $ug = "$tmp/home/.cwf/tool-check/bash/settings.json";
    make_path(dirname($ug));
    my $real = "$tmp/home/real-ug.json"; write_json($real, { rules => [] });
    symlink($real, $ug) or do { pass('symlink unsupported'); pass(); pass(); return };

    my ($e, $o) = run_seed($tmp, $h, 'off');
    is($e, 0, 'off exits 0 despite the broken user-global layer (echo is non-fatal)');
    ok(-e "$tmp/$PL_REL", 'the project-local write still completed');
    like($o, qr/effective active:/i, 'the state echo line was still printed');
};

done_testing();
