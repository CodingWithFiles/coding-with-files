#!/usr/bin/env perl
#
# cwf-apply-artefacts.t — Tests for the artefact-application helper.
# Builds a synthetic source repo + installed repo per test, runs the helper,
# and asserts file state, exit codes, and log lines.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Cwd qw(getcwd);
use JSON::PP;
use Digest::SHA qw(sha256_hex);

my $REPO   = File::Spec->rel2abs("$FindBin::Bin/..");
my $HELPER = "$REPO/.cwf/scripts/command-helpers/cwf-apply-artefacts";

# --- Fixture helpers -------------------------------------------------------

sub write_file {
    my ($path, $content) = @_;
    my (undef, $dir) = File::Spec->splitpath($path);
    make_path($dir) if length $dir && !-d $dir;
    open my $fh, '>:raw', $path or die "write_file($path): $!";
    print $fh $content;
    close $fh;
    return;
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<:raw', $path or return undef;
    local $/;
    my $blob = <$fh>;
    close $fh;
    return $blob;
}

sub sha { return sha256_hex($_[0]); }

# Build a minimal source root: includes a manifest + the source files it
# references. Returns the source root path.
sub build_source {
    my (%opts) = @_;
    my $tmp = tempdir(CLEANUP => 1);

    my $rules_inject  = $opts{rules_inject_content}  // '';
    my $preamble      = $opts{preamble_content}      // "> CWF preamble line.\n";
    my $rule_file     = $opts{rule_file_content}     // "rule body\n";

    write_file("$tmp/.cwf/templates/install/rules-inject.txt", $rules_inject);
    write_file("$tmp/.cwf/templates/install/claude-md-preamble.md", $preamble);
    write_file("$tmp/.claude/rules/cwf-workflow-files.md", $rule_file);

    my $manifest = {
        schema_version => 1,
        cwf_version    => 'test',
        generated_at   => '2026-05-05T00:00:00Z',
        artefacts      => [
            {
                id    => 'gitignore-entries',
                kind  => 'line-additive',
                dest  => '.gitignore',
                lines => [ '.cwf/task-stack', '.cwf/.update.lock' ],
            },
            {
                id     => 'rules-inject',
                kind   => 'file',
                source => '.cwf/templates/install/rules-inject.txt',
                dest   => '.cwf/rules-inject.txt',
                sha256 => sha($rules_inject),
            },
            {
                id     => 'cwf-rules-bundle',
                kind   => 'tree',
                source => '.claude/rules/',
                dest   => '.cwf-rules/',
                files  => { 'cwf-workflow-files.md' => sha($rule_file) },
            },
            {
                id           => 'claude-md-preamble',
                kind         => 'embedded-block',
                container    => 'CLAUDE.md',
                marker_start => '<!-- CWF-PREAMBLE-START -->',
                marker_end   => '<!-- CWF-PREAMBLE-END -->',
                source       => '.cwf/templates/install/claude-md-preamble.md',
                sha256       => sha($preamble),
            },
        ],
    };
    if ($opts{manifest_overrides}) {
        for my $k (keys %{$opts{manifest_overrides}}) {
            $manifest->{$k} = $opts{manifest_overrides}{$k};
        }
    }
    write_file("$tmp/.cwf/install-manifest.json",
               JSON::PP->new->pretty->canonical->encode($manifest));
    return ($tmp, $manifest);
}

# Build an installed root: optionally include an existing manifest, .gitignore,
# .cwf-rules/, .cwf/rules-inject.txt, CLAUDE.md.
sub build_installed {
    my (%opts) = @_;
    my $tmp = tempdir(CLEANUP => 1);
    write_file("$tmp/$_", '') for ();
    if ($opts{gitignore})    { write_file("$tmp/.gitignore", $opts{gitignore}) }
    if ($opts{rules_inject}) { write_file("$tmp/.cwf/rules-inject.txt", $opts{rules_inject}) }
    if ($opts{rule_file})    { write_file("$tmp/.cwf-rules/cwf-workflow-files.md", $opts{rule_file}) }
    if ($opts{claude_md})    { write_file("$tmp/CLAUDE.md", $opts{claude_md}) }
    if ($opts{installed_manifest}) {
        write_file("$tmp/.cwf/install-manifest.json",
                   JSON::PP->new->pretty->canonical->encode($opts{installed_manifest}));
    }
    return $tmp;
}

