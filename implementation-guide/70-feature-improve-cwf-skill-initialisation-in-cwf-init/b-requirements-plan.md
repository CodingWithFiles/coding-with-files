# Improve CWF skill initialisation in cwf-init - Requirements
**Task**: 70 (feature)

## Task Reference
- **Task ID**: internal-70
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/70-improve-cwf-skill-initialisation-in-cwf-init
- **Template Version**: 2.1

## Goal
Define what `cwf-init` must do to produce a fully-functional CWF environment from a fresh project.

## Functional Requirements

### FR1 — Skill Permissions Registration
`cwf-init` MUST offer to register all CWF skill permissions in the project's `.claude/settings.json`.
- Ask the user before modifying any file
- Read existing `.claude/settings.json` if present; create minimal structure if absent
- Add each `Skill(cwf-<name>)` entry to `permissions.allow`, skipping any already present
- List which skills are being added before doing so
- Preserve all existing permissions entries

### FR2 — CLAUDE.md Enforcement Preamble
`cwf-init` MUST add a CWF enforcement preamble to the project's `CLAUDE.md`.
- If `CLAUDE.md` exists: prepend the block, preserve all existing content
- If `CLAUDE.md` absent: create it with the preamble block
- Preamble MUST state:
  - CWF is installed — invoke skills via the `Skill` tool, do not manually follow SKILL.md instructions
  - All workflow steps must be executed; mark as `Skipped` if genuinely inapplicable

### FR3 — Init Commit Reminder
`cwf-init` MUST explicitly instruct the agent to create a commit after init completes, before any task work begins.
- The instruction must be a numbered step in the workflow, not a footnote
- Must specify what to stage: all files created/modified during init

## Non-Functional Requirements

### NFR1 — Idempotency
Running `cwf-init` a second time must not duplicate permissions entries or duplicate the CLAUDE.md preamble. Each step must check before adding.

### NFR2 — Safety
No user file may be silently overwritten. The permissions step MUST ask the user before writing `.claude/settings.json` or `CLAUDE.md`.

### NFR3 — Consistency
The skill permissions list must be derived from `.claude/skills/cwf-*/` directories at init time, not hardcoded. This ensures the list stays current as skills are added or removed.

## Constraints
- Changes to `cwf-init/SKILL.md` only — no new scripts or library code
- `.claude/settings.json` JSON must remain valid after modification
- Must work whether or not `.claude/settings.json` or `CLAUDE.md` already exist

## Acceptance Criteria
- [ ] AC1: After `cwf-init`, agent is not prompted when calling any `cwf-*` skill (permissions registered)
- [ ] AC2: Existing `.claude/settings.json` permissions are unchanged after merge
- [ ] AC3: `CLAUDE.md` contains the enforcement preamble and all pre-existing content
- [ ] AC4: Running `cwf-init` twice does not duplicate any permission or preamble block
- [ ] AC5: The init workflow includes a numbered step instructing an initial commit

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 70
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
