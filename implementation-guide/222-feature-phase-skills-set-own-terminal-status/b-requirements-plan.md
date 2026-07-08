# Phase skills set own terminal status at checkpoint - Requirements
**Task**: 222 (feature)

## Task Reference
- **Task ID**: internal-222
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/222-phase-skills-set-own-terminal-status
- **Template Version**: 2.1

## Goal
Specify what "every phase resolves its own wf-step file to a terminal status at
its checkpoint" must guarantee, and how it is verified, so committed phase files
stop carrying non-terminal (`Backlog`) or non-canonical (`Planning`/`Design`/
`Requirements`/`Implemented`) status — while the retrospective sweep is retained
as a defence-in-depth gate.

## Functional Requirements
> **Plan-review REDUCE (5 reviewers):** merged old FR1+FR3 (one rule, positive/negative
> framing); folded the Skipped case into FR2 and dropped the near-vacant standalone FR4;
> anchored every status grep to a *status-context* line (bare word-alternation matched 17
> prose hits → permanently red); corrected the FR2 mechanism claim (the shared helper
> hardcodes `Finished` and cannot emit `Skipped`/`Cancelled`); scoped the `Backlog` seed
> out; and corrected the hash-tracking premise (pool templates are **not** SHA256-tracked).

### Core Features
- **FR1 — Template status hygiene** *(merged old FR1+FR3)*: No shipped phase
  template (`.cwf/templates/pool/*.md.template`) instructs or defaults a
  non-terminal or non-canonical value as the phase's *completion* state; any
  remaining status hint names only canonical values
  (`workflow-steps.md#status-values`) and points completion at a terminal value.
  The one concrete edit is the `f-implementation-exec.md.template:20`
  `"Update status to \"Implemented\""` hint — the *only* non-canonical status
  token in the pool (verified). The `**Status**: Backlog` seed default is
  **intentionally retained** (it is the start state, mutated to terminal at
  checkpoint per NFR5) and is out of scope.
  *AC*: a **status-context** grep — the `**Status**:` value line and any
  `Update status to "…"` hint line, not the whole template body — names only
  canonical values across the pool.
- **FR2 — Own-status terminal stamping for every phase a–j (incl. j and
  Skipped)**: Each phase's completion path sets *its own* wf-step file to a
  terminal status. a–i already do via `cwf-checkpoint-commit`
  (`status_set($wf_file, 'Finished')`, `:39`); FR2 closes the `j-retrospective`
  gap (no checkpoint step today — its own file must be terminally stamped by a
  scripted/skill step, not left to the manual sweep) by **reusing the existing
  checkpoint surface**, not adding a new helper. Because that shared helper emits
  only `Finished`, a phase that ends **Skipped** (present-file case, rare under
  the symlink model) needs a *distinct* stamping path — design decides it.
  *AC(a)*: completing j leaves j's committed `Status` terminal via the skill's
  own step, verifiable without running the sweep.
  *AC(b)*: a skipped, present phase file ends `Skipped`, or design documents why
  no committed-leak path exists under the symlink model.
- **FR3 — Retrospective sweep retained** *(was FR5)*: The status sweep
  (retrospective SKILL gotcha #1 + `retrospective-extras.md` "Verify Task
  Status") remains present and functional as defence in depth; intent unchanged.
  *AC*: a test injecting a non-terminal status still trips the sweep /
  `stop-stale-status-detector`.
- **FR4 — Regression guard** *(was FR6)*: A test asserts (a) a **known-completed**
  task's committed phase files (a fixture task dir, or a task selected by a
  completion signal — *not* an indiscriminate repo scan, to avoid tripping on
  in-flight work) are all terminal, and (b) no pool template's *status-context*
  lines contain a non-canonical token. May be one combined test with FR3's
  negative assertion.
  *AC*: the test exists, is red on a seeded regression, and green on the fix.

### User Stories
- **As a** CWF maintainer working in an installed project **I want** each phase
  to record its own terminal status automatically **so that** the retrospective
  is not the first place status drift is discovered.
