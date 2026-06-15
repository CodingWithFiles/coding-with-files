#!/usr/bin/env perl
#
# userpromptsubmit-context-inject.t - Behaviour tests for the paths-injecting
# UserPromptSubmit hook (Task 206). Drives the hook with canned stdin and
# asserts its stdout — never a live turn (deterministic, and no permission
# prompt, the property under test).
#
# Covers (e-testing-plan TC-9..TC-12):
#   TC-9  happy path  -> emits cwd/project_root/scratch literals; exit 0; NO $ or backtick
#   TC-10 unusable payload cwd -> falls back, never emits a wrong root; exit 0
#   TC-11 missing/empty cwd & malformed JSON -> fail-open, no crash, exit 0
#   TC-12 not-a-repo (CLAUDE_PROJECT_DIR unset) -> cwd-only; exit 0
#
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use Cwd qw(cwd);
use POSIX ();
use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib');
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use CWFTest::Fixtures qw(create_git_repo);

plan tests => 4;

my $HOOK = File::Spec->catfile($FindBin::Bin, '..', '.cwf', 'scripts', 'hooks',
                               'userpromptsubmit-context-inject');

# Run the hook with the given stdin, optional process cwd, and env overrides
# (value undef => delete the var). Returns ($stdout, $exit_code).
sub run_hook {
    my %opt = @_;
    my $stdin_file = File::Spec->catfile(tempdir(CLEANUP => 1), 'in.json');
    open(my $w, '>', $stdin_file) or die "open $stdin_file: $!";
    print {$w} (defined $opt{stdin} ? $opt{stdin} : '');
    close $w;

    local %ENV = %ENV;
    if ($opt{env}) {
        for my $k (keys %{$opt{env}}) {
            if (defined $opt{env}{$k}) { $ENV{$k} = $opt{env}{$k} }
            else                       { delete $ENV{$k} }
        }
    }

    my $orig = cwd();
    chdir $opt{process_cwd} if defined $opt{process_cwd};
    my $pid = open(my $rd, '-|');
    defined $pid or die "fork: $!";
    if ($pid == 0) {
        open(STDIN, '<', $stdin_file) or POSIX::_exit(127);
        exec($HOOK) or POSIX::_exit(127);
    }
    local $/;
    my $out = <$rd>;
    close $rd;
    my $exit = $? >> 8;
    chdir $orig;
    return (defined $out ? $out : '', $exit);
}

subtest 'TC-9: happy path emits three literals, exit 0, no shell-expansion tokens' => sub {
    plan tests => 6;
    my $base = tempdir(CLEANUP => 1);
    my $repo = create_git_repo($base);
    plan skip_all => 'could not create git repo' unless defined $repo;

    my ($out, $exit) = run_hook(stdin => qq({"cwd":"$repo"}));
    is($exit, 0, 'exit 0');
    like($out, qr/^\s*cwd:\s+\Q$repo\E$/m,       'cwd line present');
    like($out, qr/^\s*project_root:\s+\S/m,      'project_root line present');
    like($out, qr/^\s*scratch:\s+\S*cwf\S/m,     'scratch line present (cwf parent)');
    unlike($out, qr/\$/,  'output contains no $ (no shell-expansion token to echo)');
    unlike($out, qr/`/,   'output contains no backtick');
};

subtest 'TC-10: unusable payload cwd never yields a wrong root, exit 0' => sub {
    plan tests => 2;
    my $non_repo = tempdir(CLEANUP => 1);
    # Payload cwd is bogus; process cwd is a non-repo dir; no CLAUDE_PROJECT_DIR.
    my ($out, $exit) = run_hook(
        stdin       => '{"cwd":"/nonexistent/path/xyz"}',
        process_cwd => $non_repo,
        env         => { CLAUDE_PROJECT_DIR => undef },
    );
    is($exit, 0, 'exit 0');
    unlike($out, qr/^\s*project_root:/m, 'no project_root emitted outside a repo');
};

subtest 'TC-11: missing/empty cwd & malformed JSON fail open, exit 0' => sub {
    my @inputs = ('{}', '', 'not json at all', '{"cwd":123}');
    plan tests => 2 * scalar(@inputs);
    my $non_repo = tempdir(CLEANUP => 1);
    for my $in (@inputs) {
        my ($out, $exit) = run_hook(
            stdin       => $in,
            process_cwd => $non_repo,
            env         => { CLAUDE_PROJECT_DIR => undef },
        );
        is($exit, 0, "exit 0 for stdin: '$in'");
        unlike($out, qr/^\s*project_root:/m, "no wrong root for stdin: '$in'");
    }
};

subtest 'TC-12: not-a-repo -> cwd-only, exit 0' => sub {
    plan tests => 3;
    my $non_repo = tempdir(CLEANUP => 1);
    my ($out, $exit) = run_hook(
        stdin => qq({"cwd":"$non_repo"}),
        env   => { CLAUDE_PROJECT_DIR => undef },
    );
    is($exit, 0, 'exit 0');
    like($out,   qr/^\s*cwd:\s+\Q$non_repo\E$/m, 'cwd line present');
    unlike($out, qr/^\s*(project_root|scratch):/m, 'no project_root/scratch outside a repo');
};
