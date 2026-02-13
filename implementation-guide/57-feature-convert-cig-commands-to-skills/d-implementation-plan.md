# Convert CIG Commands to Skills - Implementation Plan
**Task**: 57 (feature)

## Task Reference
- **Task ID**: internal-57
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/57-convert-cig-commands-to-skills
- **Template Version**: 2.1

## Goal
Convert 17 CIG commands to SKILL.md format following the approved design (c-design-plan.md) and requirements (b-requirements-plan.md).

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes — Create (17 new SKILL.md files)
- `.claude/skills/cig-design-plan/SKILL.md`
- `.claude/skills/cig-task-plan/SKILL.md`
- `.claude/skills/cig-requirements-plan/SKILL.md`
- `.claude/skills/cig-implementation-plan/SKILL.md`
- `.claude/skills/cig-testing-plan/SKILL.md`
- `.claude/skills/cig-implementation-exec/SKILL.md`
- `.claude/skills/cig-testing-exec/SKILL.md`
- `.claude/skills/cig-retrospective/SKILL.md`
- `.claude/skills/cig-maintenance/SKILL.md`
- `.claude/skills/cig-rollout/SKILL.md`
- `.claude/skills/cig-new-task/SKILL.md`
- `.claude/skills/cig-subtask/SKILL.md`
- `.claude/skills/cig-status/SKILL.md`
- `.claude/skills/cig-extract/SKILL.md`
- `.claude/skills/cig-init/SKILL.md`
- `.claude/skills/cig-config/SKILL.md`
- `.claude/skills/cig-security-check/SKILL.md`

### Primary Changes — Delete (17 command files)
- All `.claude/commands/cig-*.md` files (removed after corresponding skill created)

### Supporting Changes
- `.cig/docs/commands/` → `.cig/docs/skills/` (rename directory, FR6)

## Implementation Steps

### Step 1: Rename Shared Docs Directory (FR6)
```bash
git mv .cig/docs/commands/ .cig/docs/skills/
```
Must happen first — all new skills will reference `.cig/docs/skills/`.

### Step 2: Convert Template Skill — cig-design-plan (D1-D4)

Create `.claude/skills/cig-design-plan/SKILL.md` by translating the command:

**Frontmatter conversion** (D2):
```yaml
# Command frontmatter:
description: Guide user through design phase
argument-hint: {task-path}
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/*:*)...

# Skill frontmatter:
name: cig-design-plan
description: Guide user through design phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
```

