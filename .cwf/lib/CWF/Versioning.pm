package CWF::Versioning;

use strict;
use warnings;
use utf8;
use Exporter 'import';
use JSON::PP;
use File::Basename qw(dirname);
use File::Temp ();
use CWF::Common qw(find_git_root);

our @EXPORT_OK = qw(
    read_config
    wf_step_setting
    next_version
    current_version
    bump_to
    tag_at
    config_path
);

our $VERSION = '1.0.0';

# --- Internals --------------------------------------------------------------

# Locate the cwf-project.json for the current git repository.
# Returns the absolute path even if the file does not exist.
# Dies if no git repository is found.
# Optional: pass $git_root to override (useful in tests).
sub config_path {
    my ($git_root) = @_;
    $git_root //= find_git_root();
    die "CWF::Versioning: not inside a git repository\n" unless $git_root;
    return "$git_root/implementation-guide/cwf-project.json";
}

# --- Public API -------------------------------------------------------------

# Read and validate cwf-project.json.
# Dies if the file is missing, unreadable, malformed JSON, or missing/malformed
# versioning.major_minor (the only field this module strictly requires).
# Returns: hashref of decoded config.
sub read_config {
    my $path = config_path();

    -f $path
        or die "cwf-project.json not found at $path\n";

    open my $fh, '<', $path
        or die "Cannot read $path: $!\n";
    local $/;
    my $json = <$fh>;
    close $fh;

    my $cfg = eval { decode_json($json) };
    die "Invalid JSON in $path: $@" if $@;

    my $mm = $cfg->{versioning}{major_minor};
    die "versioning.major_minor missing in $path — add e.g. \"v1.0\"\n"
        unless defined $mm;
    die "versioning.major_minor malformed in $path: \"$mm\" (expected /^v\\d+\\.\\d+\$/)\n"
        unless $mm =~ /^v\d+\.\d+$/;

    return $cfg;
}

# Look up wf_step_config.<step>.<key>, returning $default if absent.
sub wf_step_setting {
    my ($step, $key, $default, $cfg) = @_;
    $cfg //= read_config();
    my $val = $cfg->{wf_step_config}{$step}{$key};
    return defined $val ? $val : $default;
}

# Compose the next version from major_minor + task_num.
# Required: task_num => N (positive integer).
sub next_version {
    my %args = @_;
    my $task_num = $args{task_num};
    die "next_version: task_num required\n"
        unless defined $task_num && $task_num =~ /^\d+$/ && $task_num > 0;

    my $cfg = $args{cfg} // read_config();
    my $mm  = $cfg->{versioning}{major_minor};
    return "$mm.$task_num";
}

# Return versioning.last_released or undef if absent.
sub current_version {
    my %args = @_;
    my $cfg = $args{cfg} // read_config();
    return $cfg->{versioning}{last_released};
}

# Bump versioning.last_released to $version in cwf-project.json.
# Honours wf_step_config.retrospective.bump_version (default: true).
# Idempotent: if last_released already equals $version, returns 'idempotent'.
# Atomic write: temp file in same directory as target, then rename.
# Returns: { status => 'bumped'|'skipped'|'idempotent', message => ... }.
# Dies on read/write/rename failure.
sub bump_to {
    my ($version, %opts) = @_;
    die "bump_to: version required\n" unless defined $version && length $version;

    my $cfg  = $opts{cfg} // read_config();
    my $on   = wf_step_setting('retrospective', 'bump_version', 1, $cfg);
    return { status => 'skipped', message => "skipped: bump_version=false" }
        unless $on;

    my $current = $cfg->{versioning}{last_released};
    if (defined $current && $current eq $version) {
        return { status => 'idempotent', message => "already at $version" };
    }

    $cfg->{versioning}{last_released} = $version;

    my $path = config_path();
    my $dir  = dirname($path);
    my $tmp  = File::Temp->new(
        DIR      => $dir,
        TEMPLATE => '.cwf-project.json.XXXXXX',
        UNLINK   => 0,
    );

    my $encoder = JSON::PP->new->pretty->indent_length(2)->canonical;
    my $blob    = $encoder->encode($cfg);

    print {$tmp} $blob or die "Cannot write $tmp: $!\n";
    close $tmp        or die "Cannot close $tmp: $!\n";

    rename "$tmp", $path
        or do {
            unlink "$tmp";
            die "Cannot rename $tmp → $path: $!\n";
        };

    return { status => 'bumped', message => "bumped: $version" };
}

# Create an annotated git tag at $version on the current commit.
# Honours wf_step_config.retrospective.tag_version (default: false).
# Refuses unless on the project's main branch (default 'main', overridable
# via versioning.main_branch in cwf-project.json).
# Refuses if tag already exists.
# Returns: { status => 'tagged'|'skipped'|'error', message => ... }.
# Dies on git failure.
sub tag_at {
    my ($version, %opts) = @_;
    die "tag_at: version required\n" unless defined $version && length $version;
    my $message = $opts{message} // $version;

    my $cfg = $opts{cfg} // read_config();
    my $on  = wf_step_setting('retrospective', 'tag_version', 0, $cfg);
    return { status => 'skipped', message => "skipped: tag_version=false" }
        unless $on;

    my $main = $cfg->{versioning}{main_branch} // 'main';
    my $head = `git rev-parse --abbrev-ref HEAD 2>/dev/null`;
    chomp $head;
    return {
        status  => 'error',
        message => "not on main branch (HEAD is $head, expected $main)",
    } unless $head eq $main;

    my $existing = `git tag -l '$version' 2>/dev/null`;
    chomp $existing;
    return {
        status  => 'error',
        message => "tag $version already exists",
    } if length $existing;

    # Use list form to git tag -a -m to avoid shell quoting; -F via stdin
    # would need tempfile, args are safer here since version is regex-validated
    # earlier in the pipeline.
    my $rc = system('git', 'tag', '-a', $version, '-m', $message);
    die "git tag failed (rc=$rc)\n" if $rc != 0;

    return { status => 'tagged', message => "tagged: $version" };
}

1;

__END__

=head1 NAME

CWF::Versioning - Versioning logic for CWF retrospective phase

=head1 SYNOPSIS

    use CWF::Versioning qw(next_version current_version
                           bump_to tag_at
                           read_config wf_step_setting);

    my $cfg     = read_config();                       # hashref
    my $bump_on = wf_step_setting('retrospective', 'bump_version', 1);
    my $next    = next_version(task_num => 114);       # "v1.0.114"
    my $cur     = current_version();                   # "v1.0.113" or undef

=head1 DESCRIPTION

Reads version configuration from C<implementation-guide/cwf-project.json>,
computes next version strings, and (in the bump_to / tag_at functions added
in Step 3) performs file mutations and git tag creation under the control
of C<wf_step_config.retrospective.{bump_version,tag_version}> flags.

The pure semver utilities C<parse_semver> and C<version_cmp> live in
C<CWF::Common> — this module focuses on version-with-config logic.

=cut
