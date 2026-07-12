# Separate goals from requirements in plan stage - Implementation Execution
**Task**: 226 (bugfix)

## Task Reference
- **Task ID**: internal-226
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/226-separate-goals-from-requirements-in-plan-stage
- **Template Version**: 2.1

## Goal
Execute the KD1–KD6 instruction-doc edits from d-implementation-plan.md — five prose files
plus the same-commit hash refresh — to enforce the goals-vs-requirements boundary.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Subtask gate (phase f) passed; owner-decision gate (KD2 = fenced) confirmed
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan

## Actual Results

### Step 0: Owner-decision gate (KD2) — STOP
- **Planned**: Confirm owner signed off the KD2 option before editing.
- **Actual**: Owner selected the **recommended fenced approach** on plan review — "best part
  is no part" stays universal in `planning.md` (fenced to means), fuller challenge-requirements
  discipline added to `requirements.md`. Matches c/d/e as written; no plan rework.

### Step 1: `planning.md` (goals phase, universal)
- **1a (KD1)**: Replaced the lossy `- Single-sentence objective that captures the "why"` with a
  dual-capture instruction (why **and** the user's explicit request, every named deliverable
  verbatim, "none stated" allowed, no lossy paraphrase).
- **1b (KD2)**: Replaced the entire "Simplicity Principles" block (intro + both maxims + the
  "what can be removed/simplified?/minimal solution?" prompts) with a **Goal vs means** fence —
  the maxims apply to the *means*, never the goal or named deliverables; requirement-challenging
  belongs to later phases; "you can't cut your way to success".
- **1c (KD3)**: Added a **Goal ownership** block — goal is owner-owned/near-inviolable; do not
  unilaterally narrow or widen; surface any scope change (either direction) or goal/why tension
  to the owner as a decision.

### Step 2: `requirements.md` (requirements phase, feature/discovery)
- **2a (KD2)**: Added a "Simplicity — challenge every requirement" bullet under **Focus on** —
  this is where the maxims apply; test each requirement rather than inheriting the default set
  (counters the LLM default-to-convention bias); a cut touching goal/named deliverables surfaces
  to the owner, never applied silently.

### Step 3: `cwf-task-plan/SKILL.md` (goals skill)
- **3a (KD1)**: Step 6 key question now asks for **both** the "why" and the user's explicit
  request (named deliverables, verbatim), replacing "Single-sentence objective?".
- **3b (KD5)**: Added two Success-Criteria items — (i) goal records why + explicit request
  faithfully, no lossy paraphrase; (ii) any scope change or goal/why tension surfaced to the
  owner, not resolved silently.

### Step 4: `a-task-plan.md.template` (pool source)
- **4a (KD5)**: Replaced line 13 `{{description}} - single sentence objective` with a
  dual-capture placeholder (**Why (intent)** + **Explicit request**, "none stated" if none) and
  an owner-owned HTML comment. Verified all 5 per-type symlinks still resolve to the pool file
  (mode 120000, identical blob → `../pool/a-task-plan.md.template`).

### Step 5: `cwf-agent-shared-rules.md` (reviewer binding) — HASHED
- **5a (KD4)**: Appended a new top-level section `## Goal integrity and scope changes` — a
  user-stated goal/named deliverable is never a silent de-scope target; surface scope changes
  (either direction) and goal/why tension to the owner; rooted in the Task-31 incident. The ~10
  reviewer agent defs were **not** edited (all 10 still carry the shared-rules link, verified).
- **5b (KD6)**: Hash refresh per `hash-updates.md` § How (hand-edit is the sanctioned method;
  no `cwf-manage` refresh command exists):
  1. Pre-refresh verify: doc untouched since Task 186 (its hash-set commit) — no unhashed drift.
  2. `sha256sum` → `d079837a6d29fe38af83cd169ad5c7618d953c2471076be3f2d2943500582e3f`.
  3. Hand-edited the `agent-shared-rules` `sha256` entry in `script-hashes.json`
     (was `cff45fb3…`).
  4. Doc **and** manifest staged in the **same commit**; `cwf-manage validate` → `OK`.

