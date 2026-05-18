# Consolidate Cross-Doc Reference Patterns - Design
**Task**: 151 (discovery)

## Task Reference
- **Task ID**: internal-151
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/151-consolidate-cross-doc-reference-patterns
- **Template Version**: 2.1

## Goal
Design the audit pipeline, the audit-row schema, and the style-guide document shape, so that f-implementation-exec is a mechanical fill-in rather than an open design exercise.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### D1. Detection strategy: two independent axes, not a single flat enum
- **Decision**: The FR2 closed enum was conceptually conflating two orthogonal axes. Replace with two independent axes detected by independent regex passes:
  - **`delimiter`** — the syntactic envelope around the reference: `bold` (`**...**`), `inline-backtick` (`` `...` ``), `markdown-link` (`[text](path)`), `html-comment`, `code-fence` (inside fenced block), `plain-prose` (no delimiter), `wiki-link` (`[[slug]]`).
  - **`target-shape`** — the shape of the path/URL being referenced: `path` (bare file path), `path:line`, `path:line-range`, `path#anchor`, `in-file-anchor` (`#anchor` only), `tilde-home` (`~/...`), `external-url` (`https?://`), `slug` (memory slug for `wiki-link`), `other`.
- **Rationale**: A single `form` enum cannot answer "use backticks for `path`" vs "use backticks for `path:line`" — those are independent design dimensions. Splitting halves the regex count (≈6 delimiter + ≈8 target-shape, run independently) and lets the rules table key on whichever axis discriminates per locality.
- **Trade-offs**: Two axes mean the audit emits more columns and the rules table needs explicit "this rule binds `delimiter` only" or "binds both" annotation. Acceptable — it surfaces the real question.
- **Detection order**: `code-fence` delimiter is a context pre-pass (see fence-syntax rules below). All other delimiters are mutually exclusive on a given match span — first-match-wins by source position. Target-shape is detected independently inside the matched delimiter span.
- **Fence syntax handling** (the pre-pass): Recognised fence forms are CommonMark fenced blocks: ` ``` ` (3+ backticks) and `~~~` (3+ tildes). The closer must match the opener's character and have at least the opener's run-length (so ` ``` ` inside a ` ```` ` block is content, not a closer). Indented (4-space) code blocks are NOT recognised as fences — references inside them are classified as `plain-prose`/whatever they look like; this is acceptable because indented blocks are vanishingly rare in this corpus and recognising them adds complexity for no signal. Unmatched fence at EOF: treat the rest of the file as fenced and emit a `parse-warning` row.
- **`kind` rule (inverted from prior version)**: A reference is `kind=instructional` iff it appears in (a) prose (no fence) OR (b) a fenced block with NO language tag OR with language tag `markdown`. Any other language tag (`bash`, `perl`, `python`, `json`, `text`, etc.) ⇒ `kind=example`. Rationale: only no-tag/markdown fences are part of the document's explanatory body; tagged fences are code samples whose path-shaped strings are illustrations of code, not directives.
- **What is excluded outright** (no row emitted): URL fragments inside markdown image syntax `![alt](url)` — out of scope for cross-doc references.

### D2. Audit-row schema
Each detected reference produces one row:

| Column          | Type    | Notes |
|-----------------|---------|-------|
| `source-file`   | string  | Path of file containing the reference, relative to repo root. |
| `source-line`   | int     | 1-indexed line number. |
| `delimiter`     | enum    | From D1 delimiter axis. |
| `target-shape`  | enum    | From D1 target-shape axis. |
| `locality`      | enum    | `intra-file` \| `intra-task` \| `intra-repo` \| `external`. Closed; no historic variant. |
| `target`        | string  | The path-or-URL substring as it appears in the source. Always backtick-fenced when rendered in the audit table (prompt-injection defence, see D5). |
| `kind`          | enum    | `instructional` \| `example` \| `historic` \| `parse-warning`. `historic` is set by source-file carve-out (D7); `parse-warning` for unmatched fences. |
| `matches-rule`  | bool \| `N/A` | Populated only after rules are decided. `N/A` for `kind ∈ {example, historic, parse-warning}` and `target-shape = external-url`. |

