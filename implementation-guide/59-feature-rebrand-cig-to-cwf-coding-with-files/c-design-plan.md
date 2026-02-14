# Rebrand CIG to CWF (Coding with Files) - Design
**Task**: 59 (feature)

## Task Reference
- **Task ID**: internal-59
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/59-rebrand-cig-to-cwf-coding-with-files
- **Template Version**: 2.1

## Goal
Define the ordered execution strategy, rename rules, and validation checkpoints for the CIG→CWF rebrand.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1: Rename Ordering (Structure Before Content)
- **Decision**: Execute in 4 phases: (1) structural renames via `git mv`, (2) Perl namespace updates, (3) content/path updates, (4) config/security regeneration
- **Rationale**: `git mv` must happen before content edits — otherwise edits target old paths that then move, creating confusing diffs. Perl namespace updates depend on directory structure being final. Content updates reference final paths.
- **Trade-offs**: Requires careful ordering but produces clean git history. Cannot parallelise phases.

### D2: `.cig/` Rename Strategy (Single `git mv`)
- **Decision**: `git mv .cig .cwf` as a single operation. The entire tree moves atomically — lib, scripts, templates, docs, security, autoload all come along.
- **Rationale**: Git tracks the top-level rename; subdirectory renames within `.cig/lib/CIG/` → `.cwf/lib/CWF/` must be a separate `git mv` after the top-level move.
- **Ordering**: (1) `git mv .cig .cwf`, (2) `git mv .cwf/lib/CIG .cwf/lib/CWF`, (3) move `TaskState.pm` and `TaskContextInference.pm` into `CWF/`

### D3: TaskState/TaskContextInference Namespace Migration
- **Decision**: Move files into `CWF/` directory and update `package` from bare name to `CWF::TaskState` / `CWF::TaskContextInference`. Update all `use` statements and `@EXPORT` as needed.
- **Rationale**: User requested all modules in `CWF::` namespace for consistency.
- **Impact**: 6 callers need updating (3 scripts + TaskContextInference itself for TaskState; 1 script for TaskContextInference). Exporter `import` still works — just the package name changes.

### D4: `cig-project.json` Rename and Lookup Paths
- **Decision**: Rename `implementation-guide/cig-project.json` → `implementation-guide/cwf-project.json`. Update `WorkflowFiles.pm` search paths to look for `cwf-project.json` in all 3 locations.
- **Rationale**: The config file is at `implementation-guide/` root (not inside a task subdir), so it's not protected by the historical docs constraint.
- **Content changes inside the file**: `project-name` → "Coding with Files (CWF)", path values `.cig/` → `.cwf/`, glob patterns `cig-*` → `cwf-*`
- **Keys that stay**: `project-name`, `version`, `supported-task-types` etc. are generic. Only `cig-version` in the template gets renamed to `cwf-version`.

### D5: Content Replacement Rules
- **Decision**: Three distinct find/replace patterns applied in order:
  1. **Perl source**: `CIG::` → `CWF::`, `use CIG::` → `use CWF::`, `package CIG::` → `package CWF::`, `use TaskState` → `use CWF::TaskState`, `use TaskContextInference` → `use CWF::TaskContextInference`, `package TaskState` → `package CWF::TaskState`, `package TaskContextInference` → `package CWF::TaskContextInference`
  2. **Paths**: `.cig/` → `.cwf/`, `cig-project.json` → `cwf-project.json`, `/cig-` → `/cwf-` (skill invocations)
  3. **Prose**: "Code Implementation Guide" → "Coding with Files", " (CIG)" → " (CWF)", "CIG system" → "CWF system", "CIG " → "CWF " (where CIG is the acronym in prose)
- **Exclusions**: Never touch files inside `implementation-guide/*/` or `CHANGELOG.md`

### D6: Skill Directory Renames (Batch)
- **Decision**: Batch all 19 skill directory renames in a single script/loop rather than individual `git mv` commands.
- **Pattern**: `for d in .claude/skills/cig-*; do git mv "$d" "${d/cig-/cwf-}"; done`
- **Rationale**: Consistent, less error-prone than 19 manual commands.

