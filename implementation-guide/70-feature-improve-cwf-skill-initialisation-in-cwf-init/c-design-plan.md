# Improve CWF skill initialisation in cwf-init - Design
**Task**: 70 (feature)

## Task Reference
- **Task ID**: internal-70
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/70-improve-cwf-skill-initialisation-in-cwf-init
- **Template Version**: 2.1

## Goal
Design the changes to `cwf-init/SKILL.md` that satisfy FR1–FR3.

## Current Structure (cwf-init SKILL.md)

Steps 1–7 currently:
1. Create Directory Structure
2. Generate Project Configuration
3. Create Navigation
4. Update CLAUDE.md — *extend here for FR2*
5. Configure .gitignore
6. Configure Claude Code Settings (PERL5OPT in `~/.claude/settings.json`)
7. Commit Init Output — *strengthen here for FR3*

New step inserted between 5 and 6 for FR1.

## Proposed Step Changes

### Step 4: Update CLAUDE.md (extend for FR2)

Extend the existing CLAUDE.md step to **prepend** an enforcement preamble block. Check for idempotency first.

**Preamble content**:
```markdown
> **CWF (Coding with Files) is installed in this project.**
> - Invoke CWF workflow steps using the `Skill` tool (e.g. `Skill("cwf-task-plan")`). Do not manually read or follow SKILL.md instructions directly.
> - All workflow steps are mandatory. If a step is genuinely inapplicable, mark it `Skipped` via the workflow process — do not silently omit it.
```

**Idempotency**: Check `grep -q "CWF.*is installed" CLAUDE.md` before prepending. Skip if already present.

### New Step 6: Register Skill Permissions (FR1)

Insert between current steps 5 and 6 (PERL5OPT becomes step 7):

```
### 6. Register Skill Permissions
- List available CWF skills: ls .claude/skills/cwf-*/
- Inform user which skills will be added to .claude/settings.json permissions.allow
- Ask user to confirm before writing
- Read existing .claude/settings.json (or start with minimal structure)
- Merge Skill(cwf-<name>) entries — skip any already present
- Write back valid JSON
```

**`.claude/settings.json` target structure**:
```json
{
  "permissions": {
    "allow": [
      "Skill(cwf-config)",
      "Skill(cwf-current-task)",
      "Skill(cwf-design-plan)",
      ...
    ]
  }
}
```

**Idempotency**: Read existing `permissions.allow` array, only append missing entries.

**Note**: This is the project-level `.claude/settings.json` (at git root), not the global `~/.claude/settings.json` used for PERL5OPT in step 7.

### Step 8: Commit Init Output (strengthen for FR3)

Current step 7 already mentions committing but buries it. Strengthen to make it unambiguous:

- Rename "Offer to commit" → explicit numbered instruction: **"Create the init commit now"**
- Extend `git add` to include `.claude/settings.json` and `CLAUDE.md` (now always modified)
- Add: "Do not begin task work until this commit is made"

## Renumbered Workflow

| # | Step | Change |
|---|------|--------|
| 1 | Create Directory Structure | Unchanged |
| 2 | Generate Project Configuration | Unchanged |
| 3 | Create Navigation | Unchanged |
| 4 | Update CLAUDE.md | Extended: prepend enforcement preamble |
| 5 | Configure .gitignore | Unchanged |
| 6 | Register Skill Permissions | **New** |
| 7 | Configure Claude Code Settings (PERL5OPT) | Renumbered only |
| 8 | Commit Init Output | Strengthened: mandatory, not optional |

## Design Decisions

### Why extend Step 4 rather than a new step for CLAUDE.md?
CLAUDE.md is already being written in step 4. Adding the preamble there keeps related work together.

### Why project `.claude/settings.json`, not global `~/.claude/settings.json`?
Skill permissions are project-specific — other projects shouldn't get CWF skills auto-allowed. The global file already handles PERL5OPT (step 7), keeping concerns separate.

### Why ask before writing permissions?
NFR2 (safety). Users may have deliberate permission restrictions. Silent modification of settings files violates the principle of least surprise.

### Why "Create the init commit now" rather than "offer to commit"?
FR3 / NFR from task 63: agents skip the commit when it's framed as optional. Making it a mandatory numbered step with "do not begin task work until this commit is made" removes ambiguity.

## Decomposition Check
- [ ] Time: >1 week? — No
- [ ] People: >2? — No
- [ ] Complexity: 3+ concerns? — Yes, but all in one file, no isolation benefit
- [ ] Risk: High-risk? — No
- [ ] Independence: Separable? — No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 70
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
