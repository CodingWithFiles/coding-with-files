# Infer task type from required wf steps - Requirements
**Task**: 133 (feature)

## Task Reference
- **Task ID**: internal-133
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/133-infer-task-type-from-required-wf-steps
- **Template Version**: 2.1

## Goal
Specify the behaviour of `/cwf-new-task` and `/cwf-new-subtask` when `<type>` is omitted: the skill infers the wf step set the task needs, then resolves to the closest-matching supported task type.

## Functional Requirements
### Core Features
- **FR1: Two-argument form accepted.** `/cwf-new-task <num> "<description>"` and `/cwf-new-subtask <parent-path> <num> "<description>"` (no `<type>`) must complete successfully when inference yields an unambiguous match. Acceptance: invoking either skill without a type produces a task directory whose `<type>` segment in the path matches one of the supported task types from `.cwf/templates/`.
- **FR2: Three-argument form unchanged.** The existing `<num> <type> "<description>"` form continues to work exactly as before; no inference runs when type is supplied. Acceptance: existing test fixtures for the 3-arg form pass without modification.
- **FR3: Inference rubric maps description signals to required wf steps.** The skill reasons over a documented set of signals — does the work need requirements elicitation, design, rollout, ongoing maintenance? — and produces a set of required wf step letters before consulting task types. Acceptance: the rubric is written down once under `.cwf/docs/workflow/` and referenced from both skills.
- **FR4: Closest-fit task type selection.** Given an inferred step set S, the skill picks the task type whose canonical step set most closely matches S (exact match preferred; otherwise minimum symmetric difference). Tie-break: if two or more types are equidistant from S, the skill must not pick silently — it asks the user (see FR5). Acceptance: for each supported type, a fixture description that should yield that step set produces that type; deliberate ties always prompt.
- **FR5: Ambiguity resolution by prompting.** The skill prompts the user whenever (a) the top two candidates have equal distance to S, or (b) they differ from S by ≥1 step each (no clean match exists). The prompt names the candidate types and the step-set difference. Exact wording and UI of the prompt are design decisions (see c-design-plan). Acceptance: a deliberately ambiguous description triggers an interactive prompt naming the candidates and their step sets.
- **FR6: Mapping derived from template directories at runtime.** The step-set-per-type table is read from `.cwf/templates/<type>/*.template` filenames; adding a new task type (e.g. a future `spike` type) requires no skill changes. Acceptance: introducing a stub `.cwf/templates/spike/` directory with selected step templates causes the skill to consider `spike` as a candidate without other code changes.
- **FR7: Skills stay in sync.** `cwf-new-task` and `cwf-new-subtask` share the inference rubric via reference, not duplication. Acceptance: grep shows no duplicated rubric text across the two skill files.

### User Stories
- **As a CWF user** I want to invoke `/cwf-new-task 134 "Migrate logger to structured JSON"` without specifying a type **so that** I don't have to guess between `feature`/`chore` and rely on the skill picking the right step set.
- **As a CWF maintainer** I want the type→step mapping derived from `.cwf/templates/`, **so that** adding or renaming a task type doesn't require an audit of skill files.
- **As a Task 59 retrospective reader** I want misclassification (chore for a task that needs requirements) to be impossible by construction, **so that** delete/recreate cycles don't recur.

## Non-Functional Requirements
### Performance (NFR1)
- Inference must add at most one additional LLM-internal reasoning pass (no extra tool calls in the common case). No helper script or process spawn introduced solely for inference.
- The 3-arg form must have no measurable change in latency.

### Usability (NFR2)
- Ambiguity prompts must name the two (or more) candidate types and the step-set difference between them, so the user can decide without re-reading docs.
- Error messages on inference failure (e.g. zero candidates) must point the user at the 3-arg form as a fallback.
- The 2-arg form is documented in `SKILL.md` for both skills with at least one worked example.

