# Improve CWF skill initialisation in cwf-init - Implementation Plan
**Task**: 70 (feature)

## Task Reference
- **Task ID**: internal-70
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/70-improve-cwf-skill-initialisation-in-cwf-init
- **Template Version**: 2.1

## Goal
Implement three targeted changes to `.claude/skills/cwf-init/SKILL.md` per the approved design.

## Files to Modify

### Primary Changes
- `.claude/skills/cwf-init/SKILL.md` — all three changes are in this one file

## Implementation Steps

### Step 1: Extend Step 4 (Update CLAUDE.md) for FR2

Edit the existing "### 4. Update CLAUDE.md" section. Replace the current content:

```
### 4. Update CLAUDE.md
- Add CWF system integration hints
- Include section extraction commands
- Add standard section names reference
```

With:

```
### 4. Update CLAUDE.md
- Check for existing preamble (idempotency):
  `grep -q "CWF.*is installed" CLAUDE.md 2>/dev/null`
- **If preamble already present**: Skip — do not re-add
- **If absent**: Prepend the following block to CLAUDE.md (create file if it doesn't exist):
  ```markdown
  > **CWF (Coding with Files) is installed in this project.**
  > - Invoke CWF workflow steps using the `Skill` tool (e.g. `Skill("cwf-task-plan")`). Do not manually read or follow SKILL.md instructions directly.
  > - All workflow steps are mandatory. If a step is genuinely inapplicable, mark it `Skipped` via the workflow process — do not silently omit it.

  ```
- Preserve all existing CLAUDE.md content after the preamble
- Add CWF system integration hints, section extraction commands, and standard section names reference
```

### Step 2: Insert New Step 6 (Register Skill Permissions) for FR1

Insert a new "### 6. Register Skill Permissions" section between current steps 5 and 6. Renumber old step 6 → 7.

New step content:

```
### 6. Register Skill Permissions
- List available CWF skills: `ls .claude/skills/cwf-*/`
- Show user the list of `Skill(cwf-<name>)` entries that will be added to `.claude/settings.json`
- **Ask user to confirm** before writing any file
- Read existing `.claude/settings.json` if present; use `{"permissions":{"allow":[]}}` if absent
- Add each missing `Skill(cwf-<name>)` entry to `permissions.allow` — skip any already present
- Write back valid JSON to `.claude/settings.json`
- **Note**: This is the project-level `.claude/settings.json` (at git root), not the global `~/.claude/settings.json` used for PERL5OPT in step 7
```

### Step 3: Renumber Old Step 6 → 7

Change `### 6. Configure Claude Code Settings` to `### 7. Configure Claude Code Settings`.

### Step 4: Strengthen Old Step 7 → New Step 8 (Commit Init Output) for FR3

Change `### 7. Commit Init Output` to `### 8. Commit Init Output`.

Replace the current step 7 content:

```
- Stage all files created or modified by init:
  ```bash
  git add implementation-guide/ .gitignore
  ```
- Also stage CLAUDE.md if it was modified in step 4
- Offer to commit with message: "Initialise CWF project configuration"
- Follow the project's commit conventions (see `docs/conventions/commit-messages.md` if present)
```

With:

```
- Stage all files created or modified by init:
  ```bash
  git add implementation-guide/ .gitignore CLAUDE.md .claude/settings.json
  ```
- Create the init commit now:
  ```bash
  git commit -m "Initialise CWF project configuration"
  ```
- Follow the project's commit conventions (see `docs/conventions/commit-messages.md` if present)
- **Do not begin task work until this commit is made**
```

### Step 5: Update Success Criteria

Update the success criteria checklist at the bottom to reflect the new 8-step workflow:

Replace:
```
- [ ] .gitignore updated
- [ ] PERL5OPT checked and user informed only if not already configured
- [ ] Init output committed (or offered to user)
```

With:
```
- [ ] .gitignore updated
- [ ] Skill permissions registered in `.claude/settings.json` (with user confirmation)
- [ ] PERL5OPT checked and user informed only if not already configured
- [ ] Init commit created (mandatory — do not begin task work without it)
```

## Validation Criteria

**See e-testing-plan.md for complete test plan and results**

Quick sanity checks after editing:
- Step 4 contains the blockquote preamble content and idempotency check
- Step 6 exists between steps 5 and 7
- Step 7 is the renamed PERL5OPT step
- Step 8 is the renamed commit step with "Do not begin task work"
- Success criteria has 8 bullet points matching the 8 steps

## Scope Completion

All three changes (FR1, FR2, FR3) are in one file. No supporting scripts, no new files.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 70
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
