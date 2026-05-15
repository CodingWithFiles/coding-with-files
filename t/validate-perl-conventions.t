#!/usr/bin/env perl
#
# validate-perl-conventions.t - Unit tests for CWF::Validate::PerlConventions
#
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";

BEGIN { use_ok('CWF::Validate::PerlConventions', qw(validate)) }

# Build a fixture file under $root at $rel with $content.
sub write_fixture {
    my ($root, $rel, $content) = @_;
    my $abs = "$root/$rel";
    my ($dir) = $abs =~ m{^(.*)/[^/]+$};
    make_path($dir) if $dir && !-d $dir;
    open my $fh, '>:encoding(UTF-8)', $abs or die "Cannot write $abs: $!";
    print $fh $content;
    close $fh;
    return $abs;
}

# Each subtest builds a fresh fixture root so cases stay isolated.
sub fresh_root { return tempdir(CLEANUP => 1) }

#==============================================================================
# Source-pragma assertion
#==============================================================================

subtest 'TC-U1: module with non-ASCII + use utf8; passes' => sub {
    plan tests => 1;
    my $root = fresh_root();
    write_fixture($root, '.cwf/lib/CWF/T1.pm', <<'PERL');
package CWF::T1;
use strict;
use warnings;
use utf8;
my $em = "—";
1;
PERL
    my @v = validate($root);
    is(scalar @v, 0, 'no violations when use utf8; declared');
};

subtest 'TC-U2: module without use utf8; fails source-pragma (unconditional)' => sub {
    plan tests => 2;
    my $root = fresh_root();
    write_fixture($root, '.cwf/lib/CWF/T2.pm', <<'PERL');
package CWF::T2;
use strict;
use warnings;
my $em = "—";
1;
PERL
    my @v = validate($root);
    is(scalar @v, 1, 'exactly one violation for missing use utf8;');
    is($v[0]{field}, 'use_utf8', 'violation field = use_utf8');
};

subtest 'TC-U2b: ASCII-only module without use utf8; ALSO fails (rule is unconditional)' => sub {
    plan tests => 2;
    my $root = fresh_root();
    write_fixture($root, '.cwf/lib/CWF/T2b.pm', <<'PERL');
package CWF::T2b;
use strict;
use warnings;
my $msg = "no special characters here";
1;
PERL
    my @v = validate($root);
    is(scalar @v, 1, 'pragma is required even with no non-ASCII bytes');
    is($v[0]{field}, 'use_utf8', 'violation field = use_utf8');
};

#==============================================================================
# Git output-capture assertion (scripts only)
#==============================================================================

subtest 'TC-U3: script captures git status without -z fails git-z' => sub {
    plan tests => 2;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/s3', <<'PERL');
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
my $out = qx{git status --porcelain};
PERL
    my @v = validate($root);
    is(scalar @v, 1, 'exactly one violation for missing -z');
    is($v[0]{field}, 'git_z', 'violation field = git_z');
};

subtest 'TC-U4: script captures git status with -z passes' => sub {
    plan tests => 1;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/s4', <<'PERL');
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
my $out = qx{git status --porcelain -z};
PERL
    my @v = validate($root);
    is(scalar @v, 0, 'no violations when -z is present');
};

subtest 'TC-U4b: script uses open(-|, git, ...status, -z) passes' => sub {
    plan tests => 1;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/s4b', <<'PERL');
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
open(my $fh, '-|', 'git', '-C', '/tmp', 'status', '--porcelain', '-z')
    or die $!;
PERL
    my @v = validate($root);
    is(scalar @v, 0, 'open-pipe form with -z is recognised');
};

subtest 'TC-U4c: bareword open my $fh, -|, git, ..., -z passes (no parens)' => sub {
    plan tests => 1;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/s4c', <<'PERL');
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
open my $fh, '-|', 'git', 'status', '--porcelain', '-z'
    or die $!;
PERL
    my @v = validate($root);
    is(scalar @v, 0, 'bareword open form with -z is also recognised');
};

subtest 'TC-U4d: bareword open my $fh, -|, git, ...status (no -z) fails' => sub {
    plan tests => 2;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/s4d', <<'PERL');
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
open my $fh, '-|', 'git', 'status', '--porcelain'
    or die $!;
PERL
    my @v = validate($root);
    is(scalar @v, 1, 'bareword open without -z is flagged');
    is($v[0]{field}, 'git_z', 'violation field = git_z');
};

