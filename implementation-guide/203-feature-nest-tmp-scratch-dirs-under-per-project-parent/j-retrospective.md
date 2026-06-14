# Nest tmp scratch dirs under per-project parent dir - Retrospective
**Task**: 203 (feature)

## Task Reference
- **Task ID**: internal-203
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/203-nest-tmp-scratch-dirs-under-per-project-parent
- **Template Version**: 2.1
- **Retrospective Date**: 2026-06-14

## Executive Summary
- **Duration**: ~1 working day across one workflow run (estimated ~0.5 day, Medium; modest
  over-run absorbed by design-phase deliberation, not execution).
- **Scope**: Delivered as planned — the per-task scratch convention moved from sibling
  top-level dirs (`<repo>-task-<num>/`) to a single per-project parent
  (`cwf<repo>/task-<num>/`), so the Bash/Write permission prompt fires once per project.
  One success-criterion was reshaped during design (the shipped-settings allowlist rule
  became a documented, user-owned one — D4) and one originally-instructed element was cut
  (`.cwfkeep` sentinel — D3).
- **Outcome**: Success. AC1–AC7 met; the three planned functional cases + cleanup +
  smokes pass; both exec-phase security reviews returned **no findings**. The sole
  full-suite failure (TC-VALIDATE) was a pre-existing in-flight-status artefact, resolved
  by this retrospective's status sweep — not a regression.

## Variance Analysis
### Time and Effort
- **Estimated**: ~0.5 day, Medium complexity (one convention + one in-tree consumer).
- **Actual**: One continuous workflow run, ~1 day. Implementation was small (one helper
  block, doc/skill edits); the over-run was design-phase work — pinning the
  boundary-vs-defence-in-depth framing, the no-auto-chmod divergence from the hook
  precedent, and resolving the `.cwfkeep` and settings-edit questions.
- **Variance**: Slightly over a small estimate, entirely in design deliberation. Execution
  matched the plan step-for-step with no rework.

### Scope Changes
- **Additions**: None to requirements. The `-tool-check` carve-out (D5) and the explicit
  optional-allowlist documentation (D4) were design-time clarifications of existing
  requirements, not new scope.
- **Removals**: Two, both deliberate and recorded. (1) `.cwfkeep` sentinel **cut** (D3) —
  the named parent is itself the discoverability marker; a sentinel only restates it. This
  reversed the user's original instruction after confirmation, backed by unanimous
  plan-review. (2) The shipped-settings allowlist rule (a-task-plan SC3) became
  **documentation only** (D4) — the path embeds a machine-specific absolute path and the
  settings file is user-owned, so CWF edits none.
- **Impact**: Both removals reduced surface (KISS). The `.cwfkeep` cut also simplified test
  cleanup (no non-empty-parent wrinkle in the END block).

### Quality Metrics
- **Test Coverage**: 100% of the planned security-critical behaviour — nested path
  derivation (extended TC-OUTFILE), symlinked-parent reject (TC-PARENT-SYMLINK),
  shared-parent reuse with no auto-chmod (TC-PARENT-REUSE), and END-block cleanup. D6
  provisioning (a skill step, not a `t/` test) covered by manual smoke, both success and
  forced-failure paths.
- **Defect Rate**: Zero functional defects. The one red subtest (TC-VALIDATE) is a
  test-design artefact, not a product defect (see What Could Be Improved + Future Work).
- **Performance**: One extra `mkdir` at first use per task; full-suite wall-clock unchanged
  (~37–39s).

## What Went Well
- **Established in-repo idiom, not new surface**: the parent symlink reject reused the
  exact `mkdir 0700 unless -d` → `unless -d && !-l` pattern already shipping in
  `pretooluse-bash-tool-check`. Consistency over invention kept the security delta to ~2
  lines that both reviews recognised.
- **Honest boundary framing held under review**: the design insisted the containment
  boundary stays the atomic `mkdir 0700` + fail-closed `0600` write, with the symlink
  reject explicitly scoped as defence-in-depth. This avoided a racy TOCTOU `stat`
  masquerading as the boundary, and both exec security reviews endorsed the framing.
- **"Surface, never smooth" made observable**: the deliberate omission of the hook's
  chmod-clamp (with an inline anti-reintroduction comment) is proven by TC-PARENT-REUSE,
  which asserts a 0755 parent is left untouched.
- **Tests-red-first discipline**: new assertions were confirmed red against the old
  sibling-form helper before the one-line path change made them green, tying each test to
  the behaviour it guards.

## What Could Be Improved
- **Stale planning-phase statuses (recurring)**: a–e sat at placeholder statuses
  ("Planning"/…) through every exec phase and were only swept to Finished at retrospective.
  This is the *same* finding as Task 202's retrospective — the pre-retrospective sweep
  caught it as designed, but writing `Finished` at each phase's own checkpoint would keep
  `cwf-status` honest mid-task and stop the placeholder statuses from tripping checks.
