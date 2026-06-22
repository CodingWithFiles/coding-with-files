# exec-changeset reviewer agents - Maintenance
**Task**: 210 (feature)

## Task Reference
- **Task ID**: internal-210
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/210-exec-changeset-reviewer-agents
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for exec-changeset reviewer agents.

No running service — the deliverables are three hash-tracked markdown agent
definitions and a skill-prose edit. "Maintenance" is integrity, drift, and
keeping the five changeset reviewers consistent with each other.

## Monitoring (integrity, not telemetry)
- `cwf-manage validate` is the health check: it re-verifies the three new `0444`
  sha256 entries against the on-disk files. A failure surfaces as a tampering or
  permission-drift signal — **surface, never smooth** (do not auto-recompute).
- Behavioural coverage is the test gate: `t/exec-changeset-reviewers.t` (11
  subtests) plus `t/security-review-classify.t`. CI / `prove t/` is the regression
  watch.
- The observable runtime signal is section count: after `implementation-exec`,
  `f-implementation-exec.md` carries **five** `## … Review` sections; after
  `testing-exec`, `g-testing-exec.md` carries **two**. A drift either way is the
  thing to notice.

## Maintenance tasks
- **On any edit to a changeset reviewer**: refresh its sha256 in
  `script-hashes.json` in the **same commit** (hash-updates convention); restore
  working perms to the recorded `0444`, not a bumped mode.
- **Keep the five in lockstep**: the `cwf-review` verdict block and the "Bash
  intentionally withheld" paragraph are duplicated byte-identically across all
  five changeset reviewers (no include mechanism in agent `.md`). A change to the
  shared contract must be applied to all five (or the de-dup backlog item taken
  up — see below). Diverging one silently is the maintenance hazard.
- **Dead-code / convention drift**: periodic sweep per `.cwf/docs/dead-code-audit.md`.

## Common issues
- **A lens reviewer emits `error` every run** → its Procedure likely retained a
  read-step for an input it no longer receives (the `{bp_context_file}` trap the
  clone deliberately dropped). Fix: the agent must read only `{changeset_file}`.
- **`validate` flags a new agent after an edit** → sha256 not refreshed in the
  edit commit, or perms bumped above `0444`. Fix: refresh hash + `chmod 0444` in
  the same commit; `cwf-manage fix-security` clamps perms only when sha256 already
  matches.
- **A lens `findings` appears to block the workflow** → it must not; the guard is
  name-matched to `cwf-security-reviewer-changeset` only. If a lens reviewer ever
  blocks, check the SubagentStop guard's `# cwf-hook-matcher:` directive was not
  widened.
- **Best-practice / lens reviewers fire on an irrelevant corpus** → the project's
  `active-tags` resolve off-domain best-practice docs (golang/postgres for a docs
  task); already logged (Task 209 backlog item). Not a Task 210 defect.

## Known follow-up
- BACKLOG (added in f): hoist the shared verdict block + Bash-withheld paragraph
  into `cwf-agent-shared-rules.md` and de-dup the five changeset reviewers. The
  live improvements reviewer re-surfaced this in h — it is the standing
  maintenance debt for this feature.

## Success Criteria
- [x] Integrity check defined (`cwf-manage validate`) and passing
- [x] Regression gate defined (`t/exec-changeset-reviewers.t`, full suite)
- [x] Common issues + resolutions documented
- [x] Known follow-up (verdict-block de-dup) linked to the backlog

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
