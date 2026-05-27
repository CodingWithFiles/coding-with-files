#!/usr/bin/env perl
#
# validate-template-refs.t - Unit + integration tests for
# CWF::Validate::TemplateRefs (orphaned template-reference linter).
#
# Fixtures are real git repos because the module enumerates files via
# 'git ls-files'; staging ('git add') is sufficient (no commit needed for
# ls-files, so no git identity is required).
#
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";

BEGIN { use_ok('CWF::Validate::TemplateRefs', qw(validate)) }

my $REPO = File::Spec->rel2abs("$FindBin::Bin/..");

# Build a fresh git-repo fixture from { relpath => content }, stage it, and
# return its root. 'git add' puts files in the index, which is all ls-files
# needs; we deliberately avoid 'git commit' (no identity required).
sub git_fixture {
    my (%files) = @_;
    my $root = tempdir(CLEANUP => 1);
    is(system('git', 'init', '-q', $root), 0, 'git init fixture');
    for my $rel (sort keys %files) {
        my $abs = "$root/$rel";
        my ($dir) = $abs =~ m{^(.*)/[^/]+$};
        make_path($dir) if $dir && !-d $dir;
        open my $fh, '>:encoding(UTF-8)', $abs or die "write $abs: $!";
        print $fh $files{$rel};
        close $fh;
    }
    is(system('git', '-C', $root, 'add', '-A'), 0, 'git add fixture');
    return $root;
}

sub actuals { return sort map { $_->{actual} } @_ }

#==============================================================================
# TC-1: a tree whose references are all known names -> clean
#==============================================================================
subtest 'TC-1: known references produce no violations' => sub {
    my $root = git_fixture(
        'doc.md' => "Edit a-task-plan.md then d-implementation-plan.md.\n",
        'lib.pm' => "# see j-retrospective.md\n",
    );
    my @v = validate($root);
    is(scalar @v, 0, 'no violations') or diag explain \@v;
};

#==============================================================================
# TC-2: a genuine orphan (grammar match, no version knows it) -> flagged
#==============================================================================
subtest 'TC-2: orphan reference is flagged with file/line/token' => sub {
    my $root = git_fixture('doc.md' => "line one\nrefers to a-bogus.md here\n");
    my @v = validate($root);
    is(scalar @v, 1, 'exactly one violation');
    is($v[0]{actual}, 'a-bogus.md', 'token captured');
    is($v[0]{file},   'doc.md',     'file captured');
    is($v[0]{field},  'line 2',     'line number captured');
};

#==============================================================================
# TC-3: backward-compat mention of an older-but-known name -> not flagged
#==============================================================================
subtest 'TC-3: known v2.0 back-compat name is not flagged' => sub {
    my $root = git_fixture(
        'skill.md' => "Open a-task-plan.md (v2.1) or a-plan.md (v2.0) or plan.md (v1.0).\n",
    );
    my @v = validate($root);
    is(scalar @v, 0, 'a-plan.md is a known v2.0 name') or diag explain \@v;
};

#==============================================================================
# TC-4: substring decoys inside longer filenames -> not flagged
#==============================================================================
subtest 'TC-4: embedded substrings are not matched' => sub {
    my $root = git_fixture(
        'doc.md' => "see retrospective-extras.md and cwf-plan-reviewer-misalignment.md\n",
    );
    my @v = validate($root);
    is(scalar @v, 0, 'left-boundary anchor rejects embedded tails') or diag explain \@v;
};

#==============================================================================
# TC-5: a removed compound name is matched whole -> flagged once
#==============================================================================
subtest 'TC-5: multi-segment compound token matched whole' => sub {
    my $root = git_fixture('doc.md' => "old file f-implementation-exec-audit.md\n");
    my @v = validate($root);
    is(scalar @v, 1, 'one violation');
    is($v[0]{actual}, 'f-implementation-exec-audit.md', 'whole compound token');
};

#==============================================================================
# TC-6: BACKLOG.md / CHANGELOG.md are out of scope; same token in-scope flagged
#==============================================================================
subtest 'TC-6: history files excluded, in-scope file flagged' => sub {
    my $root = git_fixture(
        'BACKLOG.md'   => "historical mention of a-bogus.md\n",
        'CHANGELOG.md' => "renamed to a-bogus.md\n",
        'src.md'       => "stale ref a-bogus.md\n",
    );
    my @v = validate($root);
    is(scalar @v, 1, 'only the in-scope file is flagged');
    is($v[0]{file}, 'src.md', 'BACKLOG/CHANGELOG excluded') or diag explain \@v;
};

#==============================================================================
# TC-6b: implementation-guide/ is out of scope
#==============================================================================
subtest 'TC-6b: implementation-guide is excluded' => sub {
    my $root = git_fixture(
        'implementation-guide/9-chore-x/a-task-plan.md' => "ref a-bogus.md\n",
        'doc.md'                                        => "ok a-task-plan.md\n",
    );
    my @v = validate($root);
    is(scalar @v, 0, 'task instances under implementation-guide are not scanned')
        or diag explain \@v;
};

#==============================================================================
# Fail-closed: the derived KNOWN set carries the asserted minimum
#==============================================================================
subtest 'KNOWN set is populated from the real modules' => sub {
    my %known = CWF::Validate::TemplateRefs::_known_names($REPO);
    ok($known{'a-task-plan.md'},         'current v2.1 name present');
    ok($known{'f-implementation-exec.md'}, 'v2.1 execution name present');
    ok($known{'e-testing.md'},           'v2.0 name present');
    cmp_ok(scalar keys %known, '>=', 15, 'union spans multiple versions');
};

#==============================================================================
# TC-7: the real repository is clean at HEAD
#==============================================================================
subtest 'TC-7: real repo has no orphaned template references' => sub {
    my @v = validate($REPO);
    is(scalar @v, 0, 'repo is clean') or diag explain \@v;
};

done_testing();
