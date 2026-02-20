# Update branding and documentation for skills architecture - Plan
**Task**: 79 (bugfix)

## Task Reference
- **Task ID**: internal-79
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/79-update-branding-and-documentation-for-skills-architectur
- **Template Version**: 2.1

## Goal
Remove all stale "commands" terminology from user-facing documentation and replace
it with accurate "skills" terminology, including correcting outdated skill names in
CLAUDE.md.

## Success Criteria
- [ ] CLAUDE.md "Available CWF Commands" section renamed to "Available CWF Skills"
  with correct current skill names
- [ ] CLAUDE.md "commands" terminology replaced with "skills" throughout
- [ ] README.md "slash commands" references updated to "skills"
- [ ] No remaining stale `/cwf-plan`, `/cwf-requirements`, `/cwf-implementation`,
  `/cwf-testing`, `/cwf-rollout`, `/cwf-maintenance`, `/cwf-retrospective` references
  in user-facing docs (these are the old v2.0 names, replaced by the `-plan`/`-exec`
  split in v2.1)
- [ ] `grep -r "CWF Commands\|slash commands" CLAUDE.md README.md` returns no matches

## Original Estimate
**Effort**: <1 session
**Complexity**: Low — text replacements in two files
**Dependencies**: None

## Known Issues Found in Audit

### CLAUDE.md
- Line 13: "commands reference docs" → "skills reference docs"
- Line 22: "### Available CWF Commands" → "### Available CWF Skills"
- Lines 24, 31, 41: section headers "Core Commands", "Workflow Commands",
  "Utility Commands" → "Core Skills", "Workflow Skills", "Utility Skills"
- Lines 32–39: stale v2.0 skill names listed:
  - `/cwf-plan` → `/cwf-task-plan`
  - `/cwf-requirements` → `/cwf-requirements-plan`
  - `/cwf-design` → `/cwf-design-plan`
  - `/cwf-implementation` → `/cwf-implementation-plan` + `/cwf-implementation-exec`
  - `/cwf-testing` → `/cwf-testing-plan` + `/cwf-testing-exec`
  - `/cwf-rollout` → `/cwf-rollout`  *(unchanged)*
  - `/cwf-maintenance` → `/cwf-maintenance`  *(unchanged)*
  - `/cwf-retrospective` → `/cwf-retrospective`  *(unchanged)*
- Line 78: "Use the designated commands instead" → "Use the designated skills instead"

### README.md
- Line 3: "slash commands" → "skills"
- Line 9: "slash commands" → "skills"
- Line 196: "Test all commands before submission" → "Test all skills before submission"

## Major Milestones
1. Fix CLAUDE.md — terminology and skill names
2. Fix README.md — terminology
3. Verify no remaining stale references

## Risk Assessment
### Low Priority Risks
- **Wrong replacements**: Replacing "command" in `.cwf/scripts/command-helpers/`
  path references — those are script directory names, not user-facing terminology,
  and should be left as-is
  - **Mitigation**: Edit only the user-facing prose sections, not path strings

## Constraints
- `.cwf/scripts/command-helpers/` directory name is not being renamed — only
  documentation prose is changing
- Skill names in CLAUDE.md must match the actual skills listed in settings.local.json

## Decomposition Check
- [ ] **Time**: <1 session — no decomposition needed
- [ ] **People**: Single-agent
- [ ] **Complexity**: One concern — text corrections in two files
- [ ] **Risk**: No risk requiring isolation
- [ ] **Independence**: N/A

**Result**: 0 signals. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 79
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All success criteria met. CLAUDE.md section headers, skill list, and prose updated;
README.md "slash commands" references replaced. Zero regressions; 158 tests pass.

## Lessons Learned
Pre-auditing exact line numbers before writing the plan doc makes implementation
a straightforward checklist rather than a search exercise.
