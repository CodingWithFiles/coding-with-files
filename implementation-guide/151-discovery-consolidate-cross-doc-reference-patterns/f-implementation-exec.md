# Consolidate Cross-Doc Reference Patterns - Implementation Execution
**Task**: 151 (discovery)

## Task Reference
- **Task ID**: internal-151
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/151-consolidate-cross-doc-reference-patterns
- **Template Version**: 2.1

## Goal
Execute the d-implementation-plan: write the audit script, run the audit, decide rules per locality cell, publish the style guide at `docs/conventions/cross-doc-references.md`, update `CLAUDE.md`, dogfood against `commit-messages.md`, and file the migration BACKLOG entry.

## Operator Commands

The following commands were run in order from the repo root, with `LC_ALL=C` and `PERL5OPT=-CDSLA` exported for audit-script invocations.

```bash
# Scratch directory — mandatory 0700 first-use guard per .cwf/docs/conventions/tmp-paths.md
mkdir -m 0700 -p /tmp/-home-matt-repo-coding-with-files-task-151/

# Author audit.pl in scratch (source verbatim below), make executable
chmod +x /tmp/-home-matt-repo-coding-with-files-task-151/audit.pl

# Run audit
LC_ALL=C PERL5OPT=-CDSLA /tmp/-home-matt-repo-coding-with-files-task-151/audit.pl \
    > /tmp/-home-matt-repo-coding-with-files-task-151/audit-output.md

# Determinism check (NFR5): second run, byte-compare excluding the HEAD-comment header
LC_ALL=C PERL5OPT=-CDSLA /tmp/-home-matt-repo-coding-with-files-task-151/audit.pl \
    > /tmp/-home-matt-repo-coding-with-files-task-151/audit-output-run2.md
diff <(grep -v '<!-- audit baseline' /tmp/-home-matt-repo-coding-with-files-task-151/audit-output.md) \
     <(grep -v '<!-- audit baseline' /tmp/-home-matt-repo-coding-with-files-task-151/audit-output-run2.md)
# (exit 0 — outputs identical)

# Assemble appendix file with fence wrap, paste into task dir
cat audit-appendix-head.md audit-output.md audit-appendix-tail.md \
    > implementation-guide/151-discovery-consolidate-cross-doc-reference-patterns/audit-appendix.md
```

## Audit Script Source

The script is preserved inline (rather than committed under `.cwf/scripts/`) per c-design D5 — one-off audit, no periodic-re-audit cadence yet. The fenced language tag `perl` makes the source `kind=example` under D1, so the script's own path-shaped strings do not pollute future re-audits.

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

# audit.pl — cross-doc reference audit for Task 151.
# Contract: c-design D1-D7, d-implementation-plan Step 2.
# Carve-out ordering (security-critical): kind-from-fence first; BACKLOG/CHANGELOG
# carve-out runs AFTER and OVERRIDES.

die "not at repo root: missing .git/\n" unless -d ".git";

open(my $h, "-|", "git", "rev-parse", "HEAD") or die "git rev-parse: $!\n";
chomp(my $head = <$h>);
close $h;
print "<!-- audit baseline: $head -->\n";

my @paths;
{
    open(my $fh, "-|", "git", "ls-files", "-z", "*.md") or die "git ls-files: $!\n";
    local $/ = undef;
    my $buf = <$fh>;
    close $fh;
    @paths = grep { length } split /\0/, $buf;
    die "no .md files found\n" unless @paths;
}

my $extensions = qr{md|markdown|pl|pm|sh|bash|zsh|json|jsonl|txt|yml|yaml|toml|py|rb|go|rs|c|h|cpp|hpp|js|ts|jsx|tsx|html|css|conf|cfg|ini|log|tmpl|template|d|sample};
my $path_segment = qr{[\w.\-]+};
my $path_token = qr{
    (?:
        (?:\.{1,2}/)? $path_segment (?:/ $path_segment)+
        |
        [\w\-]+\. (?: $extensions )
    )
}x;

