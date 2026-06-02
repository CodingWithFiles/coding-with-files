# Split workflow-steps into per-anchor docs - Implementation Plan
**Task**: 176 (chore)

## Task Reference
- **Task ID**: internal-176
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/176-split-workflow-steps-into-per-anchor-docs
- **Template Version**: 2.1

## Goal
Relocate each phase section of `.cwf/docs/workflow/workflow-steps.md` into its own
`workflow-steps/{name}.md` file, re-point the 8 skill references to those files, and
reduce `workflow-steps.md` to a table of contents — so phase guidance is fetched with a
single `Read` and no `sed` permission halt.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Key Design Decisions
(This chore has no separate design phase; decisions are recorded here.)

**D1 — One file per phase section (10 files).** The source has 10 phase sections; only
8 are skill-referenced, but the 2 execution sections carry real content, so all 10 get a
dedicated file for consistency and future linkability. Filenames disambiguate
planning vs execution (the source anchors `#implementation` / `#testing` are ambiguous
and already don't resolve to the `## Implementation Planning` / `## Testing Planning`
headers — this split fixes that).

**D2 — Status Values and Version Differences stay inline in the ToC file (RECOMMENDED — open for review).**
`#status-values` has 12 live references (10 templates + `glossary.md` + `workflow-preamble.md`).
Keeping the `Status Values` section (with its `#status-values` anchor) and the
document-level `Version Differences` section inside the rewritten `workflow-steps.md`
leaves all 12 references valid and untouched, and since the ToC file is now short,
following `#status-values` lands in a small file (no `sed` needed). 
- *Alternative (not chosen):* split `status-values.md` and rewrite all 12 references —
  more churn and risk for no clear gain, since these are passive reference pointers, not
  phase walkthroughs. **Flag for review: confirm D2 before exec.**

**D3 — Content is preserved verbatim.** Each new file keeps the section's body prose
unchanged. The only mechanical changes: the `## Heading` is promoted to `# Heading`
(top-level title), a one-line up-link to `../workflow-steps.md` is added under the title,
and the trailing `---` separators are dropped.

**D4 — Packaging needs no manifest edit.** Both installers copy `.cwf/` recursively
(`git subtree` / `cp -r ".cwf:.cwf"`); the new `workflow-steps/` subdir ships
automatically. `install-manifest.json` does not enumerate `docs/`, so it is unchanged.

## Section → File Mapping
New directory: `.cwf/docs/workflow/workflow-steps/`

| Source section (H2) | Source anchor | New file | Skill that references it |
|---------------------|---------------|----------|--------------------------|
| Planning | `#planning` | `planning.md` | cwf-task-plan |
| Requirements | `#requirements` | `requirements.md` | cwf-requirements-plan |
| Design | `#design` | `design.md` | cwf-design-plan |
| Implementation Planning | `#implementation`* | `implementation-planning.md` | cwf-implementation-plan |
| Implementation Execution | (none) | `implementation-execution.md` | — (exec skill, no current ref) |
| Testing Planning | `#testing`* | `testing-planning.md` | cwf-testing-plan |
| Testing Execution | (none) | `testing-execution.md` | — (exec skill, no current ref) |
| Rollout | `#rollout` | `rollout.md` | cwf-rollout |
| Maintenance | `#maintenance` | `maintenance.md` | cwf-maintenance |
| Retrospective | `#retrospective` | `retrospective.md` | cwf-retrospective |

`*` The skill anchor (`#implementation`, `#testing`) currently does not resolve to the
actual header; the new plain-path reference fixes the latent breakage.

**Stays in `workflow-steps.md` (per D2):** intro paragraph, `## Version Differences`,
`## Status Values` (incl. `### Valid Status Values`, anchor `#status-values` preserved).

## Files to Modify
### New files (10)
- `.cwf/docs/workflow/workflow-steps/{planning,requirements,design,implementation-planning,implementation-execution,testing-planning,testing-execution,rollout,maintenance,retrospective}.md`

### Rewrite (1)
- `.cwf/docs/workflow/workflow-steps.md` — reduce to: title + intro + Version Differences + Status Values + a Table of Contents linking each of the 10 new files.

### Re-point references (8 skills)
- `.claude/skills/cwf-task-plan/SKILL.md:29` → `workflow-steps/planning.md`
- `.claude/skills/cwf-requirements-plan/SKILL.md:35` → `workflow-steps/requirements.md`
- `.claude/skills/cwf-design-plan/SKILL.md:36` → `workflow-steps/design.md`
- `.claude/skills/cwf-implementation-plan/SKILL.md:36` → `workflow-steps/implementation-planning.md`
- `.claude/skills/cwf-testing-plan/SKILL.md:29` → `workflow-steps/testing-planning.md`
- `.claude/skills/cwf-rollout/SKILL.md:29` → `workflow-steps/rollout.md`
- `.claude/skills/cwf-maintenance/SKILL.md:29` → `workflow-steps/maintenance.md`
- `.claude/skills/cwf-retrospective/SKILL.md:38` → `workflow-steps/retrospective.md`

### Unchanged (verified still valid)
- 10 templates + `glossary.md` + `workflow-preamble.md` → `workflow-steps.md#status-values` (resolves under D2)
- `checkpoint-commit.md:56` → `workflow-steps.md` (whole file → ToC, still valid)
- `BACKLOG.md` / `CHANGELOG.md` — historical record, **must not edit**

## Implementation Steps
### Step 1: Create the per-anchor docs
- [ ] Create directory `.cwf/docs/workflow/workflow-steps/`
- [ ] For each of the 10 sections, write `{name}.md` with: `# {Heading}`, up-link line `> Part of the [Workflow Steps](../workflow-steps.md) reference.`, then the section body verbatim (drop the `---`).

### Step 2: Re-point the 8 skill references
- [ ] Edit each SKILL.md line to the new plain path (no `#anchor`), keeping surrounding wording.

### Step 3: Rewrite workflow-steps.md as a ToC
- [ ] Keep title, intro, Version Differences, Status Values (anchor intact).
- [ ] Replace the 10 phase sections with a `## Workflow Steps` ToC: a bullet/linked list to each `workflow-steps/{name}.md` with a one-line description.

### Step 4: Verify (see e-testing-plan.md)
- [ ] `git grep` shows no dangling removed `#anchor`; status-values refs intact.
- [ ] Per-file body diff against original sections (content-preserving).
- [ ] `cwf-manage validate` OK; relevant `t/*.t` pass (esp. installmanifest-integrity).

## Up-link format (each new file)
```markdown
# Planning

> Part of the [Workflow Steps](../workflow-steps.md) reference.

**Purpose**: ...
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.
All 10 files, 8 reference updates, and the ToC rewrite land together — partial work
would leave dangling references.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four steps executed as planned with no deviations. D1–D4 decisions held: 10 files (incl. 2 exec sections), status-values kept inline (D2, confirmed at review), bodies verbatim, no manifest edit. The disambiguated filenames (`implementation-planning.md` / `testing-planning.md`) also corrected the two pre-existing broken anchors.

## Lessons Learned
Recording D1–D4 inline in the impl-plan (no separate design phase for a chore) gave the review a single place to confirm the load-bearing decisions before exec — the status-values handling in particular.
