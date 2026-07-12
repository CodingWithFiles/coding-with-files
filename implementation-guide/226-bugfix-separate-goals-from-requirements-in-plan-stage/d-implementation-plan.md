# Separate goals from requirements in plan stage - Implementation Plan
**Task**: 226 (bugfix)

## Task Reference
- **Task ID**: internal-226
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/226-separate-goals-from-requirements-in-plan-stage
- **Template Version**: 2.1

## Goal
Apply the KD1–KD5 edits from `c-design-plan.md` — five files, all instruction text — to
enforce the goals-vs-requirements boundary. No code, no new files.

> **Depends on the KD2 owner decision.** Steps below implement the **recommended fenced
> approach**. If the owner picks (A) `requirements.md`-only, drop step 1b's fenced pointer
> and the planning.md means-fence; if (C), add the same discipline to `implementation.md`.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/docs/workflow/workflow-steps/planning.md` — KD1 dual-capture objective; KD2 replace
  unfenced simplicity block with a means-only fence; KD3 goals owner-owned + surface.
- `.cwf/docs/workflow/workflow-steps/requirements.md` — KD2 fuller "challenge every
  requirement" discipline (this phase only exists for feature/discovery).
- `.claude/skills/cwf-task-plan/SKILL.md` — KD1 Step 6 key question; KD5 Success-Criteria items.
- `.cwf/templates/pool/a-task-plan.md.template` — KD5 line 13 Goal placeholder (pool source).
- `.cwf/docs/skills/cwf-agent-shared-rules.md` — KD4 new top-level "Goal integrity" section. **HASHED.**

### Supporting Changes
- `.cwf/security/script-hashes.json` — KD6 refresh the `cwf-agent-shared-rules.md` `sha256`
  entry by **hand-edit** in the **same commit** (per `hash-updates.md` § How). There is **no**
  `cwf-manage` hash-refresh command, and building one is forbidden (§ What NOT to build).

<!-- No named symbols deleted; only prose blocks moved/rewritten. No **Deletes** line. -->
<!-- Line numbers below are indicative only: KD2 shortens planning.md before KD1's line-20
     edit, so key exec edits off CONTENT, not literal line numbers. -->

## Implementation Steps

### Step 0: Owner-decision gate (KD2) — **STOP before editing**
- [ ] Confirm the owner has signed off the KD2 option. Default = **recommended fenced
      approach** (steps as written). If **(A)** `requirements.md`-only: skip step 1b's fence
      (keep the KD1/KD3 goal-capture edits). If **(C)**: additionally add the
      challenge-requirements discipline to `implementation.md`. Do not start Step 1 until the
      option is confirmed — this is the single decision the whole plan pivots on.

### Step 1: `planning.md` (goals phase, universal)
- [ ] **1a (KD1)** Replace line 20 `- Single-sentence objective that captures the "why"` with
      a dual-capture instruction: record **both** the "why" and the user's explicit request
      (every named deliverable, verbatim in intent); "none stated" allowed; no lossy paraphrase.
- [ ] **1b (KD2)** Replace the **entire** "Simplicity Principles" block (lines ~7–17,
      **including** the intro line "Keeping the system simple is a core goal…", both maxims,
      and the "What can be removed/simplified? … minimal solution?" prompts — leave no
      half-fenced remnant) with a short **means-only fence**: "best part is no part" applies to
      the *means*, never the goal or named deliverables; requirement-challenging belongs to
      later phases.
- [ ] **1c (KD3)** Add a goals-are-owner-owned line: do not unilaterally narrow/expand a goal;
      surface goal/why tension or any beneficial scope change (either direction) to the owner.

### Step 2: `requirements.md` (requirements phase, feature/discovery)
- [ ] **2a (KD2)** Add a "Simplicity — challenge every requirement" bullet/subsection under
      **Focus on**: apply "best part is no part" to requirements; test whether each is *actually*
      needed vs the default set; a cut touching the goal/named deliverables is surfaced, not applied.

### Step 3: `cwf-task-plan/SKILL.md` (goals skill)
- [ ] **3a (KD1)** Update Step 6 key question (line 35) from "Single-sentence objective?" to
      "Both the why and the user's explicit deliverables captured?"
- [ ] **3b (KD5)** Add two Success-Criteria checklist items: (i) goal records why + explicit
      request faithfully; (ii) any scope change/goal tension surfaced to the owner, not decided.

### Step 4: `a-task-plan.md.template` (pool source)
- [ ] **4a (KD5)** Replace line 13 `{{description}} - single sentence objective` with a
      placeholder prompting for **Why (intent)** and **Explicit request** (named deliverables;
      "none stated" if none). Verify the 5 per-type symlinks still resolve to the pool file.

### Step 5: `cwf-agent-shared-rules.md` (reviewer binding) — HASHED
- [ ] **5a (KD4)** Append a new top-level section `## Goal integrity and scope changes`: a
      user-stated goal/named deliverable is never a silent de-scope target; surface scope
      changes (either direction) and goal/why tension to the owner; cite the Task-31 incident.
