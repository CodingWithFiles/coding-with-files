# Rebrand CIG to CWF (Coding with Files) - Requirements
**Task**: 59 (feature)

## Task Reference
- **Task ID**: internal-59
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/59-rebrand-cig-to-cwf-coding-with-files
- **Template Version**: 2.1

## Goal
Define the complete set of rename operations, content updates, and exclusions needed to rebrand from "Code Implementation Guide" (CIG) to "Coding with Files" (CWF, pronounced "swiff").

## Naming Decisions

Resolved during requirements planning:

| # | Decision | Answer |
|---|----------|--------|
| 1 | `implementation-guide/` dir | **No rename** — describes contents, not brand |
| 2 | Config keys (e.g. `cig-version`) | **Rename** → `cwf-version` |
| 3 | "swiff" in docs | **Yes** — pronunciation note in README at first CWF mention |
| 4 | `TaskState.pm` / `TaskContextInference.pm` namespace | **Move into `CWF::`** for consistency |
| 5 | `CIG-PROJECT-SPEC.md` | **Rename** → `CWF-PROJECT-SPEC.md` |
| 6 | CHANGELOG/BACKLOG historical refs | **BACKLOG: update. CHANGELOG: leave unchanged** (append-only history) |
| 7 | "implementation guide" in prose | **Replace** where it means the product; keep where it means the generic concept |
| 8 | Repo root dir `code-implementation-guide/` | **Out of scope** (manual GitHub operation) |

## Functional Requirements

### FR1: Structural Renames (directories and files)

Rename the following using `git mv`:

**Directories:**
- `.cig/` → `.cwf/` (entire tree moves with it)
- `.cig/lib/CIG/` → `.cwf/lib/CWF/` (Perl namespace dir)
- 19 skill directories: `.claude/skills/cig-*` → `.claude/skills/cwf-*`
  - cig-config, cig-current-task, cig-design-plan, cig-extract, cig-implementation-exec, cig-implementation-plan, cig-init, cig-maintenance, cig-new-task, cig-requirements-plan, cig-retrospective, cig-rollout, cig-security-check, cig-status, cig-subtask, cig-task-plan, cig-testing-exec, cig-testing-plan, test-cig-skill

**Files:**
- `.cig/templates/cig-project.json.template` → `.cwf/templates/cwf-project.json.template`
- `CIG-PROJECT-SPEC.md` → `CWF-PROJECT-SPEC.md`
- `.cig/scripts/update-cig-command-docs.sh` → `.cwf/scripts/update-cwf-skill-docs.sh`
- 5 helper scripts in `.cig/scripts/command-helpers/`:
  - `cig-find-task-numbering-structure` → `cwf-find-task-numbering-structure`
  - `cig-load-autoload-config` → `cwf-load-autoload-config`
  - `cig-load-existing-tasks` → `cwf-load-existing-tasks`
  - `cig-load-project-config` → `cwf-load-project-config`
  - `cig-load-status-sections` → `cwf-load-status-sections`

**AC-FR1**: Zero files/directories with `cig` in their name outside `implementation-guide/*/` and `CHANGELOG.md`.

### FR2: Perl Namespace (`CIG::*` → `CWF::*`)

Update all `package` declarations and `use` statements across 15 modules and 14 scripts.

**Modules (15 total)** — all under `.cwf/lib/` after FR1 renames:
1. `CWF/Common.pm` — package + used by 5+ scripts
2. `CWF/ContextInheritance/Core.pm` — package + used by context-inheritance scripts
3. `CWF/MarkdownParser.pm` — package + used by multiple modules
4. `CWF/Options.pm` — package + used by TaskContextInference, task-stack
5. `CWF/StatusAggregator/Core.pm` — package + used by status-aggregator scripts
6. `CWF/TaskPath.pm` — package + used by task-stack
7. `CWF/TemplateCopier/Core.pm` — package + used by template-copier scripts
8. `CWF/VersionRouter.pm` — package + used by multiple scripts
9. `CWF/WorkflowFiles.pm` — package + used by workflow-related scripts
10. `CWF/WorkflowFiles/V20.pm` — package
11. `CWF/WorkflowFiles/V21.pm` — package
12. `CWF/TaskState.pm` — **moved from lib root** into `CWF::` namespace
13. `CWF/TaskContextInference.pm` — **moved from lib root** into `CWF::` namespace
14-15. Any internal cross-references between these modules

**Helper scripts (14)** — update `use CIG::` → `use CWF::` and `use lib` paths:
- status-aggregator-v2.0, status-aggregator-v2.1
- template-copier-v2.0, template-copier-v2.1
- context-inheritance-v2.0, context-inheritance-v2.1
- task-stack
- workflow-manager.d/control, workflow-manager.d/status
- context-manager.d/hierarchy, context-manager.d/inheritance, context-manager.d/location, context-manager.d/version
- task-workflow.d/create

**AC-FR2**: `grep -r 'CIG::' .cwf/ .claude/skills/` returns zero matches. `perl -c` passes on all 14 helper scripts.

