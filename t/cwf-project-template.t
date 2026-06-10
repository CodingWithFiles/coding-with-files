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

# TC-2: the vestigial top-level `version` field must stay retired. Narrow scope:
# `cwf-version` is intentionally retained and deliberately NOT asserted here.
ok(defined $cfg && !exists $cfg->{version},
    'retired top-level `version` field is absent from the template');

done_testing;
