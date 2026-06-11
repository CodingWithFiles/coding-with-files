# cwf-backlog-manager — reference

The `cwf-backlog-manager` skill shows or manipulates the project's BACKLOG
and CHANGELOG (active items, priorities, retirement to CHANGELOG). Invoke
it via the Skill tool when the user asks about backlog/changelog state or
asks for an entry to be added, modified, retired, or deleted.

## Example user phrasings

- "what's in the backlog?"
- "show me the high-priority items"
- "add a backlog item for X"
- "retire that backlog entry — it shipped in task N"
- "delete the typo'd backlog entry titled Y"

## Not this skill

- Editing `BACKLOG.md` / `CHANGELOG.md` directly with Edit/Write — the
  helper enforces the heading-tree contract; direct edits skip validation.

## Structural contract (`BACKLOG-000`)

The backlog manager tracks entries as `## Task: <title>` / `## Bug: <title>`
blocks. Everything *before the first such entry* is the preamble; for a file
with no entries at all, the whole file is preamble. The preamble may contain
only blank lines, prose, and at most one leading `# ` title — it must **not**
carry other headings (`##`–`######`) or list items, because the manager does
not parse or manage that structure and `add`/`modify`/`delete`/`retire` would
silently ignore it.

`validate` reports any such content as `BACKLOG-000` (error), and the four
mutation subcommands refuse to run on a file that trips it — so a foreign-format
`BACKLOG.md` (e.g. sprint headings + flat task lists) is rejected up front
rather than mutated into an inconsistent state. An empty file, or a
title-plus-prose intro with no entries yet, is conformant and passes.

Entry **bodies** may freely contain `##` headings and lists — only the preamble
is checked. Foreign content placed *after* a genuine entry, or a preamble of
pure prose with no headings/lists, is not detected (accepted boundaries).
