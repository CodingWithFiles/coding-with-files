# Enforce recorded permissions as upper bound - Plan
**Task**: 170 (feature)

## Task Reference
- **Task ID**: internal-170
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/170-enforce-recorded-permissions-as-upper-bound
- **Baseline Commit**: 0764380e60a6c1fb3788406942dfab7ae13bb585
- **Template Version**: 2.1

## Goal
Treat recorded permissions as a least-permissive ceiling: integrity validation must flag any file whose mode is *more* permissive than its recorded value, and the repair must clear only the offending excess bits rather than overwrite to the recorded mode.

## Success Criteria
- [ ] `cwf-manage validate` reports a permissions violation when a recorded-perms file has any mode bit set beyond its recorded value (`actual & ~recorded != 0`), naming the file, actual mode, recorded mode, and a remediation hint.
- [ ] `cwf-manage fix-security` repairs such a violation by clearing only the offending bits (`actual & recorded`) — never adding bits the file lacks — and reports the before/after mode.
- [ ] Files with no recorded `permissions` key (e.g. lib `.pm` modules) remain unchecked; behaviour unchanged.
- [ ] The floor-vs-ceiling interaction with the working-perms convention (scripts recorded `0500` but kept at `0700` in-tree) and install end-to-end TC-5 is resolved, with a decision recorded in design and no regressions across `t/validate-security*.t`, `t/cwf-manage-fix-security.t`, and the install/update end-to-end tests.
- [ ] Documentation describing the security/permission model states the ceiling semantics.

## Original Estimate
**Effort**: ~1 day
**Complexity**: Medium (logic is small; the manifest-semantics and convention reconciliation carry the weight)
**Dependencies**: `.cwf/security/script-hashes.json` and its generator; install/update end-to-end test suite (TC-5)

## Major Milestones
1. **Requirements**: Pin exact semantics — ceiling-only vs floor+ceiling (combined = exact-match); fix-mode bit math; scope of files affected.
2. **Design**: Reconcile recorded values and the `0700` working-perms convention; decide whether the floor check is kept, replaced, or augmented; decide whether to extend `_apply_recorded_perms` with a third (mask/clamp) mode or reuse `exact`.
3. **Implement**: Ceiling check in `CWF::Validate::Security`; clear-excess-bits repair in `cwf-manage`; refresh recorded values if their meaning changes.
4. **Verify & document**: Tests for check + fix, security-model doc update, same-commit hash refresh.

## Risk Assessment
### High Priority Risks
- **Convention conflict**: Ceiling semantics against recorded `0500` rejects the `0700` in-tree working-perms convention (31 files) and may break install-bash-reinstall TC-5. Impact: false-positive violations on a clean dev tree.
  - **Mitigation**: Resolve in requirements/design before coding — decide whether recorded values represent the installed-mode ceiling, whether the `0700` convention is retired, or whether scripts get a wider recorded ceiling. See the working-perms feedback memory and `.cwf/docs/conventions/hash-updates.md`.
- **Manifest semantic inversion**: Recorded perms currently mean "minimum floor" (`Validate::Security` line 116; `_apply_recorded_perms` additive mode). Reinterpreting them as a ceiling changes the meaning of all 48 existing entries and the generator that produces them. Impact: silent mis-validation if not audited.
  - **Mitigation**: Audit manifest generation and every recorded value (9×`0444`, 31×`0500`, 8×`0700`); make the floor-kept-or-replaced choice explicit and test it.

### Medium Priority Risks
- **Fix-mode overlap**: `_apply_recorded_perms` already has `additive` and `exact` modes; a third clear-excess mode risks confusion. Impact: maintenance burden.
  - **Mitigation**: Extend that one function deliberately with a documented `mask`/`clamp` mode; keep all three modes described in the comment block.
- **Self-application**: This task edits hashed scripts (`Security.pm`, `cwf-manage`), so the hash refresh and working perms must land in the same commit per the hash-updates convention.
  - **Mitigation**: Follow the plan-time disclosure rule and refresh hashes in the implementing commit.

## Dependencies
- `.cwf/security/script-hashes.json` (recorded perms manifest) and its generator.
- Install/update end-to-end tests, particularly TC-5 (bash reinstall perms expectation).

## Constraints
- Perl core modules only; POSIX-only environment.
- Hash refresh in the same task and commit as the file modification (hash-updates convention).
- Integrity-check friction is a feature: do not add any surface that silences a tampering signal without surfacing it.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No (~1 day).
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? Borderline — check, fix, and convention reconciliation — but they are tightly coupled to one subsystem.
- [ ] **Risk**: High-risk components needing isolation? The convention/manifest decision is the main risk but cannot be isolated from the check it governs.
- [ ] **Independence**: Can parts be worked separately? No — check and fix share the bit-math and the recorded-value decision.

**Verdict**: No decomposition. Single cohesive change to the integrity subsystem (`Validate::Security` + `cwf-manage` fix path + manifest + tests + one doc).

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered as planned in ~1 day. All five success criteria met (ceiling validation,
clamp repair, unrecorded-file exclusion, convention reconciliation with no
regressions, doc update). The two named high-priority risks — convention conflict
and manifest semantic inversion — were the actual load-bearing work, as predicted.

## Lessons Learned
The decomposition verdict (no split) held. The one thing the plan deferred to
requirements — ceiling-only vs floor+ceiling — should have been resolved *at*
requirements with a user check; the first design draft guessed floor+ceiling and
needed a correction (commit `0f49239`) before coding.
