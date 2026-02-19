# Improve CWF skill initialisation in cwf-init - Maintenance
**Task**: 70 (feature)

## Task Reference
- **Task ID**: internal-70
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/70-improve-cwf-skill-initialisation-in-cwf-init
- **Template Version**: 2.1

## Goal
Document ongoing maintenance considerations for the cwf-init skill changes.

## Monitoring Requirements

No runtime monitoring — this is a skill instruction file. Maintenance is observational: watch for agent behaviour that deviates from the new instructions.

### Signals to watch for
- Agent prompted on skill calls after `cwf-init` (indicates step 6 wasn't completed or failed silently)
- CLAUDE.md preamble duplicated (indicates idempotency check not followed)
- Init commit skipped before task work (indicates step 8 wording insufficient)
- Agent writes `.claude/settings.json` without user confirmation (NFR2 violation)

## Maintenance Tasks

### If a new CWF skill is added
- No change needed — step 6 uses `ls .claude/skills/cwf-*/` dynamically; the new skill appears automatically on next `cwf-init` run

### If the CLAUDE.md preamble wording needs updating
- Edit the blockquote in step 4 of `cwf-init/SKILL.md`
- Update the idempotency grep pattern if the first line changes (currently `CWF.*is installed`)

### If `.claude/settings.json` structure changes in a future Claude Code version
- Step 6 merge logic assumes `permissions.allow` array — verify this remains valid
- Update the step 6 JSON skeleton if the schema changes

## Incident Response

### Agent still prompted on skill calls after cwf-init
- **Symptom**: Skill calls trigger user confirmation prompts in a freshly initialised project
- **Diagnosis**: Check `.claude/settings.json` at git root — verify `permissions.allow` contains `Skill(cwf-*)` entries
- **Resolution**: Re-run `cwf-init` step 6 manually, or add permissions entries directly

### CLAUDE.md preamble appears twice
- **Symptom**: Two blockquote preamble blocks in CLAUDE.md
- **Diagnosis**: Idempotency check (`grep -q "CWF.*is installed"`) wasn't run, or grep pattern didn't match
- **Resolution**: Remove the duplicate block; investigate why the idempotency check failed (encoding issue? different wording?)

### Init commit not made before task work
- **Symptom**: Task work committed before "Initialise CWF project configuration" commit
- **Diagnosis**: Agent skipped step 8 or treated it as optional despite "do not begin task work" wording
- **Resolution**: Commit manually; consider whether stronger wording is needed in step 8

## Success Criteria
- [x] Maintenance considerations documented
- [x] No runtime infrastructure required
- [x] Future skill additions handled automatically via dynamic enumeration

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 70
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance requirements are minimal — single skill file, no runtime dependencies.

## Lessons Learned
*To be captured during retrospective*
