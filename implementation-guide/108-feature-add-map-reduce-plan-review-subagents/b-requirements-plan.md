# Add map-reduce plan review subagents to requirements, design, and implementation plan skills - Requirements
**Task**: 108 (feature)

## Task Reference
- **Task ID**: internal-108
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/108-add-map-reduce-plan-review-subagents
- **Template Version**: 2.1

## Goal
Define what the map/reduce plan review must do, how well it must do it, and how we verify it works.

## Functional Requirements

### Map Phase (Parallel Subagents)
- **FR1**: For each plan skill invocation, after the plan file is written and decomposition checked (Step 7), launch 3 subagents in parallel using the Agent tool
  - **Acceptance**: All 3 subagents run concurrently in a single tool-call block
- **FR2**: Each subagent receives the plan file path, the plan type (requirements/design/implementation), and a focus-specific prompt
  - **Acceptance**: Subagent prompt includes file path, plan type, and focus-area-specific review criteria. Task metadata (number, type, description) is read from the plan file header by the subagent.
- **FR3**: The 3 focus areas are:
  1. **Improvements** — does the plan reduce complexity, eliminate unnecessary parts, achieve the goal with fewer moving parts? ("the best part is no part")
  2. **Misalignment** — does the plan re-use existing code/abstractions, avoid reinventing the wheel, stay consistent with project conventions?
  3. **Robustness** — does the plan prioritise correctness > maintainability > performance, handle edge cases, and make the system harder to break?
  - **Acceptance**: Each focus area has distinct review criteria that do not overlap significantly
- **FR4**: Each subagent returns a concise list of findings (issue, location in plan, suggested change, rationale)
  - **Acceptance**: Subagent output is understandable by the parent agent for synthesis

### Reduce Phase (Synthesis)
- **FR5**: After all 3 subagents complete, synthesise their findings into a single assessment that identifies tradeoffs between competing suggestions
  - **Acceptance**: Conflicting suggestions are explicitly surfaced with tradeoff analysis
- **FR6**: The parent agent decides which findings to apply based on its own judgement, applies them to the plan file, and presents a summary of changes and remaining suggestions to the user
  - **Acceptance**: Plan file is updated before checkpoint commit; user sees what was changed and any unapplied suggestions
- **FR7**: If no findings are actionable, proceed directly to checkpoint commit without modification
  - **Acceptance**: Empty/low-signal results do not block the workflow

### Per-Plan-Type Tailoring
- **FR8**: Subagent prompts are tailored per plan type with distinct review criteria per focus area. The criteria matrix is defined once in the design (c-design-plan.md) and implemented as a parameterised prompt template.

### User Stories
- **As a** CWF user writing a requirements plan **I want** automated review before commit **so that** requirements are complete and aligned before design begins
- **As a** CWF user writing a design plan **I want** architectural review before commit **so that** the design reuses existing patterns and handles failure modes
- **As a** CWF user writing an implementation plan **I want** code-awareness review before commit **so that** the plan doesn't propose new code when existing modules suffice

## Non-Functional Requirements

### Performance (NFR1)
- Subagent prompts should be concise (under ~300 tokens each excluding plan file content) to minimise review latency
- Subagents should not perform open-ended codebase exploration — focused grep/read only

### Usability (NFR2)
- Review step is automatic — no user interaction required
- Findings are presented concisely in a single conversation message
- Review output shows what was changed and any unapplied suggestions

### Maintainability (NFR3)
- Subagent prompts defined in a single shared doc (`.cwf/docs/skills/plan-review.md`), not duplicated across 3 SKILL.md files
- Each SKILL.md references the doc and specifies only the plan-type parameter
- Adding a new focus area or plan type requires updating the doc, not all skill files

### Security (NFR4)
- Subagents are read-only reviewers — their prompts must instruct them not to modify files or run commands
- Subagent prompts explicitly restrict to Read, Grep, Glob operations (enforcement is prompt-based, not architectural)

### Reliability (NFR5)
- If any subagent fails or times out, the remaining results are still synthesised; one failure does not block the checkpoint commit
- If all subagents fail, log a warning and proceed to checkpoint commit without review

## Constraints
- Agent tool must be added to `allowed-tools` in each modified SKILL.md frontmatter
- Subagent prompts must be self-contained (no access to conversation history)
- Progressive disclosure: SKILL.md files reference `.cwf/docs/skills/plan-review.md`, don't inline prompts
- The review step must not change the step numbering convention significantly — insert as Step 7.5 or renumber Steps 7→8 to Steps 7→9

## Decomposition Check
- [x] **Time**: No — estimated < 1 day
- [x] **People**: No — single developer
- [x] **Complexity**: No — one pattern applied 3× with tailored prompts
- [x] **Risk**: No — additive, non-breaking change
- [x] **Independence**: Not beneficial — too small to split

**Decision**: No decomposition.

## Acceptance Criteria
- [ ] AC1: Running `/cwf-requirements-plan` on a task produces 3 parallel subagent calls after plan file is written
- [ ] AC2: Running `/cwf-design-plan` produces 3 parallel subagent calls with design-specific criteria
- [ ] AC3: Running `/cwf-implementation-plan` produces 3 parallel subagent calls with implementation-specific criteria
- [ ] AC4: Subagent findings are synthesised with explicit tradeoff analysis before any plan changes
- [ ] AC5: Parent agent applies changes based on its judgement and presents summary to user
- [ ] AC6: Checkpoint commit contains the reviewed (possibly amended) plan file
- [ ] AC7: Subagent failure does not block the workflow

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 108
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
