#!/usr/bin/env perl
#
# validate-security-coverage.t - Coverage guard for .cwf/security/script-hashes.json
#
# Asserts every executable file under .cwf/scripts/command-helpers/** and
# .cwf/scripts/hooks/ is registered in the integrity manifest. No shebang
# filter — every executable script must be registered, regardless of language.
#
use strict;
use warnings;
use utf8;
use Test::More;
use File::Find;
use File::Spec;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use JSON::PP;

my $repo = "$FindBin::Bin/..";

sub load_manifest {
    my ($path) = @_;
    open(my $fh, '<:raw', $path) or die "open $path: $!";
    my $data = do { local $/; <$fh> };
    close($fh);
    my $json = JSON::PP->new->decode($data);
    my %registered;
    for my $section (qw(scripts lib)) {
        next unless $json->{$section};
        for my $key (keys %{$json->{$section}}) {
            my $entry = $json->{$section}{$key};
            $registered{ $entry->{path} } = 1 if $entry->{path};
        }
    }
    return \%registered;
}

sub walk_files {
    my ($root) = @_;
    my @files;
    return @files unless -d $root;
    find({
        no_chdir => 1,
        wanted   => sub {
            return if -d $_;
            return if -l $_;
            return unless -f $_;
            push @files, $_;
        },
    }, $root);
    return sort @files;
}

sub rel_to_repo { File::Spec->abs2rel($_[0], $repo) }

my $registered = load_manifest("$repo/.cwf/security/script-hashes.json");

# Walk command-helpers once and partition: top-level files vs files inside a
# `<name>.d/` subcommand directory. Files in non-`.d/` subdirectories are
# deliberately out of scope.
my $helpers_root = "$repo/.cwf/scripts/command-helpers";
my (@top_level, @subd);
for my $abs (walk_files($helpers_root)) {
    my $tail = $abs;
    $tail =~ s{^\Q$helpers_root\E/}{};
    if ($tail !~ m{/}) {
        push @top_level, $abs;
    } elsif ($tail =~ m{^[^/]+\.d/}) {
        push @subd, $abs;
    }
}

#==============================================================================
# TC-C1: Top-level command-helpers registered
#==============================================================================

subtest 'TC-C1: top-level command-helpers registered' => sub {
    plan tests => scalar(@top_level) + 1;
    ok(scalar(@top_level) > 0, 'found at least one top-level command-helper');
    for my $abs (@top_level) {
        my $rel = rel_to_repo($abs);
        ok($registered->{$rel}, "registered: $rel");
    }
};

#==============================================================================
# TC-C2: .d/ subcommands registered
#==============================================================================

subtest 'TC-C2: .d/ subcommands registered' => sub {
    plan tests => scalar(@subd) + 1;
    ok(scalar(@subd) > 0, 'found at least one .d/ subcommand');
    for my $abs (@subd) {
        my $rel = rel_to_repo($abs);
        ok($registered->{$rel}, "registered: $rel");
    }
};

#==============================================================================
# TC-C3: hooks registered
#==============================================================================

subtest 'TC-C3: hooks registered' => sub {
    my @files = walk_files("$repo/.cwf/scripts/hooks");
    plan tests => scalar(@files) + 1;
    ok(scalar(@files) > 0, 'found at least one hook');
    for my $abs (@files) {
        my $rel = rel_to_repo($abs);
        ok($registered->{$rel}, "registered: $rel");
    }
};

#==============================================================================
# TC-U4: walker skips symlinks (self-contained fixture)
#==============================================================================

subtest 'TC-U4: walker skips symlinks' => sub {
    plan tests => 2;
    my $tmp = tempdir(CLEANUP => 1);
    make_path("$tmp/sub");
    open(my $real, '>', "$tmp/sub/real-file") or die "open: $!";
    print $real "real\n";
    close($real);
    my $linked = symlink("$tmp/sub/real-file", "$tmp/sub/link-file");
    SKIP: {
        skip 'symlink not supported on this platform', 2 unless $linked;
        my @rel = map { File::Spec->abs2rel($_, $tmp) } walk_files($tmp);
        my %seen = map { $_ => 1 } @rel;
        ok($seen{'sub/real-file'}, 'real file is included');
        ok(!$seen{'sub/link-file'}, 'symlink is skipped');
    }
};

done_testing();
