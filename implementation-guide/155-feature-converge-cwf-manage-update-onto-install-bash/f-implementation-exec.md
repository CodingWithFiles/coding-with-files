# Converge cwf-manage update onto install.bash - Implementation Execution
**Task**: 155 (feature)

## Task Reference
- **Task ID**: internal-155
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/155-converge-cwf-manage-update-onto-install-bash
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status when complete

## Actual Results

### Step 1: End-to-end fixture harness (FR8)
- **Actual**: Added `t/cwf-manage-update-end-to-end.t`. Rather than a checked-in `t/fixtures/upstream-server/`, the harness builds the upstream programmatically in setup (`build_upstream`): a git repo seeded from the real `scripts/`, `.cwf/`, `.claude/{skills,rules,agents}`, tagged `v0.0.1..N`, each writing a distinct `.cwf/E2E-MARKER`. `install_consumer` installs via `install.bash` (subtree) and commits the install (mirroring post-`/cwf-init` state: gitignore the runtime lock, track `.cwf/version`). Five subtests: FR9 ref rejection, FR2/FR3/FR5 cross-version-gap update + validate, FR6 two-update pin, FR6 downgrade, FR10 staged-work isolation. All green.
- **Deviations**: (1) Built the fixture in-test rather than as a committed `t/fixtures/` tree — simpler, no second copy of CWF content to maintain, and the spanning-versions requirement is met by the seeded tags. (2) FR10 subtest does not assert the update *succeeds* with unrelated staged work: `git subtree add` requires a clean index (pre-existing git-subtree constraint, out of scope), so the meaningful assertion is that the force-reinstall remove commit never captures the staged file and the file is never lost — both verified.

### Step 2: install.bash hardening
- **Actual**: Force-block commit now uses an explicit CWF pathspec (`git commit ... -- .cwf .cwf-skills .cwf-rules .cwf-agents`), keeping the `|| true` guard. Ported the regular-file collision `die` into the generic `create_cwf_symlinks` so the subtree (delegated) path retains the protection `cwf-manage`'s `create_agent_symlinks` had.

### Step 3: ref validation + list-form (FR9, NFR4)
- **Actual**: Added `validate_ref_lexical` (allows `latest` and `[A-Za-z0-9._/-]`; rejects leading `-` and `..` segments), called first in `cmd_update` before any side effect. Converted `resolve_ref` and `resolve_sha` from backtick interpolation to list-form `open '-|'`.

### Step 4: cwf-manage delegation (subtree method)
- **Actual**: Widened `check_clean_tree` to include `.cwf-rules`. `cmd_update` subtree branch now `chdir`s to `$git_root` and `system`s the target's `install.bash` with `CWF_FORCE=1`, `CWF_SOURCE=file://$clone_dir`, `CWF_REF=$sha` (resolved SHA), `CWF_METHOD`; spawn-failure/signal/non-zero-exit each `die_msg`. Deleted `update_subtree`.
- **Deviations**: Kept `create_skill_symlinks` / `create_agent_symlinks` (the **copy** branch still needs them — only the subtree branch delegates symlink creation to install.bash). The plan's deletion list was over-scoped given copy is retained.

### Step 5: exact-perms + version reconcile (FR5, FR6)
- **Actual**: Extracted `_read_hashes_data` + `_apply_recorded_perms($mode)` from `cmd_fix_security` (entry point keeps its `exit`). Added `apply_exact_perms_or_die` (`exact` mode; fatal on sha mismatch / unfixable), called after artefacts/settings-merge. FR6 satisfied by making `cmd_update`'s version write **authoritative** (it overwrites install.bash's base version file), which both restores the real `cwf_source` (not the transient `file://`) and pins `cwf_install_manifest_sha` exactly once — cleaner than re-read-and-augment.
- **Deviations**: exact-perms runs **after** apply-artefacts/settings-merge (not before, as the data-flow first listed) so the tree is fully laid down before perms are set — resolves the design's Open Question 2 ordering invariant.

### Step 6: apply-artefacts narrowing — NOT DONE (deliberate deviation)
- **Actual**: Left `cwf-apply-artefacts` un-narrowed.
- **Deviations**: Narrowing (dropping `cwf-rules-bundle` + `claude-rules-symlinks`) would strip rule delivery from the **copy** path, which does not go through install.bash. Since copy is kept, narrowing globally is unsafe. On the subtree path the re-application is idempotent (identical content ⇒ no diff), so it is harmless. Full single-ownership is deferred with copy-method convergence.

