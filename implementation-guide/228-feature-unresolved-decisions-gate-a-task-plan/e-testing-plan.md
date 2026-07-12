# unresolved-decisions gate for a-task-plan - Testing Plan
**Task**: 228 (feature)

## Task Reference
- **Task ID**: internal-228
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/228-unresolved-decisions-gate-a-task-plan
- **Template Version**: 2.1

## Goal
Verify the three-surface change satisfies AC1–AC5. This is a docs/template/skill change with
no code path, so the strategy is artefact assertions + a generate-and-parse regression, not
a unit-test suite. Every test maps to an acceptance criterion in b-requirements-plan.

## Test Strategy
### Test Levels
- **Artefact assertion**: grep/read the three edited files for the required content.
- **Generation (system)**: run `task-workflow create` and inspect the produced a-task-plan.
- **Regression**: parse a *pre-change* v2.1 a-task-plan with the structural readers and
  confirm identical results before vs after the template edit.
- No unit level — there is no new code (design D1: no check, no script).

### Test Coverage Targets
- **Critical paths**: 100% of AC1–AC5 covered by ≥1 test case below.
- **Regression**: the additive claim (AC3/AC4) proven, not asserted.
- **Edge case**: the `None open` escape hatch and its bare-token non-conformance (FR1).

## Test Cases
### Functional Test Cases
- **TC-1 (AC1 — gate prompt reaches new plans)**:
  - **Given**: the edited `a-task-plan.md.template` and a clean tree.
  - **When**: `task-workflow create` generates a throwaway feature task.
  - **Then**: its `a-task-plan.md` contains a `## Open Decisions` section (immediately after
    `## Constraints`) and the outcome-shaped-criteria note under `## Success Criteria`.
    Delete the throwaway task afterwards.
- **TC-2 (AC2/FR3 — definition + examples present and correct)**:
  - **Given**: the edited `planning.md`.
  - **When**: read the "Open-decisions gate & outcome-shaped criteria" block.
  - **Then**: it carries the mechanism-named definition, the litmus test, and ≥1 positive
    (✗) and ≥1 negative (✓) worked example; the new `Focus on` / `Avoid` / `Key Questions`
    entries are present and the two `Avoid` tension lines are reconciled (naming≠choosing).
- **TC-3 (AC3 — additive, structural readers unaffected)** *regression*:
  - **Given**: a v2.1 a-task-plan committed *before* this change (fixture = this task's own
    `a-task-plan.md` at its phase-a commit `b447932`).
  - **When**: run `status-aggregator-v2.1` and `context-inheritance-v2.1` against it, and
    `cwf-manage validate`, both before and after the template edit is in place.
  - **Then**: output is byte-identical across before/after; no parse error; `validate` clean.
- **TC-4 (AC4 — no regression, additive only)**:
  - **Given**: the template diff for this task.
  - **When**: compare section headings pre/post.
  - **Then**: every prior heading (`Goal`, `Success Criteria`, `Original Estimate`,
    `Major Milestones`, `Risk Assessment`, `Dependencies`, `Constraints`, `Decomposition
    Check`, `Status`, `Actual Results`, `Lessons Learned`) is still present; the only
    structural addition is `## Open Decisions`; nothing renamed or removed.
- **TC-5 (AC5 — integrity + gate wording)**:
  - **Given**: the full changeset.
  - **When**: `cwf-manage validate`; and grep `.cwf/security/script-hashes.json` for the
    three edited paths; and read the SKILL `## Success Criteria` list.
  - **Then**: `validate` reports OK (no hash/permission drift); none of the three paths is
    in `script-hashes.json` (so no refresh was owed); the SKILL list carries the two new
    items mapping 1:1 to FR1 and FR2.
- **TC-6 (FR1 edge — none-open escape hatch)**:
  - **Given**: the template's `## Open Decisions` body.
  - **When**: read the escape-hatch instruction.
  - **Then**: it directs `None open — <justification>` and explicitly marks a bare `None`
    as non-conformant.

### Non-Functional Test Cases
- **Symlink integrity (NFR3)**: each per-type `a-task-plan.md.template` symlink still
  resolves to the edited pool file; the change was made in the pool only.
- **Usability (NFR2)**: the `## Open Decisions` prompt is self-explanatory and matches the
  surrounding template tone (read-through check).
- **Security (NFR4)**: no new script/exec/env-var surface introduced (confirmed by TC-5's
  no-hash-tracked-file result and the security plan-reviewer).
- **Performance/Reliability (NFR1/NFR5)**: N/A — no check shipped (design D1), so there is
  no runtime cost or fail-safe behaviour to exercise.

## Test Environment
### Setup Requirements
- The repo at the exec-phase HEAD; a clean working tree for the generation test.
- Throwaway task created under `implementation-guide/` and removed after TC-1 (use
  `/cwf-delete-task` or manual rm of the generated dir + branch — it is never committed).
- No test DB, no external services.

### Automation
- Run inline in g-testing-exec; no CI wiring needed for a docs change.

## Validation Criteria
- [ ] TC-1 … TC-6 all pass.
- [ ] AC1–AC5 each covered by a passing test.
- [ ] Regression (TC-3) shows byte-identical structural-reader output pre/post.
- [ ] `cwf-manage validate` clean.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned cases executed: TC-1..TC-6 PASS; the additivity assertion (AC3/AC4) was proven by a
byte-identical structural-reader regression (TC-3), not merely asserted.

## Lessons Learned
The right test for an additive template change is a parser regression against the pre-change file,
not a shape assertion — it catches a positional-reader break that a shape check would miss.
