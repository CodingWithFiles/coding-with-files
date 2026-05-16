# Tighten security-subagent sentinel-line output - Plan
**Task**: 144 (chore)

## Task Reference
- **Task ID**: internal-144
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/144-tighten-security-subagent-sentinel-line-output
- **Baseline Commit**: c545b26cec54df6cd7196aa80443223ae1d3bce2
- **Template Version**: 2.1

## Goal
Reduce the false-positive `findings` rate caused by the security-review
subagent prefacing its response with analysis instead of leading with
the required sentinel line.

## Success Criteria
- [ ] `.claude/agents/cwf-security-reviewer-changeset.md` instructs the
      subagent to emit the sentinel as the very first output token
      (or line) with no preamble.
- [ ] The sentinel-line contract is stated once, in the agent file, and
      the wording is strong enough that the model treats it as a
      structural requirement (not a stylistic preference).
- [ ] The three-tier classifier in `.cwf/docs/skills/security-review.md`
      remains unchanged — the conservative-default behaviour is the
      safety net and is not the thing being relaxed.
- [ ] On a dogfood invocation against a clean changeset, the subagent
      response classifies via the **primary** rule (sentinel-first),
      not the **fallback** rule.

## Original Estimate
**Effort**: <0.5 days
**Complexity**: Low
**Dependencies**: None — agent file lives entirely in this repo; no
external coordination.

## Major Milestones
1. **Wording chosen**: a tightened sentinel instruction (and possibly
   alternate sentinel tokens) committed to the agent file.
2. **Dogfood verified**: at least one real exec-phase changeset
   classified via the primary rule, captured as evidence in g-.
3. **Backlog retired**: BACKLOG entry "Tighten security-subagent prompt
   for sentinel-line compliance" moved to CHANGELOG against Task 144.

## Risk Assessment
### High Priority Risks
- **Risk**: Stronger wording still doesn't induce sentinel-first output
  reliably (the underlying model behaviour, not the prompt, is the
  bottleneck).
  - **Mitigation**: Treat the conservative-default classifier as the
    durable guarantee; do not weaken it. If primary-rule compliance
    stays low after this change, escalate to one-token sentinels
    (`FINDINGS:` / `NO_FINDINGS:` / `ERROR:`) in a follow-up, not in
    this task.

### Medium Priority Risks
- **Risk**: Wording change accidentally narrows the agent's review
  behaviour (e.g. discourages the pattern-based-risk carve-out).
  - **Mitigation**: Edit only the sentinel-line paragraph; leave
    threat-model and carve-out paragraphs untouched. Diff review at
    f- exec phase will catch incidental scope creep.

## Dependencies
- None.

## Constraints
- Single agent file (`.claude/agents/cwf-security-reviewer-changeset.md`)
  and at most a one-line cross-reference in the docs. No code changes.
- Must not alter the classifier contract — the three sentinel strings
  (`findings:`, `no findings`, `error:`) stay as-is for this task.
  Changing the sentinel *tokens* (e.g. to one-word forms) is a separate
  decision and out of scope unless explicitly approved during d-.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? — No, hours.
- [ ] **People**: Does this need >2 people working on different parts? — No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? — No, single concern (prompt wording).
- [ ] **Risk**: Are there high-risk components that need isolation? — No.
- [ ] **Independence**: Can parts be worked on separately? — No.

No signals triggered — proceed as single task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
