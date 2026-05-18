# Consolidate Cross-Doc Reference Patterns - Implementation Plan
**Task**: 151 (discovery)

## Task Reference
- **Task ID**: internal-151
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/151-consolidate-cross-doc-reference-patterns
- **Template Version**: 2.1

## Goal
Lay out the exact sequence of operator actions, file writes, and script invocations needed to execute the c-design. d-plan is the contract; f-implementation-exec writes the script body against this contract; g-testing-exec verifies the artefacts against AC1-AC8.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Phase Boundary
- **f-implementation-exec** produces: `audit.pl` (in `/tmp/`), audit output appendix inside `f-implementation-exec.md`, rule decisions, `docs/conventions/cross-doc-references.md`, the `CLAUDE.md` `## Conventions` insertion, dogfooding-against-`commit-messages.md` result, and (conditionally) the BACKLOG migration entry.
- **g-testing-exec** produces: `verify-cites.pl` execution, systematic AC1-AC8 verification with evidence, and the checkpoint commit for testing.

This split avoids the prior draft's phase bleed where g- was being written by f-.

## Files to Modify

### Primary Changes (committed, repo-tracked)
- `docs/conventions/cross-doc-references.md` — **new file**. Style guide per c-design D4.
- `CLAUDE.md` — **one insertion** in `## Conventions` block, between `**Git Path Handling**` and `**Tmp Paths**` per c-design D4. The literal snippet lives only in c-design D4 line 170-175; do not re-quote it here.
- `implementation-guide/151-discovery-consolidate-cross-doc-reference-patterns/f-implementation-exec.md` — audit script source (` ```perl ` fence), audit output appendix (` ```markdown ` fence per c-design D2), audit summary, rule decisions, dogfooding result, operator commands run.
- `implementation-guide/151-discovery-consolidate-cross-doc-reference-patterns/g-testing-exec.md` — `verify-cites.pl` source, AC1-AC8 verification with evidence.

### Conditional Changes
- `BACKLOG.md` — **one entry** iff divergence count > 0. Invocation pattern pinned in b-requirements FR5: `backlog-manager add --identified-in='Task 151 g-testing-exec.md' ...`.

### Out-of-scope (must not touch)
- `.cwf/templates/pool/*.md`, `.claude/skills/**/*.md`, `.claude/agents/**/*.md`, `.claude/rules/*.md` — LLM-facing, load-bearing.
- `.cwf/docs/conventions/*.md` — shipped tree, out of scope per c-design D4 dev-vs-shipped boundary.
- Any existing diverging references — migration is FR5, not this task.

## Implementation Steps (f-implementation-exec)

### Step 1: Scratch directory setup
- [ ] `mkdir -m 0700 -p /tmp/-home-matt-repo-coding-with-files-task-151/` — mandatory first-use guard per `.cwf/docs/conventions/tmp-paths.md`. Restated here, not just cited.
- [ ] Confirm cwd is repo root.

### Step 2: Author `audit.pl` in scratch
- [ ] Write `/tmp/-home-matt-repo-coding-with-files-task-151/audit.pl`. Then `chmod +x` and run by absolute path (per `feedback_chmod_and_execute`).
- [ ] Script contract (skeleton — full body filled during f-exec; this is the d-plan contract):
  ```perl
  #!/usr/bin/env perl
  use strict;
  use warnings;
  use utf8;
  # PERL5OPT=-CDSLA expected in env; LC_ALL=C expected in env

  die "not at repo root" unless -d ".git";

  # 1. Record HEAD as header comment.
  open(my $h, "-|", "git", "rev-parse", "HEAD") or die "git rev-parse: $!";
  chomp(my $head = <$h>);
  close $h;
  print "<!-- audit baseline: $head -->\n";

  # 2. Read paths via list-form, NUL-separated.
  open(my $fh, "-|", "git", "ls-files", "-z", "*.md") or die "git ls-files: $!";
  local $/ = undef;
  my $buf = <$fh>;
  close $fh;
  my @paths = grep { length } split /\0/, $buf;
  die "no .md files found" unless @paths;

  # 3. Per-file scan: span-based pre-passes + delimiter detect + target-shape detect.
  my @rows;
  for my $p (@paths) { push @rows, scan_file($p); }

  # 4. Sort under LC_ALL=C and emit table.
  @rows = sort { $a->{source_file} cmp $b->{source_file}
                 || $a->{source_line} <=> $b->{source_line} } @rows;
  emit_table(\@rows);

  sub scan_file { ... }    # implements D1 detection pipeline (see contract below)
  sub emit_table { ... }   # markdown table; backtick-fence `target` cells
  ```
