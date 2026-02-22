# Refactor workflow docs for efficiency - Design
**Task**: 88 (bugfix)

## Task Reference
- **Task ID**: internal-88
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/88-refactor-workflow-docs-for-efficiency
- **Template Version**: 2.1

## Goal
Define the structural changes to each workflow doc file: what is removed, what replaces it, and why.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Decision 1: Progressive Disclosure via Single-Line References
- **Decision**: Replace every duplicated block with a one-line reference to the canonical source
- **Rationale**: Content already exists at the canonical location; the reference chain is testable (grep for the path, then verify the target file contains the content)
- **Trade-offs**: Model must follow one hop to reach detail; acceptable because all target files are in `.cwf/docs/` and are already routinely read

### Decision 2: Placeholder Convention `{}` over `<>`
- **Decision**: Replace `<var>` with `{var}` wherever the model is expected to substitute a value
- **Rationale**: `<>` is ambiguous with HTML/XML; `{}` is the established convention in CWF (see skill docs)
- **Scope**: `checkpoint-commit.md` and `retrospective-extras.md` only — `workflow-preamble.md` and `decomposition-guide.md` use `<>` in CLI syntax docs (not substitution), left for a separate task

### Decision 3: Skill Calls over File-Edit Instructions
- **Decision**: Replace "Update X file then do Y" patterns in `blocker-patterns.md` with explicit `/cwf-<skill>` call chains
- **Rationale**: File-edit instructions encourage models to bypass the workflow; skill calls keep models on the established methodology path
- **Trade-offs**: Slightly more prescriptive; acceptable because the skill system exists precisely for this purpose

### Decision 4: Keep General Reversion Guidance section intact
- **Decision**: Remove the 3-line per-phase boilerplate (document blocker / update status / restart), keep the General section, add one forward pointer after the first phase's reversion guidance
- **Rationale**: The General section already states the canonical procedure; per-phase repetition adds no information

## Files and Changes

### `.cwf/docs/skills/checkpoint-commit.md`
- Line 13: `<task-dir>/<workflow-file>.md` → `{task-dir}/{workflow-file}.md`
- Line 18: `<phase>` → `{phase}`, `Task N:` → `Task {N}:`
- Line 30: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` → `.cwf/scripts/cwf-manage validate`

### `.cwf/docs/skills/retrospective-extras.md`
- Lines 11, 21, 34, 35, 98, 118: Replace `<var>` with `{var}` for all model-substitution variables

### `.cwf/docs/workflow/workflow-steps.md`
- Per-phase checkpoint commit blocks (8×~8 lines) → 1-line reference to `checkpoint-commit.md` + stage filename
- Per-phase "Typical Structure" sections (8×~8 lines) → 1-line reference to `.cwf/templates/pool/`
- Two `jq -r` code blocks → removed; keep human-readable status list; add 1-line config source reference

### `.cwf/docs/workflow/blocker-patterns.md`
- Per-phase 3-line boilerplate (9×3 lines) → removed; add one forward pointer after phase 1 reversion guidance
- File-edit reversion instructions → `/cwf-<skill>` call chains (13 replacements per plan table)
- Decomposition Signals body (~27 lines) → 1-line reference to `decomposition-guide.md`
- Stale References section (~15 lines) → removed entirely

### `.cwf/docs/workflow/decomposition-guide.md`
- Context Inheritance section body (~8 lines) → 1-line reference to `workflow-overview.md`

## Constraints
- No content disappears without a reference to its canonical location
- `cwf-manage validate` must pass after all changes
- Bugfix task type — no rollout phase

## Decomposition Check
- [ ] **Time**: No — under 1 day
- [ ] **People**: No
- [ ] **Complexity**: No — same mechanical pattern repeated across files
- [ ] **Risk**: No — documentation only
- [ ] **Independence**: N/A

No decomposition needed.

## Validation
- [ ] Every removed block has a named replacement reference
- [ ] Reference targets exist as files in the repo
- [ ] Test cases in e-testing-plan.md cover every removal

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 88
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