- [ ] **5b (KD6)** Refresh the hash per `hash-updates.md` § How — there is **no** `cwf-manage`
      refresh command; the hand-edit **is** the sanctioned method:
      1. Pre-refresh verify: `git log --oneline <last-hash-set-commit>..HEAD -- .cwf/docs/skills/cwf-agent-shared-rules.md`
         (confirm only this task's edit intervenes).
      2. `sha256sum .cwf/docs/skills/cwf-agent-shared-rules.md`.
      3. Hand-edit the matching `sha256` entry in `.cwf/security/script-hashes.json`.
      4. Stage the doc **and** manifest in the **same commit**; then `cwf-manage validate`.
      Do **not** edit the ~10 reviewer agent defs (link-propagation relied upon).

### Step 6: Validate
- [ ] Run the binding grep assertions (see Validation Criteria) and `cwf-manage validate`.

## Code Changes (representative before/after)

`planning.md` — KD1 (line 20):
```
Before:  - Single-sentence objective that captures the "why"
After:   - Objective capturing BOTH the "why" (intent) AND the user's explicit request —
           every deliverable named, verbatim in intent; "none stated" if none. No paraphrase
           that drops a named deliverable.
```

`planning.md` — KD2 (means-fence replacing the Simplicity Principles block):
```
After:   **Goal vs means:** "best part is no part" / "reduce, reuse, recycle" are first-class
         ideals, but they apply to the MEANS of achieving the goal — never to the goal or the
         deliverables the user named. Challenge requirements in the requirements/impl phases.
```

`a-task-plan.md.template` — KD5 (line 13):
```
Before:  {{description}} - single sentence objective
After:   {{description}}

         **Why (intent):** <why this matters>
         **Explicit request:** <deliverables the user named, verbatim; "none stated" if none>
```

`cwf-agent-shared-rules.md` — KD4 (new section, appended after the Inclusion bar):
```
## Goal integrity and scope changes
A task's goal (owner intent + named deliverables) is owner-owned. You may propose cutting
REQUIREMENTS (the means), but a user-stated goal/named deliverable is never a silent
de-scope target; surface any beneficial scope change (either direction) or goal/why tension
to the owner as a decision. Rooted in the Task-31 incident.
```

## Test Coverage
**See e-testing-plan.md for complete test plan** (grep-based doc-content assertions + the
confirmatory replay).

## Validation Criteria
Binding (deterministic): the grep assertions in `c-design-plan.md` § Validation; a grep
confirming all ~10 reviewer agent defs still contain the `cwf-agent-shared-rules` link
(KD4 propagation guard); plus `cwf-manage validate` clean. Confirmatory: the trigger-scenario
replay. **See e-testing-plan.md.**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned steps executed in order; no deviations. Same-commit hash refresh (KD6) ran
per convention (pre-refresh git-log verify → hand-edit → doc+manifest one commit → validate OK).

## Lessons Learned
"None stated" as an explicit dual-capture fallback is load-bearing: without it the
instruction would pressure the agent to invent deliverables for genuine one-line requests.
