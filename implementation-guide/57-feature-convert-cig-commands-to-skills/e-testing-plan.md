# Convert CIG Commands to Skills - Testing Plan
**Task**: 57 (feature)

## Task Reference
- **Task ID**: internal-57
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/57-convert-cig-commands-to-skills
- **Template Version**: 2.1

## Goal
Verify that all 17 converted skills function correctly, constraint context is preserved, and no regressions are introduced.

## Test Strategy

### Test Levels
- **Structural validation**: Verify skill files exist with correct format, frontmatter, and references
- **Constraint context verification**: Verify mandatory runtime instructions are present and no injection syntax remains
- **Functional invocation**: Invoke sample skills and verify correct behaviour
- **Regression**: Verify no commands remain, shared docs renamed, no orphaned references

### Coverage Targets
- **Structural**: All 17 skills checked (100%)
- **Constraint context**: All 10 mandatory runtime instructions verified present, all 15 Pattern C injections verified absent
- **Functional invocation**: At least 3 skills invoked (1 workflow, 1 task management, 1 system) — including cig-new-task (FR8)
- **Regression**: All file system assertions verified

### Approach
Mixed automated/manual testing. Structural and regression checks via grep/ls/wc (automated). Functional invocation is manual (skills are LLM-invoked).

## Test Cases

### Structural Tests (TC-1 to TC-4)

- **TC-1**: All 17 skill directories and SKILL.md files exist
  - **Given**: Conversion complete
  - **When**: `ls .claude/skills/cig-*/SKILL.md | wc -l`
  - **Then**: Returns 17

- **TC-2**: All SKILL.md files have valid YAML frontmatter
  - **Given**: All 17 SKILL.md files
  - **When**: Check each for `---` delimiters, `name:`, `description:`, `user-invocable: true`, `allowed-tools:`
  - **Then**: All 17 have all 4 required fields

- **TC-3**: No command files remain
  - **Given**: Conversion complete
  - **When**: `ls .claude/commands/cig-*.md 2>/dev/null | wc -l`
  - **Then**: Returns 0

- **TC-4**: Shared docs directory renamed
  - **Given**: FR6 executed
  - **When**: Check `.cig/docs/skills/` exists with 3 files, `.cig/docs/commands/` does not exist
  - **Then**: 3 files in skills/, error on commands/

### Constraint Context Tests (TC-5 to TC-9)

- **TC-5**: No injection syntax in any skill
  - **Given**: All 17 SKILL.md files
  - **When**: `grep -r '!{bash}\|!`\|!/' .claude/skills/cig-*/SKILL.md`
  - **Then**: 0 matches

- **TC-6**: Pattern A replacement — all 17 skills have context-manager runtime instruction
  - **Given**: All 17 SKILL.md files
  - **When**: Grep for `context-manager location` instruction text
  - **Then**: 17 matches (one per skill)

- **TC-7**: Pattern B replacement — 10 workflow skills have task-context-inference runtime instruction
  - **Given**: 10 workflow SKILL.md files
  - **When**: Grep for `task-context-inference` instruction text
  - **Then**: 10 matches

- **TC-8**: Mandatory Pattern C runtime instructions present (10 injections)
  - **Given**: 6 skills with Pattern C mandatory instructions
  - **When**: Check each skill for its mandatory runtime instructions:
    - cig-subtask: `context-manager hierarchy` and `context-manager inheritance` instructions
    - cig-status: `workflow-manager status` instruction
    - cig-config: `ls` config check and `cig-load-autoload-config` instructions
    - cig-security-check: `cig-load-project-config` and `find` instructions
    - cig-init: `ls implementation-guide` instruction
  - **Then**: All 10 mandatory instructions present in their respective skills

- **TC-9**: No skill references `.cig/docs/commands/` (old path)
  - **Given**: All 17 SKILL.md files
  - **When**: `grep -r 'docs/commands' .claude/skills/cig-*/SKILL.md`
  - **Then**: 0 matches (all should reference `.cig/docs/skills/`)

### Functional Tests (TC-10 to TC-12)

- **TC-10**: Workflow skill invocation — `/cig-status 57`
  - **Given**: cig-status converted to skill, Task 57 exists
  - **When**: Invoke `/cig-status 57`
  - **Then**: Skill resolves, runs `workflow-manager status` via Bash tool (mandatory context), displays progress tree. Behaviour equivalent to command version.

- **TC-11**: Task management skill — `/cig-new-task` (FR8 regression fix)
  - **Given**: cig-new-task converted to skill
  - **When**: Invoke `/cig-new-task 99 chore "Test task creation"`
  - **Then**: No permission errors. Skill creates task directory and files via `task-workflow create`. Clean up test task after verification.

- **TC-12**: System skill invocation — `/cig-config list`
  - **Given**: cig-config converted to skill
  - **When**: Invoke `/cig-config list`
  - **Then**: Skill runs config discovery (ls, autoload-config) via Bash tool (mandatory context), displays config hierarchy.

### Metrics Tests (TC-13 to TC-14)

- **TC-13**: Token budget — total skill content
  - **Given**: All 17 SKILL.md files
  - **When**: `wc -l .claude/skills/cig-*/SKILL.md`
  - **Then**: Total under 850 lines (comparable to 782-line command baseline). Document actual count.

- **TC-14**: Per-skill size consistency
  - **Given**: All 17 SKILL.md files
  - **When**: `wc -l .claude/skills/cig-*/SKILL.md | sort -n`
  - **Then**: All skills under 60 lines. Workflow skills within ±10 lines of each other (consistent template).

## Test Environment

### Setup Requirements
- Claude Code with skills support
- Task 57 directory with workflow files
- All 17 skills in `.claude/skills/`
- Shared docs in `.cig/docs/skills/`
- Task 99 available for cig-new-task test (clean up after)

### Automation
- Structural and constraint tests: automated via grep, ls, wc
- Functional tests: manual skill invocation
- Metrics: automated via wc

## Validation Criteria
- [ ] TC-1 to TC-4: Structural checks pass (17 skills, 0 commands, docs renamed)
- [ ] TC-5 to TC-9: Constraint context verified (no injection syntax, all mandatory instructions present)
- [ ] TC-10 to TC-12: Functional invocations succeed
- [ ] TC-13 to TC-14: Token budget within targets

## Status
**Status**: Finished
**Next Action**: /cig-implementation-exec 57
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
