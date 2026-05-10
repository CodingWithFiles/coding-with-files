# Refactor BACKLOG/CHANGELOG to heading-tree model - Rollout
**Task**: 132 (feature)

## Task Reference
- **Task ID**: internal-132
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/132-refactor-backlog-changelog-to-heading-tree-model
- **Template Version**: 2.1

## Goal
Roll the heading-tree refactor onto `main` and provide a clean upgrade
path for external CWF adopters whose own BACKLOG/CHANGELOG files still
use the Task 131 `**Field**:` format.

## Deployment Strategy

### Release Type
- **Strategy**: Single fast-forward merge to `main` + version bump (no
  phased/canary/blue-green — CWF is a self-contained git-tracked toolset,
  not a long-running service).
- **Rationale**: The change is atomic by construction. Adopters consume
  CWF by pulling from the published `main` branch (or via
  `cwf-manage update`), so there is no traffic to shift, no fleet to
  drain, and no shared state to migrate. The heading-tree parser is
  Postel-liberal on input (still parses Task 131-format files without
  errors); the new strict format is only required when an adopter wants
  validation to be clean.
- **Rollback Plan**: revert the squash commit on `main`; tag is
  human-only and not yet placed at this stage.

### Pre-Deployment Checklist
- [x] Code review completed (/simplify pass at f-implementation-exec
      Step 11.5; manual security walkthrough recorded in both
      f-implementation-exec § Security Review and g-testing-exec
      § Security Review).
- [x] All tests passing — `prove t/`: 412 / 412 (≥408 baseline).
- [x] Security scan — `cwf-manage validate` clean; manual review of
      changeset (3,307 lines, exceeds 500-line subagent cap)
      no findings.
- [x] Performance validated — BACKLOG 4.02ms / CHANGELOG 7.49ms median
      (1.84× / 1.89× pre-refactor baseline; NFR1 budget is 5×).
- [x] Documentation updated — `cwf-backlog-manager` SKILL.md created;
      `normalise` subcommand documented; conventions docs unchanged.
- [x] Monitoring not applicable (no runtime service).
- [x] Rollback plan documented (single squash commit on `main`).

## Rollout Plan

This is an internal-tooling rollout, not a user-traffic rollout. The
"phases" map to the CWF release lifecycle, not to canary cohorts.

### Phase 1: Squash + merge to `main`
- **Scope**: CWF own repo.
- **Steps** (all human-driven; the model never executes the merge or the tag):
  1. Retrospective phase (j) does the checkpoints branch + squash on the
     task branch (per `.cwf/docs/skills/retrospective-extras.md`).
  2. Maintainer fast-forwards `main`: `git checkout main && git merge --ff-only feature/132-…`.
  3. Maintainer pushes `main`.
- **Success criteria**: `cwf-manage validate` clean on `main`; `prove t/` clean on `main`.

### Phase 2: Version bump + tag
- **Scope**: CWF own repo.
- **Steps**:
  1. `cwf-version-bump --task-num=132` (run by retrospective skill at Step 9 — bumps `cwf-project.json`).
  2. Maintainer creates the annotated tag: `git tag -a v0.1.132 -m "Task 132"` (CwF self-tagging is human-only per `CLAUDE.md`).
  3. Maintainer pushes the tag.
- **Success criteria**: tag visible on the public repo; `cwf-manage status` reports the new version on a fresh clone.

### Phase 3: External adopter upgrade path
- **Scope**: any project that consumes CWF and has its own BACKLOG.md / CHANGELOG.md in the Task 131 `**Field**:` format.
- **Path**:
  1. Adopter runs `cwf-manage update` (or pulls the tagged release into their `.cwf/`).
  2. Adopter runs `.cwf/scripts/command-helpers/backlog-manager normalise` once against their BACKLOG.md and CHANGELOG.md.
     - The `normalise` subcommand promotes `**Field**:` lines to `### Field:`, drops `^---$` separators, and rewrites entries to the canonical title→metadata→body order.
     - It is idempotent: a second invocation reports `already canonical (no change)` and is a no-op.
     - `--dry-run` prints what would change without writing.
  3. Adopter runs `.cwf/scripts/command-helpers/backlog-manager validate` to confirm.
- **Success criteria**: `validate` exits clean against the upgraded files.
- **Failure mode**: if `normalise` cannot canonicalise (e.g. ambiguous mixed format), it aborts non-destructively and prints the offending entry; the adopter resolves manually and re-runs.

## Monitoring

Not applicable in the runtime sense. The post-rollout signals are:

- `cwf-manage validate` continues clean on every commit to `main` (enforced by the post-commit guard in `cwf-checkpoint-commit`).
- `prove t/` continues green in CI / pre-commit on subsequent tasks.
- No follow-up backlog items filed against `parse_backlog_tree` /
  `validate_backlog_tree` / `normalise` over the next 1–2 tasks.

## Rollback Plan

### Triggers
- `cwf-manage validate` regresses on `main` post-merge.
- A subsequent task discovers a parser/serialiser regression that breaks live BACKLOG round-trip.
- An external adopter reports `normalise` corrupting their file (catastrophic; no reports expected — `normalise` is round-trip-tested and snapshot-protected by the `--dry-run` workflow).

### Procedure
1. **Immediate**: revert the squash commit on `main` (`git revert <sha>`); push.
2. **Adopters**: those who already ran `normalise` retain their canonicalised files (the canonical format remains parseable by the reverted Postel-liberal parser via the legacy `**Field**:` path *if* we keep that path on revert; otherwise restore from `/tmp/task-132/BACKLOG.md.pre-migration` and `/tmp/task-132/CHANGELOG.md.pre-migration` snapshots which remain on the maintainer's machine).
3. **Communication**: open a hot-fix task, document the regression, file a follow-up.
4. **Analysis**: root-cause via `git bisect` against the test suite.

## Success Criteria
- [x] Pre-deployment checklist complete (above).
- [ ] Phase 1 (merge to `main`) completed by maintainer post-retrospective.
- [ ] Phase 2 (version bump + tag) completed by maintainer post-merge.
- [ ] Phase 3 (adopter upgrade path) available — `normalise` documented in `cwf-backlog-manager` SKILL.md and tested.

Phase 1 and Phase 2 are gated on the retrospective and explicit
maintainer action; this skill does not execute them.

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

- Pre-deployment checklist: all items green (see ticked boxes above).
- The `normalise` subcommand subsumes the throwaway migration script and provides the supported upgrade path for external adopters.
- Snapshots `/tmp/task-132/BACKLOG.md.pre-migration` (74,014 B) and `/tmp/task-132/CHANGELOG.md.pre-migration` (231,373 B) remain on the maintainer's machine pending the j-retrospective `/tmp/task-132/` cleanup.

## Lessons Learned

- For self-contained git-tracked toolsets, the rollout template's runtime-service framing (canary, blue-green, alerting) is the wrong shape. A short documentation-only h-rollout that names the actual phases (squash + merge → version bump + tag → adopter `normalise`) is sharper.
- Documenting the adopter upgrade path (`cwf-manage update` → `backlog-manager normalise` → `validate`) at rollout time, not as an afterthought, makes the maintainer's announcement-message work trivial.
