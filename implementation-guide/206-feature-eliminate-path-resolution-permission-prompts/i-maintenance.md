# Eliminate path-resolution permission prompts - Maintenance
**Task**: 206 (feature)

## Task Reference
- **Task ID**: internal-206
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/206-eliminate-path-resolution-permission-prompts
- **Template Version**: 2.1

## Goal
Ongoing care for the path-injection hook, the `scratch_parent`/`scratch_dir` helpers,
and the skill migration. No SLAs/uptime/scaling — this is a local CLI tooling system, so
the generic SaaS-ops template was replaced with the runbook the artefacts actually need.

## What must keep holding (standing invariants)
- **No path-resolution Bash in skills**: skills must not reintroduce `gcd=$(git rev-parse …)`,
  `${repo_root//\//-}`, or an "anchor the shell" block. Guarded by `t/skill-anchor-drift.t`
  (inverted in this task into a migration guard) — keep it green.
- **Single source of truth for scratch paths**: `CWF::Common::scratch_parent`/`scratch_dir`
  are the only deriver. New consumers call the helper; they do not hand-roll the dashified
  path. Per `tmp-paths.md` (Task 206 note).
- **Hook stays fail-open**: `userpromptsubmit-context-inject` is eval-wrapped and always
  `exit 0`. Any future edit must preserve that — a throwing UserPromptSubmit hook blocks turns.
- **Integrity**: the hook, `Common.pm`, and `security-review-changeset` are hash-tracked;
  any edit refreshes `script-hashes.json` in the same commit (`hash-updates.md`).

## Monitoring (manual, no daemon)
- **Acceptance signal**: migrated skills run with zero path-resolution permission prompts.
- **PATHS block present**: each turn's context shows `cwd`/`project_root`/`scratch`.
- **`cwf-manage validate` OK**: run after any update; the hook entry + refreshed hashes must verify.
- **Full suite green**: `prove -l -j4 t/` (currently 874 tests).

## Common Issues / Runbook
- **Symptom: PATHS block missing from context.**
  Diagnosis: session predates the hook (settings load at session start), or the
  `cwf-claude-settings-merge` registration didn't run, or cwd is not a git repo.
  Resolution: restart the session; confirm `.claude/settings.json` has the second
  UserPromptSubmit hook + its allow rule; the hook is fail-open so a non-repo cwd
  legitimately yields cwd-only (TC-12).
- **Symptom: path-resolution prompt returns on a skill call.**
  Diagnosis: a skill regressed an inline `$(…)`/`${…}` derivation, or the agent ignored
  the injected literals and re-resolved. Resolution: re-run `grep -rlF` for the banned
  constructs (the `skill-anchor-drift.t` guard); use the injected literals verbatim.
- **Symptom: `validate` reports tampering on the hook.**
  Resolution: surface, never smooth — investigate the diff; only refresh the hash if the
  change was an intended in-task edit. Do not build a "recompute-hashes" shortcut.
- **Symptom: scratch dir not created / `symlink_parent` error.**
  Diagnosis: the per-project parent in `$TMPDIR`/`/tmp` is a symlink (rejected by design)
  or a reaper removed it. Resolution: remove the offending symlink; consumers re-mkdir on
  demand (mode 0700, never auto-chmod).

## Preventive Maintenance
- After any `cwf-manage update`, **restart the session** before relying on the PATHS block.
- Dead-code audit (see `.cwf/docs/dead-code-audit.md`): if/when all consumers route through
  `scratch_dir`, confirm no stray hand-rolled dashify survives.
- When the Claude Code hook input schema changes upstream, re-confirm `cwd` is still a
  common field (Step 1 of f-exec verified it against the official docs).

## Known Limitation (audit triggers)
The injected `cwd` is emitted verbatim, safe under the **single-user trust model**. Re-review
the security posture if any of these change: the `-d` existence gate is relaxed, `cwd` starts
coming from a multi-tenant/remote payload, or a fourth less-trusted injected field is added.

## Success Criteria
- [x] Standing invariants documented (anchor guard, single-source scratch, fail-open, integrity)
- [x] Manual monitoring signals defined
- [x] Common issues + runbook captured
- [x] Preventive tasks + session-restart obligation recorded
- [x] Security audit triggers documented

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance is documentation-only: no monitoring infrastructure to stand up. The durable
output is the runbook above — keyed to the four standing invariants and the session-restart
obligation surfaced in rollout.

## Lessons Learned
- The maintenance burden of this feature is a small set of invariants, each already pinned
  by a test or convention (anchor guard, single-source scratch, fail-open, hash discipline).
  Maintenance here is "keep those green", not "operate a service".