subtest 'TC-U5: offending pattern only inside POD passes' => sub {
    plan tests => 1;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/s5', <<'PERL');
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

=head1 NOTES

Run something like C<git status --porcelain> to see the working tree.

=cut

print "no actual git invocation here\n";
PERL
    my @v = validate($root);
    is(scalar @v, 0, 'POD-only mention is not a violation');
};

subtest 'TC-U6: system(git, log, --, $path) without captured output passes' => sub {
    plan tests => 1;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/s6', <<'PERL');
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
system('git', 'log', '--oneline', '--', '/tmp/some/path');
PERL
    my @v = validate($root);
    is(scalar @v, 0, 'arg-only path use (no captured output) is out of scope');
};

#==============================================================================
# Shebang assertion (universal — every Perl script in scan roots)
#==============================================================================

subtest 'TC-U3c: hardcoded -C shebang rejected regardless of trailing flags' => sub {
    plan tests => 3;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/s3c', <<'PERL');
#!/usr/bin/perl -CDSLA
use strict;
use warnings;
use utf8;
my $out = qx{git status --porcelain -z};
PERL
    my @v = validate($root);
    is(scalar @v, 1, 'exactly one violation (shebang); -z is present so no git_z complaint');
    is($v[0]{field}, 'shebang', 'violation field = shebang');
    is($v[0]{expected}, '#!/usr/bin/env perl', 'expected literal = env perl');
};

subtest 'TC-U3b: capturing script with env shebang passes shebang; only -z violation' => sub {
    plan tests => 2;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/s3b', <<'PERL');
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
my $out = qx{git status --porcelain};
PERL
    my @v = validate($root);
    is(scalar @v, 1, 'env shebang passes; only -z violation remains');
    is($v[0]{field}, 'git_z', 'sole violation field = git_z');
};

#==============================================================================
# Allowlist
#==============================================================================

subtest 'TC-U7: grandfathered file skips git-z but not shebang or source-pragma' => sub {
    plan tests => 3;
    my $root = fresh_root();
    my $rel  = '.cwf/scripts/hooks/legacy-hook';
    write_fixture($root, $rel, <<'PERL');
#!/usr/bin/env perl
use strict;
use warnings;
my $out = qx{git diff --name-only};
my $em = "—";
PERL
    local @CWF::Validate::PerlConventions::GRANDFATHERED = ($rel);
    my @v = validate($root);
    is(scalar @v, 1, 'exactly one violation (use_utf8) — git-z skipped by grandfathering, shebang already env perl');
    is($v[0]{field}, 'use_utf8', 'allowlist does not silence source-pragma');
    like($v[0]{file}, qr/legacy-hook$/, 'violation cites the grandfathered file');
};

#==============================================================================
# New universal shebang rule coverage
#==============================================================================

subtest 'TC-U9: env perl + -z + use utf8; passes with zero violations' => sub {
    plan tests => 1;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/s9', <<'PERL');
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
my $out = qx{git status --porcelain -z};
PERL
    my @v = validate($root);
    is(scalar @v, 0, 'canonical-form script has no violations');
};

subtest 'TC-U10: hardcoded -CDSLA shebang rejected even with -z present' => sub {
    plan tests => 3;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/s10', <<'PERL');
#!/usr/bin/perl -CDSLA
use strict;
use warnings;
use utf8;
my $out = qx{git status --porcelain -z};
PERL
    my @v = validate($root);
    is(scalar @v, 1, '-z is present so no git_z; only shebang violation');
    is($v[0]{field}, 'shebang', 'violation field = shebang');
    is($v[0]{expected}, '#!/usr/bin/env perl', 'expected literal = env perl');
};

#==============================================================================
# Discovery filter
#==============================================================================

subtest 'TC-U8: non-Perl files are ignored' => sub {
    plan tests => 1;
    my $root = fresh_root();
    write_fixture($root, '.cwf/scripts/notes.txt', "An — em-dash here.\n");
    my @v = validate($root);
    is(scalar @v, 0, 'plain-text files are not Perl and are skipped');
};

done_testing();
