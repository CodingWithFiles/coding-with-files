# Aggregate cross-project retrospective lessons - Requirements
**Task**: 219 (discovery)

## Task Reference
- **Task ID**: internal-219
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/219-aggregate-cross-project-retrospective-lessons
- **Template Version**: 2.1

## Goal
Specify what the investigation must produce: a corroborated, novelty-filtered,
per-axis set of follow-up-shaped CwF improvement recommendations, mined from the
retrospective corpus plus session-log and LMM friction signal.

## Functional Requirements
### Core Features
- **FR1 — Corpus extraction**: Distil the "Lessons Learned" (and equivalent
  retro sections) from every CwF project's retrospectives into one uniform
  digest via a parallel per-project map.
  - *AC*: coverage reconciles against a retrospective count captured at run start
    (survey snapshot ~558 as of 2026-07-07; log the live number and any delta) —
    not a frozen literal. A retrospective whose Lessons-Learned content is an
    unpopulated stub is classed as a coverage gap, not a contributing digest.
- **FR2 — Friction-signal overlay**: Fold in harness-level signal the retros
  under-report, from session logs and LMM.
  - *AC*: session-log and LMM friction signal is present, per axis, each attributed
    to its source; signals absent from the retros (e.g. stripped permission-prompt
    reasons) are captured distinctly. The `cwf-permissions-block` and `atch`
    sessions are the expected primary sources, but any source that is
    unavailable/empty is surfaced as a logged gap (per NFR5), never silently omitted.
- **FR3 — Axis classification**: Tag every finding to one or more of the three
  objective axes — (1) token efficiency, (2) permission-prompt reduction, (3)
  SDLC friction.
  - *AC*: no finding is left untagged; a per-axis rollup exists for each axis.
- **FR4 — Corroboration filter**: Label a finding "general" only when ≥2
  independent projects corroborate it; otherwise flag it single-project.
  - *AC*: every "general" finding lists its corroborating projects; single-project
    findings are visibly marked as such. "Independent" means distinct external
    projects; this repo's own retros count as at most one corroborator and can
    never be one of the required two on their own (Constraints weighting).
- **FR5 — Novelty diff**: Diff each candidate improvement against already-codified
  guidance — `MEMORY.md`, feedback memories, `error-patterns.md`, and *both*
  convention dirs (`docs/conventions/` for CWF-dev rules, `.cwf/docs/conventions/`
  for shipped rules) — and classify it net-new / under-enforced / already-codified.
  - *AC*: no recommendation restates an existing codified rule without labelling
    it an enforcement gap; already-codified-and-enforced items are dropped; every
    "under-enforced" label cites ≥1 corpus instance of the codified rule being violated.
- **FR6 — Prioritised recommendations**: Emit a ranked recommendation set, each
  tradeoff-stated and shaped to spawn a follow-up CwF task.
  - *AC*: each recommendation carries axis, impact, effort, an explicit
    safety↔momentum tradeoff, a one-line proposed follow-up task title, and remains
    source-attributed back to its corpus origin (traceable per FR2/FR4). The set is
    ordered impact-descending, effort-ascending as tie-break.

### User Stories
- **As a** CwF maintainer **I want** cross-project friction distilled into ranked,
  follow-up-shaped recommendations **so that** I can open remediation tasks without
  re-reading 557 retrospectives.
- **As a** CwF end user **I want** the common permission-prompt and token-waste
  patterns fixed at source **so that** the workflow keeps momentum.

## Non-Functional Requirements
### Performance (NFR1)
- Extraction is map-reduce: each per-project agent returns only a bounded
  structured digest, never raw file contents, so the reduce fits one context.

### Usability (NFR2)
- The deliverable is grouped per axis and ranked by impact; a maintainer can read
  the top recommendations without opening the corpus.

### Maintainability (NFR3)
- The digest schema is uniform across projects and stated once, so digests are
  comparable across projects in the reduce (a precondition for FR4 corroboration).

### Security (NFR4)
- All mined retrospective/session-log/LMM text is treated as untrusted data, not
  instructions (prompt-injection surface) per CLAUDE.md instruction precedence.
- Extraction/miner agents run read-only (no Edit/Write/mutating Bash), so an
  injected instruction in a retrospective can at most corrupt a digest entry —
  which the FR4 corroboration filter and FR5 novelty diff then contain, and the
  FR6 source-attribution chain lets a maintainer trace any suspect recommendation
  to its origin before acting.
- LMM access is scoped to `github@mattkeenan.net`; no secrets or credential
  material are copied into the deliverable.
- File-permission, env-var, and bash-injection categories (FR4 a/b/d) are out of
  scope: this task writes no `.cwf` scripts, reads no privileged env vars, and
  lands no source changes.

### Reliability (NFR5)
- Partial-failure tolerant: one project's extraction failing — or a friction-signal
  source (a session log, LMM) being unavailable/empty — does not abort the run; the
  reconciliation step surfaces it as a logged coverage gap rather than silently
  dropping it.

## Constraints
- Assessment-only: no CwF source or doc changes land in this task.
- Recommendations must be follow-up-task-shaped (Task 178 discovery pattern).
- This repo's own retrospectives are meta signal, weighted below external-project
  corroboration.
- No silent truncation: if the corpus is sampled or capped, the cap is logged.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [x] **Complexity**: 3+ concerns (the axes) — resolved in planning: shared
      extraction, per-axis synthesis. Not a decomposition trigger.
- [ ] **Risk**: No high-risk isolated components (assessment-only).
- [x] **Independence**: Axes separable as outputs — decomposition lives in the
      seeded follow-up tasks, not this discovery.

## Acceptance Criteria
- [ ] AC1: Digest covers the run-start retrospective count (snapshot ~558, 2026-07-07); coverage reconciled, stubs and gaps logged (FR1).
- [ ] AC2: Session-log + LMM overlay present, sources attributed (FR2).
- [ ] AC3: Every finding axis-tagged with per-axis rollups (FR3).
- [ ] AC4: "General" findings carry ≥2 corroborating projects (FR4).
- [ ] AC5: Every recommendation novelty-classified against codified guidance (FR5).
- [ ] AC6: Recommendations ranked, tradeoff-stated, follow-up-shaped (FR6).

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
