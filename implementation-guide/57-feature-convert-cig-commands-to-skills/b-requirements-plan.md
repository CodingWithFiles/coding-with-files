# Convert CIG Commands to Skills - Requirements
**Task**: 57 (feature)

## Task Reference
- **Task ID**: internal-57
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/57-convert-cig-commands-to-skills
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for converting 17 CIG commands to skills format.

## Context Injection Inventory

Audit of all context injection patterns currently used across 17 commands (these all fail in skills and must be replaced):

### Pattern A: `!{bash}` block (17 commands)
All commands use `!{bash}\n.cig/scripts/command-helpers/context-manager location` to inject git root at prompt time.

### Pattern B: `!/current-task-wf` shorthand (10 workflow commands)
design-plan, task-plan, requirements-plan, implementation-plan, testing-plan, implementation-exec, testing-exec, retrospective, maintenance, rollout.

### Pattern C: `!` backtick inline (6 commands, 14 total injections)
- **cig-new-task** (1): `cig-load-project-config` — **known broken today** (permission error)
- **cig-subtask** (3): `context-manager hierarchy`, `context-manager inheritance`, `cig-load-project-config`
- **cig-status** (1): `workflow-manager status {arguments}`
- **cig-config** (3): `git rev-parse`, `ls ~/.cig/`, `cig-load-autoload-config`
- **cig-security-check** (4): `cig-load-project-config`, `find commands`, `find v1.0 scripts`, `find v2.0 scripts`
- **cig-init** (3): `pwd`, `git rev-parse`, `ls implementation-guide/`

### Pattern D: `{arguments}` template variable (17 commands)
All commands use `{arguments}` which is substituted at invocation time by the commands loader.

## Functional Requirements

### FR1: File Format Conversion
Convert each command from `.claude/commands/cig-<name>.md` (single file with YAML frontmatter) to `.claude/skills/cig-<name>/SKILL.md` (directory with SKILL.md file).

**Frontmatter mapping**:
- Command `description:` → Skill `description:` (unchanged)
- Command `argument-hint:` → Skill: investigate if equivalent exists, otherwise document in body
- Command `allowed-tools:` → Skill `allowed-tools:` (unchanged field name)
- New field: `name: cig-<name>`
- New field: `user-invocable: true` (all 17 are user-invoked)

**AC**: Each skill directory exists with SKILL.md containing valid frontmatter. Claude Code recognises all 17 as invocable skills.

### FR2: Replace `!{bash}` Block Injection (Pattern A)
Replace the `!{bash}\n.cig/scripts/command-helpers/context-manager location` block in all 17 commands with an explicit instruction for the LLM to call the Bash tool at runtime.

**Before** (command):
```
!{bash}
.cig/scripts/command-helpers/context-manager location
```

**After** (skill):
```
**First**: Run `.cig/scripts/command-helpers/context-manager location` using the Bash tool to verify git root.
```

**AC**: Every skill includes an instruction to run context-manager location at runtime. The LLM executes it when the skill is invoked, producing equivalent output to the command injection.

### FR3: Replace `!/path` Shorthand Injection (Pattern B)
Replace `!/current-task-wf` in 10 workflow commands with an instruction to read the current-task-wf skill output at runtime.

**Before** (command):
```
**Current task/workflow**: !/current-task-wf
```

**After** (skill): Instruct the LLM to call the `current-task-wf` skill or read `.cig/task-stack` + run `workflow-manager status` to obtain current task context.

**AC**: Each of the 10 workflow skills obtains current task/workflow context at runtime, equivalent to the injected value.

### FR4: Replace `!` Backtick Inline Injection (Pattern C)
Replace 15 inline `!` backtick injections across 6 commands with mandatory runtime Bash tool instructions or remove where provably redundant.

**Principle**: Injected context acts as a **constraint on agent behaviour** — its presence in the prompt reduces variability in generated output. Removing context without replacement introduces variability risk (agent may hallucinate, skip checks, or make incorrect assumptions). Each injection must be categorised as:

- **Mandatory runtime instruction**: Context that constrains agent behaviour. Must be converted to an explicit "Run X using the Bash tool" instruction placed in the Context section, ensuring the agent gathers this data every invocation before proceeding.
- **Provably redundant**: Data guaranteed to be present via another mechanism (Pattern A covers it, or a called script reads it internally as a side effect). Removal rationale must cite the specific mechanism that guarantees the data.

**Mandatory runtime instructions** (10 injections):
- cig-subtask: `context-manager hierarchy` — parent resolution constrains subtask placement
- cig-subtask: `context-manager inheritance` — parent structural map constrains subtask scope
- cig-status: `workflow-manager status {arguments}` — primary output; without it agent would guess
- cig-config: `ls ~/.cig/ .cig/` — existing state constrains init/list/reset decisions
- cig-config: `cig-load-autoload-config` — current config constrains modification decisions
- cig-security-check: `cig-load-project-config` — project config constrains what to verify
- cig-security-check: 3× `find` commands — file listings constrain verification scope
- cig-init: `ls implementation-guide/` — existence check constrains whether to create or skip

