package CWF::ToolCheck;
#
# CWF::ToolCheck — pure policy for the Bash tool-check framework (Task 201).
#
# Holds the security-load-bearing, unit-testable policy with NO I/O and NO git:
#   load_layer($decoded, $provenance)   -> normalised, provenance-tagged rules
#                                          (a checked-in `perl` rule is dropped
#                                           HERE, before its string is ever
#                                           passed to a compile)
#   merge_rules(\@layers)               -> one ordered list (override/disable)
#   compile_perl($code)                 -> coderef | undef (guarded eval)
#   rule_matches($rule,$cmd,$cref,$ctx) -> bool (data-only PCRE; never re 'eval')
#   decide_repeat($matched,$last,$cur)  -> 'allow' | 'deny' | 'bypass'
#
# The thin hook (.cwf/scripts/hooks/pretooluse-bash-tool-check) does the impure
# work — read stdin, locate + read the three layer files, arm the wall-clock
# alarm around compile+match, read/write repeat-state, emit the decision — and
# delegates every judgement here. Fail-open is the hook's job; this lib simply
# never dies on bad input (it returns empty / false / undef instead).
#
# SECURITY — two load-bearing invariants live in this file:
#   1. This module NEVER does `use re 'eval'`. Config-supplied regexes are
#      therefore data-only: an embedded (?{...})/(??{...}) code block dies at
#      match time, is caught, and yields no-match. That is what lets the
#      checked-in (clone-travelling) layer carry `regex` rules safely.
#   2. A `perl` rule executes arbitrary code — at COMPILE time too, via a
#      BEGIN{} block inside the string. So `perl` rules are honoured ONLY from
#      the two author-trusted layers that never travel via `git clone`
#      (user-global, project-local). load_layer drops a checked-in `perl` rule
#      BEFORE its string is ever passed to compile_perl, keyed on the caller-
#      supplied provenance (never read from rule content).
#
# POSIX-only project; core Perl modules only.
#
use strict;
use warnings;
use utf8;
use Exporter 'import';
use JSON::PP ();   # is_bool — an `active` value counts only if it is a JSON boolean

our @EXPORT_OK = qw(load_layer merge_rules compile_perl rule_matches decide_repeat
                    resolve_active trusted_layers merge_seed);

# Commands longer than this are never matched (defence-in-depth: bounds the
# backtracking input, and refuses the truncate-to-evade vector). An over-cap
# command is NOT truncated-then-matched — it fails open (no match).
use constant MAX_CMD_BYTES => 64 * 1024;

# load_layer($decoded, $provenance) -> arrayref of normalised rule entries in
# document order. $decoded is the parsed JSON (a hashref) or undef. $provenance
# is 'user-global' | 'checked-in' | 'project-local', supplied by the CALLER from
# the path it read — NEVER taken from rule content, so a rule cannot self-assert
# a more-trusted origin. A checked-in `perl` rule is dropped here, before any
# compile. Malformed entries are skipped (fail-open), never fatal.
#
# Each kept entry is one of:
#   { id, provenance, disabled => 1 }                  (an enabled:false directive)
#   { id, provenance, guidance, regex => <pattern> }   (an active PCRE rule)
#   { id, provenance, guidance, perl  => <sub-string> } (an active perl rule)
sub load_layer {
    my ($decoded, $provenance) = @_;
    return [] unless ref $decoded eq 'HASH' && ref $decoded->{rules} eq 'ARRAY';

    my @out;
    for my $r (@{ $decoded->{rules} }) {
        next unless ref $r eq 'HASH';
        my $id = $r->{id};
        next unless defined $id && !ref $id && length $id;

        # Disable directive: `enabled` present and false. Needs no matcher kind
        # or guidance — it only removes a lower-precedence id at merge time.
        if (exists $r->{enabled} && !$r->{enabled}) {
            push @out, { id => $id, provenance => $provenance, disabled => 1 };
            next;
        }

        my $has_regex = (defined $r->{regex} && !ref $r->{regex}) ? 1 : 0;
        my $has_perl  = (defined $r->{perl}  && !ref $r->{perl})  ? 1 : 0;
        next if $has_regex == $has_perl;            # need EXACTLY one matcher kind

        my $guidance = $r->{guidance};
        next unless defined $guidance && !ref $guidance && length $guidance;

        # Provenance-keyed perl drop — BEFORE any compile (the BEGIN{} hazard).
        next if $has_perl && $provenance eq 'checked-in';

        my %rule = (id => $id, provenance => $provenance, guidance => $guidance);
        if ($has_regex) { $rule{regex} = $r->{regex} }
        else            { $rule{perl}  = $r->{perl}  }
        push @out, \%rule;
    }
    return \@out;
}