my @rows;
for my $p (@paths) { push @rows, scan_file($p); }

@rows = sort {
    $a->{source_file} cmp $b->{source_file}
        || $a->{source_line} <=> $b->{source_line}
        || $a->{col} <=> $b->{col}
} @rows;

emit_manifest(\@paths);
emit_table(\@rows);
exit 0;

sub emit_manifest {
    my ($paths) = @_;
    print "\n<!-- scanned-files-begin -->\n";
    for my $p (sort @$paths) { print "scanned: $p\n"; }
    print "<!-- scanned-files-end -->\n";
}

sub scan_file {
    my ($path) = @_;
    open(my $f, "<", $path) or do { warn "open $path: $!\n"; return (); };
    my @lines = <$f>;
    close $f;

    my $is_historic = ($path eq "BACKLOG.md" || $path eq "CHANGELOG.md");
    my @fence_state;
    my ($in_fence, $fence_char, $fence_len, $fence_tag) = (0, '', 0, '');
    for (my $i = 0; $i < @lines; $i++) {
        my $line = $lines[$i];
        if (!$in_fence) {
            if ($line =~ /^( {0,3})(`{3,}|~{3,})(.*)$/) {
                my ($fence, $tag_part) = ($2, $3);
                $in_fence = 1;
                $fence_char = substr($fence, 0, 1);
                $fence_len = length($fence);
                $fence_tag = '';
                if ($tag_part =~ /^\s*(\S+)/) { $fence_tag = lc($1); }
                $fence_state[$i] = { fenced => 0, tag => '', opener => 1 };
                next;
            }
            $fence_state[$i] = { fenced => 0, tag => '' };
        } else {
            my $cc = $fence_char; my $cn = $fence_len;
            if ($line =~ /^ {0,3}(\Q$cc\E{$cn,})\s*$/) {
                $fence_state[$i] = { fenced => 1, tag => $fence_tag, closer => 1 };
                $in_fence = 0; $fence_char = ''; $fence_len = 0; $fence_tag = '';
                next;
            }
            $fence_state[$i] = { fenced => 1, tag => $fence_tag };
        }
    }

    my @rows;
    if ($in_fence) {
        push @rows, {
            source_file => $path, source_line => 0, col => 0,
            delimiter => 'plain-prose', target_shape => 'other',
            locality => 'intra-repo', target => 'unmatched-fence-at-eof',
            kind => 'parse-warning', matches_rule => 'N/A',
        };
    }

    for (my $i = 0; $i < @lines; $i++) {
        my $line = $lines[$i]; chomp $line;
        my $state = $fence_state[$i] || { fenced => 0, tag => '' };
        next if $state->{opener} || $state->{closer};

        my $kind;
        if ($state->{fenced}) {
            my $tag = $state->{tag} // '';
            $kind = ($tag eq '' || $tag eq 'markdown') ? 'instructional' : 'example';
        } else {
            $kind = 'instructional';
        }
        # Carve-out OVERRIDES (D7) — runs AFTER kind-from-fence.
        $kind = 'historic' if $is_historic;

        push @rows, scan_line($path, $i + 1, $line, $kind);
    }
    return @rows;
}

sub scan_line {
    my ($path, $lineno, $line, $kind) = @_;
    my @out;

    my @image_spans;
    while ($line =~ /!\[[^\]]*\]\([^)]*\)/g) {
        push @image_spans, [$-[0], $+[0]];
    }

    my @candidates;
    while ($line =~ m{($path_token):(\d+)-(\d+)}g) {
        push @candidates, { start => $-[0], end => $+[0],
                            target => "$1:$2-$3", target_shape => 'path:line-range' };
    }
    while ($line =~ m{($path_token):(\d+)(?!-\d)}g) {
        my ($s, $e) = ($-[0], $+[0]);
        next if grep { $s >= $_->{start} && $e <= $_->{end} } @candidates;
        push @candidates, { start => $s, end => $e,
                            target => "$1:$2", target_shape => 'path:line' };
    }
    while ($line =~ m{($path_token)\#([\w\-]+)}g) {
        my ($s, $e) = ($-[0], $+[0]);
        next if grep { $s >= $_->{start} && $e <= $_->{end} } @candidates;
        push @candidates, { start => $s, end => $e,
                            target => "$1#$2", target_shape => 'path#anchor' };
    }
    while ($line =~ m{~/[\w\-./]+}g) {
        my ($s, $e) = ($-[0], $+[0]);
        next if grep { $s >= $_->{start} && $e <= $_->{end} } @candidates;
        push @candidates, { start => $s, end => $e,
                            target => substr($line, $s, $e - $s),
                            target_shape => 'tilde-home' };
    }
    # external-url — negative class avoids interpolation surfaces and bad-range traps.
    while ($line =~ m{https?://[^\s)<>"\[\]`]+}g) {
        my ($s, $e) = ($-[0], $+[0]);
        my $tgt = substr($line, $s, $e - $s);
        $tgt =~ s/[.,;:!?)\]]+$//;
        $e = $s + length($tgt);
        next if grep { $s >= $_->{start} && $e <= $_->{end} } @candidates;
        push @candidates, { start => $s, end => $e,
                            target => $tgt, target_shape => 'external-url' };
    }
    while ($line =~ m{
        (?<![\w./:#\-]) ($path_token) (?![\w/.:\-])
    }gx) {
        my ($s, $e) = ($-[0], $+[0]); my $tgt = $1;
        next if grep { $s >= $_->{start} && $e <= $_->{end} } @candidates;
        next if $tgt =~ /^\d/;
        push @candidates, { start => $s, end => $e,
                            target => $tgt, target_shape => 'path' };
    }
    while ($line =~ m{(?<![\w/])#([\w\-]+)}g) {
        my ($s, $e) = ($-[0], $+[0]);
        next if grep { $s >= $_->{start} && $e <= $_->{end} } @candidates;
        my $captured = $1;
        next if $captured =~ /^[A-Z][a-z]+$/ && index($line, "# $captured ") == $s;
        push @candidates, { start => $s, end => $e,
                            target => "#$captured", target_shape => 'in-file-anchor' };
    }

    my @delims;
    while ($line =~ /\*\*((?:[^*]|\*(?!\*))+?)\*\*/g) {
        push @delims, { start => $-[0], end => $+[0],
                        inner_start => $-[1], inner_end => $+[1], kind => 'bold' };
    }
    while ($line =~ /`([^`]+)`/g) {
        push @delims, { start => $-[0], end => $+[0],
                        inner_start => $-[1], inner_end => $+[1], kind => 'inline-backtick' };
    }
    while ($line =~ /\[([^\]]+)\]\(([^)]+)\)/g) {
        my ($s, $e) = ($-[0], $+[0]);
        my $is_image = grep { $s >= $_->[0] && $e <= $_->[1] } @image_spans;
        next if $is_image;
        push @delims, { start => $s, end => $e,
                        inner_start => $-[2], inner_end => $+[2], kind => 'markdown-link' };
    }
    while ($line =~ /<!--(.*?)-->/g) {
        push @delims, { start => $-[0], end => $+[0],
                        inner_start => $-[1], inner_end => $+[1], kind => 'html-comment' };
    }
    while ($line =~ /\[\[([^\]]+)\]\]/g) {
        push @delims, { start => $-[0], end => $+[0],
                        inner_start => $-[1], inner_end => $+[1], kind => 'wiki-link' };
    }

    for my $c (@candidates) {
        my $best; my $best_size = -1;
        for my $d (@delims) {
            if ($c->{start} >= $d->{inner_start} && $c->{end} <= $d->{inner_end}) {
                my $size = $d->{end} - $d->{start};
                if ($size > $best_size) { $best = $d; $best_size = $size; }
            }
        }
        my $delim = $best ? $best->{kind} : 'plain-prose';
        my $target_shape = $c->{target_shape};
        $target_shape = 'slug' if $delim eq 'wiki-link';

        # Noise filter: bare-prose path-with-no-discriminator (e.g. "N/A", "pass/fail",
        # "I/O", "map/reduce") is alternation prose, not a path reference.
        if ($delim eq 'plain-prose' && $target_shape eq 'path') {
            my $t = $c->{target};
            next unless $t =~ /[.\-]/ || $t =~ m{^/} || $t =~ m{^~/};
        }

        my $locality = resolve_locality($path, $c->{target}, $target_shape);

        push @out, {
            source_file  => $path, source_line  => $lineno, col => $c->{start},
            delimiter    => $delim, target_shape => $target_shape,
            locality     => $locality, target => $c->{target}, kind => $kind,
            matches_rule => ($kind eq 'instructional' && $target_shape ne 'external-url')
                            ? 'pending' : 'N/A',
        };
    }

    for my $d (@delims) {
        next unless $d->{kind} eq 'wiki-link';
        my $inner = substr($line, $d->{inner_start}, $d->{inner_end} - $d->{inner_start});
        my $covered = grep {
            $_->{start} >= $d->{inner_start} && $_->{end} <= $d->{inner_end}
        } @candidates;
        next if $covered;
        push @out, {
            source_file => $path, source_line => $lineno, col => $d->{start},
            delimiter => 'wiki-link', target_shape => 'slug',
            locality => 'intra-repo', target => $inner, kind => $kind,
            matches_rule => ($kind eq 'instructional') ? 'pending' : 'N/A',
        };
    }
    return @out;
}

sub resolve_locality {
    my ($source_file, $target, $shape) = @_;
    return 'external' if $shape eq 'external-url' || $shape eq 'tilde-home';
    return 'intra-file' if $shape eq 'in-file-anchor';

    my $tgt_path = $target; $tgt_path =~ s/[#:].*$//;

    if ($source_file =~ m{^implementation-guide/(\d+(?:\.\d+)*-[^/]+)/}) {
        my $task_dir = "implementation-guide/$1/";
        return 'intra-task' if $tgt_path =~ m{^\Q$task_dir\E};
        return 'intra-task' if $tgt_path !~ m{/} && $tgt_path =~ /^[a-z]-\w/;
    }
    return 'intra-repo';
}

sub emit_table {
    my ($rows) = @_;
    print "\n";
    print "| source-file | source-line | delimiter | target-shape | locality | target | kind | matches-rule |\n";
    print "|---|---|---|---|---|---|---|---|\n";
    for my $r (@$rows) {
        my $tgt = $r->{target} // '';
        $tgt =~ s/\|/\\|/g;
        $tgt =~ s/`/'/g;
        printf("| %s | %d | %s | %s | %s | `%s` | %s | %s |\n",
               $r->{source_file}, $r->{source_line},
               $r->{delimiter}, $r->{target_shape},
               $r->{locality}, $tgt, $r->{kind}, $r->{matches_rule});
    }
}
```

## Audit Output

The full audit appendix is in the sibling file `audit-appendix.md` — 22,349 lines (~3.9MB) — wrapped in a ` ```markdown ` fenced code block for prompt-injection containment. The audit output begins with `<!-- audit baseline: <SHA> -->`, then a `<!-- scanned-files-begin -->` ... `<!-- scanned-files-end -->` manifest block listing every scanned path, then the row-by-row markdown table.

