# Lint agent files for ignored allowed-tools key - Rollout
**Task**: 193 (hotfix)

## Task Reference
- **Task ID**: internal-193
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: hotfix/193-lint-agent-files-for-ignored-allowed-tools-key
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for Lint agent files for ignored allowed-tools key.

## Deployment Strategy
### Release Type
- **Strategy**: Standard CWF delivery — squash-merge the task branch to `main`, tag a
  `v1.1.193` release (human-only), then consuming projects pick it up on their next
  `cwf-manage update`. No phased/percentage rollout: CWF is a file-based developer tool
  installed per-repo, not a hosted service with a live user population.
- **Rationale**: The change is a single new read-only validator (`CWF::Validate::Agents`)
  plus a one-line wire-in to `cwf-manage validate`. `scripts/install.bash` lays the whole
  `.cwf` tree from the git index, so the new `.cwf/lib/...` file ships automatically on
  install/update with no manifest edit. There is no runtime service to stage.
- **Blast radius**: A consuming project that runs `cwf-manage validate` will, from this
  release, see one additional check. It can only *add* AGENTS violations for agent files
  that already misuse `allowed-tools:` — i.e. it surfaces a latent privilege-escalation
  footgun rather than introducing behaviour change to correct files. Zero false positives
  on the reference corpus (this repo's five agents, all on `tools:`).

### Pre-Deployment Checklist
- [x] Plan reviewed (4 parallel reviewers, f-phase) and execs reviewed by the maintainer
- [x] All tests passing — `t/validate-agents.t` (TC-1..TC-8) + full suite `prove t/` (734)
- [x] Security review: `no findings` on both f- and g-phase changesets
- [x] `cwf-manage validate` → `validate: OK` (PerlConventions + hash integrity)
- [x] Hashes refreshed in-task (new module entry + `cwf-manage` sha256), same commits
- [x] No documentation runbook change required (developer-facing validator; behaviour
      documented in the module header and the commit body)

## Rollout Plan
Single-step. On maintainer approval:
1. Squash-merge `hotfix/193-lint-agent-files-for-ignored-allowed-tools-key` to `main`
   (human-only; see the retrospective's Suggest-Merge output).
2. Tag `v1.1.193` and push (human-only).
3. Consuming projects receive the validator on their next `cwf-manage update`; it runs on
   the next `cwf-manage validate` (and at install/update verification time).

## Monitoring
There is no telemetry surface for a file-based tool. The validator is self-monitoring:
- **Signal**: a future agent edit slipping `tools:` → `allowed-tools:` now makes
  `cwf-manage validate` exit non-zero with an `[AGENTS]` violation naming the file and the
  correct key. That *is* the alert.
- **Health check**: `cwf-manage validate` staying green on the real tree is the standing
  confirmation that the validator has no false positives.

## Rollback Plan
### Triggers
- The validator produces a false positive on a correctly-keyed agent file in any
  consuming project (would block a clean `cwf-manage validate`).
- An unforeseen interaction breaks the other validators' aggregation in `cmd_validate`.

### Procedure
1. **Revert**: `git revert` the two task commits (`38ffb41`, `1896afb`) — the change is
   additive (one new module, one wire-in line, two hash entries), so revert is clean and
   leaves the other validators untouched.
2. **Re-validate**: `cwf-manage validate` → OK confirms the revert restored the prior state.
3. **Re-tag**: cut a follow-up patch release (human-only); consuming projects drop the
   validator on their next `cwf-manage update`.
4. **Analysis**: capture the false-positive fixture as a new TC before re-attempting.

## Success Criteria
- [ ] Merged to `main` and tagged `v1.1.193` (human-only)
- [x] `cwf-manage validate` green on the reference tree (zero false positives)
- [x] No regression in the existing `t/` suite
- [ ] No rollback required post-merge

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
