# unresolved-decisions gate for a-task-plan - Requirements
**Task**: 228 (feature)

## Task Reference
- **Task ID**: internal-228
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/228-unresolved-decisions-gate-a-task-plan
- **Template Version**: 2.1

## Goal
Specify the behaviour the task-plan phase must exhibit so open surface/mechanism/constraint
decisions are named at plan time and acceptance criteria stay outcome-shaped. Requirements
state *what* and *how well*, not *where* — the gate's location (template section vs skill
prose vs a check) is an open decision carried to design.

## Functional Requirements

Section names below use the codebase's own vocabulary: the a-task-plan phase's criteria
section is `## Success Criteria` (`.cwf/templates/pool/a-task-plan.md.template`), and the
b-requirements phase's is `## Acceptance Criteria`. The mechanism-named rule (FR2) binds to
**both**, with a-task-plan `Success Criteria` as the primary target named by R4.

### Core Features
- **FR1 — Open-decisions gate**: The shipped a-task-plan surface (template and/or skill)
  must prompt the author to enumerate every open surface/mechanism/constraint decision
  (e.g. transport, storage, project layout, licensing-class) at plan time. A plan that
  silently defers such a choice to design or exec is non-conformant; an explicit "none open"
  is conformant only with a one-line justification (a bare token invites gate-bypass). This
  extends — does not contradict — `planning.md`'s existing "defer specific technology choices
  to design" guidance: the author *names* an unresolved decision, they do not *resolve* it.
  *Verify via*: AC1.
- **FR2 — Forbid mechanism-named criteria**: The workflow must forbid success/acceptance
  criteria named after a specific, not-yet-chosen mechanism and steer authors to
  outcome-shaped criteria. This sharpens the template's existing "measurable outcome"
  guidance (`a-task-plan.md.template` Success Criteria; `planning.md`), it does not add a
  parallel vocabulary. *(The prohibition is the norm; the enforcement altitude — guidance
  vs a deterministic check — is an open decision for design.)* *Verify via*: AC2.
- **FR3 — Testable definition**: The task must supply a crisp, applies-consistently
  definition of "mechanism-named criterion" usable by a human author and any tooling,
  shipping with ≥1 positive (mechanism-named) and ≥1 negative (outcome-named) worked
  example. *Verify via*: AC2.
- **FR4 — Reach**: The behaviour must be seeded into newly initialised projects and be
  available to updating installs, via the existing template/skill distribution path.
  *Verify via*: AC3.
- **FR5 — No regression**: All existing a-task-plan behaviour is preserved — goal-ownership
  note, estimate, milestones, decomposition check, status, and the why/explicit-request
  split. *Verify via*: AC3, AC4.

### User Stories
- **As a** CwF task author **I want** the plan phase to make me name the choices I haven't
  made yet **so that** they don't ambush me as a re-plan at design or exec.
- **As a** reviewer **I want** success/acceptance criteria that describe outcomes **so that**
  "done" survives a change of mechanism and I can verify it without re-reading the design.

## Non-Functional Requirements
### Performance (NFR1)
- Guidance-only has zero runtime cost. A deterministic check, if design chooses one, is a
  single-pass scan of the plan file with no perceptible delay to plan-phase tooling.

### Usability (NFR2)
- The gate's prompt is self-explanatory, carries examples, and matches the existing
  template's tone and reading level.

### Maintainability (NFR3)
- Reuse existing surfaces — the `.cwf/templates/pool/` + per-type symlink layout, the
  `cwf-task-plan` skill structure, and the `plan-mechanical-check` harness if a check is
  added — rather than new parallel machinery. Any added check is unit-testable with
  positive and negative fixture plans.

### Security (NFR4)
- If any hash-tracked file (skill, agent-rules) or Perl helper is edited, follow the
  hash-update convention (refresh `.cwf/security/script-hashes.json` in the same commit)
  and the perl conventions (`use utf8;`, core-only, `PERL5OPT=-CDSLA`).
- The gate consumes plan text as data only. Any added check reads the plan as a fixed,
  known path — no shell interpolation of file contents, no `qx`/backticks on plan text —
  so no new command-execution or injection surface is introduced.

### Reliability (NFR5)
- Any conformance/AC check must fail safe and be deterministic: for identical input it
  either advises without blocking or surfaces the violation loudly — it never silently
  passes a mechanism-named criterion. A low false-positive rate is a hard requirement (a
  noisy gate gets ignored; see High Risk 1 in a-task-plan).

## Constraints
- **Additive only** (stated once; FR4, FR5, AC3, AC4 all rely on it): a-task-plan
  file-format v2.1 stays stable — no field removed or renamed.
- `.cwf/templates/pool/` single-source + per-type symlink layout preserved.
- POSIX + core-Perl only; hash-update and perl conventions binding on any touched helper.
- Does not alter goal-ownership or decomposition semantics.

### Non-Goals (explicit scope boundaries)
- **No R6/R13 behaviour**: this task does not implement R6 (complexity tier / risk register)
  or R13 (unsourced-count claims), which also touch a-task-plan. If AC-shape enforcement
  reuses `plan-mechanical-check`, it is scoped to the mechanism-named-criterion rule alone.
- **Naming, not resolution**: the gate guarantees open decisions are *named* at plan time.
  Tracking whether they are later *resolved* (or re-surfaced) at design/exec is a separate
  concern, deliberately out of scope for this task.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — one cohesive plan-honesty change.
- [ ] **Risk**: High-risk isolation needed? No.
- [ ] **Independence**: Separable parts? Marginal; not worth the split (see a-task-plan).

**Verdict**: 0 signals — single task confirmed at requirements altitude.

## Acceptance Criteria
- [ ] AC1: The shipped a-task-plan template/skill prompts the author to enumerate open
      surface/mechanism/constraint decisions, and a plan produced through the phase carries
      that named list or a justified "none open" (FR1).
- [ ] AC2: The workflow forbids mechanism-named success/acceptance criteria and steers
      authors to outcome-shaped ones, shipping a testable definition with ≥1 positive and
      ≥1 negative worked example (FR2, FR3).
- [ ] AC3: A fresh init seeds the gate, and a v2.1 a-task-plan authored *before* the change
      still validates and parses unchanged afterwards — the additive claim verified by
      regression, not merely asserted (FR4, FR5).
- [ ] AC4: All prior a-task-plan sections and their semantics remain intact — additive
      change only (FR5).
- [ ] AC5: `cwf-manage validate` and the repo's plan-review pass; every hash-tracked edit is
      disclosed and its hash refreshed in the same commit (NFR4).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Requirements held through delivery: FR1 (name every open decision) and FR2 (outcome-shaped ACs)
both landed via the skill's two `## Success Criteria` checklist items; NFR5 (no false positives)
is what drove the design's guidance-over-check decision.

## Lessons Learned
A crisp, testable definition of "mechanism-named AC" in requirements was the precondition for
concluding, in design, that no low-false-positive mechanical check exists — so guidance was right.