- [ ] **Detection contract** (extends c-design D1):
  - **Pre-pass 1: fence spans**. Identify `\`\`\`` (3+ backticks) and `~~~` (3+ tildes) fenced regions. Closer must match opener char and have ≥ opener run-length. Indented (4-space) blocks NOT recognised. Unmatched fence at EOF → one `parse-warning` row, rest of file treated as fenced.
  - **Pre-pass 2: image-syntax spans**. Identify `!\[[^\]]*\]\([^)]*\)` spans. Subsequent `markdown-link` matches whose span overlaps an image span are discarded. (Span-based, not line-based — a line with both an image and a link keeps the link.)
  - **Delimiter detection**: regex per delimiter (`bold`, `inline-backtick`, `markdown-link`, `html-comment`, `wiki-link`, `plain-prose` catch-all). When matches nest (e.g. `[link with **bold**](path)`), prefer the **outermost** delimiter, not first-by-position. Implementation: detect all candidate spans, then for any pair where one span contains another, keep only the outer.
  - **Target-shape detection** (independent regex pass inside matched delimiter span): `path:line-range` before `path:line`; then `path#anchor`, `in-file-anchor`, `tilde-home`, `external-url`, `slug`, `path`, `other`.
  - **`kind` rule** (inverted from prior draft): `kind=instructional` iff (a) no fence OR (b) fence with NO language tag OR with tag `markdown`. Any other tag (`bash`, `perl`, `python`, `json`, `text`, etc.) ⇒ `kind=example`.
  - **Carve-out ordering** (security-critical): the kind-from-fence rule runs FIRST; the BACKLOG/CHANGELOG carve-out (`if source-file ∈ {BACKLOG.md, CHANGELOG.md} then kind=historic`) runs AFTER and OVERRIDES. Document this order in the script with a comment so future refactors preserve it.
- [ ] The full audit.pl source is later pasted into `f-implementation-exec.md` as a ` ```perl ` fenced block. Per c-design D1's inverted `kind` rule, that fence is `kind=example`, so the script's own path-shaped strings do not pollute re-audits. **This pasted source is documentation, not an executable artefact** — no `.cwf/security/script-hashes.json` entry is needed.

### Step 3: Run audit, capture output
- [ ] `LC_ALL=C /tmp/-home-matt-repo-coding-with-files-task-151/audit.pl > /tmp/-home-matt-repo-coding-with-files-task-151/audit-output.md`
- [ ] Visually confirm the `<!-- audit baseline: SHA -->` header matches `a-task-plan.md:9` Baseline Commit.
- [ ] **File-count sanity check** (replaces row-count check): `git ls-files '*.md' | wc -l` should be ≈1170 (±50 for normal churn). The audit emits one row per *reference*, which is in the thousands — row-count bounds are too volatile to be useful. File count is the FR1-relevant invariant.

### Step 4: Compose audit appendix in `f-implementation-exec.md`
- [ ] In `f-implementation-exec.md`, add section `## Audit Output`.
- [ ] Open a ` ```markdown ` fenced code block, paste the contents of `/tmp/.../audit-output.md`, close the fence. **This fence is the prompt-injection containment (c-design D2)** — every `target` cell scraped from skill bodies, agent definitions, and other LLM-facing files is rendered as literal text, not loaded as instruction when this wf file later enters LLM context.
- [ ] Below the fence, add `## Audit Summary`: total row count, count per `kind` value, count per `(locality, delimiter, target-shape)` triple (top 10), count of `matches-rule=N/A` rows.

