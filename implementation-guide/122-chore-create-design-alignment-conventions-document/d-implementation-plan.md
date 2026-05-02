# Create Design-Alignment Conventions Document - Implementation Plan
**Task**: 122 (chore)

## Task Reference
- **Task ID**: internal-122
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/122-create-design-alignment-conventions-document
- **Template Version**: 2.1

## Goal
Add `docs/conventions/design-alignment.md` and wire it into CLAUDE.md, then close out the BACKLOG entry.

## Workflow
Survey actual usage → draft → plan-review → wire references → checkpoint commit. No code changes; pure documentation.

## Files to Modify

### Primary Changes
- **`docs/conventions/design-alignment.md`** (new) — Convention document covering naming audit, naming consistency, reference-update checklist, deprecation stance, and documentation standards. Top-level `docs/conventions/` (developer-facing CWF-on-CWF), not `.cwf/docs/conventions/` (installed copies). See Task 118 commit for the distinction.

### Supporting Changes
- **`CLAUDE.md`** — Under "Conventions" (around line 50), add a `**Design Alignment**` bullet matching the existing `**Commit Messages**` bullet style.
- **`BACKLOG.md`** — Replace the "Create Design-Alignment Conventions Document" task block (lines 557–623) with a one-line `<!-- Completed: ... -->` marker matching the pattern used for completed tasks at lines 7–28.
- **`CHANGELOG.md`** — Add an entry referencing Task 122 in the same style as Task 118's CHANGELOG entry.

## Implementation Steps

### Step 1: Confirm style and audience
- [x] Read `docs/conventions/perl-git-paths.md` and `docs/conventions/commit-messages.md` to match style
- [x] Confirm `docs/conventions/` (top-level) is the right location — Task 118 commit `e9e4c2a` documents the split: top-level = CWF development, `.cwf/docs/conventions/` = installed copies. This convention is about renaming CWF skills/scripts/templates *during CWF development*, so top-level is correct.

### Step 2: Inventory the reality the doc will describe
- [ ] **Skill names**: Two categories under `.claude/skills/`:
  - **Phase-based** (10 skills, one per v2.1 workflow letter): `cwf-task-plan`, `cwf-requirements-plan`, `cwf-design-plan`, `cwf-implementation-plan`, `cwf-implementation-exec`, `cwf-testing-plan`, `cwf-testing-exec`, `cwf-rollout`, `cwf-maintenance`, `cwf-retrospective`
  - **Action-based utilities**: `cwf-init`, `cwf-new-task`, `cwf-new-subtask`, `cwf-status`, `cwf-extract`, `cwf-config`, `cwf-current-task`, `cwf-security-check`
- [ ] **Helper script names**: `.cwf/scripts/command-helpers/<name>` — kebab-case, no extension.
  - Some use `-v2.0`/`-v2.1` suffix for version dispatch (`status-aggregator-v2.1`, `template-copier-v2.1`, `context-inheritance-v2.1`). **Version suffixes apply to helper scripts only, never skills.**
  - Some use a `<name>.d/` subdirectory pattern for subcommands (`context-manager` + `context-manager.d/{location,hierarchy,inheritance,version}`, `task-workflow` + `task-workflow.d/create`, `workflow-manager` + `workflow-manager.d/control`).
- [ ] **Template names**: `.cwf/templates/pool/<phase-letter>-<phase-name>.md.template`. Task-type directories (`bugfix/`, `feature/`, etc.) contain **symlinks** into `pool/`; rename of any pool file requires the symlinks to be re-created (template-copier-v2.1 exits 2 on broken symlinks). Use `git ls-files .cwf/templates` to enumerate; symlink integrity is verified by `cwf-manage validate`.
- [ ] **Top-level scripts**: `.cwf/scripts/cwf-manage` is documented in INSTALL.md as the public install-management CLI. Subcommand renames are a weak external interface — installed copies upgrade independently.
- [ ] **Rules**: `.claude/rules/cwf-workflow-files.md` contains a hardcoded phase-letter → skill-name table (`a-` → `/cwf-task-plan`, …). Any phase-skill rename must update this file.
- [ ] **Reference surfaces** (places that mention skill/command names by string and need updating on rename) — derived empirically by Grep-ing for `cwf-task-plan` and `cwf-status` across the repo (exclude `implementation-guide/`). Ground the audit checklist in the *actual* grep result, not this list, but expect it to include at minimum:
  - `CLAUDE.md`, `README.md`, `CHANGELOG.md`, `COMMANDS.md`, `INSTALL.md`, `DESIGN.md`, `CWF-PROJECT-SPEC.md`
  - `.claude/rules/cwf-workflow-files.md`
  - `.claude/skills/*/SKILL.md` (skills that reference each other)
  - `.cwf/docs/glossary.md`
  - `.cwf/docs/workflow/workflow-overview.md`, `blocker-patterns.md`, `workflow-steps.md`
  - `.cwf/docs/skills/*.md`

