# Separate goals from requirements in plan stage - Design
**Task**: 226 (bugfix)

## Task Reference
- **Task ID**: internal-226
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/226-separate-goals-from-requirements-in-plan-stage
- **Template Version**: 2.1

## Goal
Design the minimal set of instruction-doc edits that make the plan stage enforce the
goals-vs-requirements boundary its two-phase structure already implies: goals capture
the owner's request faithfully (why **and** explicit deliverables), requirements carry
the "best part is no part" discipline, and any scope change surfaces to the owner.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

For an instruction-text change these map to: **Testability** = the output-level replay
check (SC5) — re-run the trigger scenario and confirm no goal-narrowing/silent cut;
**Readability/Consistency** dominate — wording must be unambiguous and match each doc's
existing voice; **Reversibility** is high (every edit is a doc revert).

## Key Decisions

### KD1 — Goals doc records both "why" and explicit request; kill the lossy single-sentence
- **Decision**: In `planning.md` and the `cwf-task-plan` SKILL, replace "single-sentence
  objective that captures the *why*" with an instruction to record **both** the intent
  (why) **and** the user's explicit deliverables, preserving named deliverables verbatim
  in intent; prohibit paraphrase that drops any named deliverable.
- **Rationale**: The lossy paraphrase is the first half of the Task-31 failure — it let
  "ship simple + percent" collapse to "liveness".
- **Graceful-empty**: when the request is a genuine vague one-liner with no named
  deliverables, the instruction and template placeholder must permit "none stated" —
  never pressure the agent to invent deliverables (avoids manufacturing capture-side noise).
- **Trade-offs**: Goal sections get slightly longer; accepted — faithful capture beats
  brevity here.

### KD2 — "Best part is no part" fenced to the means, kept in every task type's path
- **Decision**: Do **not** simply move the maxim from `planning.md` (a) to
  `requirements.md` (b). Only *feature* and *discovery* have a requirements phase, so a
  bugfix/hotfix/chore would lose the maxim entirely (robustness finding). Instead:
  - `planning.md` (goals — universal to all 5 types): keep a **short fenced** statement —
    "best part is no part" applies to the *means/approach* used to achieve the goal,
    **never** to the goal itself or the user's explicit deliverables. Remove the unfenced
    "what can be removed/simplified?" prompts that currently sit beside goal-capture.
  - `requirements.md` (types that have phase b): the fuller discipline — actively challenge
    assumed/default requirements (counter the LLM default-to-convention bias).
- **Rationale**: The actual bug was the maxim sitting *unfenced* beside goal-capture, not
  its mere presence. Fencing fixes the conflation while keeping the maxim first-class and
  visible to every task type.
- **⚠ Owner decision surfaced**: this departs from the literal "move it to the requirements
  phase" framing to honour the underlying intent (keep it first-class for *all* work).
  Alternatives: **(A)** `requirements.md` only — simplest, but the 3-type coverage hole;
  **(C)** also place it in `implementation.md` (d, universal) — most complete, some
  duplication. Recommendation is the fenced approach above; flagged for sign-off before exec.
- **Non-goal guard**: the maxim is kept first-class, never weakened or removed.

### KD3 — Goals are owner-owned; scope changes surface, never decided silently
- **Decision**: State in the goals doc + SKILL that goals are near-inviolable — the agent
  must not unilaterally narrow **or** expand a goal; any goal/why tension, or a beneficial
  scope change in **either** direction, is surfaced to the owner as a decision.
- **Rationale**: Second half of the Task-31 failure (a review agent proposing to defer a
  user-named deliverable).

### KD4 — Single-source the reviewer scope rule in shared-rules; refresh its hash
- **Decision**: Add the "a user-stated goal is never a silent de-scope target; surface
  scope changes to the owner" rule to `cwf-agent-shared-rules.md` **only** — as a **new
  top-level section** (the doc is currently all tool-selection guidance; do not shoehorn it
  under the tool-tier heading). Do **not** edit the ~10 reviewer agent defs (5
  `cwf-plan-reviewer-*` + 5 `*-reviewer-changeset`), which all link to shared-rules.
  `cwf-agent-shared-rules.md` is hash-tracked → refresh its entry in
  `.cwf/security/script-hashes.json` in the **same commit** (per hash-updates convention);
  no other target file is hash-tracked.
- **Rationale**: Satisfies the shared-rules inclusion bar (2+ reviewer roles; rooted in the
  Task-31 incident) and dogfoods "best part is no part" — **1 file instead of 11**.
- **Trade-offs**: Relies on the agent→shared-rules link (all ~10 present today, verified);
  if a reviewer body later drops the link, the rule silently stops reaching it — d's
  validation should note this.

