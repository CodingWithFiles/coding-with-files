---
name: cwf-backlog-manager
description: Add, modify, list, validate, retire, or delete BACKLOG.md / CHANGELOG.md entries via the heading-tree helper.
user-invocable: true
allowed-tools:
  - Bash
---

## Scope & Boundaries

**This step**: Use `.cwf/scripts/command-helpers/backlog-manager` to read or mutate `BACKLOG.md` / `CHANGELOG.md` from the repo root.
**Not this step**: Editing `BACKLOG.md` or `CHANGELOG.md` directly with `Edit` / `Write` (the helper enforces the heading-tree contract; direct edits skip validation and risk corrupting the format).

## Context

**Helper path**: `.cwf/scripts/command-helpers/backlog-manager` (relative to git root).

**Mandatory pre-step**: Resolve the git root with `git rev-parse --show-toplevel` and invoke from there. Example:
```bash
cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager <subcommand> [...]
```

This guards against working-directory pivots: an attacker who can change `cwd` to e.g. `/tmp` and stages `/tmp/.cwf/scripts/command-helpers/backlog-manager` would otherwise win the path lookup. Anchoring at `git rev-parse --show-toplevel` makes that attack impossible.

## Subcommands

Each invocation must use **list-form arguments** (separate Bash array elements), never an interpolated single-string command. Argument values containing shell metacharacters — `$`, backticks, `(`, `)`, `;`, `&` — will be expanded if interpolated. Treat user input as opaque strings and pass them as separate elements.

### `validate [--all] [--strict]`
Check the format of `BACKLOG.md` and `CHANGELOG.md`. Default: print first error and exit 1. `--all` prints every error. `--strict` escalates warnings to errors. Warnings always print.

```bash
cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager validate --all
```

### `list [--all-items]`
Show active BACKLOG entries grouped by priority. Default: top 20 (no priority band split). `--all-items` shows everything.

```bash
cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager list
```

### `add --title=TITLE --task-type=TYPE --priority=PRI (--body=TEXT | --body-file=PATH) [--status=TEXT] [--identified-in=TEXT]`
Append a new active entry to `BACKLOG.md`. `--task-type` ∈ feature|bugfix|hotfix|chore|discovery; `--priority` ∈ Very High|High|Medium|Low|Very Low.

Worked example with shell-metacharacter title (note the **list form**: each argument is separate, the title is *not* interpolated into a string):
```bash
cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager add \
    --title='Test $(date)' \
    --task-type=chore \
    --priority=Low \
    --body='Verify CLI passes argument literally'
```
The resulting BACKLOG entry's title will be the literal string `Test $(date)` — the `$(date)` is preserved verbatim because the title is a single Bash word (single-quoted), not a shell expression.

### `modify (--id=SLUG | --exact-title=TITLE) [--priority=PRI]`
Edit an existing entry. v1 supports `--priority` only. `--id` resolves to the slug of the entry's title; `--exact-title` matches exactly.

```bash
cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager modify \
    --id=add-delete-task-skill --priority=High
```

### `delete (--id=SLUG | --exact-title=TITLE) --confirm`
Remove an entry outright. `--confirm` is required (use `retire` for completed work; `delete` is for typo cleanup).

```bash
cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager delete \
    --exact-title='Bogus entry' --confirm
```

### `normalise [--dry-run]`
Convert legacy Task-131 format (`**Field**:` paragraph metadata + `^---$` separators) to canonical heading-tree form. Idempotent — a re-run on canonical files writes nothing. Run this once after `cwf-manage update` if your repo predates the heading-tree refactor; the helper will refuse to validate `**Field**:`-style entries until you have. AC5a-d gates run before any write (cardinality, identity, required-key presence, ≥90% per-entry byte budget).

```bash
cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager normalise --dry-run
cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager normalise
```

### `retire (--id=SLUG | --exact-title=TITLE) --task=N [--note=TEXT]`
Move a BACKLOG entry to CHANGELOG. The entry is appended as a `#### <title>` block under the implementing task's `### Retired Backlog Items` subsection (the subsection is created if absent). Two-file atomic write; safe to re-run on crash.

```bash
cd "$(git rev-parse --show-toplevel)" && .cwf/scripts/command-helpers/backlog-manager retire \
    --id=fix-foo --task=132 --note='Implementation slightly altered scope'
```

## Notes

- All subcommands (read and write) are valid for both LLM auto-invocation and explicit user invocation. There is no skill-side confirmation layer.
- Use `--help` on any subcommand for the canonical usage string from the helper.
- Exit codes: 0 success; 1 validation/argument error; 2 path violation; 3 internal error.

## Success Criteria
- [ ] Subcommand invoked from git-root via `cd "$(git rev-parse --show-toplevel)"`
- [ ] Arguments passed as separate Bash array elements (list form), not interpolated string
- [ ] Helper exit code observed; user informed of failure if non-zero
