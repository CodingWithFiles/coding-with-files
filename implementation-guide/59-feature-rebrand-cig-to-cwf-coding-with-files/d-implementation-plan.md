# Rebrand CIG to CWF (Coding with Files) - Implementation Plan
**Task**: 59 (feature)

## Task Reference
- **Task ID**: internal-59
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/59-rebrand-cig-to-cwf-coding-with-files
- **Template Version**: 2.1

## Goal
Implement the CIG→CWF rebrand following the 4-phase execution strategy from c-design-plan.md.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Phase 1: Structural Renames (git mv only — no content edits)
- `.cig/` → `.cwf/` (entire tree)
- `.cwf/lib/CIG/` → `.cwf/lib/CWF/` (after top-level move)
- `.cwf/lib/TaskState.pm` → `.cwf/lib/CWF/TaskState.pm`
- `.cwf/lib/TaskContextInference.pm` → `.cwf/lib/CWF/TaskContextInference.pm`
- 19 skill dirs: `.claude/skills/cig-*` → `.claude/skills/cwf-*`
- 5 helper scripts: `.cwf/scripts/command-helpers/cig-*` → `cwf-*`
- `.cwf/templates/cig-project.json.template` → `cwf-project.json.template`
- `.cwf/scripts/update-cig-command-docs.sh` → `update-cwf-skill-docs.sh`
- `CIG-PROJECT-SPEC.md` → `CWF-PROJECT-SPEC.md`
- `implementation-guide/cig-project.json` → `cwf-project.json`

### Phase 2: Perl Namespace (content edits — 15 modules + 14 scripts)
**Modules** (`.cwf/lib/CWF/`):
- `Common.pm`, `ContextInheritance/Core.pm`, `MarkdownParser.pm`, `Options.pm`
- `StatusAggregator/Core.pm`, `TaskPath.pm`, `TemplateCopier/Core.pm`, `VersionRouter.pm`
- `WorkflowFiles.pm`, `WorkflowFiles/V20.pm`, `WorkflowFiles/V21.pm`
- `TaskState.pm`, `TaskContextInference.pm`

**Scripts** (`.cwf/scripts/command-helpers/`):
- `status-aggregator-v2.0`, `status-aggregator-v2.1`
- `template-copier-v2.0`, `template-copier-v2.1`
- `context-inheritance-v2.0`, `context-inheritance-v2.1`
- `task-stack`, `task-context-inference`
- `workflow-manager.d/control`, `workflow-manager.d/status`
- `context-manager.d/hierarchy`, `context-manager.d/inheritance`, `context-manager.d/location`, `context-manager.d/version`
- `task-workflow.d/create`

### Phase 3: Content Updates (~35 files)
**Skills** (19 SKILL.md files in `.claude/skills/cwf-*/`)
**Root docs** (5): `README.md`, `CLAUDE.md`, `COMMANDS.md`, `DESIGN.md`, `BACKLOG.md`
**Spec** (1): `CWF-PROJECT-SPEC.md`
**Internal docs** (10 in `.cwf/docs/`):
- `workflow/workflow-steps.md`, `workflow/workflow-overview.md`, `workflow/decomposition-guide.md`, `workflow/blocker-patterns.md`
- `skills/workflow-preamble.md`, `skills/checkpoint-commit.md`, `skills/retrospective-extras.md`
- `migration.md`, `context/tools.md`, `context/state-tracking.md`

**Config** (3): `implementation-guide/cwf-project.json`, `.cwf/templates/cwf-project.json.template`, `.cwf/autoload.yaml`
**Utility docs** (4): `.cwf/utils/config-loader.md`, `hierarchy-manager.md`, `task-validator.md`, `template-engine.md`
**Shell script** (1): `.cwf/scripts/update-cwf-skill-docs.sh`

### Phase 4: Security (1 file)
- `.cwf/security/script-hashes.json` — regenerate

**Excluded**: `CHANGELOG.md`, all files in `implementation-guide/*/`

## Implementation Steps

