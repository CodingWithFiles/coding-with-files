#!/usr/bin/env perl
#
# task-type-inference-rubric.t - Drift-detection tests for the task-type
# inference rubric at .cwf/docs/skills/task-type-inference.md.
#
# This test does not exercise runtime LLM behaviour (that is covered by the
# smoke-test matrix in e-testing-plan.md). It enforces static invariants:
#   1. The rubric file exists and is readable.
#   2. The rubric contains the required section headings.
#   3. The canonical-step-set table in the rubric matches the actual step
#      letters present in each .cwf/templates/<type>/ directory listed in
#      cwf-project.json:supported-task-types.
#   4. Neither cwf-new-task/SKILL.md nor cwf-new-subtask/SKILL.md inlines
#      the rubric prose (no duplication of the (b,c,h,i) tuple or canonical
#      table rows).
#   5. Both SKILL.md files reference the rubric path as a literal string.
#
# During Task 133 implementation, assertions 1-3 pass after Step 2 (rubric
# written) and assertions 4-5 fail until Steps 4-5 (SKILL.md edits) land.
# Initial red bar on 4/5 is expected mid-implementation; treat as a
# regression only after Step 5.
#
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use JSON::PP;

my $REPO_ROOT = "$FindBin::Bin/..";
my $RUBRIC    = "$REPO_ROOT/.cwf/docs/skills/task-type-inference.md";
my $CONFIG    = "$REPO_ROOT/implementation-guide/cwf-project.json";
my $TEMPLATES = "$REPO_ROOT/.cwf/templates";
my $NEW_TASK_SKILL    = "$REPO_ROOT/.claude/skills/cwf-new-task/SKILL.md";
my $NEW_SUBTASK_SKILL = "$REPO_ROOT/.claude/skills/cwf-new-subtask/SKILL.md";

#==============================================================================
# Helpers
#==============================================================================

sub slurp {
    my ($path) = @_;
    open my $fh, '<:encoding(UTF-8)', $path or die "Cannot read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

# Parse the rubric's canonical-step-set table. Returns a hash:
#   { type_name => [ sorted step-letter list ], ... }
sub parse_rubric_table {
    my ($content) = @_;
    my %table;

    # The table lives under "## Canonical Step Sets". Find that section
    # and grab the table rows until the next heading.
    my ($section) = $content =~ /^##\s+Canonical Step Sets\s*\n(.*?)(?=^##\s)/sm;
    die "Could not locate '## Canonical Step Sets' section in rubric"
        unless defined $section;

    for my $line (split /\n/, $section) {
        next unless $line =~ /^\|/;            # only table rows
        next if $line =~ /^\|\s*-+\s*\|/;      # skip header separator
        next if $line =~ /^\|\s*Type\s*\|/i;   # skip header row

        my @cells = split /\|/, $line;
        shift @cells if @cells && $cells[0] eq '';   # leading empty cell
        pop   @cells if @cells && $cells[-1] =~ /^\s*$/;  # trailing empty

        next unless @cells >= 3;
        my $type    = $cells[0]; $type =~ s/^\s+|\s+$//g;
        my $letters = $cells[2]; $letters =~ s/^\s+|\s+$//g;

        my @steps = grep { length } map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x }
                    split /,/, $letters;
        $table{$type} = [ sort @steps ];
    }
    return \%table;
}

# Discover the actual step letters present in .cwf/templates/<type>/.
# Matches filenames against /^([a-j])-/ and returns a sorted list.
sub discover_steps {
    my ($type) = @_;
    my $dir = "$TEMPLATES/$type";
    return undef unless -d $dir;

    opendir my $dh, $dir or die "Cannot opendir $dir: $!";
    my @entries = readdir $dh;
    closedir $dh;

    my %letters;
    for my $entry (@entries) {
        next unless $entry =~ /^([a-j])-/;
        $letters{$1} = 1;
    }
    return [ sort keys %letters ];
}

sub read_config_types {
    my $json = slurp($CONFIG);
    my $config = JSON::PP->new->decode($json);
    my $types = $config->{'supported-task-types'};
    die "supported-task-types missing or not an array"
        unless ref($types) eq 'ARRAY';
    return $types;
}

#==============================================================================
# Assertion 1: rubric exists and is readable
#==============================================================================

ok(-f $RUBRIC, "rubric file exists at $RUBRIC");
ok(-r $RUBRIC, "rubric file is readable");

my $rubric = slurp($RUBRIC);
ok(length $rubric > 0, "rubric file is non-empty");

#==============================================================================
# Assertion 2: required headings present
#==============================================================================

my @required_headings = (
    qr/^#\s+Task Type Inference\s*$/m,
    qr/^##\s+Step Semantics\s*$/m,
    qr/^##\s+Discriminating Questions\s*$/m,
    qr/^##\s+Canonical Step Sets\s*$/m,
    qr/^##\s+Resolution Algorithm\s*$/m,
    qr/^##\s+Adding A New Task Type\s*$/m,
);
for my $re (@required_headings) {
    like($rubric, $re, "rubric contains heading matching $re");
}

#==============================================================================
# Assertion 3: rubric table matches actual template directories
#==============================================================================

my $table = parse_rubric_table($rubric);
my $types = read_config_types();

is(scalar(@$types), scalar(keys %$table),
   "rubric table has one row per supported task type");

for my $type (@$types) {
    subtest "type=$type step-set matches templates" => sub {
        ok(exists $table->{$type}, "rubric has a row for '$type'");
        my $discovered = discover_steps($type);
        ok(defined $discovered, ".cwf/templates/$type/ exists");

        if (defined $discovered && exists $table->{$type}) {
            is_deeply($table->{$type}, $discovered,
                "rubric step set for '$type' matches files in .cwf/templates/$type/");
        }
    };
}

#==============================================================================
# Assertion 4: SKILL.md files do not inline rubric prose
#==============================================================================

my $skill_task    = slurp($NEW_TASK_SKILL);
my $skill_subtask = slurp($NEW_SUBTASK_SKILL);

unlike($skill_task, qr/\(b\s*,\s*c\s*,\s*h\s*,\s*i\)/,
       "cwf-new-task/SKILL.md does not duplicate the (b,c,h,i) tuple");
unlike($skill_subtask, qr/\(b\s*,\s*c\s*,\s*h\s*,\s*i\)/,
       "cwf-new-subtask/SKILL.md does not duplicate the (b,c,h,i) tuple");

# Grep negative for canonical-table rows like "| feature ", "| chore ", etc.
for my $type (@$types) {
    my $re = qr/^\|\s*\Q$type\E\s*\|/m;
    unlike($skill_task, $re,
        "cwf-new-task/SKILL.md does not inline a '$type' canonical-table row");
    unlike($skill_subtask, $re,
        "cwf-new-subtask/SKILL.md does not inline a '$type' canonical-table row");
}

#==============================================================================
# Assertion 5: SKILL.md files reference the rubric path literally
#==============================================================================

my $rubric_path_literal = '.cwf/docs/skills/task-type-inference.md';
like($skill_task,    qr/\Q$rubric_path_literal\E/,
     "cwf-new-task/SKILL.md references the rubric path");
like($skill_subtask, qr/\Q$rubric_path_literal\E/,
     "cwf-new-subtask/SKILL.md references the rubric path");

done_testing();
