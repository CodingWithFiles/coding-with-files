# Convert CIG Commands to Skills - Maintenance
**Task**: 57 (feature)

## Task Reference
- **Task ID**: internal-57
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/57-convert-cig-commands-to-skills
- **Template Version**: 2.1

## Goal
Document ongoing maintenance considerations for the skills architecture.

## Maintenance Tasks

### When Adding a New Skill
1. Create `.claude/skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`, `user-invocable`, `allowed-tools`)
2. Include Pattern A runtime instruction: `context-manager location` via Bash tool
3. If workflow skill: include Pattern B runtime instruction: `task-context-inference` via Bash tool
4. If skill needs runtime data: add "Mandatory context" section with Bash tool instructions (Pattern C)
5. Reference shared docs via `.cig/docs/skills/` (not `.cig/docs/commands/`)
6. Verify `/cig-security-check` passes with new skill included

### When Modifying a Skill
- Keep under 60 lines where possible (workflow skills: 48-55 target)
- No injection syntax (`!{bash}`, `` !` ``, `!/path`) — runtime tool calls only
- Update CLAUDE.md command list if skill name or description changes

### Periodic Checks
- **Per task**: Skills invoke correctly (verified by using them during the task)
- **Monthly**: Run `/cig-security-check` to verify integrity
- **After Claude Code updates**: Verify skills system behaviour hasn't changed (frontmatter fields, auto-loading, tool permissions)

## Known Issues and Resolutions

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| Skill not listed in system prompt | `/skill-name` doesn't work | Check YAML frontmatter has `user-invocable: true` and `---` delimiters |
| Permission prompt on Bash calls | Unexpected "Allow?" during skill | Add the tool to `allowed-tools` in frontmatter |
| Context injection not working | `!{bash}` literal text in output | Replace with runtime instruction ("Run X using the Bash tool") |
| Duplicate skill/command conflict | Unpredictable behaviour | Delete the command file — no parallel operation |
| Token budget creep | Slow initial response | Check `wc -l .claude/skills/cig-*/SKILL.md` — total should stay under ~1000 lines |

## Architecture Reference

### File Layout
```
.claude/skills/cig-*/SKILL.md    — 18 skill files (17 converted + cig-current-task)
.cig/docs/skills/                 — 3 shared docs (workflow-preamble, checkpoint-commit, retrospective-extras)
.cig/scripts/command-helpers/     — Perl helper scripts (trampolines + modules + libraries)
```

### Patterns
- **Pattern A** (all 17 skills): `context-manager location` runtime instruction
- **Pattern B** (10 workflow skills): `task-context-inference` runtime instruction
- **Pattern C** (6 skills): Mandatory runtime instructions for skill-specific data

## Success Criteria
- [x] Maintenance procedures documented
- [x] Known issues catalogued with resolutions
- [x] Architecture reference captured for future developers

## Status
**Status**: Finished
**Next Action**: `/cig-retrospective 57`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

Maintenance is lightweight — skills are static markdown files with no runtime dependencies beyond the existing helper scripts. The main risk is Claude Code changing skills system behaviour in future updates.

## Lessons Learned

The template's monitoring/alerting/SLA sections don't apply to internal tooling. Future maintenance templates could have a "lightweight" variant for internal tasks.