- **As a** consumer upgrading CWF **I want** the corrected templates shipped
  **so that** my project inherits honest status without re-deriving the fix.

## Non-Functional Requirements
### Performance (NFR1)
- No measurable regression to checkpoint-commit or `validate` time; this is a
  text/template/test change plus at most one helper touch. No runtime hot path.

### Usability (NFR2)
- A model reading any phase template can tell the completion state is terminal
  and set at checkpoint — no ambiguous "set status to <phase-name>" cue remains.
  Guidance stays consistent with the existing template idiom.

### Maintainability (NFR3)
- Canonical status values keep a single source of truth
  (`workflow-steps.md` / `cwf-project.json`); templates reference the enum, they
  do not duplicate it. No new module unless duplication (Rule of Three) demands.

### Security (NFR4)
- Installed-artefact neutrality: no repo-specific content in `.cwf/` or skills.
- Hashed-file discipline, scoped correctly: pool `.template` files are **not**
  SHA256-tracked (verified — zero `.template` entries in `script-hashes.json`);
  only `cwf-checkpoint-commit` is. Refresh hashes in-task **only if** design
  modifies a tracked artefact (e.g. `cwf-checkpoint-commit`). Any *new* executable
  helper added for j/Skipped stamping must carry recorded permissions (0500
  ceiling) and a `script-hashes.json` entry in the same task — but prefer reusing
  the existing checkpoint surface over adding a new file.
- No change weakens `validate` or any integrity surface; templates are static
  text — no new injection surface.

### Reliability (NFR5)
- Existing all-terminal behaviour in this repo must not regress; `cwf-manage
  validate` stays green. Transient in-progress statuses (`Testing` during g,
  `In Progress`) remain valid — only the *committed completion* state is
  constrained to terminal.

## Constraints
- Core-Perl / POSIX only; British spelling in prose; no personal names in docs.
- `cwf-checkpoint-commit` is SHA256-tracked; pool `.template` files are **not** —
  scope any in-task hash refresh to tracked artefacts actually modified.
- The retrospective status sweep must remain (explicit user requirement).
- Symlink template model: skipped phases usually have no file → scope the Skipped
  clause of FR2 carefully.

## Decomposition Check
- [ ] **Time**: <1 week — no.
- [ ] **People**: one developer — no.
- [ ] **Complexity**: single concern (status terminality) — no.
- [ ] **Risk**: no isolate-worthy high-risk component — no.
- [ ] **Independence**: parts share one contract — no.

**Decision**: No decomposition.

## Acceptance Criteria
- [ ] AC1 (FR1): a **status-context** grep of the pool templates — only the
      `**Status**:` value line and any `Update status to "…"` hint line — names
      only canonical values; the `f`-template `"Implemented"` hint is gone; the
      `**Status**: Backlog` seed is deliberately unchanged.
- [ ] AC2 (FR2a): `j-retrospective`'s own committed `Status` is terminal via a
      scripted/skill step (reusing the checkpoint surface), not the manual sweep.
- [ ] AC3 (FR2b): a skipped, present phase file is committed `Skipped`, or design
      documents why no committed-leak path exists under the symlink model.
- [ ] AC4 (FR3): the retrospective sweep is retained; a test proves it still flags
      an injected non-terminal status.
- [ ] AC5 (FR4): the regression guard is present, scoped to a known-completed
      task, red on a seeded regression, green on the fix; `cwf-manage validate`
      OK; hashes refreshed in-task only for tracked artefacts actually modified.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
FR/NFR set delivered and verified in g-testing-exec: template hygiene (FR4b), own-status
stamping incl. j (FR3/D6), regression guard, sweep-retained proof, installed-artefact
neutrality (NFR4), single hashed edit (NFR4), no runtime path touched (NFR1).

## Lessons Learned
Pinning "committed completion state must be terminal" while explicitly exempting
transient `In Progress`/`Testing` in the requirements avoided a false-positive class in
the hook before it could be written.