### Step 7: hashes + docs + backlog
- **Actual**: Refreshed `script-hashes.json` `cwf-manage` sha256 (same commit). Documented the forward-only `CWF_FORCE` recovery in `INSTALL.md`. Filed BACKLOG item "Converge cwf-manage copy-method update onto install.bash" (Low).

### Step 8: Validation
- **Actual**: Full `t/` suite green (46 files, 505 tests). `cwf-manage validate` clean. New end-to-end test green (5 subtests).

## Blockers Encountered
None. Two fixture-shaped issues surfaced and resolved during test bring-up: (1) fresh `install.bash` leaves `.cwf/version` untracked and `.update.lock` present — fixed by committing the install + gitignoring the lock (mirrors real post-`/cwf-init` state); (2) `apply-artefacts` rules-inject needs `CWF_UPGRADE_RESOLVE` in non-TTY runs — set to `new` (interactive branch is out of scope).

## Deferral Check
Before marking status=Finished, verify:
- [x] All steps from d-implementation-plan.md executed (Step 6 deliberately not narrowed — see deviation)
- [x] All success criteria from a-task-plan.md met (subtree path; copy-path FR1 deferred)
- [x] All requirements from b-requirements-plan.md addressed (FR1 subtree-only; FR2-FR10 met)
- [x] All design guidance in c-design-plan.md followed (with documented refinements)
- [x] No planned work deferred without rationale
- [x] Deferred copy-method convergence: BACKLOG item filed

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 155
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
See per-step Actual Results above. All 8 steps executed; 3 deviations documented (subtree-only convergence, apply-artefacts un-narrowed, exact-perms after artefacts). Suite green, validate clean.

## Security Review

**State**: no findings

Implementation-phase review complete (subagent `cwf-security-reviewer-changeset`, changeset = 390 lines across `.cwf/scripts/cwf-manage` + `scripts/install.bash`). Verbatim:

> no findings
>
> Key checks (all clean):
> 1. FR9 ref validation runs before any side effect; charset `[A-Za-z0-9._/-]+`, no leading `-`, no `..`. Defence-in-depth on top of the backtick→list-form conversion.
> 2. Backtick→list-form conversion of `resolve_ref`/`resolve_sha` removes the shell from ref handling — the previous `` `git … "$ref"` `` was the real injection vector and is gone. `--verify --quiet` + `length $check` rejects non-existent refs.
> 3. Delegation chain: `CWF_SOURCE=file://$clone_dir`, `CWF_REF=$sha`, `CWF_FORCE=1` passed as discrete argv to list-form `system('bash', $installer)` (no shell); `$clone_dir` is an internal tempdir. Pinning `CWF_REF` to the resolved full SHA means install.bash cannot drift to a different commit — an integrity gain.
> 4. `apply_exact_perms_or_die` is fatal on sha-mismatch/missing after laydown — least-privilege, aborts before the manifest pin; does not silently repair a corrupt laydown ("surface, never smooth").
> 5. install.bash symlink conflict-check `[[ -e "$target" && ! -L "$target" ]]` refuses to clobber a user's regular file at a `cwf-*` path; `! -L` excludes the stale symlinks already removed.
> 6. Restricted reinstall commit (`-- .cwf .cwf-skills .cwf-rules .cwf-agents`) prevents unrelated staged work from being swept into a CWF commit. Security-positive.
>
> Pattern note (safe here, no action): `resolve_sha` reads git output without checking child exit status, so an empty `$sha` would propagate as `CWF_REF=''` and install.bash would fall back to `latest`. Safe because `$resolved` was `--verify`'d on the preceding line against the same just-cloned repo. Audit any future caller of `resolve_sha` passing a ref not `resolve_ref`-verified against the same clone.

## Lessons Learned
Convergence is bounded by primitive parity — the copy path's `_escapes_src` symlink-escape guard has no cheap bash equivalent, so full single-ownership was out of scope. Making `cmd_update`'s version write authoritative cleanly avoided the feared double-write against install.bash's base version file. See j-retrospective.md.