### Step 1: Phase 1 — Structural Renames
- [ ] 1.1: `git mv .cig .cwf`
- [ ] 1.2: `git mv .cwf/lib/CIG .cwf/lib/CWF`
- [ ] 1.3: `git mv .cwf/lib/TaskState.pm .cwf/lib/CWF/TaskState.pm`
- [ ] 1.4: `git mv .cwf/lib/TaskContextInference.pm .cwf/lib/CWF/TaskContextInference.pm`
- [ ] 1.5: Batch rename 19 skill dirs: `for d in .claude/skills/cig-*; do git mv "$d" "${d/cig-/cwf-}"; done` and `git mv .claude/skills/test-cig-skill .claude/skills/test-cwf-skill`
- [ ] 1.6: Batch rename 5 helper scripts: `for f in .cwf/scripts/command-helpers/cig-*; do git mv "$f" "${f/cig-/cwf-}"; done`
- [ ] 1.7: `git mv .cwf/templates/cig-project.json.template .cwf/templates/cwf-project.json.template`
- [ ] 1.8: `git mv .cwf/scripts/update-cig-command-docs.sh .cwf/scripts/update-cwf-skill-docs.sh`
- [ ] 1.9: `git mv CIG-PROJECT-SPEC.md CWF-PROJECT-SPEC.md`
- [ ] 1.10: `git mv implementation-guide/cig-project.json implementation-guide/cwf-project.json`
- [ ] **Checkpoint**: `git status` — verify renames only, no unexpected deletes

### Step 2: Phase 2 — Perl Namespace
- [ ] 2.1: Update `package` declarations in all 13 `CWF::*` modules (`CIG::` → `CWF::`)
- [ ] 2.2: Update `package` declarations in `TaskState.pm` and `TaskContextInference.pm` (bare → `CWF::`)
- [ ] 2.3: Update all `use CIG::*` → `use CWF::*` in modules (cross-references)
- [ ] 2.4: Update `use TaskState` → `use CWF::TaskState` in modules and scripts (6 callers)
- [ ] 2.5: Update `use TaskContextInference` → `use CWF::TaskContextInference` in scripts (1 caller)
- [ ] 2.6: Update `use lib` paths in all helper scripts: `.cig/lib` → `.cwf/lib`
- [ ] 2.7: Update any `FindBin`/lib path references that resolve to `.cig/`
- [ ] **Checkpoint**: `perl -c` on all 15 helper scripts (14 + task-context-inference)

### Step 3: Phase 3 — Content Updates
- [ ] 3.1: Update 19 SKILL.md files — frontmatter `name:`, base directory, script paths, `/cig-` → `/cwf-`, prose
- [ ] 3.2: Update `README.md` — title, "CWF (pronounced 'swiff')", all `/cig-*` → `/cwf-*`, paths, prose
- [ ] 3.3: Update `CLAUDE.md` — project description, command names, paths
- [ ] 3.4: Update `COMMANDS.md` — all command names, paths, prose
- [ ] 3.5: Update `DESIGN.md` — system name, paths, script names
- [ ] 3.6: Update `BACKLOG.md` — brand references (CIG → CWF)
- [ ] 3.7: Update `CWF-PROJECT-SPEC.md` — all internal references
- [ ] 3.8: Update 10 internal docs in `.cwf/docs/` — paths, prose, skill references
- [ ] 3.9: Update `implementation-guide/cwf-project.json` — project-name, `.cig/` paths, `cig-*` globs
- [ ] 3.10: Update `.cwf/templates/cwf-project.json.template` — `cig-version` → `cwf-version`, paths
- [ ] 3.11: Update `.cwf/autoload.yaml` — title, command/skill names
- [ ] 3.12: Update `.cwf/scripts/update-cwf-skill-docs.sh` — internal references
- [ ] 3.13: Update 4 utility docs in `.cwf/utils/` — `cig-project.json` → `cwf-project.json`, paths
- [ ] 3.14: Update `.cwf/task-stack` path references if the file itself contains paths (check)
- [ ] **Checkpoint**: Grep sweep — `grep -r 'CIG::\|\.cig/\|cig-project\|/cig-\|Code Implementation Guide' --include='*.md' --include='*.pm' --include='*.yaml' --include='*.json' --include='*.sh' . | grep -v 'implementation-guide/' | grep -v 'CHANGELOG.md'` returns zero matches

### Step 4: Phase 4 — Security and Validation
- [ ] 4.1: Regenerate `.cwf/security/script-hashes.json`
- [ ] 4.2: Run `/cwf-security-check verify`
- [ ] 4.3: Run `.cwf/scripts/command-helpers/context-manager location` — verify it works
- [ ] 4.4: Run `.cwf/scripts/command-helpers/task-context-inference` — verify it works
- [ ] 4.5: Verify file permissions on all scripts: `find .cwf/scripts -type f | xargs ls -la`
- [ ] **Checkpoint**: All validation passes

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
- Zero `cig`/`CIG::`/`.cig/` references outside exclusions (grep sweep)
- `perl -c` passes on all 15 helper scripts
- `/cwf-security-check verify` passes
- `/cwf-status` runs and reports progress
- File permissions preserved (u+rx on all scripts)
- `implementation-guide/*/` files unchanged (`git diff` clean for those paths)
- `CHANGELOG.md` unchanged

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cig-testing-plan 59
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
