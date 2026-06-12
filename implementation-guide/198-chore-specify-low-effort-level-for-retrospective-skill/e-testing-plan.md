# specify low effort level for retrospective skill - Testing Plan
**Task**: 198 (chore)

## Task Reference
- **Task ID**: internal-198
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/198-specify-low-effort-level-for-retrospective-skill
- **Template Version**: 2.1

## Goal
Validate that `effort: low` was added correctly to the `cwf-retrospective` SKILL.md
frontmatter without breaking YAML validity or system integrity.

## Test Strategy
### Test Levels
- **Static checks**: YAML well-formedness of the edited frontmatter block.
- **Integrity check**: `cwf-manage validate` (system-wide regression check).
- Unit/integration/system/acceptance tiers are N/A — this is a single declarative
  frontmatter key, not executable code.

### Test Coverage Targets
- 100% of the change surface (one frontmatter key in one file) is checked.
- No coverage metric applies (no code paths added).

## Test Cases
### Functional Test Cases
- **TC-1**: `effort: low` present and correctly placed
  - **Given**: `.claude/skills/cwf-retrospective/SKILL.md` after the edit
  - **When**: read the leading `---`-delimited frontmatter block
  - **Then**: an `effort: low` line exists at column 0, between `description:` and
    `user-invocable:`, matching the Task 187 exec-skill layout

- **TC-2**: Frontmatter is valid YAML
  - **Given**: the edited SKILL.md
  - **When**: extract and parse the frontmatter block (column-0 top-level keys, same
    indentation as `name:`/`description:`)
  - **Then**: it parses with no syntax error; `effort` value is one of the documented
    options (`low|medium|high|xhigh|max`) — here, `low`

- **TC-3**: System integrity preserved
  - **Given**: the edited working tree
  - **When**: run `.cwf/scripts/cwf-manage validate`
  - **Then**: output is `validate: OK` — no sha256 drift, no permission drift
    (the skill is not in the manifest, so this is a whole-system regression check)

- **TC-4**: Skill still resolves
  - **Given**: the edited SKILL.md
  - **When**: confirm the `name:` key and body are unchanged apart from the inserted line
  - **Then**: the skill metadata is intact (no accidental edit to other keys/body)

### Non-Functional Test Cases
- **Harness honour (out of scope, documented limitation)**: `validate` cannot prove the
  harness honours `effort`; an unrecognised key degrades to a silent no-op (per Task 187
  empirical evidence). No automated test asserts the effort level actually changed.
- Performance/security/usability tiers: N/A for a declarative metadata key.

## Test Environment
### Setup Requirements
- The task working tree on branch `chore/198-...`; no test data, services, or DB.

### Automation
- Manual execution of the four TCs during g-testing-exec; no CI hook required.

## Validation Criteria
- [ ] TC-1 — `effort: low` present and correctly placed
- [ ] TC-2 — frontmatter parses as valid YAML, value is documented
- [ ] TC-3 — `cwf-manage validate` reports `validate: OK`
- [ ] TC-4 — no collateral edit to other frontmatter keys or skill body

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four test cases PASS (see g-testing-exec.md): TC-1 placement, TC-2 valid YAML/documented
value, TC-3 `validate: OK`, TC-4 single-line diff with no collateral edits. Both exec-phase
security reviews returned `no findings`.

## Lessons Learned
The documented harness-honour gap remains untestable by design; carried as an accepted
limitation rather than a failing test. See j-retrospective.md.
