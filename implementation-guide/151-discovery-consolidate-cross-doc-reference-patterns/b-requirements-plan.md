# Consolidate Cross-Doc Reference Patterns - Requirements
**Task**: 151 (discovery)

## Task Reference
- **Task ID**: internal-151
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/151-consolidate-cross-doc-reference-patterns
- **Template Version**: 2.1

## Goal
Define the audit scope, the deliverable shape, and the verification rules for the cross-doc reference style guide.

## Functional Requirements

### Core Features
- **FR1 — Audit coverage**: The audit scans every path returned by `git ls-files -z '*.md'` at the task's baseline commit. Path reading uses NUL-separated parsing (per `docs/conventions/git-path-output.md`); sort/uniq passes use `LC_ALL=C`. **Acceptance**: The audit emits a "scanned files" manifest; the set difference against `git ls-files -z '*.md'` is empty in both directions.
- **FR2 — Pattern taxonomy**: Each observed reference is classified by (a) **syntactic form** drawn from a closed enum and (b) **target locality** — intra-file, intra-task, intra-repo, external. The audience axis is deliberately omitted: the audit will commit it only if the c-design phase finds it discriminates the rule set.
  - **Closed form enum**: `bold-text-path`, `inline-backtick-path`, `code-fence-path` (embedded in fenced block), `markdown-link`, `html-comment-ref`, `plain-path-prose`, `path:line`, `path:line-range`, `path#anchor`, `cross-file-anchor` (`path.md#anchor` distinct from in-file `#anchor`), `wiki-link` (`[[slug]]`), `tilde-home-path` (`~/...`), `external-url`, `other`.
  - **Acceptance**: Every row in the audit has a form value from this enum; `other` rows ≤ 5% of total; if `other` exceeds 5%, the enum is extended (with examples in the audit's "Enum decisions" section) and the audit re-classified before commit.
- **FR3 — Rule set**: The style guide states, for each occurring locality cell, exactly one preferred form, with rationale. Where two forms are both observed and both defensible, the guide picks one and documents the rejected alternative with the reason. **Acceptance**: Rules table has one row per occurring locality cell; no row says "either is fine"; rejected alternatives are listed in a "Rejected forms" sub-section per rule.
- **FR4 — Worked examples**: Each rule cites at least one concrete `path:line` (or `path:line-range`) example from the audit. Examples drawn from `.claude/skills/` skill bodies are wrapped in fenced code blocks rather than inline prose, so that imperative or LLM-instruction-shaped text inside the quoted reference is not re-interpreted when the style guide is loaded as LLM context. **Acceptance**: Every rule row links to ≥1 audit citation; `grep -E '^\| ' docs/conventions/cross-doc-references.md` shows no rule row without a citation.
- **FR5 — Divergence reporting**: The audit reports the number of references that diverge from the chosen standard, broken down by file, as a count of rows in the audit table where the `matches-rule` column is `false`. If the count is > 0, a follow-up BACKLOG entry is filed via `backlog-manager add` with `--identified-in='Task 151 g-testing-exec.md'` (matching the established format from BACKLOG.md:10, 19, 28). **Acceptance**: Divergence count = count of `matches-rule = false` rows in the audit table (mechanically reproducible); BACKLOG entry exists iff count > 0.
- **FR6 — Index integration**: A `## Conventions` entry is added to `CLAUDE.md` matching the established pattern of the existing entries (commit-messages, design-alignment, perl, git-path-output): bolded name, one-line summary sentence, `See \`docs/conventions/cross-doc-references.md\` for:` followed by a bulleted "for" list of what the doc covers. **Acceptance**: `grep -A 4 'cross-doc-references' CLAUDE.md` shows the bolded-name + summary + `See ... for:` + ≥2 bulleted items structure.
- **FR7 — Low-divergence outcome branch**: If the audit reveals existing patterns are already convergent enough that the rules table has only 1-2 occurring cells, the style guide may be a short page that states "patterns are already consistent" with the inventory as evidence. This is a successful task outcome, not a failure. **Acceptance**: A 1-2 cell outcome is documented as such in the style guide, NOT padded with speculative rules for cells that don't occur.

### User Stories
- **As a** CWF maintainer writing a new skill body or template **I want** a single rule lookup for "how do I link from here to there" **so that** I don't recreate one of the existing inconsistent patterns by accident.
- **As a** reviewer auditing a PR that adds documentation **I want** a citable convention file **so that** "this reference style is wrong" is a referenceable comment, not a stylistic opinion.

## Non-Functional Requirements

### Performance (NFR1)
Not applicable. Documentation task.

### Usability (NFR2)
- Each rule is expressible as a one-line "use X when Y" statement; rationale lives below the rule, not inline.
- The rules table is the load-bearing artefact; supporting prose is supplementary.

### Maintainability (NFR3)
- **Audit raw output** (the tabulated reference inventory) lives in this task's wf step files — specifically as appendix sections in `f-implementation-exec.md` and `g-testing-exec.md`. It is not committed under `docs/conventions/`.
- **Style guide** alone is committed under `docs/conventions/cross-doc-references.md`. The style guide cites the audit inventory by `path:line` references to the wf step files.
- **Audit script** (if written): a one-off Perl/shell helper lives in the task-scoped scratch directory `/tmp/-home-matt-repo-coding-with-files-task-151/` per `.cwf/docs/conventions/tmp-paths.md`. It is not committed unless a periodic re-audit cadence is established in c-design. Source is preserved by being pasted into `f-implementation-exec.md` as a fenced code block.

### Security (NFR4)
- No new attack surface. Documentation-only.
- Audit reads only paths within `git ls-files`; nothing outside the tracked tree (`.git/`, untracked files, parent directories) is read or quoted in committed output.
- LLM-instruction-shaped content quoted from skill bodies is fenced (per FR4) so it cannot be re-interpreted as instructions when the style guide is loaded as context.

### Reliability (NFR5)
- Audit is deterministic under `LC_ALL=C` with stable input ordering: given the same baseline commit, re-running produces byte-identical output (excluding timestamps, which are forbidden from the committed output).
- Style guide contains no path that does not currently resolve in the repo.

## Constraints
- **Scope hard-stop**: This task does NOT rewrite existing references that diverge from the standard. Migration is a separate BACKLOG entry (FR5).
- **No template / skill body churn**: Templates in `.cwf/templates/pool/` and skill bodies in `.claude/skills/` are LLM-facing and load-bearing. Do not alter them in this task; defer to the migration backlog entry.
- **Dev-vs-shipped boundary** (deliberate choice, not oversight): The style guide lives at `docs/conventions/cross-doc-references.md` (CWF-dev internal tree), not under `.cwf/docs/conventions/` (shipped tree). Rationale: this convention governs how CWF maintainers write CWF source documentation; install-consumers see the *output* (templates, skills) and their cross-references are governed by template content, not by a guide they read. If the audit reveals that install-facing docs need their own (shipped) counterpart, that is a separate task — filed as a finding in g-testing-exec.md, not folded into this task.
- **Files touched**: `docs/conventions/cross-doc-references.md` (new), `CLAUDE.md` (one `## Conventions` entry), `BACKLOG.md` (one entry if divergence > 0), and `implementation-guide/151-*/` only.

## Decomposition Check
- [ ] **Time**: 1-2 days. No trigger.
- [ ] **People**: Single-person work. No trigger.
- [ ] **Complexity**: Audit → categorise → write. Sequential. No trigger.
- [ ] **Risk**: Scope-creep handled by hard-stop. No trigger.
- [ ] **Independence**: Style guide depends on audit. Not independent. No trigger.

**Decomposition verdict**: 0/5 — no subtasks.

## Acceptance Criteria
- [ ] **AC1**: `git ls-files -z '*.md'` ⇔ audit's "scanned files" manifest. Empty set difference in both directions (FR1).
- [ ] **AC2**: Audit has no rows with `unknown` cells; `other`-bucket rows ≤ 5% of total (FR2).
- [ ] **AC3**: Rules table has one row per occurring locality cell; rejected alternatives documented per rule (FR3).
- [ ] **AC4**: Every rule row in the style guide cites ≥1 `path:line` (or `path:line-range`) example from the audit; skill-body quotes are fenced (FR4).
- [ ] **AC5**: Divergence count mechanically reproducible from audit table (`matches-rule = false` row count); BACKLOG entry exists iff count > 0; entry uses `--identified-in='Task 151 g-testing-exec.md'` format (FR5).
- [ ] **AC6**: `CLAUDE.md` `## Conventions` entry matches established pattern: bolded name + one-line summary + `See \`docs/conventions/cross-doc-references.md\` for:` + ≥2 bulleted items (FR6).
- [ ] **AC7**: Style guide self-complies AND at least one existing committed convention doc (`docs/conventions/commit-messages.md`) has been mechanically checked against the new rules. Mismatches in `commit-messages.md` are listed in the BACKLOG migration entry under FR5 (external-evidence dogfooding).
- [ ] **AC8** (low-divergence branch): If the rules table has ≤2 cells, the style guide explicitly says "patterns already consistent" rather than inventing speculative cells (FR7).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
