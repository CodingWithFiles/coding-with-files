# exec-changeset reviewer agents - Plan
**Task**: 210 (feature)

## Task Reference
- **Task ID**: internal-210
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/210-exec-changeset-reviewer-agents
- **Baseline Commit**: 99725223b672a0f81a7e709eb4e7c45b30f17a89
- **Template Version**: 2.1

## Goal
Add three exec-changeset reviewer agents — reuse, reliability, alignment — that
review the implementation-exec diff alongside the existing security and
best-practice changeset reviewers, but do **not** run in testing-exec.

## Success Criteria
- [ ] Three reviewer agents exist that critique an exec **changeset** (not a plan
      file): reuse (cf. plan-reviewer-improvements), reliability (cf.
      plan-reviewer-robustness), alignment (cf. plan-reviewer-misalignment).
- [ ] `cwf-implementation-exec` Step 8 launches the new reviewers in the existing
      parallel MAP; each emits its own `cwf-review` verdict, classified by the
      shared `security-review-classify` helper.
- [ ] `cwf-testing-exec` does **not** launch any of the three (verified by reading
      that skill — it must remain security/best-practice-only, or whatever it runs today).
- [ ] New agent files are hash-registered in `script-hashes.json` in the same commit;
      `cwf-manage validate` passes.
- [ ] A generated sample exec run (or dry trace) shows the three sections appended
      to `f-implementation-exec.md` with correct State tokens.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium
**Dependencies**: Existing `cwf-*-reviewer-changeset` agents and
`cwf-plan-reviewer-{improvements,robustness,misalignment}` agents as source
patterns; `security-review-changeset`, `best-practice-resolve`,
`security-review-classify` helpers; SubagentStop verdict guard.

## Major Milestones
1. **Pattern study**: Map how the two existing `-changeset` reviewers differ from
   their plan-reviewer cousins (input contract, verdict block, prompt template).
2. **Author agents**: Three new `cwf-*-reviewer-changeset` agent definitions.
3. **Wire into Step 8**: Extend `cwf-implementation-exec` MAP + recording; confirm
   `cwf-testing-exec` is untouched.
4. **Hashes + validate**: Register hashes, pass `cwf-manage validate`, smoke-test output.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Plan-reviewer prompts assume a plan-file input; naively copying them
  produces reviewers that mis-read a diff.
  - **Mitigation**: Derive the new prompts from the existing `-changeset` reviewers'
    input contract, porting only the *lens* (what to look for) from the plan reviewers.
- **Risk 2**: The SubagentStop verdict guard is name-matched to
  `cwf-security-reviewer-changeset` only. Adding reviewers that should/shouldn't be
  guarded could change blocking behaviour.
  - **Mitigation**: Decide guard scope explicitly in design; these are advisory
    (surface-don't-block) like best-practice, so likely stay unguarded.

### Medium Priority Risks
- **Risk 3**: Step 8 prep/MAP/classify logic grows from 2 to 5 reviewers — verbosity
  and per-reviewer verdict-or-agent branching could drift or duplicate.
  - **Mitigation**: Factor the common verdict-or-agent decision; keep one shared
    classifier (already the case).
- **Risk 4**: Forgetting the testing-exec exclusion (the explicit user constraint).
  - **Mitigation**: Dedicated success criterion + a test asserting testing-exec
    does not name the three agents.

## Dependencies
- Existing changeset-reviewer pattern (`cwf-security-reviewer-changeset`,
  `cwf-best-practice-reviewer-changeset`) and their docs under `.cwf/docs/skills/`.
- The three plan-reviewer agents as the source of each review lens.

## Constraints
- Must follow design-alignment naming (`cwf-<lens>-reviewer-changeset`, kebab-case).
- New/edited hashed files refresh `script-hashes.json` in the same commit.
- Reviewers run **only** after implementation-exec, never testing-exec.
- Reuse over duplication: share the existing helpers and classifier, don't fork them.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — 1-2 days.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one concern
      (changeset-review lenses) realised as three near-identical agents plus one
      skill-wiring change.
- [ ] **Risk**: Are there high-risk components that need isolation? No.
- [ ] **Independence**: Can parts be worked on separately? Partly (3 agents), but
      they share a pattern and a single wiring point; splitting adds overhead.

**Verdict**: 0 signals triggered — keep as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Executed as planned. The 0-decomposition-signals verdict held — single cohesive
task. All five success criteria met (the live sample exec run, criterion 5, was
verified in h). See j-retrospective.md for variance.

## Lessons Learned
The 1–2 day estimate was conservative; the "clone the `-changeset` precedent,
port only the lens" recipe reduced active effort to hours.
