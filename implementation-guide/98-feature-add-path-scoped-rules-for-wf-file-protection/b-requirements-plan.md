# Add path-scoped rules for wf file protection - Requirements
**Task**: 98 (feature)

## Task Reference
- **Task ID**: internal-98
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/98-add-path-scoped-rules-for-wf-file-protection
- **Template Version**: 2.1

## Goal
Specify what the path-scoped rules must do, how they integrate with the install pipeline, and how we verify they work.

## Functional Requirements
### Core Features
- **FR1**: Rule file `.claude/rules/workflow-files.md` must exist with YAML frontmatter containing a `globs` field that matches wf step files in any task directory depth
- **FR2**: Rule text must map each wf step file prefix (a through j) to the correct `/cwf-{step}` skill name, so the agent knows which skill to invoke
- **FR3**: `/cwf-init` must create `.claude/rules/` directory and copy rule files into the target project during initialisation
- **FR4**: `install.bash` must include `.claude/rules/` in the set of files copied from the CWF source to the target project
- **FR5**: Rule must auto-load when the agent operates on a file matching the glob pattern — no manual invocation required

### User Stories
- **As an** agent working on a CWF project **I want** to see a reminder to use the correct skill **so that** I don't bypass the skill and edit wf step files directly
- **As a** CWF installer **I want** rules to be copied during `/cwf-init` **so that** the protection is active from first use

## Non-Functional Requirements
### Context Efficiency (NFR1)
- Rule text must be concise: under 20 lines of content (excluding frontmatter)
- No explanatory prose — skill name mapping only
- Rationale: rules auto-load on every matching file operation and consume context tokens each time

### Portability (NFR2)
- Rule file must work in any project where CWF is installed
- Glob pattern must handle both flat and nested task directory structures
- No assumptions about absolute paths or project-specific configuration

### Maintainability (NFR3)
- If new workflow steps are added in future, the rule file must be the single place to update the step-to-skill mapping
- Rule file must be self-documenting (mapping is obvious from reading the file)

## Constraints
- Advisory only — rules guide the agent but cannot enforce compliance (established in Task 97)
- Claude Code rules mechanism requires YAML frontmatter with `globs` or `description` fields
- Must not conflict with existing `.claude/settings.json` or `.claude/settings.local.json`

## Decomposition Check
0/5 signals triggered — no decomposition needed.

## Acceptance Criteria
- [ ] AC1: `.claude/rules/workflow-files.md` exists with valid frontmatter and glob pattern
- [ ] AC2: Rule text correctly maps all 10 step prefixes (a-j) to skill names
- [ ] AC3: `/cwf-init` creates `.claude/rules/` and copies rule file
- [ ] AC4: `install.bash` includes `.claude/rules/` in installed file set
- [ ] AC5: Rule content is under 20 lines (context efficiency)
- [ ] AC6: Glob pattern matches wf step files in both top-level and nested task directories

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 98
**Blockers**: None

## Actual Results
All requirements met. Rule file redirects edits to corresponding skills. Glob pattern covers all 10 wf step prefixes across nested task hierarchies.

## Lessons Learned
Keep rule content minimal — one mapping table is sufficient. Verbose instructions increase token cost on every matched file.
