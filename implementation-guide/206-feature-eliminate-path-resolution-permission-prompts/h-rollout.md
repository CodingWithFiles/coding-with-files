# Eliminate path-resolution permission prompts - Rollout
**Task**: 206 (feature)

## Task Reference
- **Task ID**: internal-206
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/206-eliminate-path-resolution-permission-prompts
- **Template Version**: 2.1

## Goal
Ship Task 206 (the UserPromptSubmit path-injection hook + `scratch_parent`/`scratch_dir`
+ skill migration) the CWF way: squashed onto main, per-phase checkpoints preserved,
and propagated to installed repos via `cwf-manage update`. No SaaS deployment — this is
a self-hosted documentation/tooling system, so the generic blue-green/canary template
is not applicable and was removed.

## Deployment Strategy
### Release Type
- **Strategy**: Archaeological main — squash the seven phase commits (a–g) into one
  release commit on the task branch, then fast-forward `main`; cherry-pick the
  per-phase commits onto the `checkpoints` branch for preserved reasoning.
- **Rationale**: Repo convention (eats its own dogfood; see CLAUDE.md, MEMORY.md).
  Compact linear main, full per-phase history off-main.
- **Rollback Plan**: `main` is a ref — revert is `git revert <release-sha>` (or move the
  ref back) plus `cwf-manage rollback` on any installed repo. The hook is fail-open, so
  even a bad hook degrades to "no PATHS block injected", never a blocked turn.

### Pre-Deployment Checklist
- [x] Code review completed — both exec changesets reviewed (security + best-practice), no findings
- [x] All tests passing — full suite **874 tests green** (`prove -l -j4 t/`)
- [x] Integrity verified — `cwf-manage validate` **OK** (hashes refreshed in the f-phase commit)
- [x] Performance validated — NFR1: one `git rev-parse`/turn (hook passes its resolved root to `scratch_parent`)
- [x] Documentation updated — `tmp-paths.md` (single-source-of-truth note), 20 skills migrated, 2 task-creation skills' Step 5
- [x] **Live activation confirmed** — the `CWF PATHS` block is now injected every turn (see below)
- [x] Rollback plan understood — fail-open hook + `git revert` + `cwf-manage rollback`

## Activation Model (the one rollout subtlety)
`.claude/settings.json` is loaded at **session start**, so a hook registered mid-session
does not fire in the registering session. This was recorded honestly as a deferred smoke
in `g-testing-exec.md`.

**Now confirmed live**: after the intervening `/compact`/session boundary, this turn's
context carries the injected block:

```
CWF PATHS (use these literal absolute paths directly; do not re-resolve):
  cwd:          /home/matt/repo/coding-with-files
  project_root: /home/matt/repo/coding-with-files
  scratch:      /tmp/cwf-home-matt-repo-coding-with-files   (leaf: that path + /task-<num>)
```

Implication for end users: after `cwf-manage update` installs the new hook + the
`cwf-claude-settings-merge` registration, **a session restart is required** before the
PATHS block appears and the migrated skills run prompt-free. This belongs in the update
notes (carried into i-maintenance).

## Rollout Steps (for the maintainer to run — human-only actions flagged)
1. Squash a–g into one release commit on the task branch (`git reset --soft <baseline> && git commit -F <scratch>/msg.txt`).
2. **Suggest** fast-forward of `main` to the release commit — *do not execute*; the
   maintainer runs `git checkout main && git merge --ff-only <release-sha>`.
3. Cherry-pick the seven phase commits onto `checkpoints` (one commit per phase).
4. **Human-only**: tag `v1.1.206`, push, create the GitHub release.
5. Installed repos pick it up via `cwf-manage update`; users restart their session.

## Monitoring
### What to watch after activation
- **Prompt elimination (the acceptance metric)**: a migrated skill (e.g. `/cwf-task-plan`)
  should run with **zero** path-resolution permission prompts — no `$(...)`/`${...}` Bash.
- **PATHS block presence**: every turn's context shows the three literals.
- **Integrity**: `cwf-manage validate` stays OK across the update (hook entry + refreshed hashes).
- **Fail-open behaviour**: a malformed payload or non-repo cwd degrades to cwd-only or
  no block, never a blocked turn (TC-10..TC-12).

## Rollback Plan
### Triggers
- Hook errors visibly or blocks turns (should be impossible — eval-wrapped, always exit 0).
- `cwf-manage validate` reports tampering on the new hook entry.
- Migrated skills regress (path-resolution prompts return).

### Procedure
1. **Immediate**: the hook is fail-open, so no emergency stop is needed — worst case is no PATHS block.
2. **Rollback**: `cwf-manage rollback` on the installed repo; on the source repo `git revert <release-sha>`.
3. **Re-validate**: `cwf-manage validate` + full `prove` suite.

## Success Criteria
- [x] Release model defined (archaeological main; no SaaS deployment)
- [x] Pre-deployment checklist complete (tests, validate, reviews, performance)
- [x] Activation model documented (session-restart requirement surfaced)
- [x] Live injection confirmed observed
- [x] Rollback plan documented (fail-open + revert + `cwf-manage rollback`)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Rollout is documentation-only at this phase: the squash/ff/tag steps are human-owned and
listed above for the maintainer. The single material rollout fact — the session-restart
requirement for the new hook to activate — is now empirically confirmed (PATHS block
present this turn) and carried forward to maintenance.

## Lessons Learned
- For CWF, "rollout" is the archaeological-main release + `cwf-manage update`, not a
  phased traffic ramp; the template's SaaS framing was replaced rather than filled in.
- A session-start-loaded hook's activation is itself a rollout step: end users must
  restart after `cwf-manage update`. The deferred g-phase smoke resolved naturally at
  the next session boundary.
