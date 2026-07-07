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
       qw(load_layer merge_rules compile_perl rule_matches decide_repeat
          resolve_active trusted_layers merge_seed));

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

# ----- TC-U1: resolve_active default-true (AC1 / DK2) -----------------------
subtest 'TC-U1: no trusted layer defines active -> default true' => sub {
    plan tests => 3;
    is(resolve_active([]), 1, 'empty trusted list -> active (default true)');
    is(resolve_active([ { rules => [] } ]), 1, 'a layer with no `active` key -> default true');
    is(resolve_active([ { rules => [] }, { rules => [] } ]), 1,
        'multiple layers, none define active -> default true');
};

# ----- TC-U2: boolean-only coercion (DK2) -----------------------------------
subtest 'TC-U2: only a JSON boolean counts as defining active' => sub {
    plan tests => 7;
    is(resolve_active([ { active => JSON::PP::false } ]), 0, 'real JSON false -> 0');
    is(resolve_active([ { active => JSON::PP::true  } ]), 1, 'real JSON true -> 1');
    # Perl-truthy / non-boolean values must be IGNORED (fall through to default).
    is(resolve_active([ { active => 'false' } ]), 1, 'the STRING "false" is ignored -> default true');
    is(resolve_active([ { active => 0 }       ]), 1, 'the number 0 is ignored -> default true');
    is(resolve_active([ { active => undef }   ]), 1, 'null/undef is ignored -> default true');
    is(resolve_active([ { active => [] }      ]), 1, 'an array is ignored -> default true');
    # A non-boolean in the first layer falls through to a real boolean below it.
    is(resolve_active([ { active => 'false' }, { active => JSON::PP::false } ]), 0,
        'non-boolean high layer skipped; real false in the next layer decides');
};

# ----- TC-U3: precedence high->low + error-layer skip (DK1 / AC7) -----------
subtest 'TC-U3: first trusted layer with a boolean active wins' => sub {
    plan tests => 3;
    # Caller passes [project-local, user-global] high->low.
    is(resolve_active([ { active => JSON::PP::false }, { active => JSON::PP::true } ]), 0,
        'project-local false overrides user-global true');
    is(resolve_active([ { active => JSON::PP::true }, { active => JSON::PP::false } ]), 1,
        'project-local true overrides user-global false');
    # An undef (error layer: symlink/bad-JSON/non-HASH) contributes nothing.
    is(resolve_active([ undef, { active => JSON::PP::false } ]), 0,
        'an undef/error layer is skipped; the boolean below it decides');
};

# ----- TC-U3b: trusted_layers selects + orders + excludes checked-in (DK1) --
subtest 'TC-U3b: trusted_layers -> [project-local, user-global], checked-in dropped' => sub {
    plan tests => 4;
    my $decoded = [
        { provenance => 'user-global',   decoded => { active => JSON::PP::true,  n => 'ug' } },
        { provenance => 'checked-in',    decoded => { active => JSON::PP::false, n => 'ci' } },
        { provenance => 'project-local', decoded => { active => JSON::PP::false, n => 'pl' } },
    ];
    my $t = trusted_layers($decoded);
    is(scalar(@$t), 2, 'exactly two trusted layers returned (checked-in excluded)');
    is($t->[0]{n}, 'pl', 'project-local first (highest precedence)');
    is($t->[1]{n}, 'ug', 'user-global second');
    # An absent/error layer (decoded undef) is dropped, not passed as undef.
    my $t2 = trusted_layers([
        { provenance => 'project-local', decoded => undef },
        { provenance => 'user-global',   decoded => { active => JSON::PP::false } },
    ]);
    is_deeply($t2, [ { active => JSON::PP::false } ], 'undef project-local dropped; user-global kept');
};

# ----- TC-U4: merge_seed no-clobber + counts (AC6) --------------------------
subtest 'TC-U4: merge_seed appends missing ids, never overwrites' => sub {
    plan tests => 5;
    my @existing = ({ id => 'x', regex => 'user-edited', guidance => 'mine' });
    my @starter  = ({ id => 'x', regex => 'starter-x', guidance => 'g' },
                    { id => 'y', regex => 'starter-y', guidance => 'g' });
    my ($merged, $added, $skipped) = merge_seed(\@existing, \@starter);
    is($added,   1, 'one id added (y)');
    is($skipped, 1, 'one id skipped (x already present)');
    is_deeply([map { $_->{id} } @$merged], [qw(x y)], 'x kept first, y appended');
    my ($x) = grep { $_->{id} eq 'x' } @$merged;
    is($x->{regex}, 'user-edited', 'the user-edited x rule is NOT overwritten');
    is($x->{guidance}, 'mine', 'user guidance preserved');
};

# ----- TC-U5: merge_seed baseline (empty existing) --------------------------
subtest 'TC-U5: merge_seed onto empty existing adds every starter rule' => sub {
    plan tests => 3;
    my @starter = ({ id => 'a', regex => 'ra', guidance => 'g' },
                   { id => 'b', regex => 'rb', guidance => 'g' });
    my ($merged, $added, $skipped) = merge_seed([], \@starter);
    is($added,   2, 'all starter rules added');
    is($skipped, 0, 'nothing skipped');
    is_deeply([map { $_->{id} } @$merged], [qw(a b)], 'both starter ids present in order');
};

done_testing();