**Context section conversion** (D4 — Patterns A + B):
```markdown
# Command version:
**Current task/workflow**: !/current-task-wf
!{bash}
.cig/scripts/command-helpers/context-manager location

# Skill version:
**Current task/workflow**: Run `.cig/scripts/command-helpers/task-context-inference` using the Bash tool.
**First**: Run `.cig/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.
```

**Body content**: Copy unchanged (scope, workflow, success criteria). Update doc references from `.cig/docs/commands/` to `.cig/docs/skills/`.

**Validation**: Delete `.claude/commands/cig-design-plan.md`. Verify `/cig-design-plan` appears in skill list.

### Step 3: Apply Pattern to Remaining 9 Workflow Skills

Convert remaining Group A commands using the template from Step 2:
- cig-task-plan
- cig-requirements-plan
- cig-implementation-plan
- cig-testing-plan
- cig-implementation-exec
- cig-testing-exec
- cig-retrospective
- cig-maintenance
- cig-rollout

Each follows the same conversion:
1. Create skill directory + SKILL.md with mapped frontmatter
2. Replace `!/current-task-wf` with runtime script instruction (Pattern B)
3. Replace `!{bash}` block with runtime instruction (Pattern A)
4. Update `.cig/docs/commands/` → `.cig/docs/skills/` in references
5. Copy body content unchanged
6. Delete corresponding command file

**cig-retrospective** has extra references to `.cig/docs/commands/retrospective-extras.md` — update path to `.cig/docs/skills/`.

### Step 4: Convert Group B — Task Management Skills (4 commands)

**cig-new-task** (FR8 — known broken):
- Remove Pattern C: `cig-load-project-config` — provably redundant (task-workflow create reads config internally; agent never uses raw output)
- Replace Pattern A: `!{bash}` block → runtime instruction
- Add argument hint in body: "Arguments: `<num> <type> "description"`"
- This is the FR8 regression fix — verify it invokes without permission errors

**cig-subtask**:
- Convert 2 Pattern C to mandatory runtime instructions:
  - `context-manager hierarchy ${ARGUMENTS%% *}` → "Run context-manager hierarchy using Bash tool" — constrains subtask placement
  - `context-manager inheritance ${ARGUMENTS%% *}` → "Run context-manager inheritance using Bash tool" — constrains subtask scope
- Remove 1 Pattern C: `cig-load-project-config` — provably redundant (task-workflow create reads internally)
- Replace Pattern A: `!{bash}` block → runtime instruction

**cig-status**:
- Convert 1 Pattern C to mandatory runtime instruction:
  - `workflow-manager status {arguments}` → "Run workflow-manager status using Bash tool" — this IS the primary output; without it the agent would guess
- Replace Pattern A: `!{bash}` block → runtime instruction

**cig-extract**:
- No Pattern C (only Patterns A + D)
- Replace Pattern A: `!{bash}` block → runtime instruction

### Step 5: Convert Group C — System Skills (3 commands)

**cig-init** (53 lines, already thin):
- Convert 1 Pattern C to mandatory runtime instruction:
  - `ls implementation-guide/` → "Run ls to check if implementation-guide/ exists" — constrains create-or-skip decision
- Remove 2 Pattern C: `pwd` and `git rev-parse --show-toplevel` — provably redundant (Pattern A context-manager location returns both)
- Replace Pattern A: `!{bash}` block → runtime instruction

**cig-config**:
- Convert 2 Pattern C to mandatory runtime instructions:
  - `ls ~/.cig/ .cig/` → "Run ls to check existing config directories" — constrains init/list/reset decisions
  - `cig-load-autoload-config` → "Run cig-load-autoload-config using Bash tool" — constrains modification decisions
- Remove 1 Pattern C: `git rev-parse --show-toplevel` — provably redundant (Pattern A context-manager location returns git root)
- Replace Pattern A: `!{bash}` block → runtime instruction

**cig-security-check**:
- Convert 4 Pattern C to mandatory runtime instructions:
  - `cig-load-project-config` → "Run cig-load-project-config using Bash tool" — constrains what to verify
  - 3× `find` commands → "Run find commands using Bash tool" — constrains verification scope
- Replace Pattern A: `!{bash}` block → runtime instruction

### Step 6: Final Validation
1. Count all skill files: `ls .claude/skills/cig-*/SKILL.md | wc -l` — expect 17
2. Count remaining command files: `ls .claude/commands/cig-*.md 2>/dev/null | wc -l` — expect 0
3. Verify shared docs directory: `ls .cig/docs/skills/` — expect 3 files
4. Verify old directory gone: `ls .cig/docs/commands/` — expect error
5. Measure total lines: `wc -l .claude/skills/cig-*/SKILL.md` — compare to 782 command baseline
6. Check no residual injection syntax: `grep -r '!{bash}\|!/\|!`' .claude/skills/cig-*/SKILL.md` — expect 0
7. Check all reference `.cig/docs/skills/` not `.cig/docs/commands/`: `grep -r 'docs/commands' .claude/skills/cig-*/SKILL.md` — expect 0

## Conversion Reference Table

| Command | Group | Pattern C Count | Pattern C Disposition |
|---------|-------|-----------------|----------------------|
| cig-design-plan | A | 0 | N/A |
| cig-task-plan | A | 0 | N/A |
| cig-requirements-plan | A | 0 | N/A |
| cig-implementation-plan | A | 0 | N/A |
| cig-testing-plan | A | 0 | N/A |
| cig-implementation-exec | A | 0 | N/A |
| cig-testing-exec | A | 0 | N/A |
| cig-retrospective | A | 0 | N/A |
| cig-maintenance | A | 0 | N/A |
| cig-rollout | A | 0 | N/A |
| cig-new-task | B | 1 | Remove 1 (config read internally by task-workflow) |
| cig-subtask | B | 3 | Convert 2 (hierarchy, inheritance), Remove 1 (config) |
| cig-status | B | 1 | Convert 1 (primary output — constrains behaviour) |
| cig-extract | B | 0 | N/A |
| cig-init | C | 3 | Convert 1 (ls existence check), Remove 2 (Pattern A covers) |
| cig-config | C | 3 | Convert 2 (ls configs, autoload), Remove 1 (Pattern A covers) |
| cig-security-check | C | 4 | Convert 4 (all constrain verification scope) |

**Total**: 15 injections — 10 converted to mandatory runtime instructions (constraint context), 5 removed (provably redundant).

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

All 17 commands must be converted and all 17 command files removed. No partial conversion.

## Status
**Status**: Finished
**Next Action**: /cig-testing-plan 57
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
