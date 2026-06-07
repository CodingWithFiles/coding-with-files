# Replace git-subtree with read-tree laydown - Plan
**Task**: 185 (feature)

## Task Reference
- **Task ID**: internal-185
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/185-replace-git-subtree-with-read-tree-laydown
- **Baseline Commit**: 432fd5e39854f477946c97eaaf49187fa66cedc9
- **Template Version**: 2.1

## Goal
Stop CWF installs from forcing merge commits into consumer repositories by laying CWF
down with a merge-free `git read-tree` method (primary), keeping `copy` as a fallback,
deprecating `subtree`, and surfacing — without remediating — any merge commits already
present in a consumer's history.

## Success Criteria
- [ ] A fresh install via the default method adds CWF with **zero merge commits**
      (`git rev-list --merges` over the install commits is empty) and content that is
      byte- and mode-exact to the source tree (verifiable against the source tree SHA).
- [ ] `CWF_METHOD=subtree` is **refused** for fresh installs with guidance pointing to
      `read-tree` (primary) and `copy` (fallback); no subtree laydown path remains
      reachable for new installs. `copy` stays a working, documented fallback.
- [ ] `cwf-manage update` on an existing `cwf_method=subtree` install **migrates** the
      recorded method to `read-tree` without failing, and emits no new merge commits.
- [ ] A detection surface reports merge commits in the consumer repo — **total count
      plus the CWF-subtree-fingerprinted subset** — and advises (never performs)
      re-linearisation, pointing the user to the maintainer.
- [ ] All existing tests pass; read-tree laydown, subtree refusal/migration, and the
      detection surface are each covered by new tests; post-install `cwf-manage validate`
      is clean.

## Original Estimate
**Effort**: 2-3 days
**Complexity**: Medium
**Dependencies**: Existing update pipeline (`cwf-apply-artefacts`), manifests
(`.cwf/version`, `install-manifest.json`), deprecation convention.

## Major Milestones
1. **read-tree laydown is the default**: fresh install verified merge-free and
   tree-exact; integrity (`validate`) clean.
2. **subtree deprecated**: refused for fresh installs; existing subtree installs
   migrated on `cwf-manage update`; `copy` retained as documented fallback.
3. **Detect-and-warn migration surface**: reports total + CWF-fingerprinted merge
   commits, advisory only (no bundled rewrite, no silencing flag).
4. **Docs, tests, rollout**: conventions/method docs updated, test coverage added,
   consumer-facing rollout note explaining the change and the linearisation choice.

## Risk Assessment
### High Priority Risks
- **read-tree mechanics differ from assumption** (prefix-collision on reinstall,
  materialise step, source must be a reachable tree-ish): wrong or failed laydown.
  - **Mitigation**: `c-design-plan` runs an empirical spike in a throwaway repo to pin
    the exact incantation and reinstall behaviour before committing the approach.
- **Deprecation bricks existing subtree installs' updates**: a hard refusal that also
  blocks `cwf-manage update` would strand current users.
  - **Mitigation**: refuse-new and migrate-existing are deliberately separate paths;
    an end-to-end update test starts from a `cwf_method=subtree` fixture.

### Medium Priority Risks
- **Detection mis-attributes a user's own legitimate merges to CWF**.
  - **Mitigation**: fingerprint precisely (subject `Add CWF …` + `git-subtree-dir`
    trailer + synthetic squash parent); report the CWF subset separately from the total
    and make no claim about the remainder.
- **Integrity-model interaction**: laydown must keep producing the recorded perms/sha
  so `validate` stays clean.
  - **Mitigation**: read-tree's mode-exactness cooperates with the sha256/perms model;
    assert via `cwf-manage validate` in post-install tests.
- **Portability** (macOS): `copy`'s `cp` divergence and git availability for read-tree.
  - **Mitigation**: read-tree is git-native and portable; `copy` retained for the gap;
    note the constraint in the test plan.

## Dependencies
- Existing update pipeline (`cwf-apply-artefacts`, Tasks 155/161) — read-tree must
  integrate with it, not bypass it.
- Existing manifests as provenance anchors: `.cwf/version` (method/ref/sha) and
  sha-tracked `.cwf/install-manifest.json`.
- The maintainer's external re-linearisation skill (out of scope) — the warning points
  users toward it via the maintainer; CWF ships no history-rewrite.
- Deprecation policy in `docs/conventions/design-alignment.md`.

## Constraints
- POSIX / macOS portability; core-Perl only; no merge commits in CWF's own development
  (CWF eats its own dog food).
- **Surface, never smooth**: detection warns only; no bundled history rewrite and no
  acknowledge/silence flag that hides the signal without surfacing it.
- Versioning: feature → minor bump; tagging and release are human-only.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — estimated 2-3 days.
- [ ] **People**: Does this need >2 people? No — single maintainer.
- [x] **Complexity**: Does this involve 3+ distinct concerns? Yes — (1) read-tree
      laydown, (2) subtree deprecation + migrate-on-update, (3) detect-and-warn surface.
- [ ] **Risk**: High-risk components needing isolation? The read-tree spike is risky but
      is a design-phase activity, not a separable deliverable.
- [ ] **Independence**: Can parts be worked separately? Weakly — the detect-and-warn
      surface is the most separable, but it shares the update-path touchpoint and the
      same release as the laydown change.

**Assessment**: One signal (Complexity) clearly triggers. The three concerns share a
single release and the `cwf-manage update` touchpoint, so this is planned as **one
task**. The detect-and-warn surface is the natural cut-line **if** isolation is
preferred at review — flagged for the user's decision before exec.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