- **TC-VALIDATE is structurally red mid-task**: the subtest asserts the *live* repo's
  `cwf-manage validate` exits 0. Because every CWF task carries placeholder phase statuses
  until its own retrospective sweep, this assertion fails for **any** in-flight task,
  including the one that ships unrelated changes. It cost real diagnostic effort to confirm
  it was pre-existing rather than a regression. Carried to Future Work.
- **`.cwfkeep` mid-task touch**: the manual `touch .cwfkeep` during execution briefly
  reopened a settled design question (D3). Confirmed a one-off; the sentinel stayed cut.
  No artefact entered the repo, but it shows how an ad-hoc shell action can look like a
  design reversal.

## Key Learnings
### Technical Insights
- **Name the boundary, scope the rest as defence-in-depth.** A shared, longer-lived parent
  invites adding ownership/mode checks; doing so as the *boundary* would be a racy TOCTOU
  stat. Keeping the boundary at atomic-create + fail-closed-write, and the `-l` reject as
  honest defence-in-depth, is both safer and easier to review.
- **The one material risk change was the shared parent's lifetime**, not the path string.
  The old per-task dir vanished with the task; the new `cwf<repo>/` parent persists across
  tasks and sessions. Any *future* scratch writer that does not go through the helper must
  carry its own fail-closed write or `-l` check, or the symlink-to-dir gap reopens
  (flagged in the implementation-exec review, recorded in i-maintenance).
- **Reuse the canonical derivation snippet, never re-roll it.** D6 made the skills use the
  worktree-safe `tmp-paths.md` snippet (`git rev-parse --path-format=absolute
  --git-common-dir`) rather than a fresh `${repo//\//-}` one-liner, which would have
  silently dropped worktree-safety and created doc↔skill drift.

### Process Learnings
- **Machine-specific absolute paths don't belong in shipped config.** D4's "document the
  allowlist, don't write it" is the generalisable rule: when a convenience requires a
  per-checkout absolute path, ship the pattern and let the user opt in.
- **A named carve-out beats a forced-uniform story.** D5 left `-tool-check` on its own form
  (different dashify rule, already one-dir-per-project, written programmatically) rather
  than unifying two hashed scripts for zero functional gain. The convention doc names the
  exception so it is not silent drift.

### Risk Mitigation Strategies
- Both a-task-plan risks retired by design, not hope: "stale references left behind" by the
  anchored grep sweep (on `-task-`, so it never flags `-tool-check`) plus the output-level
  smoke; "symlink-defence regression" by designing the two-level mkdir explicitly and
  asserting parent + leaf 0700 in TC-OUTFILE.

## Recommendations
### Process Improvements
- Set `**Status**: Finished` at each phase's own checkpoint commit rather than batch-fixing
  planning-phase statuses at retrospective. This is now the **second** consecutive task
  (202, 203) to record this; the lesson is not landing — worth reinforcing in the phase
  skills or the checkpoint-commit helper rather than relying on the retrospective sweep.

### Tool and Technique Recommendations
- When adding any new scratch writer (helper, hook, skill, or doc snippet), derive the path
  from `.cwf/docs/conventions/tmp-paths.md` and — if the writer performs its own write —
  give it a fail-closed write or its own `-l` check. The shared parent makes blind trust a
  reopened gap.

### Future Work
- **TC-VALIDATE structural false-failure** (new backlog item): the live-repo
  `cwf-manage validate` assertion in `t/security-review-changeset.t` is red for any
  in-flight task because phase files legitimately carry placeholder statuses until their
  retrospective sweep. Either scope the assertion to a fixture repo, or have it tolerate
  the known in-flight placeholder statuses, so a mid-task run does not report a false
  regression. Identified here, carried to BACKLOG.
- **Agent memory `[[tmp-paths]]` update**: the on-disk convention is canonical; the agent
  memory pointer should be refreshed to the nested form post-merge (not a repo file, so
  out of this task's commit).

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-06-14
**Sign-off**: CWF maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Planning: a-task-plan.md … e-testing-plan.md (this task directory)
- Implementation/Testing results: f-implementation-exec.md, g-testing-exec.md
- Rollout/Maintenance: h-rollout.md, i-maintenance.md
- Code: `.cwf/scripts/command-helpers/security-review-changeset` (two-level mkdir +
  symlink reject), `.cwf/security/script-hashes.json` (hash refresh)
- Docs/skills: `.cwf/docs/conventions/tmp-paths.md`, `CLAUDE.md`,
  `.claude/skills/cwf-new-task/SKILL.md`, `.claude/skills/cwf-new-subtask/SKILL.md`
- Tests: `t/security-review-changeset.t`
