package CWF::Options;
#
# CWF::Options - Simple command-line option parser for CWF helper scripts
#
# Provides consistent option handling across CIG scripts without external dependencies.
# Supports long options (--option, --option=value) and short options (-h, -w).
#
# Usage:
#   use CWF::Options;
#
#   my $spec = {
#       description => "Script description",
#       options => [
#           { short => 'h', long => 'help', type => 'flag', desc => 'Show help' },
#           { short => 'w', long => 'workflow', type => 'flag', desc => 'Enable workflow mode' },
#           { long => 'format', type => 'value', desc => 'Output format (markdown|json)' },
#       ],
#       positional => { name => 'task-path', optional => 1, desc => 'Task number' }
#   };
#
#   my $opts = CWF::Options::parse($spec, @ARGV);
#   # Returns: { help => 0, workflow => 1, format => 'json', _positional => '17' }

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(parse);

# Parse command-line arguments according to specification
sub parse {
    my ($spec, @args) = @_;

    # Build lookup tables for fast option matching
    my %short_to_long;
    my %long_to_spec;
    my @option_order;

    for my $opt (@{$spec->{options}}) {
        my $long = $opt->{long};
        $long_to_spec{$long} = $opt;
        push @option_order, $long;

        if ($opt->{short}) {
            $short_to_long{$opt->{short}} = $long;
        }
    }

    # Initialize result hash with defaults
    my %result;
    for my $long (keys %long_to_spec) {
        my $type = $long_to_spec{$long}{type};
        $result{$long} = ($type eq 'flag') ? 0 : undef;
    }

    # Parse arguments
    my @positional;

    for my $arg (@args) {
        # Long option: --option or --option=value
        if ($arg =~ /^--([^=]+)(?:=(.+))?$/) {
            my ($long, $value) = ($1, $2);

            unless (exists $long_to_spec{$long}) {
                _error("Unknown option: --$long", $spec);
            }

            my $opt_spec = $long_to_spec{$long};

            if ($opt_spec->{type} eq 'flag') {
                if (defined $value) {
                    _error("Option --$long does not take a value", $spec);
                }
                $result{$long} = 1;
            } else {
                unless (defined $value) {
                    _error("Option --$long requires a value (use --$long=VALUE)", $spec);
                }
                $result{$long} = $value;
            }
        }
        # Short option: -x or -xyz (bundled flags)
        elsif ($arg =~ /^-([a-zA-Z]+)$/) {
            my $shorts = $1;

            for my $char (split //, $shorts) {
                unless (exists $short_to_long{$char}) {
                    _error("Unknown option: -$char", $spec);
                }

                my $long = $short_to_long{$char};
                my $opt_spec = $long_to_spec{$long};

                if ($opt_spec->{type} eq 'flag') {
                    $result{$long} = 1;
                } else {
                    _error("Option -$char requires a value and cannot be bundled", $spec);
                }
            }
        }
        # Not an option - treat as positional
        else {
            push @positional, $arg;
        }
    }

    # Handle --help specially
    if ($result{help}) {
        _print_help($spec, \@option_order, \%long_to_spec);
        exit 0;
    }

    # Validate positional arguments
    if ($spec->{positional}) {
        if (@positional > 1) {
            _error("Too many arguments (expected 1 positional argument)", $spec);
        }

        if (@positional == 1) {
            $result{_positional} = $positional[0];
        } elsif (!$spec->{positional}{optional}) {
            my $name = $spec->{positional}{name};
            _error("Missing required argument: $name", $spec);
        }
    } else {
        if (@positional > 0) {
            _error("Unexpected positional argument: $positional[0]", $spec);
        }
    }

    return \%result;
}