### Step 3: Draft `docs/conventions/design-alignment.md`
- [ ] Use **Convention / Why / Existing usage** structure (matches `perl-git-paths.md`). Each topic's "Existing usage" section draws concrete file paths from Step 2's inventory, so the doc stays grounded.
- [ ] Topic 1 — **Single source of truth**: skill = `.claude/skills/<name>/SKILL.md`; helper = `.cwf/scripts/command-helpers/<name>`; template = `.cwf/templates/pool/<file>.template`; rule = `.claude/rules/<name>.md`. All other mentions are *references*, not definitions.
- [ ] Topic 2 — **Naming patterns**: `cwf-` prefix for skills, helpers, and rules; phase-letter prefix (`a-` … `j-`) for workflow files; kebab-case throughout. Version suffix `-v<major>.<minor>` permitted on helper scripts for version dispatch (existing usage: `status-aggregator-v2.1`); never on skills. `.d/` subdirectory pattern for helper-script subcommand dispatch (existing usage: `context-manager.d/`). Skills track CWF version via git tags, not filename suffixes.
- [ ] Topic 3 — **Rename audit checklist** — concrete steps:
  1. Grep the repo for the old name (skip `implementation-guide/`).
  2. Walk every hit: `.claude/skills/`, `.claude/rules/`, `.cwf/scripts/`, `.cwf/docs/`, `.cwf/templates/`, root-level `*.md` (CLAUDE, README, INSTALL, CHANGELOG, COMMANDS, DESIGN, CWF-PROJECT-SPEC).
  3. If the renamed item is a phase skill, update `.claude/rules/cwf-workflow-files.md`'s phase-letter table.
  4. If a template is renamed, re-create the symlinks under `.cwf/templates/<task-type>/` and run `.cwf/scripts/cwf-manage validate` (it checks symlink integrity).
  5. If `.cwf/scripts/cwf-manage` itself or a subcommand is renamed, see Topic 4.
- [ ] Topic 4 — **Deprecation stance**:
  - **Skills, helpers, templates, rules**: no deprecation. CWF eats its own dog food; the project is the only consumer. Renames are atomic (rename + update all refs + ship in one task). Document the rationale.
  - **`.cwf/scripts/cwf-manage` and its subcommands**: weak external contract. Installed copies upgrade independently of upstream. Renaming `cwf-manage` itself is a breaking change requiring a major version bump per the versioning standard. Subcommand renames should keep the old name as an alias for one minor version, with a one-line stderr deprecation warning, then remove.
  - **Mid-task scope expansion**: if drafting reveals additional rename surfaces, escalate to the user with an updated estimate; do not silently expand scope or ship a partial rename.
- [ ] Topic 5 — **Cross-doc references**:
  - Progressive disclosure: skills reference docs in `.cwf/docs/...`; docs do not duplicate skill content.
  - When adding a new top-level convention, add a `**<Title>**: <one-sentence summary>. See \`docs/conventions/<file>.md\` for: ...` bullet to CLAUDE.md§Conventions matching the existing `**Commit Messages**` entry.
  - If the convention introduces a new term (e.g. "design alignment"), add it to `.cwf/docs/glossary.md`.
- [ ] Length target: 80–150 lines, comparable to `perl-git-paths.md`.

### Step 4: Wire references
- [ ] Add **Design Alignment** bullet to CLAUDE.md "Conventions" section (verified at lines 48–54), matching the existing **Commit Messages** bullet style.
- [ ] Replace BACKLOG.md task block (lines 557–623) with completion marker matching the format used at lines 7–28.
- [ ] Add CHANGELOG.md entry modelled on Task 118's entry: `## Task 122: …` heading, `**Status**`, `**Duration**`, `**Impact**`, brief summary, `### Changes` listing the new doc and CLAUDE.md/BACKLOG.md updates.
- [ ] If "design alignment" warrants a glossary term, add it to `.cwf/docs/glossary.md`. Otherwise note the omission.

### Step 5: Plan review
- [ ] Run plan-review subagents per `.cwf/docs/skills/plan-review.md` — see Step 8 below

### Step 6: Validation
- [ ] No reference to v1.0 paths (`.claude/commands/cwf-*.md` etc.)
- [ ] Doc is British-spelt (centre, behaviour, organise)
- [ ] All file paths cited in the doc resolve (verify with Read against a sample of cited paths)
- [ ] `cwf-manage validate` passes after wiring CLAUDE.md/BACKLOG.md/CHANGELOG.md edits

## Code Changes
N/A — documentation only.

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
This task is complete only when:
1. `docs/conventions/design-alignment.md` exists and covers the five topics
2. CLAUDE.md links to it
3. BACKLOG.md entry is removed
4. CHANGELOG.md has an entry
5. Tests in e-testing-plan pass

If any topic proves unworkable in drafting (e.g., no genuine convention exists for one of the five), document the omission in Actual Results and surface it for user decision rather than silently dropping it.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 122
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Plan executed as written. Reference-surface inventory turned up one file not in the predicted list (`.cwf/autoload.yaml`); the audit checklist correctly defers to the live grep so no plan change needed. Symlink branch of the audit was not exercised end-to-end (no template renamed) — the underlying `cwf-manage validate` is exercised every checkpoint.

## Lessons Learned
Plan-review subagents added three load-bearing items (helper `<name>.d/` subdirs, version-suffix scope, `cwf-manage` external contract). The map-reduce review pattern repays its cost on small plans where reviewers can hold the whole thing in mind.
