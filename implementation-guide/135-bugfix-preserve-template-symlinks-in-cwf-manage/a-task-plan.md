# Preserve template symlinks in cwf-manage - Plan
**Task**: 135 (bugfix)

## Task Reference
- **Task ID**: internal-135
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/135-preserve-template-symlinks-in-cwf-manage
- **Baseline Commit**: e9bce4fcc6c856cf4010e39dcae6cf726f7b3950
- **Template Version**: 2.1

## Goal
Fix `cwf-manage update` so it preserves the `.cwf/templates/<type>/*.template` symlinks (pointing into `pool/`) instead of dereferencing them to regular-file copies, and extend `cwf-manage validate` so the resulting symlink-vs-regular-file mismatch is caught rather than passing silently.

## Success Criteria
- [ ] Running `cwf-manage update` against a clean installation leaves every entry under `.cwf/templates/{bugfix,chore,discovery,feature,hotfix}/` as a symlink whose target resolves inside `.cwf/templates/pool/` (verified by `find -type l` and `readlink`).
- [ ] Running `cwf-manage validate` against an installation where one or more pool-pointing entries have been replaced by regular files (whether by a previous buggy update or by manual edit) reports the mismatch and exits non-zero.
- [ ] `cwf-manage validate` against a correctly-symlinked installation continues to pass (no regressions on the happy path).
- [ ] Regression test that re-runs `cwf-manage update` against the present (already-resolved) state of this repo restores the symlinks rather than leaving regular files in place.
- [ ] No change to the on-disk layout of `.cwf/templates/pool/` itself or to the symlink targets — fix is in the install pipeline and the validator only.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium
**Dependencies**: None — both bugs are localised to `.cwf/scripts/cwf-manage` (`copy_tree`, `update_copy`, `cmd_validate`) and `.cwf/security/script-hashes.json` (or whatever manifest the validator consults for type expectations).

## Major Milestones
1. **Reproduce both bugs in a test fixture**: stand up a scratch installation, run `cwf-manage update`, observe `120000 → 100644` typechanges, confirm `cwf-manage validate` passes on the broken state.
2. **Fix `update_copy` / `copy_tree`**: teach the copy routine to detect symlinks and recreate them at the destination (preserving relative targets), rather than reading-and-writing content.
3. **Extend `cmd_validate`**: have the validator record and check expected file type (symlink vs regular) per entry, not just content hash; surface mismatches with a clear error.
4. **Tests + regression coverage**: add tests that exercise both the fix and the new validation, including the recovery scenario (update over an already-resolved install heals it).

## Risk Assessment
### High Priority Risks
- **Cross-platform symlink behaviour**: `File::Copy::copy` was chosen partly because it works uniformly. Replacing it with `symlink()` introduces platform-dependent failure modes (e.g. Windows without developer mode). The project is POSIX-only per established convention, so this is bounded — but we should fail loudly if `symlink()` returns 0, not silently fall back to a regular-file copy.
  - **Mitigation**: Explicit `symlink($target, $dest) or die_msg(...)`. No fallback. Document POSIX-only assumption in the relevant function comment if not already present.
- **Validator manifest format change**: if `script-hashes.json` (or equivalent) currently records only `{path: sha256}`, adding "expected type" widens the schema. Older installs would need a migration path or graceful degradation.
  - **Mitigation**: Make the type field optional in the manifest reader; absence means "type-agnostic" (current behaviour). Design phase will decide whether to backfill the manifest for existing entries automatically or require a one-shot regeneration step.

### Medium Priority Risks
- **Other symlinks in the source tree**: the templates dir is the known case, but `find_git_root` and `copy_tree` walk `.cwf/` and `.claude/skills` indiscriminately. If there are other symlinks under those paths (intentional or not), the fix will affect them too. Need to enumerate before changing the copy routine.
  - **Mitigation**: Audit `git ls-files -s` for mode `120000` across the source tree as part of the design phase; decide whether the fix is "preserve all symlinks" (general) or "preserve symlinks under `.cwf/templates/`" (narrow).
- **`script-hashes.json` is for executables, not templates**: name suggests its scope is script integrity. The templates dir may not be covered by the existing validator at all, in which case extending validation means adding a new check rather than fixing one.
  - **Mitigation**: Confirm scope in the design phase by reading `cmd_validate` and `script-hashes.json`. If templates are out-of-scope today, the design must decide whether the new check piggybacks on the existing manifest or stands alone.

## Dependencies
- None external. Bug, fix, and tests all live inside `.cwf/scripts/cwf-manage` and the security/manifest data it consults.

## Constraints
- POSIX-only project (per repo convention); symlink support assumed.
- Must not change the public CLI surface of `cwf-manage` (subcommand names, exit codes for the happy path) — only add a new failing condition to `validate` and fix a silent corruption in `update`.
- The fix must heal an already-broken installation when re-run, not just prevent the regression on a clean one. End-users who have already updated to v1.0.134 should be able to recover by running `cwf-manage update` again.

## Decomposition Check
- [x] **Time**: Will this take >1 week? **No** — small, localised bugfix.
- [x] **People**: Does this need >2 people working on different parts? **No**.
- [x] **Complexity**: Does this involve 3+ distinct concerns? **No** — two tightly-related bugs in the same file.
- [x] **Risk**: Are there high-risk components that need isolation? **No** — the risks listed are routine, not isolating.
- [x] **Independence**: Can parts be worked on separately? **Borderline** — the `update` fix and the `validate` extension are technically independent, but they share a manifest-format decision and a test fixture, so splitting them would duplicate scaffolding. Keep as one task.

**Decision**: Single task; no decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 135
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
