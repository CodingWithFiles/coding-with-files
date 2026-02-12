# Test context injection syntax - Implementation Plan
**Task**: 55 (discovery)

## Task Reference
- **Task ID**: internal-55
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/55-test-context-injection-syntax
- **Template Version**: 2.1

## Goal
Define the concrete steps to create test skills and execute the context injection syntax experiment.

## Workflow
Create test skills → Invoke each skill → Observe output → Record results → Clean up

## Files to Modify
### Primary Changes
- `.claude/skills/cig-test-bash-block/SKILL.md` — **CREATE** — test skill for `!{bash}` syntax
- `.claude/skills/cig-test-inline-inject/SKILL.md` — **CREATE** — test skill for `!` path syntax
- `f-implementation-exec.md` — Record experiment results

### Supporting Changes
- None — test skills are temporary and will be deleted after experiment

## Implementation Steps

### Step 1: Create Test Skill for `!{bash}` Block Syntax

Create `.claude/skills/cig-test-bash-block/SKILL.md`:

```markdown
---
name: cig-test-bash-block
description: Test bash block context injection syntax in SKILL.md
user-invocable: true
allowed-tools:
  - Read
  - Bash
---

# Context Injection Test: !{bash} Block

## Test 1: Simple echo command

The following line should show "INJECTION_TEST_MARKER_1234" if !{bash} works:

!{bash}
echo "INJECTION_TEST_MARKER_1234"

## Test 2: CIG helper script

The following should show git repo root if !{bash} works with scripts:

!{bash}
.cig/scripts/command-helpers/context-manager location

## Instructions

Report what you see above:
1. Do you see "INJECTION_TEST_MARKER_1234" in Test 1? (YES/NO)
2. Do you see git repo root output in Test 2? (YES/NO)
3. Do you see the raw `!{bash}` syntax literally? (YES/NO)
```

### Step 2: Create Test Skill for `!` Path Syntax

Create `.claude/skills/cig-test-inline-inject/SKILL.md`:

```markdown
---
name: cig-test-inline-inject
description: Test inline context injection syntax in SKILL.md
user-invocable: true
allowed-tools:
  - Read
---

# Context Injection Test: ! Path Shorthand

## Test 1: Current task/workflow reference

The following should show current task context if ! path works:

**Current task/workflow**: !/current-task-wf

## Test 2: Inline with surrounding text

Before: !/current-task-wf :After

## Instructions

Report what you see above:
1. Do you see task context output in Test 1? (YES/NO)
2. Do you see task context inline in Test 2? (YES/NO)
3. Do you see the raw `!/current-task-wf` syntax literally? (YES/NO)
```

### Step 3: Invoke Test Skills

- [ ] Invoke `/cig-test-bash-block` and observe the expanded prompt
- [ ] Record whether marker text and script output appear
- [ ] Invoke `/cig-test-inline-inject` and observe the expanded prompt
- [ ] Record whether task context appears

### Step 4: Record Results in f-implementation-exec.md

Document for each test:
- What was expected
- What was observed
- PASS / FAIL / PARTIAL verdict
- Any differences from command behaviour

### Step 5: Clean Up Test Skills

- [ ] `rm -rf .claude/skills/cig-test-bash-block .claude/skills/cig-test-inline-inject`
- [ ] Verify cleanup: `ls .claude/skills/cig-test-*` should return "No such file or directory"

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
- [ ] Both test skills created and invocable via `/`
- [ ] Both syntaxes tested with observable results
- [ ] Results documented with PASS/FAIL verdicts
- [ ] Test skills cleaned up after experiment
- [ ] If any syntax fails, alternative approaches identified

## Status
**Status**: Finished
**Next Action**: /cig-testing-plan 55
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 5 implementation steps executed as planned. Both test skills created, invoked, and results recorded. Test skills cleaned up. No deviations from plan.

## Lessons Learned
- SKILL.md frontmatter is parsed correctly but the body is delivered as static text (no injection processing)
- Skills auto-detection is immediate — no restart or reload needed after creating SKILL.md files
