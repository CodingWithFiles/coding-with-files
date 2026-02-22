# Create CWF terminology glossary - Implementation Plan
**Task**: 87 (hotfix)

## Task Reference
- **Task ID**: internal-87
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/87-create-cwf-terminology-glossary
- **Template Version**: 2.1

## Goal
Create `.cwf/docs/glossary.md` covering term gaps not defined in existing docs,
and add a reference line to `workflow-preamble.md`.

## Files to Modify
- `.cwf/docs/glossary.md` — create new file
- `.cwf/docs/skills/workflow-preamble.md` — add one reference line

## Terms to Define

Audit confirmed these terms are **used but never defined** in any existing doc:

| Term | Used in | Gap |
|------|---------|-----|
| `CWF` | everywhere | acronym expansion never stated |
| `wf` / `WF` | retrospective-extras, filenames | abbreviation for "workflow" never explained |
| `skill` | all SKILL.md files, CLAUDE.md | core unit of CWF, never defined |
| `slug` | workflow-preamble, new-task | URL-safe task description fragment, never defined |
| `task branch` | retrospective-extras | the `<type>/<num>-<slug>` branch, never defined |
| `checkpoints branch` | retrospective-extras | branch preserving per-phase commits, never defined |
| `checkpoint commit` | checkpoint-commit.md, workflow-steps | described procedurally, never defined as concept |
| `squash commit` | retrospective-extras | single consolidated commit, never defined |

Terms already authoritatively defined elsewhere (NOT duplicated in glossary):
- `workflow steps/phases` → workflow-overview.md
- `status values` → workflow-steps.md#status-values
- `task path`, `task type`, `task number` → workflow-preamble.md
- `decomposition`, `subtask` → workflow-overview.md
- `progressive disclosure` → workflow-overview.md

## Glossary Structure

Each entry follows this format (grep `^## ` for term index):

```markdown
## <TERM>

**Abbrev**: <short form>       ← only if abbreviation exists
**Not**: <wrong variants>      ← only if common mistakes exist
<One-sentence canonical definition.>
<Optional one sentence of elaboration or example.>
**See**: <cross-reference>     ← only if related term/doc exists
```

File opens with a brief index listing all terms alphabetically so a model can
scan the full term set in one Read before looking up a specific entry.

## Implementation Steps
- [ ] Create `.cwf/docs/glossary.md` with index + 8 entries in above format
- [ ] Edit `.cwf/docs/skills/workflow-preamble.md`: add `**Terminology**: See
  `.cwf/docs/glossary.md` for canonical term definitions.` after the opening
  paragraph (before "Argument Parsing")

## Validation Criteria
**See e-testing-plan.md**

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 87
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