### KD5 — Bake the obligation into checklists, not prose alone
- **Decision**: Add faithful-capture + surface-scope items to the `cwf-task-plan` SKILL
  **Success-Criteria checklist**, and update the **pool** template Goal placeholder
  (`.cwf/templates/pool/a-task-plan.md.template`, line 13 — the symlink source; never edit
  a per-type symlink) to prompt for why + explicit deliverables.
- **Rationale**: Mitigates the "prose under-followed" risk — LLMs honour checklist gates
  and template scaffolds more reliably than narrative guidance.

## System Design

### Component Overview (change surface, with hash status)
- **`.cwf/docs/workflow/workflow-steps/planning.md`** (goals phase doc — universal to all 5
  task types) — *not hashed*. KD1 (dual capture), KD2 (**keep** a fenced means-only
  simplicity pointer; remove the unfenced "what can be removed?" prompts), KD3 (owner-owned
  + surface).
- **`.claude/skills/cwf-task-plan/SKILL.md`** (goals skill) — *not hashed*. KD1 (Step 6 key
  question), KD5 (Success-Criteria checklist items).
- **`.cwf/templates/pool/a-task-plan.md.template`** (goal placeholder — symlink source) —
  *not hashed*. KD5 (line 13 prompt).
- **`.cwf/docs/workflow/workflow-steps/requirements.md`** (requirements phase doc — phase b,
  feature/discovery only) — *not hashed*. KD2 (challenge-defaults discipline).
- **`.cwf/docs/skills/cwf-agent-shared-rules.md`** (reviewer shared rule) — **HASHED**. KD4
  (scope rule as new top-level section + same-commit hash refresh).

### Data Flow (control flow the edits enforce)
1. **Goals phase** (`cwf-task-plan`/a) → capture why + explicit deliverables faithfully;
   no simplicity-cutting here. Goal is owner-owned.
2. **Requirements phase** (`cwf-requirements-plan`/b) → apply "best part is no part";
   challenge default/assumed requirements; requirements are the cuttable means.
3. **Review phase** (plan + exec reviewers) → may propose requirement cuts, but a
   user-stated **goal** is off-limits; a beneficial scope change surfaces to the owner.

## Interface Design (instruction contracts)
- **Goal-section contract**: must contain (a) the why/intent, and (b) the user's explicit
  deliverables preserved verbatim-in-intent. Failure mode to prevent: (b) collapsed into (a).
- **Requirements-phase contract**: actively test whether each requirement is *actually*
  needed ("best part is no part"); do not inherit the conventional/default requirement set.
- **Surfacing contract**: trigger = a user-explicit goal/deliverable in tension with the
  stated why, OR a beneficial scope change in either direction. Action = surface to the
  owner as a decision; silent resolution is prohibited. Scope the trigger to user-explicit
  goals — routine requirement selection stays inside the requirements phase (noise guard).

## Constraints
- Must **not** de-scope "best part is no part" — relocate, keep first-class (KD2 guard).
- No individuals named — use roles.
- Minimal hashed-file churn: only `cwf-agent-shared-rules.md` (KD4).
- No new standalone doc — guidance lives in the existing phase docs.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: >1 week? No.
- [x] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? Related facets of one boundary, tightly coupled.
- [x] **Risk**: high-risk isolation needed? No.
- [x] **Independence**: separable? Weakly; one coherent change.

**Verdict**: No decomposition.

## Validation

**Binding regression checks (deterministic — these are the real gates):**
- [ ] `grep` confirms the unfenced "what can be removed/simplified?" prompts are gone from
      `planning.md`, and a fenced means-only pointer is present.
- [ ] `grep` confirms "best part is no part" survives in the workflow for **every** task
      type's phase path (not orphaned) — fenced in `planning.md` (universal) and, where the
      chosen option adds it, in `requirements.md`/`implementation.md`.
- [ ] `grep` confirms the dual-capture instruction (why + explicit deliverables) is present
      in `planning.md`, `cwf-task-plan/SKILL.md`, and the pool template.
- [ ] Scope rule present in `cwf-agent-shared-rules.md` as a new top-level section; the ~10
      reviewer agent defs are untouched and still link to it.
- [ ] `cwf-manage validate` clean — hash refresh for `cwf-agent-shared-rules.md` landed in
      the same commit.

**Confirmatory (soft — a single green pass is not proof):**
- [ ] Output-level replay of the trigger scenario yields no goal-narrowing and no silent
      de-scope against a user-named deliverable.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design decisions KD1–KD6 all implemented as specified; the recommended fenced KD2 option
(maxim stays universal in `planning.md`, fenced to means) was the one exec executed.

## Lessons Learned
Encoding the goal/requirement distinction as a *phase boundary* (goals-step vs
requirements-step docs) rather than a prose caveat is what makes it agent-enforceable.
The robustness advisory (cross-reference to a phase bugfix/hotfix/chore lack) is a design
gap KD2 scoping foresaw and deliberately left for a follow-up.
