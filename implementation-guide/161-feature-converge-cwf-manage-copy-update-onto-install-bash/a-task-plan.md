# converge cwf-manage copy update onto install.bash - Plan
**Task**: 161 (feature)

## Task Reference
- **Task ID**: internal-161
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/161-converge-cwf-manage-copy-update-onto-install-bash
- **Baseline Commit**: cd1d206f761658a9840c9db52d67ae27391925ab
- **Template Version**: 2.1

## Goal
Converge the `cwf-manage` copy update method onto `install.bash` so there is a single laydown path, preserving the upstream symlink-escape guard at equal strength and extending it to the fresh copy-install path (which is unguarded today).

## Background
FR3 of Task 159, deferred at that task's design gate (see `implementation-guide/159-feature-fix-outstanding-cwf-manage-issues/c-design-plan.md:44` — Decision D3, retained Option A/B/C analysis). Task 155 converged only the subtree update method; the copy update method still uses `cwf-manage`'s own laydown. This task is the focused follow-up the deferral pre-seeded, and includes the preconditions D3 flagged.

## Success Criteria
- [ ] `cwf-manage update` copy branch (`cwf-manage:490-496`) delegates laydown to `install.bash` like the subtree branch; no duplicate copy-laydown code remains (`update_copy`/`copy_tree`/`_escapes_src`/`_collapse_dotdot` removed or relocated, with every caller enumerated to prove none are orphaned).
- [ ] Both a copy-method **update** and a fresh copy-method **install** refuse an upstream tree containing an out-of-tree (absolute or `..`-escaping) symlink — guard strength equal to today's `_escapes_src`, evaluated before any `cp -r`, now also covering fresh install (`install.bash:211-248`, currently unguarded).
- [ ] The extracted guard is integrity-covered: verified by `cwf-manage validate` (present in `.cwf/security/script-hashes.json`) **and** inside the security-review-changeset auto-include set (`@CWF_INTERNAL_PREFIXES`, `security-review-changeset:56`).
- [ ] Preconditions resolved: copy delegation passes the full env block including `CWF_FORCE=1`; the `.cwf-rules` laydown divergence (`update_copy` omits `.cwf-rules`; `install_copy:235` copies it) is reconciled against `run_apply_artefacts` (`cwf-manage:503`) with no double-handling.
- [ ] Full suite (`prove -lr t/`) green and `cwf-manage validate` clean; new tests cover the guard on both install and update paths plus the env-contract precondition.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium (de-risked: Task 159's design phase already mapped the options and preconditions; the only genuinely sensitive work is relocating an audited security check without weakening it)
**Dependencies**: Task 159 c-design D3 analysis (design seed); Perl (already a hard dependency); existing escaping-symlink test fixtures, if any, from the Task 155 copy-guard work.

## Major Milestones
1. **Guard relocated + integrity-covered**: the symlink-escape check is callable from `install.bash` before `cp -r`, lives where `cwf-manage validate` and `@CWF_INTERNAL_PREFIXES` cover it.
2. **Fresh-install gap closed**: `install_copy` invokes the guard before copying — the headline security win.
3. **Copy update converged**: `cwf-manage` copy branch delegates to `install.bash`; dead laydown subs removed after caller enumeration.
4. **Preconditions reconciled**: full env block (`CWF_FORCE=1`) passed; `.cwf-rules` handling settled against `run_apply_artefacts`.
5. **Verified**: tests for the guard on both paths and the env contract; suite + validate green.

## Risk Assessment
### High Priority Risks
- **Weakening an audited security check during relocation**: porting/moving `_escapes_src`/`_collapse_dotdot` risks introducing the exact path-canonicalisation bug class the guard exists to prevent.
  - **Mitigation**: relocate the existing lexical logic verbatim (move, do not rewrite); keep implementation diversity at the verifier/producer boundary; regression tests with known absolute and `..`-escaping symlink fixtures, asserted on **both** install and update paths.
- **Guard lands outside the integrity boundary**: if the guard is co-located with `install.bash` at repo-root `scripts/` it is outside the hash ledger (Task 155 settled `install.bash` itself as out-of-ledger) and outside `@CWF_INTERNAL_PREFIXES`, so the "verified guard" benefit is only partially real.
  - **Mitigation**: success criterion makes integrity coverage non-optional; design phase chooses a location inside `.cwf/` or explicitly adds the guard to the manifest **and** `@CWF_INTERNAL_PREFIXES`.

### Medium Priority Risks
- **`.cwf-rules` behaviour change causing double-handling**: converging gains `.cwf-rules` staging on the copy update path, which `run_apply_artefacts` may already handle.
  - **Mitigation**: confirm against `run_apply_artefacts` in design; test the produced tree for duplicate/inconsistent `.cwf-rules`.
- **Orphaning a caller when deleting dead subs**: removing `update_copy`/`copy_tree`/`_escapes_src`/`_collapse_dotdot` could break an unenumerated caller (Task 155 lesson).
  - **Mitigation**: enumerate every caller of each sub before deletion; delete only those proven unreferenced.

## Dependencies
- Task 159 `c-design-plan.md` D3 analysis (design record motivating the deferral; pre-seeds this task).
- Perl at the copy step of `install.bash` (Perl is already a hard project dependency).

## Constraints
- MUST NOT weaken upstream-symlink-escape protection under any option (Task 159 b-requirements NFR4); no out-of-tree symlink may be written into the installed `.cwf/`.
- POSIX-only; core Perl modules only.
- Per the hash-updates convention, any edit to a hashed file refreshes `.cwf/security/script-hashes.json` in the same task and commit.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No (1-2 days).
- [ ] **People**: Does this need >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? Borderline — guard relocation, fresh-install guard, cwf-manage convergence, and two preconditions. They are tightly coupled around a single convergence and Task 159's design already scoped them as one focused task.
- [ ] **Risk**: high-risk component needing isolation? The guard relocation is sensitive but isolated to milestones 1-2 and already de-risked by the D3 analysis.
- [ ] **Independence**: Can parts be worked on separately? No — the steps are sequential (guard must be relocated before either path can call it).

**Conclusion**: One borderline signal (complexity); the concerns are sequential and coupled, and Task 159 deliberately scoped this as a single focused task. Proceed as a flat task — no subtasks.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met in one session, milestones executed in plan order. The copy branch now delegates to `install.bash`; the guard was extracted to `cwf-check-tree-symlinks` (integrity-covered) and wired into the fresh copy-install path; 340 lines of dead laydown code (six subs + five imports) removed after caller enumeration. The one borderline decomposition signal (complexity) was correct to proceed flat — the concerns were sequential and coupled.

## Lessons Learned
The plan's "Medium (de-risked)" rating held because Task 159's D3 analysis had already mapped the options and preconditions — the deferral pre-seeded a tractable follow-up. The single sensitive piece (relocating an audited check) was handled by the plan's stated mitigation: move the lexical logic verbatim, don't rewrite. See j-retrospective.md.