- **Locality resolution**: `intra-file` if target lacks a path component; `intra-task` if target's resolved path is inside the same `implementation-guide/NNN-*/` directory as `source-file`; `intra-repo` otherwise (within `git ls-files`); `external` for URLs and `tilde-home`.
- **`target-exists` is NOT a column**: Existence verification is a final-pass check applied only to the ≤20 examples actually cited by the style guide (see D5 "Citation verification"). Computing existence per-row adds I/O for data the rules step never consumes.
- **Format**: Single markdown table. To defuse the prompt-injection surface (every `target` cell is text scraped from a tracked `.md` file, including skill bodies with imperative LLM-shaped content), the **entire audit table is emitted inside a fenced code block** (` ```markdown ` ... ` ``` `) in `g-testing-exec.md`. Markdown table cells inside a fenced code block render as literal text, not as table syntax — but the layout remains human-readable and any imperative text in `target` cells is not loaded as instruction when `g-testing-exec.md` becomes LLM context downstream.
- **Sorting**: rows sorted by `(source-file, source-line)` under `LC_ALL=C`.

### D3. Rules table schema
The style guide's rules table:

| Column         | Notes |
|----------------|-------|
| `locality`     | One of the four locality enum values. |
| `binds`        | Which axis the rule constrains: `delimiter`, `target-shape`, or `both`. |
| `preferred`    | One value from the bound axis (or pair, if `binds = both`). |
| `rationale`    | One sentence. |
| `example`      | A `path:line` (or `path:line-range`) citation from the audit. |
| `rejected`     | Comma-separated list of observed alternatives, each followed by a one-line reason. |

### D4. Style guide document structure
Two shapes exist in `docs/conventions/`. The structural-reference shape (`commit-messages.md`, `design-alignment.md`) is appropriate for docs that catalogue an external standard's format. The rules-with-rationale shape (`perl.md`, `git-path-output.md`, plus `.cwf/docs/conventions/tmp-paths.md`, `session-hygiene.md`) is appropriate for an in-repo convention with a rules table and rationale.

This style guide is the latter. **Adopt the rules-with-rationale shape** verbatim:

```
# Cross-Doc Reference Conventions

<one-paragraph opening: what this doc governs and what it does not>

## Convention
<rules table from D3, immediately followed by any per-locality
clarifying paragraphs (e.g. the BACKLOG/CHANGELOG carve-out from D7)>

## Why
<rationale: the audit's headline findings, which patterns dominated,
which were inconsistent, why the chosen rules. Migration status —
divergence count and reference to the BACKLOG entry if filed —
appears as a final paragraph here, NOT as a separate section, to
match `git-path-output.md`'s "Pre-convention scripts" inline
treatment of legacy cases.>

## See also
<selective links — only related convention docs, 1-3 max, matching
the observed selective-linking pattern in the existing siblings.
Candidates: `docs/conventions/design-alignment.md` (the closest
neighbour — both govern in-repo authoring), `.cwf/docs/conventions/
session-hygiene.md` (mentions `path:line` idiom in passing).>
```

- **No `## Enforcement`**: no mechanical linter is in scope for this task. If one is later proposed, that BACKLOG entry adds the section.
- **No `## Migration`**: matches the existing siblings' convention (none have it; legacy/divergent cases go in `## Why` as inline paragraphs).
- **CLAUDE.md insertion point** (concrete, not "guess in f-"): The `## Conventions` block in `CLAUDE.md` lists entries alphabetically-ish but in practice grouped (commit-messages, design-alignment, perl, git-path-output, then session-hygiene, hash-updates, tmp-paths). The new entry slots between `git-path-output` and the `session-hygiene` block — it concerns authoring conventions, like the four above it. Format matches sibling entries verbatim: bolded name, one-line summary, `See \`docs/conventions/cross-doc-references.md\` for:` plus ≥2 bulleted items.

### D5. Audit script: location, language, lifecycle, hardening
- **Location**: `/tmp/-home-matt-repo-coding-with-files-task-151/audit.pl`.
- **First action of the f-implementation-exec harness** (before any write to that path): `mkdir -m 0700 -p /tmp/-home-matt-repo-coding-with-files-task-151/`. This is restated here, not just cited, because `.cwf/docs/conventions/tmp-paths.md` names the guard "mandatory" and the design's job is to make hardening unambiguous.
- **Language**: Perl, core modules only (`feedback_perl_core_only`). Shebang `#!/usr/bin/env perl`; `PERL5OPT=-CDSLA` from caller env; `use utf8;`.
- **Git interface**:
  - Path listing: `system("git", "ls-files", "-z", "*.md")` captured into a buffer via list-form open: `open(my $fh, "-|", "git", "ls-files", "-z", "*.md")`; parsed with `split /\0/`. NEVER `qx{git ls-files -z *.md}` or any interpolated form.
  - HEAD recording (informational only — see "No pre-flight check" below): `open(my $h, "-|", "git", "rev-parse", "HEAD")`. List-form.
  - No `--baseline-commit` CLI argument. The script has no CLI options.