# Run the helper. Returns ($exit, $stdout, $stderr).
sub run_helper {
    my ($git_root, $source_root, @args) = @_;
    my $stdout_path = "$git_root/.helper.stdout";
    my $stderr_path = "$git_root/.helper.stderr";
    my $rc = system("$HELPER '$git_root' '$source_root' "
                    . join(' ', map { "'$_'" } @args)
                    . " >'$stdout_path' 2>'$stderr_path' </dev/null");
    my $exit = $rc >> 8;
    return ($exit, read_file($stdout_path) // '', read_file($stderr_path) // '');
}

# --- TC-U-HELP ----
subtest '--help prints usage and exits 0' => sub {
    my $rc = system("$HELPER --help >/dev/null 2>&1");
    is($rc >> 8, 0, '--help exits 0');
};

# --- TC-LA-1: line-additive — append missing lines, leave unrelated alone ---
subtest 'line-additive: append missing lines, idempotent' => sub {
    my ($src) = build_source();
    my $inst  = build_installed(gitignore => "node_modules/\n");
    my ($e, $o, $err) = run_helper($inst, $src, '--bootstrap-init');
    is($e, 0, 'exit 0') or diag $err;
    my $gi = read_file("$inst/.gitignore");
    like($gi, qr/^node_modules\/\n/m,    'preserves user line');
    like($gi, qr/^\.cwf\/task-stack$/m,   'adds .cwf/task-stack');
    like($gi, qr/^\.cwf\/\.update\.lock$/m, 'adds .cwf/.update.lock');

    # Idempotency
    my $first = read_file("$inst/.gitignore");
    my ($e2) = run_helper($inst, $src, '--bootstrap-init');
    is($e2, 0, 'rerun exit 0');
    is(read_file("$inst/.gitignore"), $first, 'second run is byte-identical');
};

# --- TC-LA-NEWLINE: reject newline-injected manifest line ------------------
subtest 'line-additive: rejects newline injection' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    write_file("$tmp/.cwf/templates/install/rules-inject.txt", '');
    write_file("$tmp/.cwf/templates/install/claude-md-preamble.md", "x\n");
    write_file("$tmp/.claude/rules/cwf-workflow-files.md", "y\n");
    my $manifest = {
        schema_version => 1,
        artefacts => [
            { id => 'gitignore-entries', kind => 'line-additive', dest => '.gitignore',
              lines => [ "evil\n.evil-injected" ] },
        ],
    };
    write_file("$tmp/.cwf/install-manifest.json",
               JSON::PP->new->canonical->encode($manifest));
    my $inst = build_installed();
    my ($e, $o, $err) = run_helper($inst, $tmp);
    is($e, 3, 'exit 3 (path validation)') or diag $err;
    like($err, qr/forbidden newline/, 'rejection logged');
};

