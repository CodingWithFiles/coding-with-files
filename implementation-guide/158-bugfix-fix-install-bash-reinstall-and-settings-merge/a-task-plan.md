# Fix install.bash reinstall and settings-merge - Plan
**Task**: 158 (bugfix)

## Task Reference
- **Task ID**: internal-158
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/158-fix-install-bash-reinstall-and-settings-merge
- **Baseline Commit**: 920c96421a1ec0989641c3d05be7aab088e0d7bb
- **Template Version**: 2.1

## Goal
Fix two `scripts/install.bash` defects that break a copy→subtree reinstall and
leave `.claude/settings.json` unmerged on a fresh install, and correct a stale
`.claude/agents/` omission in the security-review pathspec-coverage doc — all
three surfaced by a downstream consumer's install log.

## Background
A CWF consumer migrating a copy install to subtree (via `CWF_FORCE=1`) hit two
install.bash bugs, plus a doc/helper drift:

1. **Force-reinstall commit aborts on a non-matching pathspec** (`install.bash:177-188`).
   The removal loop `git rm`s only dirs that *exist* (`-d "$dir"` guard, 178), but
   the follow-up commit hard-codes the full pathspec `-- .cwf .cwf-skills .cwf-rules .cwf-agents`
   (188). When a pre-state lacks one of them (e.g. `.cwf-agents`, absent on a copy
   install predating agents), `git commit -- .cwf-agents` fails with "pathspec did
   not match"; because git commits *nothing* on a pathspec error and `|| true`
   swallows it, the staged deletions of the other dirs remain in the index. The
   subsequent `git subtree add` (193+) then fails on the dirty index. The code
   comment (185) only anticipated an *empty* pathspec, not a *non-matching* one.

2. **`post_install` never merges `.claude/settings.json`** (`install.bash:246-265`).
   It writes symlinks and `.cwf/version` only. `cwf-claude-settings-merge` (which
   lands PERL5OPT and the Bash allowlist entries) is never invoked, so a fresh
   install via install.bash omits them. `cwf-manage update` does call it
   (`run_settings_merge`, cwf-manage:273), so the direct-install path is the gap.

3. **Doc omits `.claude/agents/`** (`.cwf/docs/skills/security-review.md` §Pathspec
   coverage). The enumeration lists `.claude/{scripts,skills,hooks,rules}/` but not
   `.claude/agents/`, although the helper `security-review-changeset:63` already
   includes it. The helper is correct; the doc is stale.

The consumer's interim fix is a `sed` patch on their extracted installer; the real
fix is upstream (this repo). The same-family `cwf_version=$ref` ref-vs-semver issue
at `install.bash:257` is **out of scope** — already tracked as a separate Very High
backlog item (cwf-manage records a ref instead of a resolved semver).

## Success Criteria
- [ ] A `CWF_FORCE=1` reinstall whose pre-state is missing one or more of the CWF dirs (notably `.cwf-agents`) completes cleanly: the removal commit succeeds with only the dirs that were actually removed, and every `git subtree add` runs against a clean index
- [ ] A fresh install via `install.bash` lands the `.claude/settings.json` merge (PERL5OPT + allowlist) — verified by inspecting the file after a clean install
- [ ] `security-review.md` §Pathspec coverage lists `.claude/agents/`, matching the helper
- [ ] Existing install/update tests still pass; new coverage exercises the missing-dir reinstall path

## Original Estimate
**Effort**: <1 day
**Complexity**: Low–Medium (item 1 needs careful git-index reasoning; items 2–3 are small)
**Dependencies**: None. Touches `scripts/install.bash` and `.cwf/docs/skills/security-review.md`.

## Major Milestones
1. **Reinstall pathspec fix**: removal commit restricted to dirs actually `git rm`'d; reinstall with a missing dir verified end-to-end
2. **Settings-merge wired into install.bash**: `cwf-claude-settings-merge` invoked post-laydown; fresh-install settings verified
3. **Doc corrected + tests green**: `.claude/agents/` added to the doc; install/update test suite passes with new reinstall coverage

## Risk Assessment
### Medium Priority Risks
- **Completion-caller architecture, not a simple missing call**: install.bash is intentionally laydown-only. The "completion" steps (apply-artefacts, settings-merge, exact-perms) are done by the *caller* — `/cwf-init` for fresh installs (SKILL.md steps 6b + 6d), `cwf-manage update` for updates (`run_apply_artefacts` + `run_settings_merge`). The consumer's raw `CWF_FORCE=1 bash install.bash` migration has *no* completion caller, so neither artefacts nor settings get merged. Item 2 (settings) is one facet of this; apply-artefacts is the symmetric facet.
  - **Mitigation**: design phase decides whether install.bash should self-complete (call both helpers, relying on their idempotency) or whether only settings-merge is in scope with apply-artefacts deferred. Surface the coherence trade-off (a settings-only fix leaves the migration path half-complete) for review; do not silently expand or under-scope.
- **Double-apply is safe**: `cwf-claude-settings-merge` is idempotent (helper header line 31; PERL5OPT add-if-absent, allowlist union/dedup) and `cwf-apply-artefacts --bootstrap-init` overwrites conflicts. So adding either call to install.bash is safe even though `/cwf-init` and `cwf-manage update` also call them.
  - **Mitigation**: confirmed during planning; no special guarding needed.
- **Symlink overlap if apply-artefacts is included**: install.bash post_install already creates `.claude/rules` (and skills/agents) symlinks inline (251-253), and `cwf-apply-artefacts` also manages `.claude/rules` symlinks.
  - **Mitigation**: if apply-artefacts is brought in scope, design must reconcile the overlap (idempotent creation, or remove the inline subset).

### Low Priority Risks
- **End-to-end install test cost**: exercising a real `CWF_FORCE` reinstall needs a scratch git repo + fixture source.
  - **Mitigation**: reuse the `t/cwf-manage-update-end-to-end.t` fixture-server pattern (Task 155) rather than building new scaffolding.

## Dependencies
- None external. Reuses existing helpers (`cwf-claude-settings-merge`, `cwf-apply-artefacts`) and the Task-155 end-to-end test harness pattern.

## Constraints
- Neither file in scope is hash-tracked: `scripts/install.bash` lives outside the hashed `.cwf/` tree (it bootstraps before `.cwf/` exists) and is absent from `script-hashes.json`; `.cwf/docs/skills/security-review.md` is also not tracked. So this task needs **no** `script-hashes.json` refresh — confirmed during planning.
- Bugfix workflow: no requirements phase; design (c) settles the open scope question (apply-artefacts parity) before implementation.
- Bounded to the three reported items + their direct test coverage; the `install.bash:257` ref-vs-semver issue and any broad install/cwf-init refactor are out of scope.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No (<1 day)
- [ ] **People**: >2 people? No
- [ ] **Complexity**: 3+ distinct concerns? Borderline — two install.bash bugs + one doc fix, but all small and in adjacent code; one task with a clear design is appropriate
- [ ] **Risk**: High-risk components needing isolation? No
- [ ] **Independence**: Separable? The doc fix is independent, but trivial; not worth a separate task

No decomposition: the items share a root (install.bash post-laydown completeness + a consumer report) and are individually small. Design phase will confirm.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four success criteria met. Scope held to the three reported items; the
`install.bash:257` ref-vs-semver issue stayed out of scope (tracked as a
separate Very High backlog item).

## Lessons Learned
The "completion-caller architecture" risk flagged here was the crux of the task.
Item 2 (settings-merge) is one facet of it; the symmetric facet (apply-artefacts)
was correctly judged *out of scope* in design after its premise was refuted.
