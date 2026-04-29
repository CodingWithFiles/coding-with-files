# Add gotchas to cwf-implementation-exec skill - Implementation Plan
**Task**: 117 (chore)

## Task Reference
- **Task ID**: internal-117
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/117-add-gotchas-to-cwf-implementation-exec-skill
- **Template Version**: 2.1

## Goal
Insert a new `## Gotchas` section into `cwf-implementation-exec/SKILL.md` containing
the two project-neutral gotchas from the backlog item: (1) `git status` before every
commit, (2) verify generated output after a rename or string substitution.

## Context
Task 107 (LMM memory analysis) identified two recurring execution-phase failures:
- Untracked files left out of commits (e.g. workflow files, new scripts) because
  `git diff` was checked but `git status` wasn't.
- Renames that pass source-level grep but leave stale strings in generated output
  (templates, script-emitted text, docs).

Both happen during implementation execution, so they belong in
`cwf-implementation-exec`. Sibling skills (`cwf-design-plan`,
`cwf-implementation-plan`, `cwf-retrospective`) already have a `## Gotchas`
section between the front-matter and `## Scope & Boundaries`; this task adds the
same shape to `cwf-implementation-exec`.

## Files to Modify
- `.claude/skills/cwf-implementation-exec/SKILL.md` — insert new `## Gotchas`
  section between line 10 (closing `---` of front-matter) and line 12
  (`## Scope & Boundaries`).

No other files change.

## Implementation Steps
### Step 1: Insert Gotchas Section
- [ ] Use Edit tool to insert the `## Gotchas` section block immediately before
      `## Scope & Boundaries` in `.claude/skills/cwf-implementation-exec/SKILL.md`
- [ ] Match the placement and single-line item formatting used by
      `cwf-retrospective/SKILL.md` (header at top, blank line, numbered list, blank line)

**Section text to insert (project-neutral, no Task NNN references):**

```
## Gotchas

1. **Run `git status` before every checkpoint commit**: `git diff` only shows unstaged changes to already-tracked files. New files created during the phase (workflow files, helper scripts, generated docs) and tracked files that were modified but never staged are easy to miss, and the commit will silently exclude them. Always inspect `git status` for untracked or unstaged entries before staging.
2. **After any rename or string substitution, verify both source and generated output**: A clean source grep is not proof the change is complete — stale strings persist in artefacts produced from templates, script-emitted text, or rendered documentation. After renaming, grep the entire codebase for the old string, then generate at least one sample output artefact and grep that too. Both checks are required; neither is sufficient alone.

```

### Step 2: Verify No Other Sections Disturbed
- [ ] Diff should show only the new `## Gotchas` block inserted
- [ ] All existing sections (Scope & Boundaries, Context, Workflow, Success Criteria) byte-identical
- [ ] Front-matter unchanged

### Step 3: Project-Neutrality Check
- [ ] Both gotchas contain no "Task NNN", branch names, or commit hashes
- [ ] Wording is generic — applies in any downstream project that installs the skill

## Validation Criteria
- [ ] Pre-condition (before edit): no existing `## Gotchas` section in `cwf-implementation-exec/SKILL.md` — insertion is one-shot, not idempotent
- [ ] `## Gotchas` section present in `cwf-implementation-exec/SKILL.md` with exactly 2 numbered items
- [ ] Section sits between front-matter and `## Scope & Boundaries` (matches sibling-skill placement)
- [ ] `grep -E "Task [0-9]+" .claude/skills/cwf-implementation-exec/SKILL.md` returns zero matches
- [ ] No changes outside the inserted section

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Plan applied with three plan-review revisions before exec:
1. Gotcha 1 reworded to explicitly mention "untracked or unstaged" (plan review, R3).
2. Gotcha 2 reworded to require source-grep first then output-grep, both required (plan review, R3).
3. Pre-existence validation criterion added (plan review, R3).
After plan review, user prose review replaced "rebrand" with "rename or string substitution".
Implementation step was a single Edit anchored on `## Scope & Boundaries`.

## Lessons Learned
Plan review caught structural/content issues; user review caught prose imprecision.
Both gates were needed — plan review alone would have shipped "rebrand".
