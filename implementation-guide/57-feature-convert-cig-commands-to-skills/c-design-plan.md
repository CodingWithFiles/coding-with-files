# Convert CIG Commands to Skills - Design
**Task**: 57 (feature)

## Task Reference
- **Task ID**: internal-57
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/57-convert-cig-commands-to-skills
- **Template Version**: 2.1

## Goal
Define architecture and design decisions for converting 17 CIG commands to SKILL.md format.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### D1: Skill File Format — Directory-based
- **Decision**: Use `.claude/skills/cig-<name>/SKILL.md` (directory-based)
- **Rationale**: Consistent with existing `cig-current-task` and `test-cig-skill` patterns. Allows future bundled assets if needed. Standard plugin-compatible format.
- **Trade-offs**: 17 directories instead of 17 files, but each is a single SKILL.md file.

### D2: Frontmatter Format — YAML with Mapped Fields
- **Decision**: Use YAML frontmatter (`---` delimited) with these fields:

```yaml
---
name: cig-<name>
description: <mapped from command description>
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---
```

- **Rationale**: Matches `test-cig-skill` format. `name` and `user-invocable` are required for the skill to appear in `/` completions.
- **Trade-offs**: Command `allowed-tools` uses fine-grained patterns (e.g., `Bash(.cig/scripts/command-helpers/*:*)`). Skills may not support these patterns — initial conversion uses broad tool names. If skills DO support glob patterns, refine later.
- **Field mapping**:
  - `description:` → `description:` (unchanged)
  - `argument-hint:` → Dropped (skills don't support it; hint documented in body instead)
  - `allowed-tools:` → Simplified to tool names (Read, Write, Edit, Bash)

### D3: `{arguments}` Handling — Keep As-Is
- **Decision**: Keep `{arguments}` template variable in skill body unchanged.
- **Rationale**: Session evidence confirms `{arguments}` is substituted in skills (all skill expansions show `ARGUMENTS: <value>` and `{arguments}` appears substituted in skill body text).
- **Trade-offs**: None. Zero-effort change.

### D4: Context Injection Replacement Strategy
Four patterns, four replacement strategies:

#### Pattern A: `!{bash}` block → Runtime Bash instruction
**Before** (command):
```
!{bash}
.cig/scripts/command-helpers/context-manager location
```
**After** (skill):
```
**First**: Run `.cig/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.
```
Affects: All 17 skills.

#### Pattern B: `!/current-task-wf` → Runtime Bash call
**Before** (command):
```
**Current task/workflow**: !/current-task-wf
```
**After** (skill):
```
**Current task/workflow**: Run `.cig/scripts/command-helpers/task-context-inference` using the Bash tool.
```
Affects: 10 workflow skills. Bypasses `current-task-wf.md` (which itself uses `!` backtick injection) and calls the underlying script directly.

#### Pattern C: `!` backtick inline → Mandatory runtime instruction or provably redundant removal
Each injection is **constraint context** — its presence reduces variability in agent output. Removal requires proving another mechanism guarantees the data. Each injection categorised as:

- **Mandatory runtime instruction** (10): Context that constrains agent behaviour. Converted to "Run X using Bash tool" in the Context section, gathered every invocation.
- **Provably redundant** (5): Data guaranteed by Pattern A (`context-manager location`) or by a called script's internal reads. Removal rationale cites the specific mechanism.

Example — **cig-status** (mandatory):
**Before**: `- Task hierarchy with progress: !`.cig/scripts/command-helpers/workflow-manager status {arguments}``
**After**: `**Context**: Run `.cig/scripts/command-helpers/workflow-manager status {arguments}` using the Bash tool.`
**Rationale**: This IS the primary output — without it the agent would guess status values.

Example — **cig-new-task** (provably redundant):
**Before**: `- Project config: !`.cig/scripts/command-helpers/cig-load-project-config``
**After**: Removed.
**Rationale**: `task-workflow create` reads project config internally. Agent never uses the raw config output.

Affects: 6 skills with 15 total injections (10 mandatory, 5 removed).

#### Pattern D: `{arguments}` → No change
Keep as-is. Works in skills.

### D5: Shared Docs — Rename Directory
- **Decision**: Rename `.cig/docs/skills/` to `.cig/docs/skills/`. Skills reference the renamed path.
- **Rationale**: Directory name should reflect the new architecture. Content unchanged (same 3 files from Task 56). Historical docs (Task 56 files, CHANGELOG) left referencing old path since they document the commands era.
- **Trade-offs**: One extra `git mv` step during implementation. Skills need Read in `allowed-tools` (already included).

### D6: current-task-wf Files — Keep Unchanged
- **Decision**: Keep `.claude/skills/current-task-wf.md` and `current-task-wf-verbose.md` as standalone skills.
- **Rationale**: They still work when invoked directly (their `!` backtick injection works in the context of being loaded as standalone files by Claude Code). Workflow skills bypass them via direct script calls (Pattern B above).
- **Trade-offs**: Slight inconsistency (standalone files vs directory-based skills). Acceptable — they serve a different purpose (utility helpers, not workflow commands).

## Skill Template

### Workflow Skill (Group A — 10 commands)

Example: `cig-design-plan`

```markdown
---
name: cig-design-plan
description: Guide user through design phase
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

## Scope & Boundaries

**This step**: Complete c-design-plan.md with architecture decisions, component design, and interface specifications.
**Not this step**: Implementation, testing, or deployment.
**If blocked or finished**: Call `workflow-manager control --current-step=c-design-plan --task-path=<path>` to determine next action.

## Context

**Task arguments**: {arguments}
**Current task/workflow**: Run `.cig/scripts/command-helpers/task-context-inference` using the Bash tool.

**First**: Run `.cig/scripts/command-helpers/context-manager location` using the Bash tool to confirm git root.

## Workflow

**Steps 1-4 (Preamble)**: Read `.cig/docs/skills/workflow-preamble.md` and follow Steps 1-4.

**Step 5**: Read `.cig/docs/workflow/workflow-steps.md#design` for detailed design phase guidance.

**Step 6 (Execute)**:
- Open c-design-plan.md
- **Focus on**: Architecture decisions, component design, API contracts, data models, interface design
- **Avoid**: Detailed implementation code, specific test cases, deployment procedures
- Apply design priorities: Testability → Readability → Consistency → Simplicity → Reversibility

**Step 7**: Check decomposition signals. See `.cig/docs/workflow/decomposition-guide.md`.

**Step 8**: Checkpoint commit. See `.cig/docs/skills/checkpoint-commit.md`. Stage: `c-design-plan.md`

**Step 9 (Next Steps)**:
- **Primary**: Move to implementation → `/cig-implementation-plan <task-path>`
- **Alt**: Return to requirements if design reveals gaps
- **Alt**: Create spike/prototype if uncertainty is high

## Success Criteria
- [ ] Design file opened and updated
- [ ] Architecture choice documented with rationale and trade-offs
- [ ] Component overview with clear responsibilities
- [ ] Data flow documented
- [ ] Interface design specified
- [ ] Next steps suggested
```

### Changes from Command Version
1. **Frontmatter**: `description` + `argument-hint` + `allowed-tools` → `name` + `description` + `user-invocable` + `allowed-tools`
2. **`!{bash}` block** (line 18-19 in command) → Natural language instruction
3. **`!/current-task-wf`** (line 16 in command) → Script invocation instruction
4. **Body content**: Identical — same scope, workflow, success criteria sections

### Non-Workflow Skills (Groups B + C — 7 commands)

Same frontmatter pattern. Key difference: Pattern C replacements vary per command.

**cig-new-task**: Remove `!` backtick for `cig-load-project-config`. LLM doesn't need project config pre-loaded — `task-workflow create` reads it internally.

**cig-subtask**: Remove 3 `!` backtick injections. Parent resolution and config loading happen via workflow instructions, not prompt pre-loading.

**cig-status**: Remove `!` backtick for `workflow-manager status`. The skill's own workflow calls this script.

**cig-config**: Remove 3 `!` backtick injections. Replace with runtime instructions since config discovery is the skill's purpose (it gathers this information as part of its workflow).

**cig-security-check**: Remove 4 `!` backtick injections. Verification is the skill's purpose — it gathers file listings as part of its workflow.

**cig-init**: Remove 3 `!` backtick injections. Environment detection happens as part of the init workflow.

**cig-extract**: No Pattern C injections. Only Patterns A and D (both handled).

## Data Flow

### Command Invocation (current)
```
User: /cig-design-plan 57
  → Claude Code command loader
  → Expands !{bash}, !/path, !`...` injections (prompt-time)
  → Substitutes {arguments}
  → Sends expanded prompt to LLM
  → LLM reads shared docs via Read tool (runtime)
  → LLM executes workflow steps
```

### Skill Invocation (target)
```
User: /cig-design-plan 57
  → Claude Code skill loader
  → Substitutes {arguments} (prompt-time — only substitution that occurs)
  → Sends skill prompt to LLM
  → LLM runs context-manager location via Bash tool (runtime)
  → LLM runs task-context-inference via Bash tool (runtime)
  → LLM reads shared docs via Read tool (runtime)
  → LLM executes workflow steps
```

Key difference: Context gathering moves from prompt-time expansion to runtime tool calls. The LLM does 2 extra tool calls at the start of each invocation.

## Token Budget Estimate

### Per-Skill Size
- Frontmatter: ~6 lines
- Scope/Context: ~8 lines
- Workflow: ~20 lines
- Success criteria: ~8 lines
- **Total: ~42 lines per workflow skill**

### Total Auto-Load Budget
- 10 workflow skills × 42 lines = 420 lines
- 7 non-workflow skills × 35 lines (avg) = 245 lines
- **Total: ~665 lines** (less than command baseline of 782)
- Estimated tokens: ~665 lines × 8 words/line × 1.5 tokens/word ≈ **8,000 tokens**
- Within NFR1 target of 20k tokens.

## Constraints
- Skills don't support `!{bash}`, `!/path`, or `!` backtick injection (Task 55 confirmed)
- Skills DO support `{arguments}` substitution (session evidence)
- `allowed-tools` in skills may not support glob patterns (test during implementation)
- No hooks in initial conversion

## Validation
- [ ] Template skill (cig-design-plan) invoked and working
- [ ] cig-new-task specifically tested (FR7 regression)
- [ ] Token budget measured against estimate
- [ ] All shared doc references verified

## Status
**Status**: Finished
**Next Action**: /cig-implementation-plan 57
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
