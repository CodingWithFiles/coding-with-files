# Cross-Doc Reference Conventions

This document governs how to reference other documents (and parts of documents) from CWF source files — skills, agents, helpers, templates, wf-step files, and convention docs. It does not govern external-standard quoting (commit message format, ref naming) which has its own conventions, and it does not govern references inside `BACKLOG.md` or `CHANGELOG.md` (those follow `backlog-manager` format and are exempt).

## Convention

| Locality | Binds | Preferred form | Rationale | Example |
|---|---|---|---|---|
| intra-file (anchor in the same doc) | delimiter | `markdown-link × in-file-anchor` — `[link text](#anchor)` | Renders as a clickable link in GitHub/IDE markdown previews; CommonMark idiom. | `.cwf/docs/dead-code-audit.md:8` |
| intra-task (sibling wf-step file) | delimiter | `inline-backtick × path` — `` `a-task-plan.md` `` | Distinguishes file names from English prose; matches template-pool style where wf-step bodies reference each other. | `implementation-guide/102-feature-add-checkpoint-commit-helper-script-cwf-checkpoin/c-design-plan.md:61` |
| intra-repo (path, citation, or anchor) | both | `inline-backtick × {path, path:line, path:line-range, path#anchor}` — `` `docs/conventions/perl.md:7` `` | Scannable; distinguishes path identifiers from prose; gives precise locator for line-level evidence. | `.cwf/docs/skills/security-review.md:94` |
| external (URL or `~/...`) | both | URLs → `markdown-link × external-url` — `[label](https://...)`; tilde-home paths → `inline-backtick × tilde-home` — `` `~/.claude/...` `` | Titled URLs are accessible and clickable; tilde-home paths read as path identifiers, not URLs. | `docs/conventions/commit-messages.md:138` (URL); `.claude/skills/cwf-config/SKILL.md:34` (tilde-home) |

Entries in `BACKLOG.md` and `CHANGELOG.md` follow the `backlog-manager` format and are exempt from these rules.

### Rejected alternatives

- **`plain-prose × path` for intra-repo references** (5,616 observed). Rejected: ambiguous with English prose ("the `pass/fail` policy" vs "the `pass/fail.md` file"); breaks "grep for references-to-X" workflows. Acceptable narrowly when the path appears at the head of a heading-emphasis line (e.g. `**See \`path\`**`) and the surrounding bold conveys document-organisation emphasis, not reference style.
- **`plain-prose × path` for intra-task references** (2,128 observed). Same reason. Even within a task directory, sibling wf-step file names should be backticked to make the file-vs-prose distinction unambiguous when files are read in isolation.
- **`bold × path`** outside the head-of-skill-file `**Path**: …` idiom. The bold emphasises the *role* of the path slot, not the path itself; the path within should still be backticked: `**Path**: \`some/path\``. The 832 `bold × path#anchor` and 517 `bold × path` rows are predominantly skill/agent file headers (`**Path**: projectSettings:cwf-task-plan`) — that idiom is preserved.
- **`inline-backtick × external-url`** for narrative references (14 observed). Backticks signal "code or path identifier"; URLs read better as titled markdown links. Backticked URLs are acceptable only for *example/template* URLs where the URL is illustrative (e.g. `` `https://github.com/org/repo/issues/123` ``), not a destination.
- **`plain-prose × in-file-anchor`** (134 observed) — visually indistinguishable from heading text in plain prose. Prefer markdown-link form.

### Citation precision

When citing a specific line or range, use `` `path:line` `` or `` `path:line-range` ``. Both forms must appear inside inline-backticks. Line numbers refer to the file at the most-recent commit on the current branch; line drift after subsequent edits is expected and is the citation author's responsibility to refresh.

## Why

The audit at task 151 enumerated 21,161 cross-doc references across 1,172 tracked `.md` files. The dominant patterns at the intra-repo level were:

- `inline-backtick × path` (8,400 observations) — the established idiom in skill bodies, agent definitions, and convention docs.
- `plain-prose × path` (5,616 observations) — concentrated in wf-step files and skill prose; reads as English but loses scannability.

For citations, the picture is clearer: `inline-backtick × path:line` (155 observations) dominates over `plain-prose × path:line` (23). For external URLs, `markdown-link × external-url` (110 observations) dominates over bare URL forms (33 combined). For in-file anchors, the data is more mixed (plain-prose 134, markdown-link 34) — markdown-link is chosen here despite being a minority because it produces a clickable, navigable link in any markdown-rendering surface; the migration cost (134 cells) is bounded.

Migration status: 7,884 references diverge from the rules in this guide. See the migration entry in `BACKLOG.md` for the per-file breakdown and scope. The migration is filed as a separate task because rewriting cross-doc references inside skill bodies and template files risks regressing LLM-facing patterns that are working well, and warrants a dedicated review.

## See also

- `docs/conventions/design-alignment.md` — keep skill/helper/template/rule names consistent; this doc keeps cross-references to those names consistent.
- `.cwf/docs/conventions/session-hygiene.md` — uses the `path:line` citation idiom; preserved as-is by this convention.
