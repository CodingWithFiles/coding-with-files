#!/usr/bin/env perl
#
# cwf-project-template.t - Guard test for the shipped cwf-project.json template
#
# Locks the retirement of the vestigial top-level `version` field (Task 188):
# the template must remain valid JSON and must not reintroduce `version`.
# A parse error is a hard failure here, never a silent skip.
#
use strict;
use warnings;
use utf8;
use Test::More;
use JSON::PP;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use CWF::Validate::Config qw(validate_config_hash);

my $template = "$FindBin::Bin/../.cwf/templates/cwf-project.json.template";

ok(-f $template, "template exists at $template") or BAIL_OUT("template missing");

# Slurp raw bytes: decode_json expects a UTF-8 byte string and decodes itself.
open(my $fh, '<:raw', $template) or BAIL_OUT("cannot read $template: $!");
my $json = do { local $/; <$fh> };
close($fh);

# TC-1: the shipped template must parse as JSON. A malformed template fails
# loudly here rather than slipping through as a silent skip.
my $cfg = eval { decode_json($json) };
ok(!$@, 'template parses as valid JSON') or diag("decode_json error: $@");

# TC-2: the vestigial top-level `version` field must stay retired.
# Task 196 reverses the earlier (Task 188) carve-out for `cwf-version`: that key
# is now also removed from the template and asserted absent by TC-4 below, so the
# template aligns with CWF-PROJECT-SPEC.md. (Retiring `cwf-version` /
# `security.version-tracking` from the *live* config is a separate, out-of-scope
# Low backlog item — it does not affect this template guard.)
ok(defined $cfg && !exists $cfg->{version},
    'retired top-level `version` field is absent from the template');

# TC-3: the template must validate clean against CWF::Validate::Config. Weak on
# its own (the validator ignores unknown keys), so the real shape-guard is the
# explicit key assertions in TC-4/TC-5 below — both are required.
my @violations = validate_config_hash($cfg, $template);
is(scalar @violations, 0, 'template validates clean (zero violations)')
    or diag(explain(\@violations));

# TC-4: vestigial keys removed by Task 196 must stay absent.
for my $key (qw(cwf-version _cwf-version-note title team task-management project)) {
    ok(defined $cfg && !exists $cfg->{$key},
        "vestigial key `$key` is absent from the template");
}

# TC-5: documented pass-through names present, and the branch placeholder fixed.
ok(defined $cfg && exists $cfg->{'project-name'},
    'documented `project-name` key is present');
ok(defined $cfg && exists $cfg->{'task-tracking'},
    'documented `task-tracking` key is present');
like($cfg->{'source-management'}{'branch-naming-convention'} // '',
    qr/\{description-slug\}/,
    'branch-naming-convention uses the {description-slug} placeholder');

# TC-6 (Task 221): the security-review exclude default ships seeded. The template
# must carry `security.review.max-lines-exclude-paths` as a non-empty array so new
# projects inherit the generic test/generated/vendored/doc-only discount, and must
# NOT seed `security.review.max-lines` (per design D2 — new projects inherit the
# built-in cap default; the key is set only to diverge).
my $review = defined $cfg ? ($cfg->{security}{review} // undef) : undef;
is(ref $review, 'HASH', 'template carries a security.review block');
my $excl = ref $review eq 'HASH' ? $review->{'max-lines-exclude-paths'} : undef;
is(ref $excl, 'ARRAY', 'security.review.max-lines-exclude-paths is an array');
ok(ref $excl eq 'ARRAY' && @$excl > 0,
    'seeded max-lines-exclude-paths is non-empty');
ok(ref $review ne 'HASH' || !exists $review->{'max-lines'},
    'template does NOT seed security.review.max-lines (D2)');

done_testing;
