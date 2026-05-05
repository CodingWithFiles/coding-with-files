# upgrade installs cwf-init artefacts - Plan
**Task**: 127 (feature)

## Task Reference
- **Task ID**: internal-127
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/127-upgrade-installs-cwf-init-artefacts
- **Template Version**: 2.1

## Goal
Make `cwf-manage update` re-apply every artefact `/cwf-init` and `install.bash` produce outside `.cwf/` and `.cwf-skills/`, prompting for resolution (Debian dpkg-style) when an existing artefact has diverged from what the previous CWF version shipped.

## Success Criteria
- [ ] `cwf-manage update` re-installs (or refreshes) every artefact category currently produced by `/cwf-init` + `install.bash`: `.cwf-rules/`, `.claude/rules/` symlinks, `.claude/settings.json` permissions / hooks, CLAUDE.md preamble, `.gitignore` entries. Skill symlinks and `.cwf/version` (already covered) keep working.
- [ ] When an upgrade-supplied artefact differs from both the previous-version baseline and the on-disk file (three-way divergence), the user is prompted with dpkg-style options (keep current, install new, show diff, abort) and the choice is honoured.
- [ ] When the on-disk file matches the previous-version baseline, the new version is installed silently (no prompt for unmodified files).
- [ ] When the on-disk file already matches the new version, no prompt and no spurious diff is shown.
- [ ] `cwf-manage update` exits non-zero if conflict resolution is aborted, and leaves the working tree in a state the user can re-run from (no half-applied artefact set).
- [ ] An end-to-end test exercises: clean upgrade (no conflicts), unmodified-replace, user-modified conflict (each prompt branch), and abort. Test uses a real repo + real CWF source (no mocked filesystem) per memory `feedback_db_real_not_mocked` analogue.
- [ ] No regression: existing `cwf-manage update` paths (`.cwf/`, `.cwf-skills/`, skill symlinks, version file) keep current behaviour.

## Original Estimate
**Effort**: 3-5 days
**Complexity**: Medium-High
**Dependencies**:
- Task 126 (the new `cwf-claude-settings-merge` helper is the natural spot to re-run on upgrade — it is already idempotent).
- Existing `cwf-init` SKILL.md sections 4, 5, 6, 6b, 6c, 6d, 8 define the canonical artefact set.

## Major Milestones
1. **Artefact inventory**: Enumerate every file/section `/cwf-init` and `install.bash` write outside `.cwf/`/`.cwf-skills/`, classify each as "replace silently / merge idempotently / prompt on conflict", and decide where the previous-version baseline is recorded.
2. **Baseline + diff mechanism**: Pick how the previous version's shipped artefacts are made available during update (e.g. read from the cloned source at the previously-installed ref, or from a committed `.cwf/install-manifest.json`). Implement a three-way comparison (baseline / on-disk / new).
3. **Conflict prompt UX**: Build the dpkg-style interactive prompt (keep / install new / show diff / abort), reusable across artefact categories. Non-TTY behaviour: default to keep + log a warning, exit non-zero so CI surfaces it.
4. **Wire into `cwf-manage update`**: After `update_subtree`/`update_copy` and `create_skill_symlinks`, run an `apply_init_artefacts` phase that processes the inventory in a fixed order. Atomicity: write to staging, swap on success.
5. **Tests + docs**: `t/cwf-manage-update-artefacts.t` covering each branch; update `cwf-init` SKILL.md to point at the shared helper so init and upgrade share one code path; CHANGELOG + BACKLOG entries.

## Risk Assessment
### High Priority Risks
- **Risk**: Mishandling `.claude/settings.json` corrupts a user's hook / permission config silently.
  - **Mitigation**: Reuse `cwf-claude-settings-merge` (idempotent, parses + writes valid JSON, already covered by `t/cwf-claude-settings-merge.t`). Never overwrite the file; only add missing entries the new version expects. Treat user-added entries as untouchable.
- **Risk**: Three-way diff requires the previous-version baseline; if we can't reconstruct it (e.g. project upgraded from v1.x with no manifest), we cannot tell "user modified" from "we shipped this exact thing once". Risks false-positive prompts on every upgrade.
  - **Mitigation**: Start by shipping an `install-manifest.json` from this version onward. For projects without a manifest, prompt only when on-disk and new differ AND we cannot prove on-disk came from a prior CWF version — log the assumption clearly.

### Medium Priority Risks
- **Risk**: Interactive prompt blocks CI/non-interactive upgrades.
  - **Mitigation**: Detect TTY; non-TTY default = keep current + exit non-zero with a clear "rerun interactively or set CWF_UPGRADE_RESOLVE=keep|new" knob.
- **Risk**: Symlink semantics on `.claude/rules/` differ between systems / `git rm` situations.
  - **Mitigation**: Reuse the existing `create_cwf_symlinks` logic from `install.bash` (already removes stale, recreates relative). Treat symlink absence as "needs install", broken symlink as "replace".
- **Risk**: Scope creep — re-running the full `/cwf-init` flow on every update would re-prompt for things like PERL5OPT every time.
  - **Mitigation**: Inventory step explicitly classifies each artefact: `cwf-init`-only (one-shot, never on update — e.g. `cwf-project.json`, init commit, PERL5OPT prompt) vs upgrade-eligible.

## Dependencies
- Task 126's `cwf-claude-settings-merge` helper (must remain idempotent — it already is).
- `.cwf/security/script-hashes.json` — every new helper added as part of this task must be registered there (per Task 125).
- No external blockers.

## Constraints
- POSIX-only (per project memory `feedback_no_perl_c_check.md`).
- Perl + `use utf8;` + `-CDSL` for any new helper (`feedback_always_use_utf8`, `feedback_perl_git_paths`).
- Helper must live under `.cwf/scripts/command-helpers/` and be invoked by `cwf-manage update`; do not put logic inline in `cwf-manage` if it can be a reusable helper that `/cwf-init` can also call (eats own dog food: one source of truth for the artefact set).
- Heredocs and inline `perl -e` are forbidden in any Bash tool calls used during implementation/testing (`feedback_no_heredocs.md`).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? Probably not — upper-bound 5 days.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [x] **Complexity**: Does this involve 3+ distinct concerns? Yes — artefact inventory, three-way diff/baseline, interactive UX, integration into existing update path.
- [x] **Risk**: Are there high-risk components that need isolation? Yes — `.claude/settings.json` corruption risk and the "no baseline" upgrade-from-old-version case both warrant their own design + test focus.
- [ ] **Independence**: Can parts be worked on separately? Marginally — they need to land together to be useful.

**Recommendation**: 2 of 5 signals triggered. **Do not pre-decompose.** Instead, design phase should produce an explicit artefact inventory + baseline strategy; if either grows large enough to warrant its own task, decompose then. Decision is reversible after `c-design-plan`.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All success criteria met. Decomposition decision (no pre-decompose) held — design-phase explicit inventory + baseline strategy + D12 manifest-SHA pin grew the scope by ~50 LOC, well within the original task boundary. See j-retrospective.md § "Variance Analysis" for the full picture.

## Lessons Learned
Time estimate (3-5 days) overshot actual effort by 3-5×. Future LLM-assisted "design + implement + test" tasks with no novel research should be calibrated downward.
