# Refactor CIG commands for progressive disclosure - Implementation Plan
**Task**: 56 (chore)

## Task Reference
- **Task ID**: internal-56
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/56-refactor-cig-commands-for-progressive-disclosure
- **Template Version**: 2.1

## Goal
Extract shared instruction patterns from 17 CIG commands into `.cig/docs/commands/` reference files, then slim each command to a thin dispatcher that references those docs.

## Workflow
Analyse shared patterns → Create shared docs → Refactor one command as template → Apply pattern to remaining commands → Validate each

## Analysis: Current Command Structure

### Command Groups

**Group A — Workflow step commands (10)**: task-plan, requirements-plan, design-plan, implementation-plan, testing-plan, implementation-exec, testing-exec, rollout, maintenance, retrospective

Shared structure (identical across all 10):
- YAML frontmatter (~4 lines)
- Scope & boundaries (~5 lines, unique per command)
- Context section + `!{bash}` injection (~8 lines, identical)
- Argument parsing CRITICAL block (~14 lines, **identical**)
- Task resolution step (~8 lines, **identical**)
- Parent context loading (~15 lines, **identical**)
- Status field guidance (~2 lines, **identical**)
- Checkpoint commit block (~12 lines, **identical** except file path)

Unique per command:
- Scope description (which step, what's excluded)
- Phase-specific workflow (focus/avoid/key questions/key content: ~15-25 lines)
- Next steps suggestions (~5-8 lines)
- Success criteria (~5-10 lines)

**Group B — Task management commands (4)**: new-task, subtask, status, extract

Shared: context-manager location injection, helper scripts location reference
Mostly unique: each has distinct logic (task creation, hierarchy, extraction)

**Group C — System commands (3)**: init, config, security-check

Shared: context-manager location injection
Mostly unique: each has distinct purpose

### Shared Content Analysis

| Shared Block | Lines | Occurrences | Total Lines Saved |
|---|---|---|---|
| Argument parsing + task validation | 14 | 10 | 126 |
| Task resolution (Step 1) | 8 | 10 | 72 |
| Parent context loading (Steps 2-4) | 15 | 10 | 135 |
| Context section | 8 | 10 | 72 |
| Checkpoint commit block | 12 | 8 | 84 |
| Decomposition check reference | 2 | 6 | 10 |
| CHANGELOG/BACKLOG update (retro) | 45 | 1 | 0 (unique) |
| Checkpoints branch + squash (retro) | 45 | 1 | 0 (unique) |
| **Total saveable** | | | **~499 lines** |

## Files to Modify

### New Files (CREATE)
- `.cig/docs/commands/workflow-preamble.md` — Shared Steps 1-4: argument parsing, task validation, task resolution, parent context loading, context summary, LLM decision point (~45 lines)
- `.cig/docs/commands/checkpoint-commit.md` — Checkpoint commit instructions with template (~15 lines)
- `.cig/docs/commands/retrospective-extras.md` — Retrospective-specific steps: CHANGELOG/BACKLOG management, checkpoints branch, squash workflow (~80 lines)

### Modified Files (EDIT)
**Group A — Workflow commands** (10 files):
- `.claude/commands/cig-task-plan.md` — 155 → ~40 lines
- `.claude/commands/cig-requirements-plan.md` — 87 → ~35 lines
- `.claude/commands/cig-design-plan.md` — 108 → ~35 lines
- `.claude/commands/cig-implementation-plan.md` — 113 → ~35 lines
- `.claude/commands/cig-testing-plan.md` — 115 → ~35 lines
- `.claude/commands/cig-implementation-exec.md` — 157 → ~40 lines
- `.claude/commands/cig-testing-exec.md` — 160 → ~40 lines
- `.claude/commands/cig-rollout.md` — 113 → ~35 lines
- `.claude/commands/cig-maintenance.md` — 98 → ~35 lines
- `.claude/commands/cig-retrospective.md` — 237 → ~45 lines

**Group B — Task management commands** (4 files):
- `.claude/commands/cig-new-task.md` — 113 → ~80 lines (mostly unique, minimal extraction)
- `.claude/commands/cig-subtask.md` — 84 → ~60 lines (already references new-task)
- `.claude/commands/cig-status.md` — 75 → ~60 lines (minimal shared content)
- `.claude/commands/cig-extract.md` — 82 → ~65 lines (minimal shared content)

**Group C — System commands** (3 files):
- `.claude/commands/cig-init.md` — 53 lines (already thin, no change)
- `.claude/commands/cig-config.md` — 76 → ~60 lines (minor extraction)
- `.claude/commands/cig-security-check.md` — 88 → ~70 lines (minor extraction)

## Implementation Steps

### Step 1: Measure baseline token count
- [ ] Count total lines across all 17 commands (current: 1,914)
- [ ] Record per-command line counts for comparison

### Step 2: Create shared documentation files
- [ ] Create `.cig/docs/commands/workflow-preamble.md` with:
  - Argument parsing rules (CRITICAL blocks)
  - Task path validation (format, injection prevention)
  - Task resolution via `context-manager hierarchy`
  - Parent context loading via `context-manager inheritance`
  - Context summary presentation
  - LLM decision point for reading parent details
- [ ] Create `.cig/docs/commands/checkpoint-commit.md` with:
  - Checkpoint commit template
  - Stage + commit + rationale pattern
  - Co-developed-by trailer
- [ ] Create `.cig/docs/commands/retrospective-extras.md` with:
  - CHANGELOG.md update workflow (9.1)
  - BACKLOG.md remove/add workflow (9.2, 9.3)
  - Checkpoints branch creation (10.1)
  - Squash workflow (10.2-10.3)
  - Verify checkpoints (10.4)

### Step 3: Refactor cig-design-plan.md as template
- [ ] Refactor cig-design-plan.md (108 lines) as the pattern template
- [ ] Target structure (see Code Changes below)
- [ ] Verify it still works by invoking `/cig-design-plan` on a test task
- [ ] Document the final line count

### Step 4: Apply pattern to remaining Group A commands (9)
- [ ] Refactor cig-requirements-plan.md
- [ ] Refactor cig-implementation-plan.md
- [ ] Refactor cig-testing-plan.md
- [ ] Refactor cig-task-plan.md
- [ ] Refactor cig-implementation-exec.md
- [ ] Refactor cig-testing-exec.md
- [ ] Refactor cig-rollout.md
- [ ] Refactor cig-maintenance.md
- [ ] Refactor cig-retrospective.md (references retrospective-extras.md)

### Step 5: Refactor Group B and C commands
- [ ] Refactor cig-new-task.md (extract context-manager location block)
- [ ] Refactor cig-subtask.md (extract context-manager location block)
- [ ] Refactor cig-status.md (minor — already fairly thin)
- [ ] Refactor cig-extract.md (minor)
- [ ] Refactor cig-config.md (minor)
- [ ] Refactor cig-security-check.md (extract file listing injections)
- [ ] Skip cig-init.md (already 53 lines, minimal value)

### Step 6: Measure and validate
- [ ] Count total lines across all 17 commands (target: <750)
- [ ] Verify each workflow command is under 45 lines
- [ ] Calculate reduction percentage (target: 60%+)

## Code Changes

### Before (cig-design-plan.md — 108 lines, representative example)

```markdown
---
description: Guide user through design phase
argument-hint: {task-path}
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/*:*), ...
---

## Scope & Boundaries
{5 lines of scope}

## Context
{8 lines of context references and !{bash} injection}

## Your task
{1 line description}

{4 lines: !{bash} context-manager location}

**CRITICAL - Argument Parsing**:
{14 lines of argument parsing rules — IDENTICAL across 10 commands}

Follow the 8-step workflow structure:

1. **Resolve Task Directory**:
{4 lines — IDENTICAL}

2. **Load Parent Context**:
{3 lines — IDENTICAL}
3. **Present Context Summary**: {1 line — IDENTICAL}
4. **LLM Decision**: {1 line — IDENTICAL}
5. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#design`
6. **Execute Design Workflow**:
{15 lines of phase-specific instructions — UNIQUE}

   **Status Field**: {1 line — IDENTICAL}

7. **Check Decomposition Signals**: Review 5 universal signals
8. **Create Checkpoint Commit**:
{12 lines — IDENTICAL except file path}

9. **Suggest Next Steps**:
{4 lines — UNIQUE}

## Success Criteria
{7 lines — UNIQUE}
```

### After (cig-design-plan.md — ~35 lines)

```markdown
---
description: Guide user through design phase
argument-hint: {task-path}
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/*:*), Bash(git rev-parse:*), Bash(git add:*), Bash(git commit:*)
---

## Scope & Boundaries

**This step**: Complete c-design-plan.md with architecture decisions, component design, and interface specifications.
**Not this step**: Implementation, testing, or deployment.
**If blocked or finished**: Call `workflow-manager control --current-step=c-design-plan --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: !/current-task-wf

!{bash}
.cig/scripts/command-helpers/context-manager location

## Workflow

**Steps 1-4 (Preamble)**: Read `.cig/docs/commands/workflow-preamble.md` and follow Steps 1-4 (argument parsing, task resolution, parent context, LLM decision).

**Step 5**: Read `.cig/docs/workflow/workflow-steps.md#design` for detailed design phase guidance.

**Step 6 (Execute)**:
- Open c-design-plan.md
- **Focus on**: Architecture decisions, component design, API contracts, data models, interface design
- **Avoid**: Detailed implementation code, specific test cases, deployment procedures
- Apply design priorities: Testability → Readability → Consistency → Simplicity → Reversibility

**Step 7**: Check decomposition signals. See `.cig/docs/workflow/decomposition-guide.md`.

**Step 8**: Checkpoint commit. Read `.cig/docs/commands/checkpoint-commit.md`. Stage: `implementation-guide/<task-dir>/c-design-plan.md`

**Step 9 (Next Steps)**:
- **Primary**: Move to implementation → `/cig-implementation-plan <task-path>`
- **Alternative**: Return to requirements if design reveals missing requirements
- **Alternative**: Create spike/prototype task if design uncertainty is high

## Success Criteria
- [ ] Design file opened and updated
- [ ] Architecture choice documented with rationale and trade-offs
- [ ] Component overview defined with clear responsibilities
- [ ] Data flow documented
- [ ] Interface design specified
- [ ] Next steps suggested
```

### Shared doc example: workflow-preamble.md (~45 lines)

```markdown
# Workflow Preamble (Steps 1-4)

Shared instructions for all CIG workflow commands. Follow these steps before executing phase-specific workflow.

## Argument Parsing

- If task arguments provided: Extract the FIRST space-separated word as the task path
- If NO task arguments: Use task_num from "Current task/workflow" context above
- Any additional words provide user context about their intent — do NOT pass to scripts
- If neither available: Error "Cannot determine task. Specify task number or ensure context is inferrable."

## Task Path Validation

Task paths MUST match hierarchical number format: digits separated by dots.
- Valid: "11", "1.2", "12.2.3", "1.1.1.1"
- Invalid: "some text", "`date`", "11; rm -rf", "text.text"
- If invalid: inform user and do NOT invoke scripts (prevents command injection)

## Step 1: Resolve Task Directory

- Call `.cig/scripts/command-helpers/context-manager hierarchy <task-path>` using Bash tool
- If task not found: provide clear error with available tasks
- Extract task number, type, and slug from resolution

## Step 2: Load Parent Context

If subtask (not top-level):
- Call `.cig/scripts/command-helpers/context-manager inheritance <task-path>` using Bash tool
- Provides ~50-100 tokens per parent (vs 500-1000 for full files)

## Step 3: Present Context Summary

- Show navigable links with file paths and line ranges
- Display status markers for parent context reliability
- Highlight key parent decisions relevant to current phase

## Step 4: LLM Decision — Read Parent Details

- Use Read tool with offset/limit from structural map
- Only read sections directly informing current phase
- Skip irrelevant parent context to conserve tokens

**Status Field**: Use valid values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
- [ ] Total command lines reduced by 60%+ (from 1,914 to <750)
- [ ] Each workflow command under 45 lines
- [ ] All commands still function correctly (invoke and verify)
- [ ] Shared docs comprehensive (no missing instructions)
- [ ] No duplicate content between commands and docs

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cig-testing-plan 56
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 6 implementation steps executed as planned. 3 shared docs created (169 lines total). 16 commands refactored across 3 groups. Three-group categorisation (A: workflow, B: task management, C: system) proved effective — each group had distinct extraction strategies.

## Lessons Learned
Reading all 17 commands upfront during planning prevented surprises during execution. The natural command floor is ~48 lines (frontmatter + scope + context + workflow + success criteria). Group A commands had ~80% shared content; Groups B/C were mostly unique content requiring inline trimming rather than doc extraction.
