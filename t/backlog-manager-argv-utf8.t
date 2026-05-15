#!/usr/bin/env perl
#
# backlog-manager-argv-utf8.t — Bug-137 regression cover. Proves that
# `backlog-manager add` writes non-ASCII argv values as clean UTF-8
# bytes (not double-encoded mojibake) and that `normalise` preserves
# pre-existing non-ASCII bytes byte-for-byte.
#
# The fix relies on PERL5OPT=-CDSLA being set in the environment (the
# `A` decodes @ARGV as UTF-8). Task 27 / Task 139 moved this contract
# off the kernel shebang line and onto PERL5OPT — the shebang itself
# is now plain `#!/usr/bin/env perl`. To prove PERL5OPT is the contract,
# the child process is spawned with PERL5OPT explicitly set, regardless
# of what the parent session has.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use Encode qw(encode);

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $SCRIPT    = File::Spec->catfile($REPO_ROOT, '.cwf', 'scripts',
                                    'command-helpers', 'backlog-manager');

my $VALID_BACKLOG_MIN = <<'END';
# CWF System Backlog

Intro.


END

my $VALID_CHANGELOG = <<'END';
# Changelog

END

sub make_isolated {
    my (%files) = @_;
    my $dir = tempdir(CLEANUP => 1);
    system('git', 'init', '-q', $dir) == 0 or die "git init: $?";
    for my $name (keys %files) {
        my $path = File::Spec->catfile($dir, $name);
        open my $fh, '>:raw', $path or die "$path: $!";
        print {$fh} $files{$name};
        close $fh;
    }
    return $dir;
}

# Spawn backlog-manager with PERL5OPT=-CDSLA forced in the child env, so the
# env var is the sole source of -C flags. List-form exec — no shell, no
# quoting. @args must contain UTF-8 octet strings (no Perl character strings).
sub run_bm_with_perl5opt {
    my ($dir, @args) = @_;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        $ENV{PERL5OPT} = '-CDSLA';
        chdir $dir or die "chdir $dir: $!";
        open STDERR, '>', "$dir/.stderr" or die "redirect stderr: $!";
        open STDOUT, '>', "$dir/.stdout" or die "redirect stdout: $!";
        exec { $SCRIPT } $SCRIPT, @args;
        die "exec: $!";
    }
    waitpid $pid, 0;
    my $rc = $? >> 8;
    my $err = '';
    if (open my $fh, '<:raw', "$dir/.stderr") { local $/; $err = <$fh>; close $fh }
    return ($rc, $err);
}

sub slurp_raw {
    open my $fh, '<:raw', $_[0] or die "$_[0]: $!";
    local $/;
    my $b = <$fh>;
    close $fh;
    return $b;
}

# The three multi-byte UTF-8 codepoints under test:
#   →  U+2192  →  e2 86 92
#   §  U+00A7  →  c2 a7
#   —  U+2014  →  e2 80 94
my $ARROW   = "\xe2\x86\x92";   # raw bytes, not character string
my $SECTION = "\xc2\xa7";
my $EMDASH  = "\xe2\x80\x94";

# The double-encoded ("mojibake") forms the bug produced:
#   →  e2 86 92  →  c3 a2 c2 86 c2 92   (6 bytes)
#   §  c2 a7     →  c3 82 c2 a7         (4 bytes)
#   —  e2 80 94  →  c3 a2 c2 80 c2 94   (6 bytes)
my $ARROW_MOJI   = "\xc3\xa2\xc2\x86\xc2\x92";
my $SECTION_MOJI = "\xc3\x82\xc2\xa7";
my $EMDASH_MOJI  = "\xc3\xa2\xc2\x80\xc2\x94";

#==============================================================================
# TC-F1 — add with non-ASCII argv writes clean UTF-8 bytes (the reported bug)
#==============================================================================

subtest 'TC-F1: add with non-ASCII argv writes clean UTF-8 bytes' => sub {
    plan tests => 7;
    my $dir = make_isolated(
        'BACKLOG.md'   => $VALID_BACKLOG_MIN,
        'CHANGELOG.md' => $VALID_CHANGELOG,
    );
    my $title_bytes = "Smoke 137: $ARROW $SECTION $EMDASH";
    my $body_bytes  = "non-ascii body: $ARROW $SECTION $EMDASH";
    my ($rc, $err) = run_bm_with_perl5opt(
        $dir, 'add',
        '--priority=Low',
        '--task-type=chore',
        "--title=$title_bytes",
        "--body=$body_bytes",
    );
    is($rc, 0, "add exit 0 (err: $err)")
        or diag("backlog-manager add stderr: $err");

    my $content = slurp_raw(File::Spec->catfile($dir, 'BACKLOG.md'));
    like($content, qr/\Q$ARROW\E/,   '→ written as clean e2 86 92');
    like($content, qr/\Q$SECTION\E/, '§ written as clean c2 a7');
    like($content, qr/\Q$EMDASH\E/,  '— written as clean e2 80 94');

    unlike($content, qr/\Q$ARROW_MOJI\E/,
        '→ NOT double-encoded (no c3 a2 c2 86 c2 92)');
    unlike($content, qr/\Q$SECTION_MOJI\E/,
        '§ NOT double-encoded (no c3 82 c2 a7)');
    unlike($content, qr/\Q$EMDASH_MOJI\E/,
        '— NOT double-encoded (no c3 a2 c2 80 c2 94)');
};

#==============================================================================
# TC-F2 — normalise preserves existing non-ASCII bytes byte-for-byte
#==============================================================================

subtest 'TC-F2: normalise preserves existing non-ASCII bytes' => sub {
    plan tests => 4;
    my $backlog_with_unicode = <<"END";
# CWF System Backlog

Intro with $ARROW and $SECTION and $EMDASH.


## Task: Existing $ARROW $SECTION $EMDASH

### Task-Type: chore
### Priority: Low
### Status: Backlog

Body with $ARROW arrow.
END
    my $dir = make_isolated(
        'BACKLOG.md'   => $backlog_with_unicode,
        'CHANGELOG.md' => $VALID_CHANGELOG,
    );
    my ($rc, $err) = run_bm_with_perl5opt($dir, 'normalise');
    is($rc, 0, "normalise exit 0 (err: $err)")
        or diag("backlog-manager normalise stderr: $err");

    my $content = slurp_raw(File::Spec->catfile($dir, 'BACKLOG.md'));
    like($content, qr/\Q$ARROW\E/,   '→ preserved by normalise');
    like($content, qr/\Q$SECTION\E/, '§ preserved by normalise');
    like($content, qr/\Q$EMDASH\E/,  '— preserved by normalise');
};

done_testing;