### Step 6: Validate
- `cwf-manage validate` → `[CWF] validate: OK`.
- Binding smoke-checks: removed strings absent from all three goal-phase targets;
  "best part is no part" present in **both** `planning.md` (fenced) and `requirements.md`
  (KD2 no-orphan — bugfix/hotfix/chore still see it via planning.md); all new sections present.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] No b-requirements-plan.md (bugfix type — no requirements phase)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred

## Files Changed
- `.cwf/docs/workflow/workflow-steps/planning.md` (KD1, KD2, KD3)
- `.cwf/docs/workflow/workflow-steps/requirements.md` (KD2)
- `.claude/skills/cwf-task-plan/SKILL.md` (KD1, KD5)
- `.cwf/templates/pool/a-task-plan.md.template` (KD5)
- `.cwf/docs/skills/cwf-agent-shared-rules.md` (KD4) — **HASHED**
- `.cwf/security/script-hashes.json` (KD6 hash refresh, same commit)

## Changeset Reviews (Step 8 — 5-reviewer MAP, run in parallel)
Branch is a task branch (not main). `security-review-changeset` → exit 0, 1027 lines
(77 production); `best-practice-resolve` → 3 matched entries. All five reviewers launched;
`security-review-classify` returned `no findings` for all five (launched set = classified set,
none dropped). Verbatim outputs archived in the per-task scratch `.out` files.

### Security Review
**State**: no findings

Documentation/instruction-only change; no code, shell, Perl, or env surface. Verified the
`cwf-agent-shared-rules.md` sha256 refresh (`d079837a…`) matches on-disk and is in the same
commit — in-scope for `cwf-manage validate`, so not a finding.

### Best-Practice Review
**State**: no findings

3 matched sources (golang / postgres / perl), all readable. Changeset is entirely
instruction-doc/template/backlog prose plus a JSON hash refresh — no Go/Perl/Postgres code
for the language conventions to apply to. Genuine clean, not an inability to review.

### Improvements Review
**State**: no findings

Reuses the shared-rules link mechanism (1 file vs ~11 reviewer defs), the template symlink
pool, and the existing same-commit hash procedure; no new tooling. The cross-doc restatements
serve disjoint audiences (reviewer subagents vs planning author vs generated scaffold) and are
not avoidable duplication; the SKILL-checklist restatement is the deliberate KD5 mitigation.

### Robustness Review
**State**: no findings

Edge cases handled: "none stated" fallback (no invented deliverables), "best part is no part"
preserved fenced in universal `planning.md` (KD2 no-orphan), scope tension routed to owner.
Hash-integrity path intact (all 10 reviewer defs still link shared-rules; none edited).
**Advisory (not a finding), surfaced to owner**: the `planning.md` means-fence points to "the
requirements **and implementation** phases," but the fuller challenge-requirements discipline
text lives only in `requirements.md` (feature/discovery) — so for bugfix/hotfix/chore that
cross-reference has no dedicated downstream discipline block. The maxim itself is still stated
inline in `planning.md` for all types, so this is a dangling cross-reference, not a broken path.
**Disposition**: not fixed in this task — adding challenge-requirements text to the
implementation-phase docs is beyond this bugfix's KD2 scope; recorded for the owner to accept
or spin into a follow-up.

### Misalignment Review
**State**: no findings

Reuses shared-rules link propagation, the hash-updates same-commit rule, the
`d-implementation-plan.md.template` HTML-comment pattern, and in-place phase-doc structure; no
reinvention. Inclusion bar satisfied (2+ roles, Task-31 incident); British spelling and
role-only phrasing preserved.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See per-step results above.

## Lessons Learned
Single-source reviewer binding (KD4 in one shared-rules file, not 10 defs) kept the change
minimal and was independently confirmed clean by the misalignment reviewer. Surfacing the
two advisories without fixing them is the correct KD2 discipline — expanding scope to fix
them would re-commit the boundary-stretch error the task exists to prevent.