### Step 5: Rule-decision pass
- [ ] In `f-implementation-exec.md`, add `## Rule Decisions`. For each occurring locality cell (intra-file, intra-task, intra-repo, external):
  - Which `delimiter` × `target-shape` is preferred?
  - Does the rule bind `delimiter`, `target-shape`, or `both`?
  - One-sentence rationale.
- [ ] Low-divergence outcome (b-requirements FR7, AC8): if only 1-2 locality cells occur, the style guide is short and explicitly says "patterns already consistent". Do NOT pad.

### Step 6: Author `docs/conventions/cross-doc-references.md`
- [ ] Write the file. Structure per c-design D4 (rules-with-rationale shape, sections `## Convention` / `## Why` / `## See also`).
- [ ] `## Convention`: rules table per c-design D3, followed by the BACKLOG/CHANGELOG carve-out paragraph (one sentence per c-design D7).
- [ ] `## Why`: headline findings; migration status (divergence count + BACKLOG reference) as the final paragraph (not a separate section, matching `git-path-output.md` precedent).
- [ ] `## See also`: 1-3 selective links — `docs/conventions/design-alignment.md` is the closest neighbour. Include `.cwf/docs/conventions/session-hygiene.md` only if it genuinely relates.
- [ ] Citation policy: every rule row cites a `path:line` (or `path:line-range`) from the audit. Quoted snippets from skill bodies are backtick-fenced (b-requirements FR4).

### Step 7: Update `CLAUDE.md`
- [ ] Edit `CLAUDE.md`. Use the verbatim snippet from c-design D4 line 170-175. Insertion point: between `**Git Path Handling**` and `**Tmp Paths**`.

### Step 8: Dogfooding against `commit-messages.md` (AC7)
- [ ] Filter audit output: `grep '^| docs/conventions/commit-messages.md' /tmp/.../audit-output.md > /tmp/.../commit-messages-rows.md`. No second classification pass — the audit already classified these rows.
- [ ] In `f-implementation-exec.md`, add `## Dogfooding Result`. Walk the filtered rows against the rule set from Step 5. List any references that don't match the new rules. If none: "No mismatches in `commit-messages.md` — dogfooding confirmed."
- [ ] Snippet rule: any audit-row excerpts pasted in this section are wrapped in the same ` ```markdown ` fence as Step 4. The injection defence applies to every committed paste of audit-scraped text, not just the main appendix.

### Step 9: Divergence count + conditional BACKLOG entry
- [ ] In `f-implementation-exec.md`, add `## Divergence Report`: count of audit rows where `matches-rule = false` (excluding `N/A`), broken down by `source-file`.
- [ ] If count = 0: write "No divergences observed; no migration entry filed." Done.
- [ ] If count > 0: file BACKLOG entry. **Use the Write tool first to create the body file**, then invoke `backlog-manager`. Sequence:
  1. Write `/tmp/-home-matt-repo-coding-with-files-task-151/migration-body.md`. Contents: one-line summary, total count, top-5 worst files, the dogfooding-result list from Step 8. **Any audit-row excerpts in this body are wrapped in a ` ```markdown ` fence** — this file flows into `BACKLOG.md`, which is committed and re-enters LLM context downstream.
  2. Run:
     ```bash
     .cwf/scripts/command-helpers/backlog-manager add \
         --title='Migrate cross-doc references to canonical style' \
         --task-type=chore \
         --priority=Low \
         --identified-in='Task 151 g-testing-exec.md' \
         --body-file=/tmp/-home-matt-repo-coding-with-files-task-151/migration-body.md
     ```
- [ ] Step 8 (dogfooding) runs BEFORE Step 9 (BACKLOG entry) — there is no `backlog-manager edit` subcommand, so the entry body must be complete at submission.

### Step 10: f-implementation-exec checkpoint commit
- [ ] Use the canonical helper: `.cwf/scripts/command-helpers/cwf-checkpoint-commit 151 f "<why message>"`. The helper stages the wf file and runs `cwf-manage validate` automatically.
- [ ] Stage non-wf files first via `git add`: `docs/conventions/cross-doc-references.md`, `CLAUDE.md`, and `BACKLOG.md` (if applicable).
- [ ] No `.cwf/scripts/` writes in this task → no `script-hashes.json` updates.

## Test Coverage (g-testing-exec)

### Step 11: Author `verify-cites.pl`, run it
- [ ] Write `/tmp/-home-matt-repo-coding-with-files-task-151/verify-cites.pl`. Implementation contract:
  - Read `docs/conventions/cross-doc-references.md`.
  - Extract every `path:line` and `path:line-range` substring with a regex.
  - For each: parse `M` (line) or `M-N` (range). Assert `-e $path`. Compute `$effective_lines` in pure Perl by opening the file and counting `\n` characters in the buffer, then adding 1 iff the buffer is non-empty and doesn't end with `\n`. Assert `1 ≤ M ≤ N ≤ $effective_lines`.
  - **No `wc -l` shell-out** — pure Perl. The earlier draft's backtick `\`wc -l < $path\`` is a string-interpolation surface forbidden by `feedback_perl_git_paths` and FR4(b).
  - List-form `open` only.
  - Exit non-zero on any failure.
  - Same shebang/PERL5OPT/`use utf8;`/core-modules-only discipline as `audit.pl`.
