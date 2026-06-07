# Replace git-subtree with read-tree laydown - Rollout
**Task**: 185 (feature)

## Task Reference
- **Task ID**: internal-185
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/185-replace-git-subtree-with-read-tree-laydown
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for Replace git-subtree with read-tree laydown.

## Deployment Strategy
### Release Type
- **Strategy**: Single tagged release on `main`; consumers adopt independently via
  `cwf-manage update` (or a fresh `install.bash`). There is no server to deploy — CWF
  ships as files laid into each consumer repo, so "rollout" is the consumer-adoption path,
  not a fleet push.
- **Rationale**: CWF's distribution model is git-tag + `install.bash` + `cwf-manage update`
  (see `INSTALL.md`, `.cwf/docs/workflow/versioning-standard.md`). Each consumer upgrades
  on their own schedule; the maintainer cannot and does not push to consumer repos.
- **Compatibility**: this is a **minor**, backward-compatible change for consumers —
  `read-tree` becomes the default and `copy` is retained; only `subtree` is removed, and
  existing subtree installs are **migrated on update**, not broken. No consumer action is
  required beyond a normal `cwf-manage update`.

### Pre-Deployment Checklist
- [x] Plan-review (4 agents) clean across requirements/design/implementation
- [x] All tests passing — `prove t/` → 61 files, 706 tests green
- [x] Security review clean — implementation-exec and testing-exec both `no findings`
- [x] `cwf-manage validate: OK` at every checkpoint
- [x] Docs updated — INSTALL.md (read-tree default / copy fallback / subtree deprecated),
      `docs/conventions/design-alignment.md` §4 deprecation entry
- [x] Integrity refreshed — `script-hashes.json` updated for `cwf-manage` + new
      `cwf-detect-merges` in the same commit as the edits
- [ ] BACKLOG/CHANGELOG entry for the release (maintainer, at tag time)
- [ ] Tag + GitHub release (**human-only** — see Versioning in CLAUDE.md)

## Rollout Plan
Consumer adoption is inherently staged (each repo updates when it chooses); there are no
percentage cohorts to manage. The meaningful axis is **what each consumer experiences**:

### Fresh installs
- `install.bash` defaults to `read-tree` → a merge-free, single-parent laydown the user
  commits. `copy` remains available (`CWF_METHOD=copy`) where read-tree cannot run.
- `CWF_METHOD=subtree` is refused with guidance naming read-tree (primary) and copy.

### Existing `copy` installs
- `cwf-manage update` behaves as before; method stays `copy`. No change.

### Existing `subtree` installs (the migration path)
- `cwf-manage update` translates the recorded method to `read-tree`, re-lays merge-free,
  and rewrites `.cwf/version` to `cwf_method=read-tree` on success (fail-closed otherwise).
- The update then runs `cwf-detect-merges`, surfacing any pre-existing subtree merge commits
  already in the consumer's history. **CWF rewrites nothing** — the warning is advisory and
  points the user to the maintainer, who provides a separate re-linearisation skill for
  those who want a linear history. Users who do not care about merge commits need do nothing.

## Monitoring
No telemetry exists or is added (CWF is local tooling). Post-release signals to watch:
- **`cwf-manage validate`** in a migrated consumer is clean (the migration runs
  `apply_exact_perms_or_die`).
- **`cwf-manage check-merges`** reports sensible totals/subset on real consumer histories
  (the maintainer can spot-check during individual outreach).
- Issue reports of update failures, refused fresh-install messages, or detection false
  attributions.

## Known follow-ups carried into rollout
- **Fresh-install perms ceiling** (see f-implementation-exec Blockers): a raw `curl|bash`
  fresh install leaves recorded-ceiling perm drift until the first `cwf-manage
  fix-security`/`update` — **identical to the pre-existing `copy` behaviour**, not a
  regression. Decision on whether to add a `post_install` clamp is deferred to the user
  (captured in j-retrospective for a possible follow-up task).

## Rollback Plan
### Triggers
- A consumer-breaking defect in the read-tree laydown or the migration path.
- The detector mis-attributing a user's own merge as CWF's (over-claim) — a correctness bug.

### Procedure
1. **Consumer-side**: pin to the prior release — `cwf-manage rollback <previous-tag>` (or
   `CWF_REF=<previous-tag>` on install). `copy` remains a always-available escape hatch
   (`CWF_METHOD=copy`) if read-tree itself is implicated.
2. **Repo-side (maintainer)**: a follow-up fix task on `main`; tags are not deleted (a new
   patch release supersedes). No history on consumer repos is ever rewritten by CWF.
3. **Analysis**: capture the failure in a new task; the detector's under-claim invariant
   means a rollback is needed only for over-claim or laydown corruption, not for advisory
   noise.

## Success Criteria
- [x] Fresh read-tree install is merge-free and tree-exact (TC-1)
- [x] Subtree refused on fresh install; existing subtree installs migrate on update (TC-2, TC-6)
- [x] Migration is fail-closed and detection is advisory-only (TC-7, TC-9, TC-12)
- [ ] Release tagged and consumers can `cwf-manage update` onto it (maintainer, at tag time)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