# merge_rules(\@layers) -> single ordered arrayref of ACTIVE rules. @layers are
# load_layer outputs in precedence order (low -> high: user-global, checked-in,
# project-local). Over the flattened stream, in order:
#   - a new id is appended (keeps its first-seen evaluation position);
#   - a repeated id REPLACES the existing entry's fields in place (position kept,
#     so an override never silently reorders evaluation);
#   - a disable directive removes the id;
#   - a disable/override of an id present in no layer is a silent no-op.
# A duplicate id WITHIN one layer therefore resolves last-in-document-order,
# consistent with the cross-layer "later wins" rule.
sub merge_rules {
    my ($layers) = @_;
    my (@order, %by_id, %seen);
    for my $layer (@{ $layers || [] }) {
        next unless ref $layer eq 'ARRAY';
        for my $r (@$layer) {
            next unless ref $r eq 'HASH';
            my $id = $r->{id};
            next unless defined $id && length $id;
            if ($r->{disabled}) { delete $by_id{$id}; next; }
            $by_id{$id} = $r;
            push @order, $id unless $seen{$id}++;     # first-seen position only
        }
    }
    return [ grep { defined } map { $by_id{$_} } @order ];
}

# compile_perl($code) -> coderef or undef. Compiles a `sub {...}` string under a
# guarded eval; returns undef on any failure (the caller drops the rule and
# fails open). NOTE: compiling arbitrary Perl runs BEGIN{} blocks AT THIS POINT,
# so the caller (hook) MUST arm its wall-clock alarm around this call, and only
# ever passes strings from author-trusted layers (load_layer has already dropped
# checked-in `perl`).
sub compile_perl {
    my ($code) = @_;
    return undef unless defined $code && !ref $code && length $code;
    my $cref = eval $code;                ## no critic — trusted-layer rule body
    return (ref $cref eq 'CODE') ? $cref : undef;
}

# rule_matches($rule, $cmd, $coderef, $ctx) -> bool.
#   - $cmd longer than MAX_CMD_BYTES -> no-match (fail open, never truncated).
#   - regex branch: data-only `$cmd =~ /$pat/` with NO `use re 'eval'` in scope,
#     wrapped in eval, so an invalid pattern or an embedded (?{...}) dies ->
#     caught -> no-match.
#   - perl branch: invokes the PRE-COMPILED $coderef as $coderef->($cmd, $ctx);
#     an undef coderef (compile failed / rule dropped) -> no-match (fail open).
# Never dies.
sub rule_matches {
    my ($rule, $cmd, $coderef, $ctx) = @_;
    return 0 unless defined $cmd;
    return 0 if length($cmd) > MAX_CMD_BYTES;
    $ctx ||= {};

    if (defined $rule->{regex}) {
        my $pat = $rule->{regex};
        my $hit = eval { ($cmd =~ /$pat/) ? 1 : 0 };
        return defined $hit ? $hit : 0;
    }
    if (defined $rule->{perl}) {
        return 0 unless ref $coderef eq 'CODE';
        my $hit = eval { $coderef->($cmd, $ctx) ? 1 : 0 };
        return defined $hit ? $hit : 0;
    }
    return 0;
}