- [ ] Paste the source into `g-testing-exec.md` as a ` ```perl ` fence (kind=example by D1, so it doesn't pollute future audits).
- [ ] Run it. If non-zero exit, return to f- and fix citations.

### Step 12: AC1-AC8 systematic verification
- [ ] For each AC in b-requirements AC1-AC8, record evidence in `g-testing-exec.md`:
  - **AC1**: Run `comm -23 <(git ls-files -z '*.md' | tr '\0' '\n' | sort) <(grep '^|' audit-output | extract source-file column | sort -u)` — empty in both directions.
  - **AC2**: Count rows with `other` form ≤ 5% of total. Record the percentage.
  - **AC3**: Rules-table cardinality = number of occurring locality cells; no "either is fine" cells.
  - **AC4**: Every rule row in `cross-doc-references.md` has a `path:line` citation. `verify-cites.pl` exit code = 0.
  - **AC5**: Divergence count = `grep -c '^|.*matches-rule.*false' audit-output` (excluding N/A rows). BACKLOG entry presence matches the "iff count > 0" rule.
  - **AC6**: `grep -A 4 'cross-doc-references' CLAUDE.md` shows the four-line entry pattern.
  - **AC7**: Dogfooding section in `f-implementation-exec.md` is populated.
  - **AC8**: If ≤2 locality cells occur, style guide explicitly states "patterns already consistent".

### Step 13: g-testing-exec checkpoint commit
- [ ] `.cwf/scripts/command-helpers/cwf-checkpoint-commit 151 g "<why message>"`.

## Validation Criteria
See e-testing-plan.md.

## Scope Completion
This task's "Finished" state requires all of:
1. `docs/conventions/cross-doc-references.md` exists, has a rules table, passes `verify-cites.pl`, self-complies.
2. `CLAUDE.md` `## Conventions` has the new entry at the specified position.
3. `f-implementation-exec.md` has audit appendix (fenced), summary, rule-decisions, divergence report, dogfooding result.
4. `g-testing-exec.md` has `verify-cites.pl` source + run result + AC1-AC8 evidence.
5. BACKLOG entry exists iff divergence > 0.

Incomplete = not Finished. The FR5 migration entry is the only follow-up permitted; in-scope gaps must be closed in this task.

## Decomposition Check
- [ ] **Time**: 1-2 days. No trigger.
- [ ] **People**: Single-person. No trigger.
- [ ] **Complexity**: Linear sequence with explicit f/g phase split. No trigger.
- [ ] **Risk**: Hardening explicit (mkdir 0700, list-form git, fence-wrap pastes, carve-out ordering). No trigger.
- [ ] **Independence**: Sequential. No trigger.

**Decomposition verdict**: 0/5 — no subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
