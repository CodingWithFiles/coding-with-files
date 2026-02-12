# Test context injection syntax - Design
**Task**: 55 (discovery)

## Task Reference
- **Task ID**: internal-55
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/55-test-context-injection-syntax
- **Template Version**: 2.1

## Goal
Design the test skills and experiment procedure for verifying context injection syntax in SKILL.md format.

**Note**: Discovery task — design defines experiment structure, not software architecture.

## Key Decisions

### Test Skill Design
- **Decision**: Create two minimal test skills in `.claude/skills/`, each testing one syntax
- **Rationale**: Isolating each syntax in its own skill makes pass/fail attribution unambiguous
- **Trade-offs**: Could test both in one skill, but separate skills give cleaner evidence

### Syntax Patterns to Test

CIG commands use two context injection patterns:

**Pattern 1: `!{bash}` block** — executes a command and injects stdout into the prompt
```
!{bash}
.cig/scripts/command-helpers/context-manager location
```
Used in: every CIG workflow command (location check at start of execution)

**Pattern 2: `!` path shorthand** — injects content from a file or command path
```
**Current task/workflow (if available)**: !/current-task-wf
```
Used in: workflow commands for loading current task context

### Test Skill Names
- `cig-test-bash-block` — tests `!{bash}` block syntax
- `cig-test-inline-inject` — tests `!` path/inline syntax

Both prefixed with `cig-test-` to avoid clashing with existing CIG commands and to make cleanup easy (`rm -rf .claude/skills/cig-test-*`).

## Component Design

### Skill 1: `cig-test-bash-block`

**File**: `.claude/skills/cig-test-bash-block/SKILL.md`

**Frontmatter**:
```yaml
---
name: cig-test-bash-block
description: Test !{bash} context injection syntax in SKILL.md
user-invocable: true
allowed-tools:
  - Read
  - Bash
---
```

**Body** — tests two levels:
1. **Simple command**: `!{bash}\necho "INJECTION_TEST_MARKER_1234"` — if we see `INJECTION_TEST_MARKER_1234` in the expanded prompt, the syntax works
2. **CIG helper script**: `!{bash}\n.cig/scripts/command-helpers/context-manager location` — tests real-world usage

### Skill 2: `cig-test-inline-inject`

**File**: `.claude/skills/cig-test-inline-inject/SKILL.md`

**Frontmatter**:
```yaml
---
name: cig-test-inline-inject
description: Test inline context injection syntax in SKILL.md
user-invocable: true
allowed-tools:
  - Read
---
```

**Body** — tests the `!` path pattern:
1. **File reference**: `!/current-task-wf` — the same pattern CIG commands use
2. **Inline with label**: `**Test output**: !/current-task-wf` — tests inline embedding

## Data Flow

1. User invokes `/cig-test-bash-block`
2. Claude Code loads SKILL.md, processes context injection syntax (or doesn't)
3. Expanded prompt delivered to LLM
4. LLM observes whether injection markers/output are present
5. LLM reports PASS/FAIL based on observed content
6. Repeat for `/cig-test-inline-inject`

## Validation
- [ ] Test skill file structure matches existing skill patterns (see `test-cig-skill/SKILL.md`)
- [ ] Marker strings are unique enough to avoid false positives
- [ ] Both skills can be cleaned up with a single `rm -rf` pattern

## Decomposition Check
- [ ] **Time**: NO
- [ ] **People**: NO
- [ ] **Complexity**: NO
- [ ] **Risk**: NO
- [ ] **Independence**: NO

## Status
**Status**: Finished
**Next Action**: /cig-implementation-plan 55
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Test skill design worked as intended. SKILL.md frontmatter parsed correctly, skills detected immediately, marker strings were unambiguous. The `cig-test-` naming prefix made cleanup pattern straightforward.

## Lessons Learned
- Using unique marker strings (e.g., "INJECTION_TEST_MARKER_1234") makes PASS/FAIL judgement trivially easy
- Designing for cleanup from the start (common prefix) prevents test artefact leakage
