#!/usr/bin/env perl
#
# tool-check.t — unit tests for CWF::ToolCheck (Task 201).
#
# The policy core is pure: layer load + provenance-keyed `perl` drop, the
# cross-layer merge/override/disable, data-only PCRE matching (never re 'eval'),
# `perl` compilation resilience, and the repeat-bypass decision. No live hook,
# no git — each test passes already-decoded JSON structures straight in. The
# hook's I/O wiring is covered separately in t/pretooluse-bash-tool-check.t.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use JSON::PP;

use_ok('CWF::ToolCheck',
       qw(load_layer merge_rules compile_perl rule_matches decide_repeat));

# Build the decoded shape JSON::PP->decode would yield for a layer file.
sub layer { return { rules => [ @_ ] } }

# ----- TC-1: merge precedence (AC2) -----------------------------------------
subtest 'TC-1: merge precedence user-global -> checked-in -> project-local' => sub {
    plan tests => 4;
    my $ug = load_layer(layer(
        { id => 'a',      regex => 'aaa', guidance => 'ga' },
        { id => 'shared', regex => 'old', guidance => 'g-old' },
    ), 'user-global');
    my $ci = load_layer(layer(
        { id => 'b',      regex => 'bbb', guidance => 'gb' },   # new id, appended
    ), 'checked-in');
    my $pl = load_layer(layer(
        { id => 'shared', regex => 'new', guidance => 'g-new' },# override in place
        { id => 'c',      regex => 'ccc', guidance => 'gc' },
    ), 'project-local');

    my $m = merge_rules([$ug, $ci, $pl]);
    is_deeply([map { $_->{id} } @$m], [qw(a shared b c)],
        'first-seen order preserved; override keeps position; new ids appended');
    my ($shared) = grep { $_->{id} eq 'shared' } @$m;
    is($shared->{regex},      'new',           'override replaces the pattern in place');
    is($shared->{guidance},   'g-new',         'override replaces guidance');
    is($shared->{provenance}, 'project-local', 'overriding layer provenance wins');
};

# ----- TC-2: disable + hand-errors (AC2) ------------------------------------
subtest 'TC-2: disable removes; dup-in-layer last-wins; absent-id no-op' => sub {
    plan tests => 3;
    my $ug = load_layer(layer(
        { id => 'x',   regex => 'xxx',    guidance => 'gx' },
        { id => 'dup', regex => 'first',  guidance => 'g1' },
        { id => 'dup', regex => 'second', guidance => 'g2' },   # dup WITHIN a layer
    ), 'user-global');
    my $pl = load_layer(layer(
        { id => 'x',     enabled => JSON::PP::false },          # disable lower-layer id
        { id => 'ghost', enabled => JSON::PP::false },          # absent id -> no-op
    ), 'project-local');

    my $m = merge_rules([$ug, $pl]);
    ok(!(grep { $_->{id} eq 'x' } @$m), 'enabled:false removes the id from the eval list');
    my ($dup) = grep { $_->{id} eq 'dup' } @$m;
    is($dup->{regex}, 'second', 'duplicate id within a layer -> last-in-doc-order wins');
    is(scalar(@$m), 1, 'absent-id disable is a silent no-op (only dup survives)');
};

# ----- TC-3: provenance-keyed perl drop (FR7e / security) -------------------
subtest 'TC-3: checked-in perl dropped before compile; provenance from arg' => sub {
    plan tests => 4;
    my $perl = 'sub { 1 }';

    my $ci = load_layer(layer({ id => 'p', perl => $perl, guidance => 'g' }), 'checked-in');
    is(scalar(@$ci), 0, 'checked-in perl rule dropped at load (never reaches compile)');

    my $ug = load_layer(layer({ id => 'p', perl => $perl, guidance => 'g' }), 'user-global');
    is(scalar(@$ug), 1, 'user-global perl rule kept');
    is($ug->[0]{provenance}, 'user-global', 'provenance taken from the caller arg');

    # Rule CONTENT cannot self-assert a more-trusted origin: arg wins.
    my $lie = load_layer(layer(
        { id => 'p', perl => $perl, guidance => 'g', provenance => 'user-global' },
    ), 'checked-in');
    is(scalar(@$lie), 0,
       'content claiming user-global is ignored; arg provenance (checked-in) drops it');
};

# ----- TC-4: PCRE match + no code-eval (FR2 / FR7b) -------------------------
subtest 'TC-4: data PCRE matches; (?{...}) never executes (no re eval)' => sub {
    plan tests => 3;
    my $rule = { id => 'sed', regex => '(?:^|[|;&]\s*)sed\s+-n', guidance => 'g' };
    ok( rule_matches($rule, "sed -n '1,5p' f", undef, {}), 'PCRE matches sed -n');
    ok(!rule_matches($rule, "grep foo file",   undef, {}), 'non-matching command -> no match');

    # A config pattern carrying embedded code must NOT execute: it dies ->
    # caught -> no-match, proving `re 'eval'` is never enabled.
    our $PWNED = 0;
    my $evil = { id => 'evil', regex => '(?{ $main::PWNED = 1 })', guidance => 'g' };
    rule_matches($evil, 'anything', undef, {});
    is($PWNED, 0, '(?{...}) in a config regex does not execute');
};

# ----- TC-5: over-cap + decide_repeat truth table ---------------------------
subtest 'TC-5: over-cap no-match; decide_repeat truth table' => sub {
    plan tests => 7;
    my $rule = { id => 'a', regex => 'x', guidance => 'g' };
    ok(!rule_matches($rule, 'x' x (64 * 1024 + 1), undef, {}),
        'command > 64 KB -> no match (not truncated)');
    ok( rule_matches($rule, 'x' x (64 * 1024), undef, {}),
        'command at the 64 KB cap still matches');

    is(decide_repeat(0, undef, 'h'), 'allow',  'no match -> allow');
    is(decide_repeat(0, 'h',   'h'), 'allow',  'no match -> allow even if last==cur');
    is(decide_repeat(1, undef, 'h'), 'deny',   'match + no prior -> deny');
    is(decide_repeat(1, 'g',   'h'), 'deny',   'match + different prior -> deny');
    is(decide_repeat(1, 'h',   'h'), 'bypass', 'match + identical prior -> bypass');
};

# ----- TC-6: compile_perl resilience + perl matching ------------------------
subtest 'TC-6: compile_perl returns coderef on valid, undef on broken' => sub {
    plan tests => 6;
    my $code = compile_perl('sub { my ($c) = @_; return $c =~ /foo/ }');
    is(ref $code, 'CODE', 'valid perl compiles to a coderef');
    ok($code->('foo bar'), 'compiled coderef runs');
    is(compile_perl('sub { syntax ((( error'), undef, 'broken perl -> undef, no die');

    my $cref  = compile_perl('sub { my ($cmd, $ctx) = @_; return $cmd =~ tr/|// > 3 }');
    my $prule = { id => 'pipe', perl => 'irrelevant-once-compiled', guidance => 'g' };
    ok( rule_matches($prule, 'a|b|c|d|e', $cref,  {}), 'perl rule matches via compiled coderef');
    ok(!rule_matches($prule, 'a|b',       $cref,  {}), 'perl rule no-match');
    ok(!rule_matches($prule, 'a|b|c|d|e', undef,  {}),
        'perl rule with undef coderef -> no match (fail open)');
};

done_testing();
