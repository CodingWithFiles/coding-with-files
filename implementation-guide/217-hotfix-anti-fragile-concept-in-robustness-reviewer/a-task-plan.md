# Anti-fragile concept in robustness reviewer - Plan
**Task**: 217 (hotfix)

## Task Reference
- **Task ID**: internal-217
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/217-anti-fragile-concept-in-robustness-reviewer
- **Baseline Commit**: 95c5ddfda845e7fbcdb6a9b8ca205a87ade04654
- **Template Version**: 2.1

## Goal
Name the anti-fragile concept in the robustness reviewer's instructions so it
credits changes that strengthen under stress — not only ones that avoid fragile
failure paths — without bloating the reviewer's prose.

## Success Criteria
- [ ] The robustness reviewer's focus statement names "anti-fragile" (or
      "anti-fragility") and distinguishes it from mere robustness (resists
      failure) — i.e. the change should get *stronger*/degrade gracefully under
      unexpected input, not just avoid breaking.
- [ ] Net word count added to the reviewer instructions is minimal (target: a
      single clause/phrase, not a new section or bullet list); no duplicated
      guidance.
- [ ] Instructions remain accurate: no new criteria the reviewer cannot assess
      from a diff, and the existing "avoid fragile failure paths" framing is
      subsumed, not contradicted.

## Original Estimate
**Effort**: <0.5 day
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Wording decided**: exact phrase and placement chosen in the design plan.
2. **Applied**: robustness reviewer file(s) edited; the agent defs ARE
   hash-tracked (perms 0444), so `script-hashes.json` is refreshed in the same
   commit (corrected during d-plan review — see d-implementation-plan.md).
3. **Verified**: grep confirms the term is present; word-count delta reviewed.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Scope creep — turning a one-phrase clarification into a new
  criterion the reviewer can't judge from a diff, or bloating the prose.
  - **Mitigation**: Success criteria cap the net addition at a clause; design
    phase pins exact wording before any edit.

### Medium Priority Risks
- **Risk 2**: Divergence between the two robustness reviewers (plan vs
  changeset) if only one is updated, or inconsistent wording if both are.
  - **Mitigation**: Decide the file scope explicitly in the design plan and
    keep phrasing identical where both are touched.

## Dependencies
- None (self-contained doc edit to `.claude/agents/` robustness reviewer file(s)).

## Constraints
- Anti-fragile guidance is single-role, so it must NOT go in
  `cwf-agent-shared-rules.md` (inclusion bar requires 2+ roles).
- The changeset reviewer sees only a static `.out` diff (no Bash/execution), so
  the wording must stay to diff-observable properties — no runtime-only criteria.
- The edited agent def files ARE hash-tracked at perms 0444; a same-commit
  `script-hashes.json` refresh is required (hash-updates convention).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — sub-day doc edit.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — single concern (one phrase).
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No.

No signals triggered — no decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All three success criteria met. Both robustness reviewers name the spectrum;
wording is one clause + one advisory sentence per file; every criterion is
diff-observable. See j-retrospective.md.

## Lessons Learned
The "no hash refresh" constraint was wrong — agent defs ARE hash-tracked. Run the
hash-updates plan-time grep for `.claude/` paths too, not just `.cwf/`.