**Provably redundant** (5 injections):
- cig-new-task: `cig-load-project-config` — `task-workflow create` reads config internally; agent never uses the raw config output
- cig-subtask: `cig-load-project-config` — same mechanism as cig-new-task
- cig-init: `pwd` — `context-manager location` (Pattern A) returns current directory
- cig-init: `git rev-parse --show-toplevel` — `context-manager location` (Pattern A) returns git root
- cig-config: `git rev-parse --show-toplevel` — `context-manager location` (Pattern A) returns git root

**AC**: Zero `!` backtick patterns remain. 10 converted to mandatory runtime instructions in Context section. 5 removed with per-injection rationale citing the guaranteeing mechanism.

### FR5: Handle `{arguments}` Template Variable (Pattern D)
Determine how `{arguments}` works in skills and adapt accordingly.

**Investigation needed**: Does Claude Code substitute `{arguments}` in SKILL.md the same way it does in commands? If yes, no change needed. If no, provide alternative (e.g., instruct LLM to parse user input from conversation context).

**AC**: All 17 skills receive user arguments correctly. Verified by invoking a skill with arguments (e.g., `/cig-status 57`).

### FR6: Rename Shared Docs Directory
Rename `.cig/docs/commands/` to `.cig/docs/skills/` to reflect the new architecture. Update all references in skill files to point to the new path.

**AC**: `.cig/docs/commands/` no longer exists. `.cig/docs/skills/` contains the same 3 files (workflow-preamble.md, checkpoint-commit.md, retrospective-extras.md). All skill files reference `.cig/docs/skills/`. Historical documentation (Task 56 files, CHANGELOG) left unchanged.

### FR7: Clean Cutover per Command
Remove the corresponding `.claude/commands/cig-<name>.md` file when creating the skill `.claude/skills/cig-<name>/SKILL.md`. No parallel operation period.

**AC**: After conversion, `.claude/commands/` contains zero `cig-*.md` files. `.claude/skills/` contains 17 `cig-*/SKILL.md` files (plus existing non-CIG skills).

### FR8: Fix cig-new-task (Known Broken)
cig-new-task currently fails with "Bash command permission check failed" when invoked as a skill due to `!` backtick injection of `cig-load-project-config`. The converted skill must work without this error.

**AC**: `/cig-new-task 58 chore "Test task"` invoked successfully as a skill without permission errors. Project config is loaded at runtime via Bash tool.

## Non-Functional Requirements

### NFR1: Token Budget
- **Constraint**: Skills auto-load into conversation context. Total skill content must be measured.
- **Target**: Total auto-loaded content under 20k tokens (rough estimate: 17 skills x ~50 lines x ~1.5 tokens/word x ~8 words/line = ~10k tokens)
- **Measurement**: Count total lines across all SKILL.md files. Compare to command baseline (782 lines).
- **AC**: Total SKILL.md content measured and documented. If over 20k tokens, identify skills for `disable-model-invocation: true`.

### NFR2: Structural Consistency
- All 17 skills follow the same SKILL.md structure: frontmatter → description/scope → context gathering instructions → workflow → success criteria
- Consistent with patterns established by existing `cig-current-task` skill
- **AC**: All skills pass a structural consistency check (same sections in same order).

### NFR3: Maintainability
- Skills continue to reference shared docs in `.cig/docs/commands/` (same as post-Task 56 commands)
- No duplication of shared content into skill files
- **AC**: Grep for shared doc references confirms skills reference the same docs as commands did.

### NFR4: Reliability
- No silent failures — if a skill can't gather context, it must produce a visible error or fallback
- Contrast with commands: `!` backtick injection either silently fails or produces permission errors
- **AC**: Skills that fail to resolve task directory produce clear error messages to the user.

## Constraints
- Skills-only mode (`.claude/skills/` directories, not plugin packages)
- No hooks in initial conversion (can be added later)
- Must work with current Claude Code version
- `allowed-tools` must be preserved accurately from command frontmatter
- Shared docs in `.cig/docs/commands/` remain unchanged

## Acceptance Criteria
- [ ] AC1: All 17 skills created in `.claude/skills/cig-*/SKILL.md` with valid frontmatter
- [ ] AC2: All context injection patterns (A-D) replaced with runtime equivalents
- [ ] AC3: All `.claude/commands/cig-*.md` files removed
- [ ] AC4: `.cig/docs/commands/` renamed to `.cig/docs/skills/`, all skill references updated (FR6)
- [ ] AC5: `/cig-new-task` works without permission errors (FR8 regression fix)
- [ ] AC6: Sample invocations of 3+ skills produce correct behaviour
- [ ] AC7: Token budget measured and documented (NFR1)
- [ ] AC8: Skills reference shared docs in `.cig/docs/skills/`, no content duplication (NFR3)

## Status
**Status**: Finished
**Next Action**: /cig-design-plan 57
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
