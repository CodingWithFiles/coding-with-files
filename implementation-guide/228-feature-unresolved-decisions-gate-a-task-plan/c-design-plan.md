# unresolved-decisions gate for a-task-plan - Design
**Task**: 228 (feature)

## Task Reference
- **Task ID**: internal-228
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/228-unresolved-decisions-gate-a-task-plan
- **Template Version**: 2.1

## Goal
Resolve the open decisions flagged in a-task-plan and specify exactly which files change,
so implementation is mechanical. This is a documentation/template/skill change — the SaaS
sections of this template (frontend/backend/DB, API endpoints, data models) are N/A and
mapped to their honest equivalents below.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Resolved Open Decisions
Each resolves an open decision named in `a-task-plan.md` §Open Decisions.

### D1 — Enforcement altitude: guidance-at-authoring-time, **no deterministic check**
- **Decision**: The gate is delivered as authoring-time guidance embedded where the plan
  is written (template prompt + reference doc + skill completion-gate). No new
  `plan-mechanical-check` rule, no new script.
- **Rationale**:
  - **Coverage**: `plan-mechanical-check` scans only `b-/c-/d-` plan files and the a-phase
    runs **no** plan-review MAP at all (`cwf-task-plan` SKILL has no Step-8 review). R4's
    primary target is a-task-plan `Success Criteria`, which a check would not reach without
    new plumbing — cost the requirement does not justify.
  - **Correctness > everything (NFR5)**: "mechanism-named" is a semantic judgement; a
    keyword heuristic would mislabel legitimate criteria (false positives), and NFR5 makes
    a low false-positive rate a *hard* requirement. Guidance has zero false positives.
  - **Fewer moving parts**: guidance adds no code, no hash-tracked surface, no maintenance
    (the best part is no part). It reaches the author at the exact moment they write the
    criterion.
  - **Scope hygiene**: keeps clear of R13 (which *does* extend `plan-mechanical-check`).
- **Trade-off**: Guidance advises rather than mechanically blocks. Stated honestly: this
  trades away *all* mechanical detection (no false positives, but a 100% false-negative
  ceiling — nothing is ever caught automatically), so the gate's efficacy rests on
  author/agent diligence. The sole backstop is the skill's own Success-Criteria checklist
  (I2 below): the agent must confirm the gate before the checkpoint, which is how every
  other planning-phase norm in CwF is enforced. This is the accepted posture under NFR5
  (advise-or-surface), not a mechanical block.
- **Reversibility**: If a robust check later proves warranted, it can be added under R13's
  umbrella without unwinding this guidance.

### D2 — Gate location: reference doc (authority) + template (prompt) + skill (gate)
- **Decision**: Three coordinated, reuse-first surfaces, each already in the plan path:
  1. **`planning.md`** — the authority: carries the gate's definition, the crisp definition
     of "mechanism-named criterion", and the worked examples (FR3). Single source of truth.
  2. **`a-task-plan.md.template`** — the prompt: a new `## Open Decisions` section and a
     sharpening note on `## Success Criteria`, pointing to `planning.md`.
  3. **`cwf-task-plan` SKILL** — the gate: two new Success-Criteria checklist items so the
     agent must confirm the gate before the phase-a checkpoint.
- **Rationale**: The skill already instructs "Read `planning.md` for detailed planning
  guidance", so the authority doc auto-surfaces. Definition lives once (`planning.md`),
  the template prompts, the skill enforces — no duplicated prose, each surface plays to
  its role.
- **Trade-off**: Three files vs one. Justified: a template prompt with no reference is
  cryptic; a reference with no prompt is unread; a prompt+reference with no skill gate is
  skippable. Each is load-bearing.

### D3 — "Open Decisions" is a new top-level section, not folded into Constraints
- **Decision**: Add `## Open Decisions` between `## Constraints` and `## Decomposition
  Check`. A constraint is a *fixed* boundary; an open decision is an *unresolved* choice —
  distinct concepts that read poorly merged.
- **Trade-off**: One more section in the template. It is additive (see D5). Note this
  *diverges* — deliberately — from this task's own dogfood, which nested Open Decisions as
  an H3 *under* `## Constraints` (`a-task-plan.md` §Constraints); the top-level H2 is the
  better shipped form precisely because constraint ≠ open decision, and the dogfood's
  placement was expedient, not exemplary.

### D4 — Definition of "mechanism-named criterion" (FR3), lives in `planning.md`
- **Definition**: A success/acceptance criterion is *mechanism-named* if its statement of
  "done" is worded around a specific chosen means — a named tool, library, data structure,
  transport, file format, algorithm, flag, or component — rather than the observable end.
  **Litmus test**: if a legitimate change of mechanism that still achieves the goal would
  force the criterion to be reworded, it is mechanism-named. An *outcome-shaped* criterion
  states an observable result and survives that change.