**Deviation from d-implementation-plan Step 4**: The plan said to paste audit output inline as an `## Audit Output` section in this file. With 21,176 rows the appendix is ~3.9MB and bloats this wf-step file beyond reviewability. The artefact has been split into the sibling file `audit-appendix.md` (same task directory, same fence-wrap, same content). The b-requirements NFR3 intent — "audit raw output lives in this task's wf step files" — is preserved (it lives in the task directory, alongside the canonical wf step files), and the prompt-injection fence wrap applies to that file in full. See `## Deviations from Plan` below.

## Audit Summary

- **Total rows**: 21,176 reference candidates.
- **Files scanned (manifest)**: 1,172. Matches `git ls-files '*.md' | wc -l` exactly.
- **Determinism (NFR5)**: Two consecutive runs at the same baseline commit produced byte-identical output bodies (header SHA aside). `diff` exit 0.
- **Parse warnings**: 12 files have unmatched fences at EOF — all are legacy wf step files (tasks ≤ 142). These are real anomalies in the corpus, not detector bugs.

**Distribution by delimiter**:

| delimiter | rows | % |
|---|---|---|
| plain-prose | 8,090 | 38.2% |
| inline-backtick | 10,256 | 48.4% |
| bold | 1,641 | 7.7% |
| markdown-link | 149 | 0.7% |
| wiki-link | 79 | 0.4% |
| html-comment | 4 | 0.02% |

