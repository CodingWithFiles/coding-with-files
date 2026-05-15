# Design Alignment

This document describes the conventions that keep CWF skill, helper-script,
template, and rule names consistent across the codebase, and the audit
procedure to follow when renaming or removing any of them.

Scope: CWF *development* (this repository). Conventions that ship with
installed CWF copies live under `.cwf/docs/conventions/`.

## Convention

### 1. Single source of truth

Every named CWF artefact has exactly one canonical location. All other
mentions are *references*.

| Artefact      | Canonical location                            |
|---------------|-----------------------------------------------|
| Skill         | `.claude/skills/<name>/SKILL.md`              |
| Helper script | `.cwf/scripts/command-helpers/<name>`         |
| Top-level CLI | `.cwf/scripts/<name>` (e.g. `cwf-manage`)     |
| Template      | `.cwf/templates/pool/<file>.template`         |
| Rule          | `.claude/rules/<name>.md`                     |
| Workflow doc  | `.cwf/docs/workflow/<name>.md`                |

A rename means moving the canonical file; everything else is a reference
update (Step 3 below).

### 2. Naming patterns

- **`cwf-` prefix** on every CWF-owned skill, helper script, top-level
  CLI, and rule. The prefix is what distinguishes CWF artefacts from
  user or third-party ones in the same directory.
- **kebab-case** throughout. No camelCase, no underscores.
- **Phase-letter prefix** (`a-` … `j-`) on workflow files and on the
  workflow-step skills that drive them. The letter encodes the phase
  position; renaming a phase requires updating the letter table in
  `.claude/rules/cwf-workflow-files.md`.
- **Version suffix `-v<major>.<minor>`** on helper scripts only, and
  only for genuine version-dispatch (e.g. `status-aggregator-v2.0`
  vs `-v2.1` for v2.0/v2.1 template formats). **Never on skills.**
  Skill versioning is tracked by the repo's git tag, not the filename.
- **`<name>.d/` subdirectory pattern** for helper-script subcommand
  dispatch (e.g. `context-manager` + `context-manager.d/location`).
  The dispatcher and its subcommand files share a single canonical
  base name.
- **No legacy aliases**. CWF eats its own dog food and is the only
  consumer of these names; the post-rename name is the only name
  (see *Deprecation* below for the one exception).

### 3. Rename audit checklist

Before committing a rename of any artefact in §1:

1. **Grep the repo** for the old name, excluding task records:

   ```bash
   git ls-files | grep -v ^implementation-guide/ \
     | xargs grep -l '<old-name>'
   ```

   Walk every hit and update.

2. **Phase skills**: if the renamed skill is one of the ten phase-letter
   skills, update the letter → skill table in
   `.claude/rules/cwf-workflow-files.md`.

3. **Templates**: if a template under `.cwf/templates/pool/` is
   renamed, the per-task-type symlinks (`bugfix/`, `feature/`, …)
   must be re-created to point at the new pool file. Verify with:

   ```bash
   .cwf/scripts/cwf-manage validate
   ```

   Validate exits non-zero on broken symlinks and on stale
   `script-hashes.json` entries; both are common rename casualties.

4. **`cwf-manage` and its subcommands**: see *Deprecation* below;
   these are not in-repo references only.

5. **Output artefacts**: re-run a representative skill (e.g.
   `/cwf-status`) and grep its output for the old name. Source-level
   greps miss strings emitted from templates or computed at runtime;
   this caught regressions in Tasks 59 and 90.

### 4. Deprecation

**In-repo artefacts (skills, helpers, templates, rules)**: no
deprecation period. CWF develops itself; there are no external consumers
of these names. Rename + update all references + ship in one task.

**`.cwf/scripts/cwf-manage` and its subcommands**: weak external
contract. Installed CWF copies upgrade independently of upstream
(see `INSTALL.md` and `.cwf/docs/workflow/versioning-standard.md`),
so an installed project may invoke `cwf-manage` subcommands that the
upstream renamed yesterday.

- Renaming `cwf-manage` itself is a breaking change and requires a
  major version bump.
- Renaming a subcommand: keep the old subcommand name as an alias
  for one minor version, with a one-line stderr deprecation warning
  pointing at the new name. Remove the alias in the next minor.

**Mid-task scope expansion**: if a rename turns out to touch more
surfaces than planned, escalate to the user with an updated
estimate. Do not silently expand scope; do not ship a partial
rename.

### 5. Cross-document references

- **Progressive disclosure** — skills reference docs in
  `.cwf/docs/`; docs do not duplicate skill content. A skill that
  needs deep procedural detail links into a doc; the doc owns
  the prose.
- **CLAUDE.md§Conventions** is the discovery surface for top-level
  conventions. When adding a new convention doc, add a bullet
  matching the existing `**Commit Messages**` style:
  `**<Title>**: <one-line summary>. See \`docs/conventions/<file>.md\` for: ...`
- **Glossary**: if the convention introduces a new term, add it to
  `.cwf/docs/glossary.md` so other docs can refer to it without
  redefining it.

## Why

Without these conventions, every rename is a search-and-replace
guessing game. Three concrete failures motivate the doc:

- **Task 35**: command references in `.claude/commands/` lagged a
  rename for two task cycles before being noticed.
- **Task 59 → Task 90**: a rebrand passed source-level grep but
  left stale strings in computed output, which only surfaced when a
  user generated a sample artefact a month later.
- **Task 81**: a new file (`c-design-plan.md`) was missed in the
  commit because `git status` was not checked before staging.

The audit checklist (§3) closes each of these.

The single-source-of-truth rule (§1) makes "where is this defined?"
a one-step lookup — important because CWF is read 10× more than
written.

The deprecation policy (§4) is asymmetric on purpose: in-repo
renames are cheap (one task, one PR); `cwf-manage` renames are
expensive (every installed project breaks until they pull). The
asymmetry should not be hidden.

## Existing usage

Phase-skill ↔ phase-letter table that must stay in sync on rename:
`.claude/rules/cwf-workflow-files.md`.

Helper scripts using version-suffix dispatch:
- `.cwf/scripts/command-helpers/status-aggregator-v2.0` / `-v2.1`
- `.cwf/scripts/command-helpers/template-copier-v2.1`
- `.cwf/scripts/command-helpers/context-inheritance-v2.0` / `-v2.1`

Helper scripts using the `<name>.d/` subcommand pattern:
- `context-manager` + `context-manager.d/{location,hierarchy,inheritance,version}`
- `task-workflow` + `task-workflow.d/create`
- `workflow-manager` + `workflow-manager.d/control`

Conventions doc style this file follows:
- `docs/conventions/perl.md`
- `docs/conventions/git-path-output.md`
- `docs/conventions/commit-messages.md`

Validation tool used by §3 step 3:
- `.cwf/scripts/cwf-manage validate`