### FR3: Skill Updates (19 SKILL.md files)

For each `.claude/skills/cwf-*/SKILL.md` (after FR1 rename):
- Frontmatter `name:` field: `cig-*` → `cwf-*`
- Base directory path in body: `.claude/skills/cig-*` → `.claude/skills/cwf-*`
- Script paths: `.cig/scripts/` → `.cwf/scripts/`
- Skill cross-references: `/cig-*` → `/cwf-*`
- Prose: "CIG system" → "CWF system", "Code Implementation Guide" → "Coding with Files"

**AC-FR3**: `grep -r 'cig-' .claude/skills/` returns zero matches (excluding historical context in test fixtures if any).

### FR4: Documentation Updates

**Root docs (5 files — CHANGELOG excluded):**
- `README.md` — full rebrand including "CWF (pronounced 'swiff')" at first mention
- `CLAUDE.md` — all command names, paths, prose
- `COMMANDS.md` — all command names, paths, prose
- `DESIGN.md` — system name, paths, script names
- `BACKLOG.md` — update brand references to CWF

**Product spec (1 file after rename):**
- `CWF-PROJECT-SPEC.md` — update all internal references

**Internal docs (10 files in `.cwf/docs/`):**
- `workflow/workflow-steps.md`, `workflow/workflow-overview.md`, `workflow/decomposition-guide.md`, `workflow/blocker-patterns.md`
- `skills/workflow-preamble.md`, `skills/checkpoint-commit.md`, `skills/retrospective-extras.md`
- `migration.md`, `context/tools.md`, `context/state-tracking.md`

**Excluded:**
- `CHANGELOG.md` — append-only historical record, do not modify
- `implementation-guide/*/` — historical task workflow docs

**AC-FR4**: `grep -r 'Code Implementation Guide\|\.cig/' README.md CLAUDE.md COMMANDS.md DESIGN.md BACKLOG.md CWF-PROJECT-SPEC.md .cwf/docs/` returns zero matches.

### FR5: Configuration and Security

**Config files:**
- `cwf-project.json.template` — rename internal keys: `cig-version` → `cwf-version`, any other `cig-` prefixed keys
- `.cwf/autoload.yaml` — update command/skill names
- All `implementation-guide/cig-project.json` references in skills/scripts → `cwf-project.json`

**Security:**
- `.cwf/security/script-hashes.json` — regenerate all SHA256 hashes after renames complete
- Verify with `/cwf-security-check`

**AC-FR5**: `cwf-project.json.template` contains zero `cig-` prefixed keys. Security check passes.

## Non-Functional Requirements

### NFR1: Historical Preservation
All files under `implementation-guide/*/` must remain unchanged. Zero modifications to any historical task workflow document.

**AC-NFR1**: `git diff` shows no changes to files matching `implementation-guide/*/`.

### NFR2: Git History Preservation
Use `git mv` for all structural renames (FR1) to preserve file history tracking.

**AC-NFR2**: All renames appear as renames (not delete+add) in `git log --diff-filter=R`.

### NFR3: Permission Preservation
All executable scripts must retain their permissions (minimum u+rx / 0500) after rename.

**AC-NFR3**: `find .cwf/scripts -name '*.sh' -o -name '*.pl' | xargs ls -la` shows correct permissions. All scripts in `command-helpers/` have u+rx.

## Constraints
- Must not modify `implementation-guide/*/` (historical docs)
- Must not modify `CHANGELOG.md` (append-only)
- Must use `git mv` for renames (preserve history)
- Must preserve file permissions (u+rx on scripts)
- GitHub repo slug change (`coding-with-files`) is out of scope
- Repo root directory rename is out of scope

## Decomposition Check
- [ ] **Time**: >1 week? **No** — 3-5 hours
- [ ] **People**: >2 people? **No**
- [x] **Complexity**: 3+ concerns? **Yes** — structural, namespace, skills, docs, config
- [ ] **Risk**: High-risk components? **No**
- [x] **Independence**: Parts separable? **Yes** — FR1→FR2→FR3/FR4/FR5

**Decision**: No decomposition. Same reasoning as a-task-plan.md — sequential steps of a single rename, interdependencies require ordering.

## Acceptance Criteria (Summary)
- [ ] AC-FR1: Zero `cig`-named files/dirs outside exclusions
- [ ] AC-FR2: Zero `CIG::` references in `.cwf/` and `.claude/skills/`; `perl -c` passes on all scripts
- [ ] AC-FR3: Zero `cig-` references in `.claude/skills/`
- [ ] AC-FR4: Zero old brand references in updated docs
- [ ] AC-FR5: Zero `cig-` config keys; security check passes
- [ ] AC-NFR1: Zero changes to `implementation-guide/*/`
- [ ] AC-NFR2: Renames tracked by git
- [ ] AC-NFR3: Permissions preserved

## Status
**Status**: Finished
**Next Action**: /cig-design-plan 59
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
