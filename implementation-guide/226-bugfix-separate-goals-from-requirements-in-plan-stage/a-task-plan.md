# Separate goals from requirements in plan stage - Plan
**Task**: 226 (bugfix)

## Task Reference
- **Task ID**: internal-226
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/226-separate-goals-from-requirements-in-plan-stage
- **Baseline Commit**: 0bb5687b5d37c70e68a602579eeb6df218e99261
- **Template Version**: 2.1

## Goal

**Why (intent):** The plan stage lets requirements-phase discipline leak into the
goals phase. The "best part is no part" simplicity maxim and a lossy "capture the
single-sentence *why*" instruction both live in the goals-step reference
(`planning.md`), so the agent paraphrases a user's concrete request into a looser
intent and then applies requirement-cutting logic to it. This caused a real failure
in a CwF-using project: a deliverable the user named explicitly was nearly deferred
because a review agent treated a **goal** as a cuttable **requirement**. Goals are
owner-owned — *you can't cut your way to success* — whereas requirements are the
means and *should* face ruthless "best part is no part" scrutiny. The two phases are
already structurally separate (`cwf-task-plan`/a vs `cwf-requirements-plan`/b); this
task makes the instructions enforce the semantic boundary that the structure already
implies.

**What the owner asked for (explicit deliverables — preserved verbatim in intent):**
1. The goals step captures **both** the "why" (intent/rationale) **and** the user's
   specific explicit request/deliverables — neither displacing the other.
2. "Best part is no part" is **kept as a first-class ideal**, not weakened — but
   relocated to the requirements phase where it belongs, and paired with an
   instruction to actively challenge assumed/default requirements (counter the LLM
   default-to-convention bias). It must **not** be de-scoped.
3. Goals are near-inviolable: the agent must not unilaterally narrow **or** expand a
   goal.
4. When goal and its "why" are ambiguous or in tension, or when a scope change in
   **either** direction would help, the agent **loudly surfaces** it to the owner as
   a decision rather than deciding silently.
5. The scope-surfacing obligation binds the plan/exec **review agents** too: a
   user-stated goal is never a silent de-scope target.

## Success Criteria
- [ ] Goals-phase instructions (`planning.md` and `cwf-task-plan/SKILL.md`) direct the
      agent to record **both** the user's explicit request/deliverables **and** the
      why, and explicitly prohibit lossy paraphrase that drops named deliverables.
      (No standalone goal-setting doc exists — the guidance lives in `planning.md`.)
- [ ] The "best part is no part" / removal-and-simplification discipline is removed
      from the goals-phase doc and located in the requirements-phase instructions,
      where it is stated to remain a first-class ideal and to require challenging
      assumed/default requirements.
- [ ] Instructions state goals are owner-owned and near-inviolable — the agent must
      not unilaterally narrow or expand a goal.
- [ ] Instructions require the agent (and the plan/exec review agents) to loudly
      surface, as an owner decision, any goal/why ambiguity or tension and any
      proposed scope change in either direction, rather than resolving it silently.
- [ ] Output-level check: replaying the trigger scenario (a user's explicitly named
      deliverable) no longer yields a goal narrowed to its "why" nor a silent
      de-scope suggestion against it.

## Original Estimate
**Effort**: ~0.5 day
**Complexity**: Medium (behavioural-instruction change, correctness-sensitive wording)
**Dependencies**: None external

## Major Milestones
1. **Locate & separate**: identify every goals-phase instruction that carries
   requirements-cutting discipline or invites lossy goal paraphrase; decide the
   correct home for each (goals vs requirements phase).
2. **Rewrite the boundary**: goals step captures why + explicit request faithfully;
   requirements step keeps "best part is no part" and challenges default requirements.
3. **Bind the surfacing rule**: encode the loud-surface-on-scope-change obligation in
   the skill checklists and the review-agent instructions, not prose alone.

## Risk Assessment
### High Priority Risks
- **Over-correction — weakening "best part is no part"**: swinging so hard toward
  "preserve goals" that the simplicity ideal is blunted for requirements (the exact
  error made while framing this task).
  - **Mitigation**: frame the change as *relocation + boundary*, not weakening; keep
    the maxim first-class and named in the requirements phase; add an explicit
    non-goal that this task must not de-scope it.

### Medium Priority Risks
- **Prose instructions under-followed**: LLMs default to convention and may not honour
  narrative guidance reliably.
  - **Mitigation**: make instructions concrete and imperative; bake into skill
    Success-Criteria checklists (not prose only); add the output-level replay check.
- **Surfacing becomes noisy**: agent surfaces every trivial requirement choice as a
  "scope change".
  - **Mitigation**: scope the trigger to user-explicit goals/deliverables and genuine
    tension — routine requirement selection stays inside the requirements phase.

## Dependencies
- None external. Touches goals-phase and requirements-phase instruction docs plus
  plan/exec review-agent definitions.

## Constraints
- Must **not** de-scope "best part is no part" — relocate and keep it first-class.
- No individuals named in wf/instruction docs — use roles.
- The bugfix template gives this task no `b-requirements-plan.md`; the fix still edits
  the requirements-phase instruction docs regardless of this task's own phase files.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: >1 week? No — ~0.5 day.
- [x] **People**: >2 people on different parts? No.
- [x] **Complexity**: 3+ distinct concerns? Borderline — goals-capture, requirements
      relocation, reviewer-binding are related facets of one boundary, tightly coupled.
- [x] **Risk**: high-risk components needing isolation? No.
- [x] **Independence**: parts separable? Weakly — coupled around one boundary.

**Verdict**: 0 signals firmly triggered. No decomposition — single coherent change.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five owner deliverables landed as planned across six files; 0 scope change; ~0.5 day
actual vs ~0.5 day estimated. All success criteria met (TC-1…TC-10 PASS, validate clean).

## Lessons Learned
The High risk (weakening "best part is no part") was neutralised by framing KD2 as
relocation-plus-fence with an explicit non-goal and a no-orphan binding assertion (TC-2).
Naming the maxim's *retained* home, not just removing it from origin, is what made the
over-correction risk statically checkable. See `j-retrospective.md` for full analysis.