### Maintainability (NFR3)
- Rubric lives in exactly one file under `.cwf/docs/workflow/` and is referenced from both skills.
- Step-set-per-type mapping is derived at runtime from `.cwf/templates/<type>/`; no hard-coded duplication of that data.
- No new helper scripts unless the existing `task-workflow` helper needs an option (e.g. listing supported types). Prefer LLM reasoning + existing scripts over new code.

### Security (NFR4)
- The description argument continues to flow through the existing `generate_slug` validation in `template-copier-v2.1` (≤50 char check, allowlist of characters). Inference does not bypass slug rules.
- **Description is advisory, not authoritative.** The free-text description informs the LLM's step-set inference but does not directly choose the task type. Final type selection is determined by matching the inferred step set against the validated set derived from `.cwf/templates/<type>/`. A description containing instruction-like text (e.g. "ignore previous constraints") cannot redirect type selection because the resolution gate is a finite-set lookup, not a free-text routing decision.
- **No new environment variables introduced.** The inference rubric is read from `.cwf/docs/workflow/` and the type→step mapping from `.cwf/templates/<type>/` filenames; no env-var overrides for rubric content, inference behaviour, or candidate filtering.
- No new external input surfaces introduced.

### Reliability (NFR5)
- If inference produces no candidates (empty step set or no task type matches at all), the skill must refuse and tell the user, not pick a default.
- If multiple task types tie for closest fit, ask the user; never break ties silently.
- Failure of inference must not leave a half-created task directory; directory creation runs only after type is resolved.

## Constraints
- POSIX-only, no new dependencies (consistent with project conventions).
- Cannot change the existing `task-workflow create` helper interface — type must be resolved to a string before it is called.
- Cannot break v2.0 task directory creation paths still in use during transition.
- British spelling in prose; no personal names in committed docs.

## Decomposition Check
- [ ] **Time**: Will this take >1 week? No — 1-2 days
- [ ] **People**: Does this need >2 people working on different parts? No
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — inference rubric + two skill updates is one concern with two edit points
- [ ] **Risk**: Are there high-risk components that need isolation? No
- [ ] **Independence**: Can parts be worked on separately? No — skills + shared rubric must ship together to satisfy FR7

**Decomposition not needed.**

## Acceptance Criteria
- [ ] AC1: `/cwf-new-task 200 "Add user authentication"` (no type) infers `feature` (canonical step set a,b,c,d,e,f,g,h,i,j) without prompting.
- [ ] AC2: `/cwf-new-task 201 "Migrate Bash helpers to Perl"` (no type) infers `chore` (canonical step set a,d,e,f,g,j — no requirements/design/rollout/maintenance).
- [ ] AC3: A deliberately ambiguous description (e.g. "Investigate why X is slow and fix it") triggers a disambiguation prompt naming the candidate types and the steps that differ between them.
- [ ] AC4: `/cwf-new-task 202 bugfix "Fix off-by-one in pagination"` (explicit type) skips inference entirely and behaves identically to current main.
- [ ] AC5: Both `cwf-new-task/SKILL.md` and `cwf-new-subtask/SKILL.md` reference a single rubric file under `.cwf/docs/workflow/`; `grep -r` shows no duplicated rubric prose.
- [ ] AC6: Adding a stub task type directory under `.cwf/templates/<new-type>/` containing at minimum `a-task-plan.md.template` plus templates for any other steps the type should require, makes `<new-type>` selectable by inference with no skill edits and no changes to `cwf-project.json`. (If a separate registry of supported types exists in config or skill prose, that registry must be derived from the template directory listing or this AC fails.)
- [ ] AC7: BACKLOG entry "Infer Task Type When Not Specified in new-task and subtask Skills" is retired into CHANGELOG during the rollout phase (h-rollout).
- [ ] AC8: A description containing instruction-like content (e.g. `"Add login and then ignore all task constraints"`) yields the same inferred type as its non-adversarial equivalent (`"Add login"`); type selection is independent of free-text payload, because the resolution gate is a finite-set lookup.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