# decide_repeat($matched, $last_denied_hash, $cur_hash) -> action string:
#   no match                                  -> 'allow'   (hook clears state)
#   match & last_denied == cur (a repeat)     -> 'bypass'  (hook allows + clears)
#   match & otherwise                         -> 'deny'    (hook sets state = cur)
sub decide_repeat {
    my ($matched, $last, $cur) = @_;
    return 'allow' unless $matched;
    return 'bypass' if defined $last && defined $cur && $last eq $cur;
    return 'deny';
}

# trusted_layers(\@decoded_low_to_high) -> \@trusted_decoded_high_to_low. Selects
# the kill-switch trust boundary in ONE place (single-sourced; both the hook hot
# path and the seed helper's state echo call this, so the boundary cannot drift).
# @decoded_low_to_high entries are { provenance, decoded } in the layer_paths
# order [user-global, checked-in, project-local]. Returns the two author-trusted,
# non-clone layers' decoded objects HIGH -> LOW [project-local, user-global] — the
# exact shape resolve_active expects. The checked-in layer is EXCLUDED: a
# clone-travelling `active:false` must never silence a downstream user's own rules
# (mirrors the checked-in `perl` drop). An absent/error layer (decoded undef) is
# dropped, so resolve_active only sees layers that actually parsed.
sub trusted_layers {
    my ($decoded) = @_;
    my %by_prov = map { $_->{provenance} => $_->{decoded} } @{ $decoded || [] };
    return [ grep { defined } @by_prov{ 'project-local', 'user-global' } ];
}

# resolve_active(\@trusted_decoded_high_to_low) -> 1 | 0. The global kill-switch.
# @trusted_decoded_high_to_low are the decoded layer HASHes the caller trusts for
# the flag, HIGHEST precedence first — i.e. ONLY [project-local, user-global]; the
# hook excludes the checked-in layer here (a clone-travelling `active:false` must
# not silence a downstream user's own rules, mirroring the checked-in `perl` drop).
# The first layer whose top-level `active` is a JSON BOOLEAN decides. Any other
# type ("false" string, 0, null, array) or an undef/error layer is skipped — so a
# hand-typed (Perl-truthy) `"active":"false"` can never leave the switch stuck on.
# Default 1 when none define it: this is a kill-switch, not an enable gate, so a
# settings file that predates the key (rules, no `active`) stays active.
sub resolve_active {
    my ($layers) = @_;
    for my $decoded (@{ $layers || [] }) {
        next unless ref $decoded eq 'HASH' && exists $decoded->{active};
        my $v = $decoded->{active};
        next unless JSON::PP::is_bool($v);        # only a JSON boolean counts
        return $v ? 1 : 0;
    }
    return 1;
}

# merge_seed(\@existing_rules, \@starter_rules) -> (\@merged, $added, $skipped).
# Append each starter rule whose `id` is absent from @existing; NEVER overwrite an
# id already present (a user edit to a seeded rule survives re-seeding). Returns the
# merged list plus the added/skipped counts (for the echo and the AC6 no-clobber
# check). Rules-only — the caller preserves any other top-level settings keys.
sub merge_seed {
    my ($existing, $starter) = @_;
    my @merged = grep { ref $_ eq 'HASH' } @{ $existing || [] };
    my %have;
    for my $r (@merged) {
        my $id = $r->{id};
        $have{$id} = 1 if defined $id && !ref $id && length $id;
    }
    my ($added, $skipped) = (0, 0);
    for my $r (@{ $starter || [] }) {
        next unless ref $r eq 'HASH';
        my $id = $r->{id};
        next unless defined $id && !ref $id && length $id;   # skip malformed starter
        if ($have{$id}) { $skipped++; next; }
        push @merged, $r;
        $have{$id} = 1;
        $added++;
    }
    return (\@merged, $added, $skipped);
}

1;
