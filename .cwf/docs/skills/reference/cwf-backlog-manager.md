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
