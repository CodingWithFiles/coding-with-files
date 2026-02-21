#!/usr/bin/env perl
#
# templatecopier.t - Unit tests for CWF::TemplateCopier::Core
#
# Tests only substitute_variables and copy_templates.
# discover_templates and compute_variables are excluded: they call exit() or load_config().
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

use_ok('CWF::TemplateCopier::Core');

my $tmp = tempdir(CLEANUP => 1);

#==============================================================================
# substitute_variables()
#==============================================================================

subtest 'substitute_variables() - replaces known variables' => sub {
    plan tests => 2;

    my $content = "Task: {{taskId}}\nBranch: {{branchName}}\n";
    my %vars = (taskId => 'internal-42', branchName => 'feature/42-test');
    my $result = CWF::TemplateCopier::Core::substitute_variables($content, \%vars);

    like($result, qr/Task: internal-42/,        'taskId substituted');
    like($result, qr/Branch: feature\/42-test/, 'branchName substituted');
};

subtest 'substitute_variables() - leaves unknown variables unchanged' => sub {
    plan tests => 1;

    my $content = "{{unknown}} stays";
    my %vars = (taskId => '1');
    my $result = CWF::TemplateCopier::Core::substitute_variables($content, \%vars);
    is($result, "{{unknown}} stays", 'unknown variable not touched');
};

subtest 'substitute_variables() - multiple occurrences replaced' => sub {
    plan tests => 1;

    my $content = "{{taskId}} and again {{taskId}}";
    my %vars = (taskId => 'X');
    my $result = CWF::TemplateCopier::Core::substitute_variables($content, \%vars);
    is($result, 'X and again X', 'all occurrences replaced');
};

subtest 'substitute_variables() - empty vars returns content unchanged' => sub {
    plan tests => 1;

    my $content = "no placeholders here";
    my $result = CWF::TemplateCopier::Core::substitute_variables($content, {});
    is($result, "no placeholders here", 'content unchanged with no vars');
};

#==============================================================================
# copy_templates()
#==============================================================================

my $tmpl_idx = 0;

sub make_template {
    my ($dir, $name, $content) = @_;
    my $path = "$dir/$name";
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
    return { name => $name, pool_file => $path };
}

subtest 'copy_templates() - creates files in destination' => sub {
    plan tests => 2;

    my $src  = tempdir(CLEANUP => 1);
    my $dest = "$tmp/dest1";
    my $tmpl = make_template($src, 'a-task-plan.md.template', "# Plan\nBranch: {{branchName}}\n");
    my %vars = (branchName => 'feature/1-test');

    my ($created, $overwritten) = CWF::TemplateCopier::Core::copy_templates([$tmpl], $dest, \%vars);

    ok(-f "$dest/a-task-plan.md", 'destination file created');
    is(scalar @$created, 1, 'one file in created list');
};

subtest 'copy_templates() - variables substituted in output' => sub {
    plan tests => 1;

    my $src  = tempdir(CLEANUP => 1);
    my $dest = "$tmp/dest2";
    my $tmpl = make_template($src, 'a-task-plan.md.template', "Branch: {{branchName}}\n");
    my %vars = (branchName => 'hotfix/99-fix');

    CWF::TemplateCopier::Core::copy_templates([$tmpl], $dest, \%vars);

    open my $fh, '<', "$dest/a-task-plan.md" or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    like($content, qr/Branch: hotfix\/99-fix/, 'variable substituted in output');
};

subtest 'copy_templates() - overwrite tracking' => sub {
    plan tests => 2;

    my $src  = tempdir(CLEANUP => 1);
    my $dest = "$tmp/dest3";
    my $tmpl = make_template($src, 'x.md.template', "content\n");
    my %vars;

    my ($c1, $o1) = CWF::TemplateCopier::Core::copy_templates([$tmpl], $dest, \%vars);
    my ($c2, $o2) = CWF::TemplateCopier::Core::copy_templates([$tmpl], $dest, \%vars);

    is(scalar @$c1, 1, 'first copy: one created');
    is(scalar @$o2, 1, 'second copy: one overwritten');
};

subtest 'copy_templates() - creates destination directory if missing' => sub {
    plan tests => 1;

    my $src  = tempdir(CLEANUP => 1);
    my $dest = "$tmp/newdir/nested";
    my $tmpl = make_template($src, 'y.md.template', "hello\n");

    CWF::TemplateCopier::Core::copy_templates([$tmpl], $dest, {});

    ok(-d $dest, 'destination directory created');
};

done_testing();
