# Infer task type from required wf steps - Plan
**Task**: 133 (feature)

## Task Reference
- **Task ID**: internal-133
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/133-infer-task-type-from-required-wf-steps
- **Baseline Commit**: 4f474945dbc7b6bf92ea40d56b4b4244212db011
- **Template Version**: 2.1

## Goal
When `<type>` is omitted from `/cwf-new-task` or `/cwf-new-subtask`, infer which wf steps the task needs from its description, then pick the supported task type whose canonical step set most closely matches.

## Background
Each task type in `.cwf/templates/<type>/` is a named bundle of wf steps:

| Type | Steps | Distinguishing concerns |
|---|---|---|
| feature | a,b,c,d,e,f,g,h,i,j | requirements + design + rollout + maintenance |
| discovery | a,b,c,d,e,f,g,j | requirements + design, no rollout/maintenance |
| bugfix | a,c,d,e,f,g,j | design (non-trivial fix), no requirements/rollout |
| hotfix | a,d,e,f,g,h,j | rollout (deploy urgency), no requirements/design |
| chore | a,d,e,f,g,j | mechanical, no requirements/design/rollout |

Today the agent guesses a type label and inherits its step bundle as a side effect. The reframing: decide which steps are needed first (a principled, per-task question), then let type fall out as packaging. This makes misclassification less costly — wrong type with the right steps is still workable; right type with the wrong steps means missing or stray phases.

The BACKLOG entry (`Infer Task Type When Not Specified in new-task and subtask Skills`) cites Task 59 as motivating incident: agent chose `chore` for a task with unclear requirements, forcing a delete/recreate as `feature`. That failure was a step-set problem (no `b-requirements-plan`), not a label problem.

## Success Criteria
- [ ] `/cwf-new-task <num> "<description>"` (no type) does not error; it produces a task directory with an inferred type
- [ ] Inference is deterministic for a given description+model — the same input picks the same type, or asks the same disambiguation question
- [ ] When the inferred step set straddles two task types (no clean match), the skill asks the user to choose between the top candidates instead of guessing
- [ ] Existing 3-arg form (`<num> <type> <description>`) is unchanged — explicit type wins, no inference triggered
- [ ] Step-set → type mapping is derived from `.cwf/templates/<type>/` at runtime, not hard-coded — adding a new task type requires no skill change
- [ ] Both `cwf-new-task` and `cwf-new-subtask` skills implement the same inference (single source of truth, not duplicated prose)

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium
**Dependencies**:
- `.cwf/templates/<type>/` directories (source of truth for step sets)
- `cwf-new-task` and `cwf-new-subtask` skill files
- `task-workflow create` helper (no changes expected — receives a resolved type)

## Major Milestones
1. **Inference rubric drafted** — a written list of signals in the description that map to required wf steps (requirements? design? rollout? maintenance?), plus the closest-fit rule for resolving step set → type
2. **Skills updated** — `cwf-new-task` and `cwf-new-subtask` accept the 2-arg form, run inference, ask on ambiguity, fall through to existing helper
3. **Tests written** — fixture-driven tests covering one description per task type plus at least two ambiguous cases

## Risk Assessment
### High Priority Risks
- **Inference is fuzzy by nature**: the rubric works from the description text alone, but real-world descriptions are terse and often ambiguous.
  - **Mitigation**: keep an explicit "ask the user" fallback whenever the top two candidates' step sets differ in ≥1 step. Don't optimise for full automation; optimise for "right type or a clarifying question".
- **Drift from template directories**: hard-coding a `{feature: [a,b,c,...], ...}` table in the skill duplicates `.cwf/templates/<type>/`.
  - **Mitigation**: derive the mapping by listing `.cwf/templates/<type>/*.template` at runtime (or via the existing `task-workflow` helper).

### Medium Priority Risks
- **Rubric becomes a prose blob inside the skill**: skill files balloon and drift between `new-task` and `new-subtask`.
  - **Mitigation**: write the rubric once under `.cwf/docs/workflow/` and reference it from both skills (progressive disclosure pattern already used elsewhere).
- **LLM context cost**: inference adds a reasoning step on the hot path of task creation.
  - **Mitigation**: keep the rubric short (signals + closest-fit rule, not exhaustive examples); resist the urge to add a helper script for what's a one-shot LLM judgement call.

### Low Priority Risks
- **User confusion about ambiguity prompts**: agent asks too often or too rarely.
  - **Mitigation**: log/track in retrospective; tune threshold (≥1 step difference between top candidates) post-rollout.

## Dependencies
- No external requirements
- Templates layout in `.cwf/templates/<type>/` (already exists, no changes needed)

## Constraints
- Cannot break the 3-arg explicit-type form — that is the dominant call site
- Must keep both `cwf-new-task` and `cwf-new-subtask` in sync; whatever inference logic lives must live in one referenced location
- POSIX-only, no extra dependencies; LLM does the inference, no NLP library

## Decomposition Check
- [ ] **Time**: Will this take >1 week? No — 1-2 days
- [ ] **People**: Does this need >2 people working on different parts? No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one concern (inference at task-creation entry point), touches two skills + one shared doc
- [ ] **Risk**: Are there high-risk components that need isolation? No — failure mode is "asks user to pick", not corruption
- [ ] **Independence**: Can parts be worked on separately? No — skills and shared rubric ship together

**Decomposition not needed.**

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