### D7: Security Hash Regeneration
- **Decision**: Regenerate hashes as the final step, after all renames and content changes are complete.
- **Rationale**: Hashes depend on file content and paths. Any change invalidates them. Must be last.
- **Method**: Use the existing hash generation mechanism referenced by `/cwf-security-check`.

## Execution Phases

### Phase 1: Structural Renames (FR1)
1. `git mv .cig .cwf`
2. `git mv .cwf/lib/CIG .cwf/lib/CWF`
3. `git mv .cwf/lib/TaskState.pm .cwf/lib/CWF/TaskState.pm`
4. `git mv .cwf/lib/TaskContextInference.pm .cwf/lib/CWF/TaskContextInference.pm`
5. Batch rename 19 skill dirs: `cig-*` → `cwf-*`
6. Rename 5 helper scripts: `cig-*` → `cwf-*` (within `.cwf/scripts/command-helpers/`)
7. `git mv .cwf/templates/cig-project.json.template .cwf/templates/cwf-project.json.template`
8. `git mv .cwf/scripts/update-cig-command-docs.sh .cwf/scripts/update-cwf-skill-docs.sh`
9. `git mv CIG-PROJECT-SPEC.md CWF-PROJECT-SPEC.md`
10. `git mv implementation-guide/cig-project.json implementation-guide/cwf-project.json`
**Checkpoint**: `git status` shows only renames, zero deletes without corresponding adds.

### Phase 2: Perl Namespace (FR2)
1. Update all 15 module `package` declarations (`CIG::` → `CWF::`, bare → `CWF::`)
2. Update all `use CIG::` → `use CWF::` in modules
3. Update all `use TaskState` → `use CWF::TaskState` in modules and scripts
4. Update all `use TaskContextInference` → `use CWF::TaskContextInference` in scripts
5. Update `use lib` paths in all 14 helper scripts (`.cig/lib` → `.cwf/lib`)
**Checkpoint**: `perl -c` passes on all 14 helper scripts.

### Phase 3: Content Updates (FR3 + FR4 + FR5)
1. Update 19 SKILL.md files (frontmatter + body)
2. Update root docs: README.md (inc. "swiff"), CLAUDE.md, COMMANDS.md, DESIGN.md, BACKLOG.md
3. Update CWF-PROJECT-SPEC.md
4. Update 10 internal docs in `.cwf/docs/`
5. Update `implementation-guide/cwf-project.json` content (project-name, paths, globs)
6. Update `cwf-project.json.template` content (keys, paths)
7. Update `.cwf/autoload.yaml`
8. Update `.cwf/scripts/update-cwf-skill-docs.sh` content
9. Update utility docs in `.cwf/utils/`
**Checkpoint**: Grep sweeps return zero residual `cig`/`CIG`/`.cig` outside exclusions.

### Phase 4: Security and Validation (FR5)
1. Regenerate `.cwf/security/script-hashes.json`
2. Run `/cwf-security-check verify`
3. Run `/cwf-status` to verify end-to-end functionality
4. Verify `perl -c` on all scripts one final time
**Checkpoint**: All validation passes.

## Constraints
- `implementation-guide/*/` files: untouched (historical)
- `CHANGELOG.md`: untouched (append-only)
- `git mv` for all structural renames
- File permissions preserved (u+rx)
- GitHub repo slug out of scope

## Decomposition Check
- [ ] **Time**: >1 week? **No**
- [ ] **People**: >2 people? **No**
- [x] **Complexity**: 3+ concerns? **Yes** — 4 phases
- [ ] **Risk**: High-risk? **No**
- [x] **Independence**: Separable? **Yes** — phases are sequential

**Decision**: No decomposition. Phases are inherently sequential (structure → namespace → content → validation).

## Validation
- [ ] Grep sweep: zero `cig`/`CIG::`/`.cig/` outside `implementation-guide/*/` and `CHANGELOG.md`
- [ ] `perl -c` passes on all 14 helper scripts
- [ ] `/cwf-security-check verify` passes
- [ ] `/cwf-status` runs successfully
- [ ] File permissions preserved on all scripts

## Status
**Status**: Finished
**Next Action**: /cig-implementation-plan 59
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
