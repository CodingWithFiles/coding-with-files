# fix-deferred-docs-and-avoid-future-deferrals - Design

## Task Reference
- **Task ID**: internal-38
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/38-fix-deferred-docs-and-avoid-future-deferrals
- **Template Version**: 2.1

## Goal
Define documentation structure and template changes to complete Task 37's deferred work and prevent future deferrals.

## Design Priorities
Readability → Simplicity → Consistency (documentation-focused task)

## Architecture Preferences
Explicit guidance over implicit assumptions. Compact over verbose. Examples over theory.

## Key Decisions
### Decision 1: state-tracking.md Refactor Strategy
- **Decision**: Restructure as compact reference with examples, move verbose explanations to separate docs
- **Rationale**:
  - Current file is 655 lines - too verbose for quick reference
  - Mix of conceptual explanation and technical specification reduces scannability
  - Users need quick lookup, not a tutorial
- **Trade-offs**:
  - ✓ Pros: Faster reference lookup, easier to maintain, clearer structure
  - ✓ Pros: New inference output format prominently featured
  - ✗ Cons: Some contextual explanation removed (mitigated by linking to detailed docs)

### Decision 2: Template Guidance Approach
- **Decision**: Add explicit "Do Not Defer Implementation" section in templates with Task 37 as cautionary example
- **Rationale**:
  - Task 37 deferred documentation, marked complete anyway, created technical debt
  - Templates should actively discourage this pattern
  - Provide escape valve for legitimate deferrals (user approval)
- **Trade-offs**:
  - ✓ Pros: Clear guidance prevents repeating Task 37's mistake
  - ✓ Pros: User approval requirement creates accountability
  - ✗ Cons: Slightly more prescriptive (acceptable for preventing technical debt)

## System Design
### Files to Modify
**Documentation**:
- `.cig/docs/context/state-tracking.md` (655 lines → target ~200 lines)
  - Purpose: CIG system documentation explaining task context tracking
  - Current issues: Too verbose, missing Task 37's new output format
  - Design: Compact reference with quick-lookup structure

**Templates**:
- `.cig/templates/pool/d-implementation-plan.md.template`
  - Purpose: Template for implementation planning phase
  - Add: "Scope Completion" section warning against deferrals

- `.cig/templates/pool/f-implementation-exec.md.template`
  - Purpose: Template for implementation execution phase
  - Add: "Deferral Check" before marking status=Finished

### Refactor Strategy for state-tracking.md
**Current structure** (verbose, 655 lines):
1. Long conceptual introduction
2. Detailed signal explanations
3. Buried output format specs
4. Extensive examples and edge cases

**New structure** (compact, ~200 lines):
1. **Quick Reference** (top): Output format examples (conclusive, inconclusive, no_signals)
2. **Signal Overview**: Brief table of signals with 1-line descriptions
3. **Correlation Logic**: Compact explanation of how signals combine
4. **Exit Codes**: Simple table mapping confidence to exit codes
5. **Links**: Point to detailed docs for deep dives

## Interface Design
### state-tracking.md Structure
```markdown
# Task Context Tracking

## Quick Reference - Output Formats

### Conclusive (Exit 0)
```
current: conclusive
confidence: correlated
task_num: 37
task_slug: fix-output-format
workflow_step: c-design-plan
```

### Inconclusive - Uncorrelated (Exit 1)
```
current: inconclusive
confidence: uncorrelated
task_nums: 14,32,37
task_slugs: slug1,slug2,slug3
workflow_steps: step1,step2,step3
candidates: 3
reasons: branch_signal,recency_signal,progress_signal
```

### Inconclusive - No Signals (Exit 3)
```
current: inconclusive
confidence: no_signals
task_nums: unknown
task_slugs: unknown
workflow_steps: unknown
candidates: 0
reasons: none
```

## Signal Overview
| Signal | Purpose | Weight | Example |
|--------|---------|--------|---------|
| branch | Current git branch | 100 | bugfix/37-fix-output |
| recency | Recently modified tasks | 90 | Task 37 modified 2min ago |
| progress | In-progress workflow files | 60 | Task 37 has In Progress files |

## Correlation Logic
- **Correlated**: All non-null signals agree → conclusive
- **Uncorrelated**: Signals disagree → inconclusive (plural fields)
- **No signals**: All signals null → inconclusive (unknown values)

## Exit Codes
| Code | Meaning | Output |
|------|---------|--------|
| 0 | Conclusive | Singular fields |
| 1 | Uncorrelated | Plural fields, reasons |
| 3 | No signals | Unknown values |
```

### Template Additions
**d-implementation-plan.md.template** - Add after "Implementation Steps" section:
```markdown
## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section
```

**f-implementation-exec.md.template** - Add before "Status" section:
```markdown
## Deferral Check
Before marking status=Finished, verify:
- [ ] All steps from d-implementation-plan.md executed
- [ ] All success criteria from a-task-plan.md met
- [ ] All requirements from b-requirements.md addressed (if applicable)
- [ ] All design guidance in c-design.md followed (if applicable)
- [ ] No planned work deferred without user approval
- [ ] If work deferred: Follow-up task created and linked

**If deferral required**: Get user approval, document rationale, create follow-up task.
```

## Constraints
- **Backward compatibility**: state-tracking.md must document both old (Task 32) and new (Task 37) output formats during migration
- **Compactness target**: Reduce state-tracking.md from 655 lines to ~200 lines (70% reduction)
- **Template compatibility**: Changes must work with template-copier system (variable substitution)
- **Readability**: Despite compactness, must remain clear and usable as quick reference

## Validation
- [x] Design review completed
- [x] Architecture approved (compact reference + template guidance approach)
- [x] Integration points verified (templates, documentation structure)

## Status
**Status**: Finished
**Next Action**: Move to implementation planning → `/cig-implementation-plan 38`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
