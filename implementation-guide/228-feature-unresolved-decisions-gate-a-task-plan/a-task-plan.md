# unresolved-decisions gate for a-task-plan - Plan
**Task**: 228 (feature)

## Task Reference
- **Task ID**: internal-228
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/228-unresolved-decisions-gate-a-task-plan
- **Baseline Commit**: b8b0723d05abfd11ae4f90bbe223628e7a0f21c5
- **Template Version**: 2.1

## Goal
Add an "unresolved decisions" gate to the task-plan phase and stop mechanism-named
acceptance criteria, so open surface/mechanism/constraint choices are named at plan
time rather than discovered at design or exec.

**Why (intent):** Task 219's cross-project synthesis (S5, R4) found that late
surface/mechanism decisions — chat transport, firewall model, UUID anchor, project
layout — routinely surfaced at design or exec instead of task-plan, driving ~3× re-plans
across 6 projects (gocryptoknock, lensman, thenetworking, gresearch, gate, lmm, terminfo).
A related failure: acceptance criteria named after a chosen mechanism age badly after a
pivot, so "done" tracks the mechanism instead of the outcome. Front-loading the open
decisions and keeping ACs outcome-shaped is pure planning-time front-loading with no
downstream cost.

**Explicit request:** R4 from the Task 219 backlog group, verbatim: *"Add an 'unresolved
decisions' gate to `a-task-plan` (name every open surface/mechanism/constraint) and forbid
mechanism-named acceptance criteria."*

<!-- The goal is owner-owned. Do not unilaterally narrow or widen it. Surface any
     scope change (either direction) or goal/why tension to the owner as a decision. -->

## Success Criteria
<!-- Outcome-shaped by design: this task bans mechanism-named ACs, so its own ACs must
     describe observable outcomes, not the mechanism (template section / skill prose /
     check) that delivers them — that choice is an open decision for the design phase. -->
- [ ] At task-plan time the author is prompted to name every open surface/mechanism/
      constraint decision, so unknowns are explicit before the requirements phase rather
      than surfacing at design or exec.
- [ ] The workflow steers acceptance criteria toward observable outcomes and discourages
      criteria named after a not-yet-chosen mechanism.
- [ ] The behaviour reaches a newly initialised CwF project (seeded) and is available to
      an updating install.
- [ ] Existing task-plan behaviour is unchanged: goal ownership, estimate, decomposition
      signals, status, and the "why/explicit request" split all still work as before.
- [ ] The change passes CwF's own plan-review and security/hash validation with no drift.

## Original Estimate
**Effort**: ~1 day-equivalent (docs + template + skill edits; a deterministic check would add a little)
**Complexity**: Low
**Dependencies**: None blocking

## Major Milestones
1. **Requirements**: Define the gate's observable behaviour and a testable definition of
   "mechanism-named AC"; record the enforcement-altitude question as a named decision.
2. **Design**: Choose where the gate lives (template section, skill guidance, and/or a
   deterministic check) so it reuses existing sections rather than duplicating them.
3. **Implementation & Testing**: Edit the a-task-plan template / skill / planning doc
   (plus any check), seed reaches new inits, verify guidance present and behaviour intact.

## Risk Assessment
### High Priority Risks
- **Risk 1**: "Mechanism-named AC" is a fuzzy notion; a deterministic enforcement check
  could produce false positives that erode trust in the gate.
  - **Mitigation**: Require a crisp, testable definition in requirements; prefer guidance
    over a check unless a robust, low-false-positive rule is found (decide in design).
- **Risk 2**: Overlap with existing surfaces — the template's `Constraints` section, R6
  (complexity tier + risk register), and R13 (extend `plan-mechanical-check`) all touch
  a-task-plan; naive addition risks duplicated/competing structure.
  - **Mitigation**: Audit existing a-task-plan sections and the adjacent backlog items in
    design; reuse/extend rather than add a parallel section.

### Medium Priority Risks
- **Risk 3**: The a-task-plan template is symlinked from `.cwf/templates/pool/` and the
  `cwf-task-plan` skill file is hash-tracked; edits must follow the hash-update convention
  and per-type symlink layout or validation drifts.
  - **Mitigation**: Disclose every hashed/ shipped file at plan time; refresh
    `script-hashes.json` in the same commit; verify symlinks unbroken.

## Dependencies
- None blocking. Adjacent (not prerequisite) to R6 and R13, which also modify a-task-plan;
  coordinate structure so the three don't collide, but this task can ship independently.

## Constraints
- Must reach both new inits (seeded via the shipped template/skill) and be safe for an
  updating install (no breaking change to the a-task-plan file format v2.1).
- If any Perl/helper is touched, follow the perl + hash-update conventions.
- Do not alter goal-ownership or decomposition behaviour.

### Open Decisions (front-loaded; to be resolved in requirements/design, not here)
<!-- Dogfooding R4: this task names its own open surface/mechanism decisions up front. -->
- **Gate location**: new template section vs `cwf-task-plan` skill prose vs both — and how
  it relates to the existing `Constraints` section (extend vs add).
- **AC-ban enforcement altitude**: guidance-only, or a deterministic check (and if a check,
  whether it belongs in `plan-mechanical-check`, overlapping R13's scope).
- **Definition of "mechanism-named AC"**: the precise, testable heuristic the gate applies.
- **Scope boundary vs R6/R13**: what this task owns vs what it explicitly leaves to those.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — a low-complexity docs/template/skill edit.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — the two deliverables
      (decisions gate, AC-shape rule) are one cohesive "keep the plan honest" change on a
      single surface (a-task-plan).
- [ ] **Risk**: High-risk components needing isolation? No.
- [ ] **Independence**: Can parts be worked on separately? Marginally, but they share the
      same file and reviewer context; splitting would add overhead without benefit.

**Verdict**: 0 signals triggered — keep as a single task, no subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Plan delivered as written: R4 scoped as a guidance-only, single-surface (`a-task-plan`) change
with two deliverables (open-decisions gate + outcome-shaped-AC rule); 0 decomposition signals;
this task's own open decisions front-loaded (dogfooding). No scope change through exec.

## Lessons Learned
Front-loading this task's own open decisions mapped almost 1:1 onto design decisions D1–D5,
making the design phase resolution rather than discovery — the exact benefit R4 exists to produce.
