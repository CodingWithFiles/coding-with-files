# Phase skills set own terminal status at checkpoint - Plan
**Task**: 222 (feature)

## Task Reference
- **Task ID**: internal-222
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/222-phase-skills-set-own-terminal-status
- **Baseline Commit**: 0999aa18f7263d78f3069c910143b6e6668b5d3c
- **Template Version**: 2.1

## Goal
Stop non-terminal and non-canonical `Status` values leaking onto committed CWF
phase files by making every phase resolve its **own** wf-step file to a terminal
status at its checkpoint — fixing the shipped phase templates and closing the
`j-retrospective` / skipped-phase gaps — while **retaining** the retrospective
status sweep as a defence-in-depth gate (R2, Task 219).

## Evidence (why this is real, not already-delivered)
The corpus premise ("skills set the next file's status, not their own") was
partly stale — the shared `cwf-checkpoint-commit` helper (Task 102) already
force-stamps the current phase `Finished`, and this repo's last four tasks are
all-terminal *because* they reliably route through it. But the leak is live in
projects that commit off the script path or run older CWF, confirmed at three
levels:
- **LMM memories (Jun–Jul 2026, cross-project):** retros repeatedly find phases
  showing `Backlog` / `Planning` / `Implemented` / `In Progress (25%)`.
- **atch terminal logs (omnilsp):** real committed-era stamps `**Status**:
  Backlog` (×9), `Design` (×3), `Requirements`, `Planning` — the phase *name*
  used as a status (non-canonical enum).
- **Current shipped templates:** `f-implementation-exec.md.template:20` hints
  `Update status to "Implemented"` (not a canonical value); every template's
  `## Status` defaults to `Backlog` (non-terminal).

The durable fix ships in the templates/skills so every project inherits it on
upgrade; the sweep stays as the detector.

## Success Criteria
- [ ] No shipped phase template seeds a non-terminal or non-canonical `Status`
      as its completion state (remove the `"Implemented"` hint in `f`; no
      phase-name-as-status guidance); a grep of `.cwf/templates/pool/*.template`
      finds zero non-canonical status tokens.
- [ ] Every phase a–j stamps its **own** file to a terminal status via the
      shared checkpoint mechanism; `j-retrospective` gains an equivalent
      own-status stamp rather than relying on the manual sweep for its own file.
- [ ] A regression test asserts (a) committed phase files of a completed task
      are terminal, and (b) no shipped template body contains a non-canonical
      status token.
- [ ] The retrospective status sweep is retained and still effective — a test
      proves it still flags an injected non-terminal status (defence in depth).
- [ ] `cwf-manage validate` passes; SHA256 hashes for any changed hashed
      template/script are refreshed in the same commit (hash-updates convention).

## Original Estimate
**Complexity**: Low–Medium (documentation/template/skill edits + one helper touch + tests; no new subsystem)
**Risk tier**: Low (installed-artefact + hashed-file discipline are the main hazards)
**Dependencies**: None external

## Major Milestones
1. **Root cause mapped**: every status touch-point inventoried (10 templates, 10 skills, `cwf-checkpoint-commit`, the sweep, `CWF::TaskState`).
2. **Cause fixed**: templates carry no misleading status hints; own-status stamping guaranteed for all phases incl. `j` and skipped phases.
3. **Guarded**: regression test green, sweep retained and proven, `validate` clean, hashes refreshed.

## Risk Assessment
### High Priority Risks
- **Hashed installed artefacts**: templates and `cwf-checkpoint-commit` are SHA256-tracked and project-neutral.
  - **Mitigation**: refresh hashes in the same commit as each edit; keep all edits repo-neutral (no repo-specific names); run `cwf-manage validate` at each checkpoint.

### Medium Priority Risks
- **Legit transient `Testing`**: `Testing` is a valid non-terminal status *during* g-exec; a naive fix could forbid it.
  - **Mitigation**: constrain only the *committed completion* state to terminal; leave transient in-progress statuses untouched.
- **`j-retrospective` commit shape**: j stages the whole task dir and then squashes; adding its own-status stamp must order correctly and not double-commit.
  - **Mitigation**: fold j's own terminal stamp into the existing retrospective checkpoint step; verify against the squash flow in design.

### Low Priority Risks
- **Skipped automation scope creep**: the checkpoint helper hardcodes `Finished`; supporting `Skipped` may exceed value (skipped phases usually have no file under the symlink model → no committed leak).
  - **Mitigation**: design decides whether Skipped automation is in-scope or documented-out with rationale (best part is no part).

## Dependencies
- None external. Touches only in-repo CWF artefacts and their tests.

## Constraints
- Installed-artefact neutrality (no repo-specific content in `.cwf/` or skills).
- Hashed-file discipline (in-task hash refresh, per `.cwf/docs/conventions/hash-updates.md`).
- Core-Perl / POSIX only; British spelling in prose.
- The retrospective status sweep must remain (explicit user requirement).

## Decomposition Check
- [ ] **Time**: <1 week — no.
- [ ] **People**: single developer — no.
- [ ] **Complexity**: one concern (status terminality) across parallel-shaped edits — no.
- [ ] **Risk**: no high-risk component needing isolation — no.
- [ ] **Independence**: parts share one contract; splitting adds coordination — no.

**Decision**: No decomposition — single cohesive task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All success criteria met: no shipped template seeds a non-canonical status (the `f:20`
`"Implemented"` hint removed); every phase stamps its own file terminal (j gained an
`&&`-chained own-stamp); regression guard `t/status-terminality.t` added; the sweep is
retained and proven; `validate` OK with the hook sha256 refreshed in-commit.

## Lessons Learned
The premise was partly stale — `cwf-checkpoint-commit` already force-stamped `Finished`
since Task 102. Grepping the shared helper path early would have confirmed the true
residual leak (off-script commits, older CWF, phase-name-as-status) faster.
