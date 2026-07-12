# unresolved-decisions gate for a-task-plan - Implementation Plan
**Task**: 228 (feature)

## Task Reference
- **Task ID**: internal-228
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/228-unresolved-decisions-gate-a-task-plan
- **Template Version**: 2.1

## Goal
Implement the three surfaces from c-design-plan (D2): `planning.md` (authority),
`a-task-plan.md.template` (prompt), `cwf-task-plan/SKILL.md` (gate). Docs/template/skill
only — no code, no hash-tracked file.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Primary Changes
- `.cwf/docs/workflow/workflow-steps/planning.md` — **authority**. Add a definition-and-
  examples block for "mechanism-named criterion" (design D4), and append entries to the
  existing `Focus on`, `Avoid`, and `Key Questions` lists. No free-standing gate-description
  prose (design improvements-review fix).
- `.cwf/templates/pool/a-task-plan.md.template` — **prompt**. Insert a new `## Open
  Decisions` section immediately after `## Constraints` (before `## Decomposition Check`),
  and add a one-line outcome-shaped-criteria note under `## Success Criteria` pointing to
  `planning.md`.
- `.claude/skills/cwf-task-plan/SKILL.md` — **gate**. Append two checkbox items to the
  existing `## Success Criteria` list (design I2), mapping 1:1 to FR1 and FR2.

### Supporting Changes
- None. Per-type templates are symlinks to the pool file (edit pool only). No
  `script-hashes.json` refresh — none of the three files is hash-tracked (design + all
  three plan-reviewers verified).
- Test fixtures for the AC3 regression live in the testing phase (e-testing-plan), not here.

**Deliberate non-edits** (recorded so the drift is a decision, not an oversight):
- `cwf-task-plan/SKILL.md` Step 6 abbreviates `planning.md`'s `Avoid`/`Key Questions`.
  Per design I2, SKILL edits are scoped to `## Success Criteria` only; the Step-6 echo is
  intentionally left as-is (the authority is `planning.md`, which the skill Step 5 reads).
- The escape token `None open — <justification>` is a *deliberately distinct* idiom from the
  template's existing `none stated` (used for the explicit-request field). They mean
  different things — `none stated` records "no deliverable named"; `None open` asserts "no
  open decision" and, unlike `none stated`, requires a one-line justification (FR1).

<!-- No symbol is deleted; the **Deletes** line is intentionally omitted. -->

## Implementation Steps
### Step 1: Authority — `planning.md`
- [ ] Under `Focus on`, add a bullet: name every open surface/mechanism/constraint
      decision at plan time (transport, storage, layout, licensing-class), as a question.
- [ ] Under `Avoid`, reconcile **both** tension lines — "Specific technology choices (save
      for design phase)" **and** "Detailed design decisions" — with a naming≠choosing
      carve-out: *naming* an unresolved surface/mechanism decision at plan time is required
      and is not the same as *resolving* it (which still waits for design). Without this,
      an author reads "detailed design decisions" and suppresses exactly what the gate wants.
- [ ] Under `Key Questions`, add: "What surface/mechanism/constraint decisions are still
      open?" and "Is any success criterion named after a not-yet-chosen mechanism?"
- [ ] Add a self-contained block "**Open-decisions gate & outcome-shaped criteria**" with
      the design-D4 definition, litmus test, and the four worked examples (2 ✗, 2 ✓).

### Step 2: Prompt — `a-task-plan.md.template`
- [ ] Insert `## Open Decisions` after `## Constraints`: one-line instruction + bulleted
      prompt; the escape hatch is `None open — <one-line justification>` (bare token
      non-conformant, FR1).
- [ ] Add an HTML-comment note under `## Success Criteria`: criteria must be outcome-shaped,
      not mechanism-named — see `planning.md`. Keep the existing "measurable outcome"
      per-criterion text (no parallel vocabulary).

### Step 3: Gate — `.claude/skills/cwf-task-plan/SKILL.md`
- [ ] Append two `- [ ]` items to the skill's **`## Success Criteria`** list (lines 47–54,
      NOT the Step-6 "Key questions" prose) per design I2 — Open Decisions
      captured-or-justified; criteria outcome-shaped. This wording *is* the entire gate
      (design D1's sole enforcement surface) — get it exact and mapped 1:1 to FR1/FR2.

### Step 4: Exec smoke check (full regression deferred to e-testing)
- [ ] Confirm the edited pool template still resolves via each per-type symlink.
- [ ] Generate a fresh task via `task-workflow create`, grep its a-task-plan for
      `## Open Decisions` + the criteria note (AC1 smoke), then delete the throwaway task.
- [ ] Sanity-parse one **existing** v2.1 a-task-plan (e.g. this task's own) with
      `status-aggregator-v2.1` / `context-inheritance-v2.1` to confirm nothing regresses;
      the formal AC3 pre/post fixture regression is authored and run in e-testing.
- [ ] `cwf-manage validate` clean (no hash/permission drift).

## Code Changes
Illustrative — exact wording finalised in exec.

### `a-task-plan.md.template` — After `## Constraints`, before `## Decomposition Check`
```markdown
## Open Decisions
List every surface/mechanism/constraint choice not yet made (transport, storage, layout,
licensing-class, …), each as a question to resolve in requirements/design. Naming ≠ choosing.
- <open decision as a question>

<!-- If genuinely none, write exactly: "None open — <one-line justification>". A bare
     "None" is not conformant. -->
```

### `a-task-plan.md.template` — under `## Success Criteria`
```markdown
<!-- Criteria must be outcome-shaped (observable results), never named after a
     not-yet-chosen mechanism. See planning.md, "Open-decisions gate & outcome-shaped
     criteria", for the definition and examples. -->
```

### `.claude/skills/cwf-task-plan/SKILL.md` — appended to `## Success Criteria`
```markdown
- [ ] Open decisions captured — every open surface/mechanism/constraint choice is named as
      a question, or an explicit "None open — <justification>" is given (not a bare token)
- [ ] Success criteria are outcome-shaped — none is named after a not-yet-chosen mechanism
      (see planning.md)
```

## Test Coverage
**See e-testing-plan.md for complete test plan** (AC1 fresh-generate grep; AC2 definition +
examples present; AC3 pre-change fixture still parses; AC4 no-regression section diff).

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

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
Implementation followed the plan's four steps exactly (authority → prompt → gate → smoke); the
only deviation was backticking two `planning.md` cross-references, flagged by the misalignment
reviewer and fixed in-phase before the f checkpoint.

## Lessons Learned
Verifying up front that all three target files were untracked by `script-hashes.json` removed the
only hash-refresh risk before any edit was made.