- **Worked examples** (≥1 positive, ≥1 negative — FR3):
  - ✗ mechanism-named: "Ranks results with a Redis sorted-set." (names Redis + sorted-set)
  - ✓ outcome-shaped: "Returns results in rank order." (survives a storage swap)
  - ✗ mechanism-named: "Adds a `--json` CLI flag." (names the flag mechanism)
  - ✓ outcome-shaped: "A caller can obtain the report as machine-readable output."

### D5 — Additivity strategy (FR4/FR5, AC3)
- **Decision**: Only *add* a section and *append* guidance; rename/remove nothing. The
  a-task-plan structural readers (`status-aggregator`, context-inheritance) match specific
  headers and tolerate unknown extra sections, so a new `## Open Decisions` cannot break a
  pre-change v2.1 plan. Verified by the AC3 regression fixture in the testing phase.

## System Design
### Component Overview (files changed)
- **`.cwf/docs/workflow/workflow-steps/planning.md`** (untracked by hashes): authority —
  one definition-and-examples block (D4), plus new entries appended to the *existing*
  `Focus on` / `Avoid` / `Key Questions` lists. No free-standing "gate description" prose
  restating the same thing a third time.
- **`.cwf/templates/pool/a-task-plan.md.template`** (untracked): prompt — `## Open
  Decisions` section + `## Success Criteria` sharpening note. Reaches all task types via
  the existing per-type symlinks (no per-type edits).
- **`.claude/skills/cwf-task-plan/SKILL.md`** (untracked): gate — two Success-Criteria
  checklist items.
- **No script, no hash-tracked file, no new test harness beyond fixtures.**

### Data Flow (author's path through the gate)
1. Author runs `/cwf-task-plan` → skill Step 5 reads `planning.md` (definition + examples).
2. Author fills the template's `## Open Decisions` (each open choice as a question, or
   "None open — <why>") and writes outcome-shaped `## Success Criteria`.
3. Skill Step "Success Criteria" checklist forces confirmation both are satisfied before
   the phase-a checkpoint commit.

## Interface Design
### Template section contract (`## Open Decisions`)
- Heading `## Open Decisions`, placed immediately after `## Constraints`.
- Body: a one-line instruction + a bulleted prompt; the "none" escape is
  `None open — <one-line justification>` (bare "none" is non-conformant per FR1).

### Success Criteria sharpening note (`## Success Criteria`)
- A short HTML-comment/inline note: criteria must be outcome-shaped, not mechanism-named;
  see `planning.md` for the definition and examples. (Reuses the template's existing
  "measurable outcome" phrasing rather than introducing a parallel vocabulary.)

### I2 — SKILL Success-Criteria gate (`cwf-task-plan/SKILL.md`) — the enforcing surface
This is the only surface that catches a non-conformant plan (D1 ships no check), so its
contract is specified, not left as "two items". Append two checkbox items to the skill's
existing `## Success Criteria` list, each asserting one observable conformance:
- `[ ] Open Decisions captured — every open surface/mechanism/constraint choice is named
  as a question, or an explicit "None open — <justification>" is given (not a bare token)`
  → confirms FR1.
- `[ ] Success criteria are outcome-shaped — none is named after a not-yet-chosen mechanism
  (see planning.md definition)` → confirms FR2.
Wording may be tightened in implementation, but each item must map 1:1 to FR1 / FR2 so the
gate is mechanical for the agent to self-check before the phase-a checkpoint.

## Constraints
- Additive only; a-task-plan v2.1 format stable (D5).
- `.cwf/templates/pool/` single-source + per-type symlinks preserved (edit pool only).
- No hash-tracked file touched → no `script-hashes.json` refresh needed this task.
- Skill edits are session-cached (load at session start) — they ship for future
  sessions/installs, not live this session; not a blocker.

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — three files, one cohesive change.
- [ ] **Risk**: High-risk isolation needed? No.
- [ ] **Independence**: Separable parts? No benefit (see a-task-plan).

**Verdict**: 0 signals — single task, no subtasks.

## Validation
- [ ] Design satisfies FR1–FR5 and honours the Non-Goals (no R6/R13, no check per D1).
- [ ] Every changed file confirmed untracked by `script-hashes.json` (no hash refresh).
- [ ] Additivity (D5) verifiable by an AC3 regression fixture in the testing phase.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five design decisions implemented verbatim (D1 guidance-only, D2 three surfaces, D3 new
`## Open Decisions` H2, D4 definition + litmus + examples, D5 additive-only); no design revision
needed during exec.

## Lessons Learned
Choosing enforcement altitude (guidance vs deterministic check) early closed the one open cost
driver and kept the estimate on target; "guidance vs check" is an altitude decision, not a
strength one.