- **No pre-flight HEAD check**: The prior design had the script abort/warn if HEAD ≠ recorded baseline. Two reviewers flagged this as misfire-prone (checkpoint commits move HEAD constantly during the task). Replace with: the script writes the current `git rev-parse HEAD` as a header comment in its stdout output: `<!-- audit baseline: <40-char-SHA> -->`. The operator visually confirms this matches `a-task-plan.md:9` before committing the audit appendix. Determinism (NFR5) is a property of the script's inputs and logic; runtime self-policing is theatre.
- **Output**: Single markdown table on stdout, preceded by the HEAD comment. The wrapping fenced code block (D2) is added by the operator when pasting into `g-testing-exec.md`, NOT by the script — keeping the script's output as raw table makes diffing successive runs easier.
- **Exit codes**: 0 on success; 2 on git command failure (no `--baseline-commit`, so no SHA-validation surface). Single-failure-mode semantics: any non-zero exit means the output is incomplete and must not be consumed.
- **Source preservation**: The full `audit.pl` source is pasted into `f-implementation-exec.md` as a fenced code block (` ```perl ` — so per D1 the script's own path-shaped strings classify as `kind=example` and don't pollute later re-audits).
- **Not committed under `.cwf/scripts/`**: One-off audit. If a periodic re-audit cadence emerges, file a BACKLOG entry to promote it.
- **Citation verification (replaces `target-exists` column)**: After the style guide is drafted, run a final-pass check: for each `path:line` or `path:line-range` citation in `docs/conventions/cross-doc-references.md`, verify the path resolves (`-e $path`) and the line range is in bounds (line ≤ `wc -l < $path`). Failure halts the commit. This is a script in the same `/tmp/` scratch — call it `verify-cites.pl`.

### D6. Locality enum: dropped axes confirmed (evidence sample, 3 rows)
The b-requirements decision to drop the `audience` axis is confirmed against three sample references representative of the corpus:

| Sample ref | locality | "audience" if forced | Preferred form |
|------------|----------|----------------------|----------------|
| `CLAUDE.md:75` "See `docs/conventions/perl.md`" | intra-repo | dual | `bold` or `inline-backtick` × `path` |
| `.claude/skills/cwf-task-plan/SKILL.md` "Read `.cwf/docs/workflow/workflow-steps.md#planning`" | intra-repo | LLM-facing | `inline-backtick` × `path#anchor` |
| `BACKLOG.md:10` "Task 150 j-retrospective.md §..." | intra-repo (kind=historic) | human-facing | `plain-prose` × `path` (carved out per D7) |

The audience axis collapses 2 of 3 to `dual`, leaving one cell with a real decision. Locality plus the D7 carve-out discriminates the rule set; audience adds noise. (Full evidence — every row in the audit — lives in `g-testing-exec.md`.)

### D7. BACKLOG/CHANGELOG carve-out via `kind=historic`, not a fifth locality
Earlier draft introduced an `intra-task-historic` locality that was inconsistent with the 4-valued enum. Replace with a source-file rule:
- **Carve-out**: if `source-file ∈ {BACKLOG.md, CHANGELOG.md}`, set `kind = historic` regardless of fence context.
- **Locality**: classified normally per D2 rules (almost always `intra-repo`).
- **`matches-rule`**: `N/A` for all `kind=historic` rows.
- **Style guide treatment**: The `## Convention` rules table has a clarifying paragraph immediately below it: "Entries in `BACKLOG.md` and `CHANGELOG.md` follow the `backlog-manager` format and are exempt from these rules." Single sentence, no separate section.

This keeps the locality enum closed (D2), keeps the carve-out auditable in the data (the `kind` column), and stays close to the existing `git-path-output.md:52` precedent for "convention has a legacy carve-out".

## System Design

### Component Overview
- **Audit script** (`audit.pl`, `/tmp/...task-151/`): Reads `git ls-files -z '*.md'`, scans each file line-by-line with the delimiter pre-pass + target-shape regex pipeline, emits markdown table on stdout with HEAD-comment header.
- **Verification script** (`verify-cites.pl`, same `/tmp/`): Reads style-guide citations and validates each `path:line` resolves.
- **Operator** (manual, in f-implementation-exec): Wraps audit output in ` ```markdown ` fenced block, pastes into `g-testing-exec.md`. Reads audit, decides rules per locality cell, writes style guide. Adds `## Conventions` entry to `CLAUDE.md`. Runs `verify-cites.pl`.
- **Migration filer** (conditional, in g-testing-exec): If divergence > 0, runs `backlog-manager add --identified-in='Task 151 g-testing-exec.md' ...`.
- **External-evidence dogfooder** (in g-testing-exec, per AC7): Runs audit's classification logic against `docs/conventions/commit-messages.md` only, lists any mismatches in the BACKLOG entry.

### Data Flow
1. `mkdir -m 0700 -p /tmp/-home-matt-repo-coding-with-files-task-151/`.
2. Operator pastes `audit.pl` into the scratch dir, `chmod +x`, runs it.
3. `audit.pl` records HEAD as `<!-- audit baseline: <SHA> -->`, runs `git ls-files -z '*.md'`.
4. Per-file scan: fence pre-pass → delimiter detect → target-shape detect → locality resolve → emit row.
5. Sort under `LC_ALL=C` → deterministic markdown table on stdout.
6. Operator wraps output in ` ```markdown ` fence and pastes into `g-testing-exec.md` audit appendix.
7. Operator reads table → makes rule decisions per occurring locality cell → writes `docs/conventions/cross-doc-references.md`.
8. Operator adds `## Conventions` entry to `CLAUDE.md`.
9. Operator runs `verify-cites.pl` against the new style guide; fixes any broken `path:line` citations.
10. Operator computes divergence count from audit table; files BACKLOG entry iff count > 0.
11. Operator dogfoods against `commit-messages.md`; adds findings to BACKLOG entry.

## Interface Design

### Audit script CLI
```
audit.pl
```
No options. Output to stdout. Exit 0 on success, 2 on git failure.

### Audit table row schema
See D2. Public interface between `audit.pl` and the operator.

### Style guide rules table
See D3. Public interface between audit findings and convention doc.

### CLAUDE.md `## Conventions` entry template
```markdown
**Cross-Doc References**: Standard for how to reference other documents from CWF docs, templates, skills, and wf step files. See `docs/conventions/cross-doc-references.md` for:
- Rules table by locality (intra-file, intra-task, intra-repo, external)
- Rejected alternatives with rationale
- BACKLOG/CHANGELOG carve-out
```
Insertion point: between the `**Git Path Handling**` block and the `**Tmp Paths**` block in `CLAUDE.md`.

## Constraints
- No new helper script under `.cwf/scripts/`.
- No template/skill-body writes.
- Style-guide writes go to `docs/conventions/cross-doc-references.md` and `CLAUDE.md` only.
- Determinism (NFR5): `LC_ALL=C`, NUL-separated path reads, no timestamps in output, no runtime SHA checks.
- All git invocations: list-form `open(... "-|", "git", ...)`. No `qx{}` with interpolation.

## Decomposition Check
- [ ] **Time**: Design adds ~half a day. Total still 1-2 days. No trigger.
- [ ] **People**: Single-person. No trigger.
- [ ] **Complexity**: D1-D7 are coupled — one design. No trigger.
- [ ] **Risk**: Managed by determinism (NFR5) and scope hard-stop. No trigger.
- [ ] **Independence**: Not separable. No trigger.

**Decomposition verdict**: 0/5 — no subtasks.

## Validation
- [x] **Two-axis schema (D1)** covers the question b-requirements FR3 actually asks ("which form for which locality") — verified by walking the FR3 rules-table columns and confirming each is now expressible.
- [x] **Audit row schema (D2)** has columns sufficient for every acceptance criterion AC1-AC8 — verified by mapping each AC to the source column(s): AC1↔scanned-files manifest, AC2↔`target-shape`+`delimiter` populated, AC3↔rules table, AC4↔`source-file:source-line` citations, AC5↔`matches-rule=false` row count, AC6↔CLAUDE.md grep (external), AC7↔dogfood-against-commit-messages.md (external), AC8↔rules-table cardinality.
- [x] **Style guide shape (D4)** is structurally compatible with `perl.md` and `git-path-output.md` — verified by reading both during c-design; the chosen shape uses the same heading sequence (`Convention` / `Why` / `See also`) and the same selective-link `## See also` discipline.
- [x] **Audit-script location (D5)** complies with `.cwf/docs/conventions/tmp-paths.md` (project-namespaced form `/tmp/<dashified-abs-repo-path>-task-<num>/`) and restates the mandatory `mkdir -m 0700` first-use guard.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
