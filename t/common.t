#!/usr/bin/env perl
#
# common.t - Unit tests for CWF::Common
#
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('CWF::Common', qw(check_perl5opt format_error parse_semver version_cmp generate_slug)) }

#==============================================================================
# check_perl5opt()
#==============================================================================

subtest 'check_perl5opt() - warns when PERL5OPT missing -C' => sub {
    plan tests => 1;

    local $ENV{PERL5OPT} = '';
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    CWF::Common::check_perl5opt();
    ok(@warnings > 0, 'emits warning when PERL5OPT does not contain -C');
};

subtest 'check_perl5opt() - no warning when PERL5OPT contains -C' => sub {
    plan tests => 1;

    local $ENV{PERL5OPT} = '-CDSLA';
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    CWF::Common::check_perl5opt();
    is(scalar @warnings, 0, 'no warning when PERL5OPT contains -C');
};

subtest 'check_perl5opt() - warns when PERL5OPT is undef' => sub {
    plan tests => 1;

    local $ENV{PERL5OPT};
    delete $ENV{PERL5OPT};
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    CWF::Common::check_perl5opt();
    ok(@warnings > 0, 'emits warning when PERL5OPT is unset');
};

#==============================================================================
# format_error()
#==============================================================================

subtest 'format_error() - message only' => sub {
    plan tests => 2;

    my $out = format_error('validation', 'Invalid task path');
    like($out, qr/Invalid task path/, 'contains the error message');
    unlike($out, qr/Usage:/, 'no Usage line when usage omitted');
};

subtest 'format_error() - message with usage' => sub {
    plan tests => 2;

    my $out = format_error('validation', 'Missing argument', 'script <task-path>');
    like($out, qr/Missing argument/, 'contains the error message');
    like($out, qr/Usage:.*script <task-path>/s, 'contains the usage string');
};

subtest 'format_error() - type parameter is not in output' => sub {
    plan tests => 1;

    # $type is accepted but not currently surfaced in the formatted string
    my $out = format_error('security', 'Hash mismatch');
    like($out, qr/Hash mismatch/, 'error message appears in output');
};

#==============================================================================
# parse_semver()
#==============================================================================

subtest 'parse_semver() - valid input returns numeric triple' => sub {
    plan tests => 4;

    my @p = parse_semver('v1.0.113');
    is_deeply(\@p, [1, 0, 113], 'v1.0.113 → (1,0,113)');

    # Verify numeric coercion (regression guard for cwf-manage's filter_releases)
    use Scalar::Util qw(looks_like_number);
    ok(looks_like_number($p[0]), 'major is numeric');
    ok(looks_like_number($p[1]), 'minor is numeric');
    ok(looks_like_number($p[2]), 'patch is numeric');
};

subtest 'parse_semver() - invalid inputs return empty list' => sub {
    plan tests => 6;

    is_deeply([parse_semver('')],          [], 'empty string → ()');
    is_deeply([parse_semver(undef)],       [], 'undef → ()');
    is_deeply([parse_semver('1.0.113')],   [], 'no v-prefix → ()');
    is_deeply([parse_semver('v1.0')],      [], 'missing patch → ()');
    is_deeply([parse_semver('vfoo')],      [], 'non-numeric → ()');
    is_deeply([parse_semver('v1.0.0-rc1')],[], 'pre-release suffix → ()');
};

#==============================================================================
# version_cmp()
#==============================================================================

subtest 'version_cmp() - ordering' => sub {
    plan tests => 5;

    is(version_cmp('v1.0.113', 'v1.0.97'),  1, 'v1.0.113 > v1.0.97 (numeric, not lexical)');
    is(version_cmp('v1.0.113', 'v1.0.113'), 0, 'equal');
    is(version_cmp('v1.0.97',  'v1.0.113'),-1, 'v1.0.97 < v1.0.113');
    is(version_cmp('v1.0.5',   'v1.0.50'), -1, 'v1.0.5 < v1.0.50 (numeric, not lexical)');
    is(version_cmp('v0.2.1',   'v1.0.0'),  -1, 'v0.2.1 < v1.0.0');
};

subtest 'version_cmp() - mixed lengths default missing components to 0' => sub {
    plan tests => 3;

    is(version_cmp('v1.0.0', 'v1.0'),   0, 'v1.0.0 == v1.0');
    is(version_cmp('v1.0',   'v1.0.0'), 0, 'v1.0 == v1.0.0');
    is(version_cmp('v1.0.1', 'v1.0'),   1, 'v1.0.1 > v1.0');
};

subtest 'version_cmp() - works without v-prefix' => sub {
    plan tests => 2;

    is(version_cmp('1.0.113', '1.0.97'), 1, 'works on bare semver');
    is(version_cmp('v1.0.0',  '1.0.0'),  0, 'mixed prefix and bare');
};

#==============================================================================
# generate_slug()
#==============================================================================

subtest 'generate_slug() - basic ASCII transformation' => sub {
    plan tests => 4;
    is(generate_slug('Hello World'),       'hello-world',     'lowercase + space-to-hyphen');
    is(generate_slug('FooBarBaz'),         'foobarbaz',       'no spaces, just lowercase');
    is(generate_slug('Add a Feature'),     'add-a-feature',   'multi-word');
    is(generate_slug(''),                  '',                'empty input → empty output');
};

subtest 'generate_slug() - punctuation and special characters' => sub {
    plan tests => 4;
    is(generate_slug('Add Settings.json Merge'), 'add-settingsjson-merge',
        'punctuation dropped (period inside settings.json)');
    is(generate_slug('Foo! Bar? Baz.'),   'foo-bar-baz',     'trailing punctuation dropped');
    is(generate_slug('Test (parens)'),    'test-parens',     'parens dropped');
    is(generate_slug('A/B/C'),            'abc',             'slashes dropped, no separator added');
};

subtest 'generate_slug() - whitespace collapsing' => sub {
    plan tests => 3;
    is(generate_slug('Foo    Bar'),       'foo-bar',         'multiple spaces → single hyphen');
    is(generate_slug('  Leading'),        'leading',         'leading whitespace stripped');
    is(generate_slug('Trailing  '),       'trailing',        'trailing whitespace stripped');
};

subtest 'generate_slug() - hyphen handling' => sub {
    plan tests => 4;
    is(generate_slug('---foo---'),        'foo',             'leading/trailing hyphens stripped');
    is(generate_slug('foo--bar'),         'foo-bar',         'consecutive hyphens collapsed');
    is(generate_slug('foo - bar'),        'foo-bar',         'hyphen with surrounding spaces');
    is(generate_slug('-'),                '',                'lone hyphen → empty');
};

subtest 'generate_slug() - non-ASCII characters dropped' => sub {
    plan tests => 2;
    is(generate_slug('Café Latte'),       'caf-latte',       'é dropped (not in [a-z0-9])');
    is(generate_slug('foo — bar'),        'foo-bar',         'em-dash dropped, surrounding hyphens collapsed');
};

done_testing();
