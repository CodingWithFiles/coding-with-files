# Add map-reduce plan review subagents to requirements, design, and implementation plan skills - Design
**Task**: 108 (feature)

## Task Reference
- **Task ID**: internal-108
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/108-add-map-reduce-plan-review-subagents
- **Template Version**: 2.1

## Goal
Design how the map/reduce plan review integrates into existing skill structure, what the shared doc contains, and how subagent prompts are structured.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice: Shared Doc + Minimal Skill References
- **Decision**: Single shared doc (`.cwf/docs/skills/plan-review.md`) contains all subagent prompt templates and the reduce/synthesis instructions. Each SKILL.md adds one new step that references the doc with a plan-type parameter.
- **Rationale**: Progressive disclosure — same pattern as `workflow-preamble.md` and `checkpoint-commit.md`. Avoids duplicating 9 prompt templates across 3 skill files. Adding a new focus area or plan type means editing one file.
- **Trade-offs**: Subagent prompts are not visible inline in the skill file (must follow the reference), but this matches the established CWF convention where skills are thin dispatchers that reference docs.

### Skill File Changes: Insert Step 8 (Review), Renumber 8→9, 9→10
- **Decision**: Add new Step 8 between decomposition check (Step 7) and checkpoint commit (current Step 8). Renumber current Step 8 → Step 9, Step 9 → Step 10.
- **Rationale**: Maintains the existing flow — review happens after the plan is written and decomposition checked, but before the commit locks it in. Consistent renumbering across all 3 skills.
- **Trade-offs**: Step numbers change, but no external references to step numbers exist (skills reference step names, not numbers).

### Subagent Configuration: Read-Only via Prompt Instruction
- **Decision**: Use `subagent_type: "Explore"` for all subagents as an analytics label. Tool restriction is enforced via prompt instruction ("You may only use Read, Grep, and Glob tools"). The parent agent performs edits during the reduce step.
- **Rationale**: The `subagent_type` parameter is a label for tracking, not a tool restriction mechanism. Read-only behaviour must be instructed in the prompt itself.
- **Trade-offs**: Prompt-based restriction relies on the subagent following instructions rather than architectural enforcement. Acceptable risk for a review step where the parent agent validates all changes.

## System Design

### Component Overview

1. **`.cwf/docs/skills/plan-review.md`** (new) — Shared doc containing:
   - Overview of map/reduce methodology
   - 1 parameterised prompt template with `{plan_file_path}`, `{plan_type}`, `{focus_area}`, and `{criteria}` placeholders
   - 3×3 criteria lookup table (the skill substitutes `{plan_type}` to get 3 rows, launches 3 agents with different `{focus_area}`/`{criteria}` values)
   - Reduce step instructions: how to synthesise findings, assess tradeoffs, apply changes

2. **SKILL.md modifications** (3 files) — Each gains:
   - `Agent` added to `allowed-tools` in frontmatter
   - New Step 8: "Read `.cwf/docs/skills/plan-review.md` and follow the plan review procedure for plan type `{plan-type}`"
   - Renumbered Steps 9 (checkpoint commit) and 10 (next steps)

3. **Criteria lookup table** (defined in plan-review.md) — one prompt template, parameterised by:

   |              | Improvements | Misalignment | Robustness |
   |--------------|-------------|--------------|------------|
   | Requirements | Completeness, minimality of acceptance criteria | Overlap with existing functionality, convention consistency | Testability, edge case coverage |
   | Design       | Architectural simplicity, unnecessary components | Pattern reuse, abstraction consistency | Failure modes, degradation paths |
   | Implementation | Minimal file changes, code reuse | Existing libraries/modules vs new code | Correctness > maintainability > performance |

### Data Flow

```
Skill Step 6: Write plan file
    ↓
Skill Step 7: Decomposition check
    ↓
Skill Step 8: Plan review (new)
    ├─── MAP: Launch 3 Explore subagents in parallel
    │    ├── Subagent 1 (improvements): Read plan + grep codebase → findings
    │    ├── Subagent 2 (misalignment): Read plan + grep codebase → findings
    │    └── Subagent 3 (robustness): Read plan + grep codebase → findings
    │
    └─── REDUCE: Synthesise findings
         ├── Collect all findings from 3 subagents
         ├── Identify tradeoffs between competing suggestions
         ├── Apply "must-fix" items → Edit plan file
         ├── Present "consider" items → User output
         └── If no findings or all subagents failed → proceed unchanged
    ↓
Skill Step 9: Checkpoint commit (plan file with review amendments)
    ↓
Skill Step 10: Next steps
```

### Subagent Output

Subagents return findings in natural language. No rigid format — the parent agent (an LLM) synthesises the output directly. Prompt instruction: "For each finding, state what is wrong, where it is in the plan, and what to do about it."

### Reduce Step Logic

1. Collect findings from all 3 subagents (skip any that failed/timed out)
2. Identify tradeoffs between competing suggestions (e.g., "add validation" vs "reduce moving parts")
3. Use parent agent judgement to decide which findings to apply
4. Apply chosen changes to the plan file using Edit tool
5. Present a summary of changes made and any unapplied suggestions to the user
6. If no actionable findings: output "Plan review: no changes needed" and proceed

## Constraints
- Subagent prompts must fit within reasonable token budget (~500 tokens each including the plan file path and task context)
- Explore subagents cannot run Bash commands — codebase verification is limited to Grep/Glob/Read
- The reduce step runs in the parent agent's context, so it has full tool access for applying edits

## Decomposition Check
- [x] **Time**: No
- [x] **People**: No
- [x] **Complexity**: No — single pattern
- [x] **Risk**: No — additive change
- [x] **Independence**: No benefit

**Decision**: No decomposition.

## Validation
- [ ] Design follows progressive disclosure (skill → doc reference)
- [ ] Subagent tools restricted to read-only (Explore agent)
- [ ] Data flow shows clear map → reduce → edit → commit sequence
- [ ] Prompt matrix covers all 9 combinations without significant overlap

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 108
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