# --- TC-RI-1: rules-inject replace — install via bootstrap ----------------
subtest 'rules-inject: install in bootstrap mode' => sub {
    my ($src) = build_source(rules_inject_content => "ALPHA\n");
    my $inst  = build_installed();
    my ($e, $o, $err) = run_helper($inst, $src, '--bootstrap-init');
    is($e, 0, 'exit 0') or diag $err;
    is(read_file("$inst/.cwf/rules-inject.txt"), "ALPHA\n", 'content installed');
    like($err, qr{rules-inject\.txt updated \(was , now },
         'audit log line written');
};

# --- TC-RI-2: rules-inject — already up to date ---------------------------
subtest 'rules-inject: no-op when on-disk == new' => sub {
    my ($src) = build_source(rules_inject_content => "BETA\n");
    my $inst  = build_installed(rules_inject => "BETA\n");
    my ($e, $o, $err) = run_helper($inst, $src, '--bootstrap-init');
    is($e, 0, 'exit 0');
    like($err, qr/rules-inject: already up to date/, 'no-op log');
};

# --- TC-RI-3: rules-inject conflict — non-TTY default = abort -------------
subtest 'rules-inject: non-TTY default abort on conflict' => sub {
    my ($src) = build_source(rules_inject_content => "NEW\n");
    my $inst  = build_installed(rules_inject => "USER-MOD\n");
    # Set installed manifest so on-disk != baseline → conflict.
    write_file("$inst/.cwf/install-manifest.json",
               JSON::PP->new->canonical->encode({
                   schema_version => 1,
                   artefacts => [
                       { id => 'rules-inject', kind => 'file',
                         source => '.cwf/templates/install/rules-inject.txt',
                         dest => '.cwf/rules-inject.txt',
                         sha256 => sha("BASELINE\n") },
                   ],
               }));
    my ($e, $o, $err) = run_helper($inst, $src);
    is($e, 1, 'exit 1 (abort)') or diag $err;
    like($err, qr/no TTY/, 'logs no-TTY reason');
    is(read_file("$inst/.cwf/rules-inject.txt"), "USER-MOD\n",
       'on-disk file unchanged');
};

# --- TC-FR5-INVALID: invalid env exits 1 -----------------------------------
subtest 'CWF_UPGRADE_RESOLVE invalid value exits 1' => sub {
    local $ENV{CWF_UPGRADE_RESOLVE} = 'maybe';
    my ($src) = build_source();
    my $inst  = build_installed();
    my ($e, $o, $err) = run_helper($inst, $src, '--bootstrap-init');
    is($e, 1, 'exit 1') or diag $err;
    like($err, qr/invalid CWF_UPGRADE_RESOLVE/, 'rejection logged');
};

# --- TC-FR5-KEEP: env=keep skips overwrite ---------------------------------
subtest 'CWF_UPGRADE_RESOLVE=keep skips conflicting replace' => sub {
    local $ENV{CWF_UPGRADE_RESOLVE} = 'keep';
    my ($src) = build_source(rules_inject_content => "NEW\n");
    my $inst  = build_installed(rules_inject => "USER-MOD\n");
    write_file("$inst/.cwf/install-manifest.json",
               JSON::PP->new->canonical->encode({
                   schema_version => 1,
                   artefacts => [
                       { id => 'rules-inject', kind => 'file',
                         source => '.cwf/templates/install/rules-inject.txt',
                         dest => '.cwf/rules-inject.txt',
                         sha256 => sha("BASELINE\n") },
                   ],
               }));
    my ($e) = run_helper($inst, $src);
    is($e, 0, 'exit 0');
    is(read_file("$inst/.cwf/rules-inject.txt"), "USER-MOD\n",
       'on-disk preserved');
};

# --- TC-FR5-NEW: env=new installs upstream over modified -------------------
subtest 'CWF_UPGRADE_RESOLVE=new installs upstream' => sub {
    local $ENV{CWF_UPGRADE_RESOLVE} = 'new';
    my ($src) = build_source(rules_inject_content => "NEW\n");
    my $inst  = build_installed(rules_inject => "USER-MOD\n");
    write_file("$inst/.cwf/install-manifest.json",
               JSON::PP->new->canonical->encode({
                   schema_version => 1,
                   artefacts => [
                       { id => 'rules-inject', kind => 'file',
                         source => '.cwf/templates/install/rules-inject.txt',
                         dest => '.cwf/rules-inject.txt',
                         sha256 => sha("BASELINE\n") },
                   ],
               }));
    my ($e) = run_helper($inst, $src);
    is($e, 0, 'exit 0');
    is(read_file("$inst/.cwf/rules-inject.txt"), "NEW\n",
       'upstream installed');
};

# --- TC-EB-1: embedded-block — installs preamble with sentinels ------------
subtest 'embedded-block: bootstrap installs into empty CLAUDE.md' => sub {
    my ($src) = build_source(preamble_content => "> hello\n");
    my $inst  = build_installed(claude_md => "# Title\n\nuser stuff\n");
    my ($e, $o, $err) = run_helper($inst, $src, '--bootstrap-init');
    is($e, 0, 'exit 0') or diag $err;
    my $cm = read_file("$inst/CLAUDE.md");
    like($cm, qr/<!-- CWF-PREAMBLE-START -->/, 'start sentinel');
    like($cm, qr/<!-- CWF-PREAMBLE-END -->/,   'end sentinel');
    like($cm, qr/> hello/,                      'block content present');
    like($cm, qr/user stuff/,                   'pre-existing content preserved');
};

# --- TC-EB-2: embedded-block — wrap legacy block (no sentinels) -----------
subtest 'embedded-block: wraps legacy block in sentinels' => sub {
    my ($src) = build_source(preamble_content => "> CWF block line.\n");
    my $legacy = "# Title\n\n> **CWF (Coding with Files) is installed in this project.**\n> existing line\n\nfooter\n";
    my $inst   = build_installed(claude_md => $legacy);
    my ($e, $o, $err) = run_helper($inst, $src, '--bootstrap-init');
    is($e, 0, 'exit 0') or diag $err;
    my $cm = read_file("$inst/CLAUDE.md");
    like($cm, qr/<!-- CWF-PREAMBLE-START -->\n> CWF block line\.\n<!-- CWF-PREAMBLE-END -->/s,
         'legacy block replaced and sentinel-wrapped');
    like($cm, qr/footer/, 'post-block content preserved');
};

# --- TC-EB-3: embedded-block — already up to date with sentinels ----------
subtest 'embedded-block: no-op when on-disk matches' => sub {
    my $block = "> SAME\n";
    my ($src) = build_source(preamble_content => $block);
    my $cm = "# Title\n\n<!-- CWF-PREAMBLE-START -->\n${block}<!-- CWF-PREAMBLE-END -->\n";
    my $inst  = build_installed(claude_md => $cm);
    my ($e, $o, $err) = run_helper($inst, $src, '--bootstrap-init');
    is($e, 0, 'exit 0') or diag $err;
    like($err, qr/claude-md-preamble: already up to date/, 'no-op log');
};

# --- TC-RS-1: regenerate-symlinks — creates fresh symlinks ----------------
subtest 'regenerate-symlinks: creates relative symlinks' => sub {
    my ($src) = build_source();
    my $inst  = build_installed(rule_file => "rule body\n");
    my ($e, $o, $err) = run_helper($inst, $src, '--bootstrap-init');
    is($e, 0, 'exit 0') or diag $err;
    my $link = "$inst/.claude/rules/cwf-workflow-files.md";
    ok(-l $link, 'symlink created');
    is(readlink($link), '../../.cwf-rules/cwf-workflow-files.md',
       'relative target');
};

# --- TC-RS-2: regenerate-symlinks — sweeps broken symlinks ----------------
subtest 'regenerate-symlinks: removes broken cwf-* symlinks' => sub {
    my ($src) = build_source();
    my $inst  = build_installed();
    make_path("$inst/.claude/rules");
    symlink('../../.cwf-rules/cwf-removed.md', "$inst/.claude/rules/cwf-removed.md");
    my ($e, $o, $err) = run_helper($inst, $src, '--bootstrap-init');
    is($e, 0, 'exit 0') or diag $err;
    ok(! -e "$inst/.claude/rules/cwf-removed.md", 'broken symlink removed')
        or diag "still exists: " . `ls -la $inst/.claude/rules/`;
};

# --- TC-RS-3: regenerate-symlinks — leaves user files alone ---------------
subtest 'regenerate-symlinks: leaves non-symlink files alone' => sub {
    my ($src) = build_source();
    my $inst  = build_installed(rule_file => "x\n");
    write_file("$inst/.claude/rules/cwf-user.md", "user content\n");
    my ($e) = run_helper($inst, $src, '--bootstrap-init');
    is($e, 0, 'exit 0');
    ok(! -l "$inst/.claude/rules/cwf-user.md", 'still a regular file');
    is(read_file("$inst/.claude/rules/cwf-user.md"), "user content\n",
       'content preserved');
};

# --- TC-PATH-TRAVERSAL: dest containing .. is rejected --------------------
subtest 'path traversal in manifest dest is rejected' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    write_file("$tmp/.cwf/templates/install/rules-inject.txt", '');
    write_file("$tmp/.cwf/templates/install/claude-md-preamble.md", "x\n");
    write_file("$tmp/.claude/rules/cwf-workflow-files.md", "y\n");
    my $manifest = {
        schema_version => 1,
        artefacts => [
            { id => 'rules-inject', kind => 'file',
              source => '.cwf/templates/install/rules-inject.txt',
              dest => '../../etc/passwd',
              sha256 => sha('') },
        ],
    };
    write_file("$tmp/.cwf/install-manifest.json",
               JSON::PP->new->canonical->encode($manifest));
    my $inst = build_installed();
    my ($e, $o, $err) = run_helper($inst, $tmp);
    is($e, 3, 'exit 3 (path validation)') or diag $err;
    like($err, qr/dest path/, 'rejection logged');
};

# --- TC-9-NO-SOURCE-MANIFEST: skip with WARN ------------------------------
subtest 'no source manifest → exit 2, WARN logged' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    my $inst = build_installed();
    my ($e, $o, $err) = run_helper($inst, $tmp);
    is($e, 2, 'exit 2 (bootstrap manifest missing)');
    like($err, qr/source manifest not found/, 'WARN logged');
};

# --- TC-FIXTURE-HYGIENE: no real-looking secrets in this test file --------
subtest 'no API keys / model names in test fixtures' => sub {
    open my $fh, '<', $FindBin::Bin . '/cwf-apply-artefacts.t' or die $!;
    local $/;
    my $self = <$fh>;
    close $fh;
    unlike($self, qr/sk-(ant|live)-[a-z0-9]/, 'no live API keys');
    unlike($self, qr/(claude|gpt)-[0-9]/i,    'no real model names');
};

done_testing();
