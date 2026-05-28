#!/usr/bin/env perl
#
# t/installmanifest-integrity.t — Two invariants over .cwf/install-manifest.json
#
# INV-1 (source agreement): every artefact's recorded sha256 must match the
# sha256 of the file the manifest's `source` (or `files{*}`) actually points
# at. Catches the Task-167-class defect where the manifest baseline disagreed
# with the file shipped by the .cwf/ subtree.
#
# INV-2 (anti-recurrence schema rule): no artefact may have a `dest` or
# `container` field beginning with ".cwf/". The .cwf/ subtree ships those
# files itself; routing them through apply-artefacts dual-distributes them
# and yields drift conflicts on every consumer update. This invariant is the
# institutional memory of Task 167.
#
# Manifest trust: $manifest->{artefacts}[*]{source} is read raw from
# .cwf/install-manifest.json. The manifest is hash-tracked in
# .cwf/security/script-hashes.json and integrity-checked by
# `cwf-manage validate`. Do NOT copy this pattern into contexts where the
# manifest is untrusted (e.g. consumer-supplied input) — there, treat every
# path with the validate_write_path_allowlist machinery in CWF::ArtefactHelpers.

use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;
use Test::More;
use Digest::SHA qw(sha256_hex);
use JSON::PP;

my $REPO = File::Spec->rel2abs("$FindBin::Bin/..");

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "$path: $!";
    local $/;
    return scalar <$fh>;
}

my $manifest_path = "$REPO/.cwf/install-manifest.json";
my $manifest      = decode_json(slurp_raw($manifest_path));

# --- Sanity floor: at least one artefact in the manifest --------------------
cmp_ok(scalar @{ $manifest->{artefacts} }, '>=', 1,
       'manifest has at least one artefact');

# --- INV-1: every artefact's recorded sha256 matches on-disk content --------
for my $a (@{ $manifest->{artefacts} }) {
    my $id = $a->{id} // '<unknown>';

    # kind: file / kind: embedded-block — single `source` + `sha256`.
    if (defined $a->{source} && defined $a->{sha256}) {
        my $abs = "$REPO/$a->{source}";
        SKIP: {
            skip "$id: source file missing on disk: $a->{source}", 1
                unless -f $abs;
            my $actual = sha256_hex(slurp_raw($abs));
            is($actual, $a->{sha256},
               "INV-1: $id — sha256 of $a->{source} matches manifest");
        }
    }

    # kind: tree — `source` directory + per-relpath sha256 in `files{*}`.
    if (defined $a->{source} && ref $a->{files} eq 'HASH') {
        for my $rel (sort keys %{ $a->{files} }) {
            my $abs = "$REPO/$a->{source}$rel";
            SKIP: {
                skip "$id/$rel: file missing on disk: $a->{source}$rel", 1
                    unless -f $abs;
                my $actual = sha256_hex(slurp_raw($abs));
                is($actual, $a->{files}{$rel},
                   "INV-1: $id — sha256 of $a->{source}$rel matches manifest");
            }
        }
    }
}

# --- INV-2: no artefact dest/container under .cwf/ --------------------------
for my $a (@{ $manifest->{artefacts} }) {
    my $id = $a->{id} // '<unknown>';

    for my $field (qw(dest container)) {
        next unless defined $a->{$field};
        unlike($a->{$field}, qr{\A\.cwf/},
               "INV-2: $id $field must not start with .cwf/ "
               . "(subtree ships there; routing through apply-artefacts "
               . "dual-distributes and causes drift)");
    }
}

done_testing;