# Print help message and preserve option order
sub _print_help {
    my ($spec, $option_order, $long_to_spec) = @_;

    print $spec->{description}, "\n\n";

    # Build usage line
    print "Usage: ";
    my @usage_parts;

    for my $long (@$option_order) {
        my $opt = $long_to_spec->{$long};
        next if $long eq 'help';  # Don't show --help in usage

        my $usage = "";
        if ($opt->{short}) {
            $usage .= "-" . $opt->{short} . "|";
        }
        $usage .= "--" . $long;

        if ($opt->{type} eq 'value') {
            $usage .= "=VALUE";
        }

        push @usage_parts, "[$usage]";
    }

    if ($spec->{positional}) {
        my $pos_name = uc($spec->{positional}{name});
        $pos_name =~ s/-/_/g;
        if ($spec->{positional}{optional}) {
            push @usage_parts, "[$pos_name]";
        } else {
            push @usage_parts, $pos_name;
        }
    }

    print join(" ", @usage_parts), "\n\n";

    # Print option descriptions
    print "Options:\n";
    for my $long (@$option_order) {
        my $opt = $long_to_spec->{$long};
        my $line = "  ";

        if ($opt->{short}) {
            $line .= "-" . $opt->{short} . ", ";
        } else {
            $line .= "    ";
        }

        $line .= "--" . $long;

        if ($opt->{type} eq 'value') {
            $line .= "=VALUE";
        }

        # Pad to column 30
        while (length($line) < 30) {
            $line .= " ";
        }

        $line .= $opt->{desc};
        print $line, "\n";
    }

    if ($spec->{positional}) {
        print "\nArguments:\n";
        my $name = uc($spec->{positional}{name});
        $name =~ s/-/_/g;
        printf "  %-26s  %s\n", $name, $spec->{positional}{desc};
    }

    print "\n";
}

# Print error message and exit
sub _error {
    my ($message, $spec) = @_;

    print STDERR "Error: $message\n";
    print STDERR "Use --help for usage information\n";
    exit 1;
}

1;

__END__

=head1 NAME

CWF::Options - Simple command-line option parser for CWF helper scripts

=head1 SYNOPSIS

    use CWF::Options;

    my $spec = {
        description => "my-script.pl - Does something useful",
        options => [
            { short => 'h', long => 'help', type => 'flag', desc => 'Show help message' },
            { short => 'v', long => 'verbose', type => 'flag', desc => 'Enable verbose output' },
            { long => 'format', type => 'value', desc => 'Output format (json|markdown)' },
        ],
        positional => { name => 'input-file', optional => 0, desc => 'Input file path' }
    };

    my $opts = CWF::Options::parse($spec, @ARGV);

    if ($opts->{verbose}) {
        print "Verbose mode enabled\n";
    }

    my $input = $opts->{_positional};

=head1 DESCRIPTION

CWF::Options provides a simple, dependency-free command-line option parser
for CWF helper scripts. It supports long options (--option), short options (-o),
option values (--format=json), and bundled flags (-vh).

=head1 FEATURES

=over 4

=item * Long options: --option, --option=value

=item * Short options: -o (single flag), -vh (bundled flags)

=item * Automatic --help generation with formatted output

=item * Clear error messages with --help suggestion

=item * No external dependencies (pure Perl)

=item * Consistent API across all CIG scripts

=back

=head1 SPECIFICATION FORMAT

The specification hash defines the script's command-line interface:

    {
        description => "One-line script description",
        options => [
            {
                short => 'x',           # Optional: single character
                long => 'option-name',  # Required: option name
                type => 'flag|value',   # Required: flag or value
                desc => 'Description'   # Required: help text
            },
            ...
        ],
        positional => {                 # Optional: positional argument
            name => 'arg-name',         # Argument name (for help)
            optional => 0|1,            # Whether argument is optional
            desc => 'Description'       # Help text
        }
    }

=head1 RETURN VALUE

Returns a hashref with option names as keys:

=over 4

=item * Flag options: 0 (not set) or 1 (set)

=item * Value options: undef (not set) or string value

=item * Positional: stored in '_positional' key if provided

=back

=head1 EXIT CODES

=over 4

=item * 0: --help was used (after printing help)

=item * 1: Invalid arguments or unknown options

=back

=head1 AUTHOR

Coding with Files (CWF) System

=cut