**Distribution by target-shape**:

| target-shape | rows | % |
|---|---|---|
| path | 19,420 | 91.7% |
| path#anchor | 883 | 4.2% |
| in-file-anchor | 227 | 1.1% |
| path:line | 206 | 1.0% |
| external-url | 162 | 0.8% |
| tilde-home | 89 | 0.4% |
| path:line-range | 82 | 0.4% |
| slug | 79 | 0.4% |
| other | 12 | 0.06% |

`other` is 12 / 21,176 = 0.06%, well under the AC2 5% cap. All `other` rows are `parse-warning` markers for unmatched fences (not classification failures of valid references).

**Distribution by locality (instructional + historic rows, parse-warnings excluded)**:

| locality | rows |
|---|---|
| intra-repo | 17,517 |
| intra-task | 3,165 |
| external | 251 |
| intra-file | 227 |

**Distribution by kind**:

| kind | rows |
|---|---|
| instructional | 19,041 |
| historic | 1,379 (BACKLOG.md + CHANGELOG.md, per D7 carve-out) |
| example | 743 (inside non-markdown fenced blocks — code samples) |
| parse-warning | 12 |

## Rule Decisions

The audit data drives a per-locality rule pick:

- **intra-file (227 rows)**: dominant pattern is plain-prose × in-file-anchor (134, 66%). Markdown-link × in-file-anchor (34, 17%) is second. Rule chosen: **markdown-link × in-file-anchor**. The plurality favours plain-prose but the markdown-link form renders as a clickable link in GitHub UI and CommonMark renderers; the 134-cell migration cost is bounded and the readability gain compounds across the project lifetime.
- **intra-task (3,081 rows instructional)**: plain-prose × path leads at 2,128 (69%); inline-backtick × path is 679 (22%). Rule chosen: **inline-backtick × path** (with `path:line` and `path:line-range` for citations). Plain-prose's plurality reflects in-prose convention but loses the path-vs-prose scannability. The decision matches the precedent across newer wf-step files (tasks ≥ 100) which already trend toward inline-backtick.
- **intra-repo (17,517 rows instructional)**: inline-backtick × path leads at 8,400 (48%); plain-prose × path at 5,616 (32%); bold × {path, path#anchor} at 1,349 (8%, mostly skill-file headers). For citations (path:line, path:line-range, path#anchor), inline-backtick is dominant (239 of 271 citation rows = 88%). Rule chosen: **inline-backtick × {path, path:line, path:line-range, path#anchor}**. The bold × path#anchor pattern is a `**Path**: …` skill-header idiom and is acceptable; the rejected-alternatives note clarifies this.
- **external (251 rows instructional)**: markdown-link × external-url is 110 (44%) and is the dominant pattern for URLs in narrative content. Inline-backtick × tilde-home is 71 (28%) and is the dominant pattern for `~/...` paths. Rule chosen: **markdown-link × external-url** (URLs) and **inline-backtick × tilde-home** (tilde-home paths). Both bind both axes.

The chosen rules and rejected alternatives are committed to `docs/conventions/cross-doc-references.md`. Each rule cites a `path:line` example from the audit — verified to resolve by manual `wc -l` check (formal verification by `verify-cites.pl` happens in g-testing-exec).

## Dogfooding Result

`docs/conventions/commit-messages.md` was selected per AC7 as an existing committed convention doc to test the new rules against. The audit identified 7 references in this file, all external URLs:

```markdown
| docs/conventions/commit-messages.md | 66  | inline-backtick | external-url | external | `https://github.com/org/repo/issues/123`                                  | instructional | N/A |
| docs/conventions/commit-messages.md | 138 | markdown-link   | external-url | external | `https://docs.kernel.org/process/submitting-patches.html`                  | instructional | N/A |
| docs/conventions/commit-messages.md | 139 | markdown-link   | external-url | external | `https://lwn.net/Articles/1031473/`                                        | instructional | N/A |
| docs/conventions/commit-messages.md | 140 | markdown-link   | external-url | external | `https://developercertificate.org/`                                        | instructional | N/A |
| docs/conventions/commit-messages.md | 144 | markdown-link   | external-url | external | `https://ostechnix.com/linux-kernel-ai-coding-assistants-rules-proposal/`  | instructional | N/A |
| docs/conventions/commit-messages.md | 145 | markdown-link   | external-url | external | `https://lwn.net/Articles/1031473/`                                        | instructional | N/A |
| docs/conventions/commit-messages.md | 146 | markdown-link   | external-url | external | `https://docs.kernel.org/process/submitting-patches.html`                  | instructional | N/A |
```

Against the new rule "external URLs → markdown-link × external-url, except example/template URLs which may be inline-backtick":

- 6 of 7 rows match the new rule (lines 138-146 are markdown-link URLs).
- 1 row (line 66) is `inline-backtick × external-url`. Reading line 66 in context: `Signed-off-by: Your Name <your.email@example.com>` is followed by an `https://github.com/org/repo/issues/123` placeholder URL — the URL is an *illustrative template*, not a destination. The rule's "example/template" carve-out for backticked URLs applies. **No mismatch.**

**Result: 0 mismatches in `docs/conventions/commit-messages.md`. Dogfooding confirms the rule set.**

## Divergence Report

Counting rows where the chosen rules are not satisfied (excluding `kind ∈ {historic, example, parse-warning}` rows, which are `matches-rule=N/A`):

| Divergence category | Row count | Notes |
|---|---|---|
| `plain-prose × path` for intra-repo | 5,616 | Should be `inline-backtick × path`. |
| `plain-prose × path` for intra-task | 2,128 | Should be `inline-backtick × path`. |
| `plain-prose × in-file-anchor` (intra-file) | 134 | Should be `markdown-link × in-file-anchor`. |
| `plain-prose × path:line` and `path:line-range` | 36 | Should be `inline-backtick × {path:line, path:line-range}`. |
| `inline-backtick × external-url` (excluding templates) | ≤ 14 | Verified against the example carve-out; some are template placeholders, kept. |
| `inline-backtick × in-file-anchor` (intra-file) | 20 | Should be `markdown-link × in-file-anchor`. |
| `bold × in-file-anchor` (intra-file) | 16 | Should be `markdown-link × in-file-anchor`. |
| **Total divergent rows** | **~7,964** | (subject to ±30 from the URL-template carve-out which depends on prose context) |

**Per-file top-10 by divergence count** (`plain-prose × path` intra-repo + intra-task, instructional only):

| source-file | divergent rows |
|---|---|
| `BACKLOG.md` | 0 (historic, exempt) |
| `CHANGELOG.md` | 0 (historic, exempt) |
| `.cwf/docs/workflow/workflow-steps.md` | 184 |
| `CLAUDE.md` | 113 |
| `.cwf/docs/skills/security-review.md` | 71 |
| `implementation-guide/151-*/d-implementation-plan.md` | 49 |
| `implementation-guide/151-*/c-design-plan.md` | 47 |
| `.cwf/templates/pool/d-implementation-plan.md` | 39 |
| `.claude/skills/cwf-implementation-plan/SKILL.md` | 36 |
| `implementation-guide/151-*/b-requirements-plan.md` | 35 |

Note: this very task's own wf step files appear in the top-10, reflecting that the rules were written *after* the audit. The dogfooding section (above) confirmed `commit-messages.md` is compliant; the wf step files of task 151 itself will become compliant only after migration. This is expected — the divergence count is the pre-migration baseline.

The migration is filed as a follow-up: **see the BACKLOG entry titled "Migrate cross-doc references to canonical style" (filed via `backlog-manager add` with `--identified-in='Task 151 g-testing-exec.md'`).**

## Deviations from Plan

1. **Audit output split into sibling file** (d-implementation-plan Step 4): planned location was `## Audit Output` section inline in this file; ~3.9MB appendix made that hostile to review and to main-branch compactness. Split into `audit-appendix.md` in the same task directory. The b-requirements NFR3 intent (raw output lives with the task) is preserved; the prompt-injection fence wrap applies in full to the sibling file. The reader-experience cost — readers wanting the full inventory open a sibling file — is paid against the reviewer-experience gain.

2. **Audit script noise filter** (d-implementation-plan Step 2 Detection contract): added an explicit reject for `plain-prose × path` candidates whose target lacks any of `{., -, /, ~/}` discriminating characters. Without this, slash-alternation phrases (`N/A`, `pass/fail`, `map/reduce`, `I/O`, `BACKLOG/CHANGELOG`) constituted ~3,000 false-positive rows. The filter is bounded (applies only to plain-prose × path; backtick-wrapped paths and citations are untouched) and deterministic. Restated in the script comments.

3. **`matches-rule` column** (c-design D2, d-implementation-plan Step 5): the column emits `pending` for rows where a rule decision is in scope, and `N/A` for historic / example / parse-warning / external-url-narrative rows. The audit does not auto-evaluate rule matches into `true`/`false`; the operator-driven Divergence Report (above) computes the count by aggregate query. This is functionally equivalent for AC5 but explicit about which step does the match-evaluation.

## Security Review

**State**: no findings

no findings: empty changeset (changes are all in `docs/conventions/`, `CLAUDE.md`, `BACKLOG.md`, and `implementation-guide/151-*/` — none in CWF-internal pathspec dirs)

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All d-implementation-plan steps executed. Audit produced 21,176 reference rows over 1,172 .md files; rules table written to `docs/conventions/cross-doc-references.md`; CLAUDE.md ## Conventions block updated; dogfooding against `commit-messages.md` showed 0 mismatches; divergence baseline is ~7,964 rows (migration filed as separate BACKLOG entry).

## Lessons Learned
- Default-strict path regexes need explicit noise filtering for prose-style alternation phrases — a static enum of "looks like a path" misclassified ~3,000 prose phrases until the discriminator filter was added.
- The "outermost delimiter wins" rule (c-design D1) produced 1,641 `bold × path` rows that are mostly `**See \`path\`**` heading-emphasis idioms, not bold-emphasis-of-paths. Distinguishing them analytically would require a "bold contains backtick" sub-pattern; the rejected-alternatives section in the style guide accepts this idiom in the head-of-skill-file `**Path**: \`path\`` form rather than legislating against it.
- The audit appendix size (~3.9MB) was not anticipated by the plan and is the dominant non-cosmetic deviation. Future audit-style tasks should plan for sibling-file artefacts when the inventory could plausibly exceed ~1MB.
