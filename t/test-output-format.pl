#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../.cwf/lib";
use TaskContextInference qw(format_output);

my $test_count = 0;
my $pass_count = 0;

sub test {
    my ($name, $condition, $message) = @_;
    $test_count++;
    if ($condition) {
        print "✓ PASS: $name\n";
        $pass_count++;
    } else {
        print "✗ FAIL: $name - $message\n";
    }
}

print "=" x 60 . "\n";
print "TaskContextInference Output Format Tests\n";
print "=" x 60 . "\n\n";

# TC-1: Conclusive Output Format
print "TC-1: Conclusive Output Format\n";
my $context_conclusive = {
    current => 'conclusive',
    confidence => 'correlated',
    task_num => '37',
    task_slug => 'fix-inconclusive-inference-output-format',
    workflow_step => 'g-testing-exec',
    candidates => 1,
};
my $output = format_output($context_conclusive, 0);
test("TC-1.1", $output =~ /^current: conclusive$/m, "Missing 'current: conclusive'");
test("TC-1.2", $output =~ /^confidence: correlated$/m, "Missing 'confidence: correlated'");
test("TC-1.3", $output =~ /^task_num: 37$/m, "Missing 'task_num: 37'");
test("TC-1.4", $output =~ /^task_slug: fix-inconclusive-inference-output-format$/m, "Missing task_slug");
test("TC-1.5", $output =~ /^workflow_step: g-testing-exec$/m, "Missing workflow_step");
test("TC-1.6", $output !~ /task_nums:/, "Should not have plural fields");
print "\n";

# TC-2: Inconclusive Output Format - Uncorrelated
print "TC-2: Inconclusive Output Format - Uncorrelated\n";
my $context_uncorrelated = {
    current => 'inconclusive',
    confidence => 'uncorrelated',
    candidates => 3,
    task_nums => ['14', '32', '37'],
    task_slugs => ['retro-suggest-updating', 'task-tracking-inference', 'fix-inconclusive-output'],
    workflow_steps => ['j-retrospective', 'j-retrospective', 'g-testing-exec'],
    reasons => ['branch_signal', 'recency_signal', 'progress_signal'],
};
$output = format_output($context_uncorrelated, 0);
test("TC-2.1", $output =~ /^current: inconclusive$/m, "Missing 'current: inconclusive'");
test("TC-2.2", $output =~ /^confidence: uncorrelated$/m, "Missing 'confidence: uncorrelated'");
test("TC-2.3", $output =~ /^task_nums: 14,32,37$/m, "Wrong task_nums format");
test("TC-2.4", $output =~ /^task_slugs: .*,.*,.*$/m, "Wrong task_slugs format");
test("TC-2.5", $output =~ /^workflow_steps: .*,.*,.*$/m, "Wrong workflow_steps format");
test("TC-2.6", $output =~ /^candidates: 3$/m, "Missing 'candidates: 3'");
test("TC-2.7", $output =~ /^reasons: .*signal.*$/m, "Missing reasons field");
test("TC-2.8", $output !~ /task_num:(?!\w)/, "Should not have singular fields");
print "\n";

# TC-3: Inconclusive Output Format - No Signals
print "TC-3: Inconclusive Output Format - No Signals\n";
my $context_no_signals = {
    current => 'inconclusive',
    confidence => 'no_signals',
    candidates => 0,
    task_nums => ['unknown'],
    task_slugs => ['unknown'],
    workflow_steps => ['unknown'],
    reasons => ['none'],
};
$output = format_output($context_no_signals, 0);
test("TC-3.1", $output =~ /^current: inconclusive$/m, "Missing 'current: inconclusive'");
test("TC-3.2", $output =~ /^confidence: no_signals$/m, "Missing 'confidence: no_signals'");
test("TC-3.3", $output =~ /^task_nums: unknown$/m, "Wrong task_nums value");
test("TC-3.4", $output =~ /^task_slugs: unknown$/m, "Wrong task_slugs value");
test("TC-3.5", $output =~ /^workflow_steps: unknown$/m, "Wrong workflow_steps value");
test("TC-3.6", $output =~ /^candidates: 0$/m, "Missing 'candidates: 0'");
test("TC-3.7", $output =~ /^reasons: none$/m, "Wrong reasons value");
print "\n";

# TC-4: Parseability - Simple Regex
print "TC-4: Parseability - Simple Regex\n";
my @lines = split /\n/, $output;
my $parseable_count = 0;
for my $line (@lines) {
    $parseable_count++ if $line =~ /^(\w+): (.+)$/;
}
test("TC-4.1", $parseable_count >= 5, "Not all lines parseable (found $parseable_count)");
print "\n";

# TC-5: Parseability - Comma-Separated Values
print "TC-5: Parseability - Comma-Separated Values\n";
my ($task_nums) = $output =~ /^task_nums: (.+)$/m;
my @nums = split /,/, $task_nums if $task_nums;
test("TC-5.1", @nums > 0, "Cannot split task_nums on comma");
print "\n";

# TC-7: Edge Case - Empty Arrays
print "TC-7: Edge Case - Empty Arrays\n";
my $context_empty = {
    current => 'inconclusive',
    confidence => 'uncorrelated',
    candidates => 0,
    task_nums => [],
    task_slugs => [],
    workflow_steps => [],
    reasons => [],
};
$output = format_output($context_empty, 0);
test("TC-7.1", $output =~ /^task_nums: unknown$/m, "Empty array should default to 'unknown'");
test("TC-7.2", $output =~ /^candidates: 0$/m, "Empty should have candidates: 0");
test("TC-7.3", defined($output), "Should not crash on empty arrays");
print "\n";

# TC-8: Edge Case - Single Candidate in Plural Format
print "TC-8: Edge Case - Single Candidate in Plural Format\n";
my $context_single = {
    current => 'inconclusive',
    confidence => 'uncorrelated',
    candidates => 1,
    task_nums => ['37'],
    task_slugs => ['fix-output'],
    workflow_steps => ['testing'],
    reasons => ['branch_signal'],
};
$output = format_output($context_single, 0);
test("TC-8.1", $output =~ /^task_nums: 37$/m, "Single value should not have trailing comma");
test("TC-8.2", $output !~ /37,/, "Should not have comma after single value");
print "\n";

# Summary
print "=" x 60 . "\n";
print "Test Summary: $pass_count/$test_count tests passed\n";
print "=" x 60 . "\n";

exit($pass_count == $test_count ? 0 : 1);
