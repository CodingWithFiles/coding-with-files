# Make cwf-manage update handle a dirty working tree - Plan
**Task**: 116 (bugfix)

## Task Reference
- **Task ID**: internal-116
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A (sibling follow-up to Task 115; both surfaced from same external-user upgrade report v1.0.95 → v1.0.114)
- **Branch**: bugfix/116-make-cwf-manage-update-handle-a-dirty-working-tree (branched from Task 115 tip; ff-folded into main once 115 merges)
- **Template Version**: 2.1

## Goal
Make `cwf-manage update` detect a dirty working tree and guide the user out of it — rather than failing opaquely under the `subtree` method or silently destroying uncommitted `.cwf/` changes under the `copy` method.

## Success Criteria
- [ ] `cwf-manage update` detects a dirty working tree before invoking `update_subtree` or `update_copy`
- [ ] On detection, the user sees a CWF-prefixed, actionable error or a labelled stash entry — never a raw `git subtree` error or silent overwrite
- [ ] Chosen behaviour (fail-fast vs auto-stash) is documented in `cwf-manage help` and the file-header comment block
- [ ] A regression test runs `cwf-manage update` against a dirty-tree fixture and asserts the chosen behaviour
- [ ] Existing 235/235 test suite still passes; `cwf-manage validate` OK after sha256 re-hash
- [ ] Both `subtree` (noisy git failure) and `copy` (silent destruction) paths protected

## Original Estimate
**Effort**: 0.5–1 day
**Complexity**: Low–Medium (single helper, two call sites, but dirty-vs-clean semantics need a small decision in c-design)
**Dependencies**: Task 115's `resolve_source` helper is on this branch — no functional dependency, just a branch-ordering one. Will fold into main correctly via the squashed-linear-history convention once 115 lands.

## Major Milestones
1. **Decide fail-fast vs auto-stash** (locked in c-design): single source of truth for the behaviour, including which definition of "dirty" applies (working-tree only? include untracked? .cwf-scoped?)
2. **Add dirty-tree detection helper** (`check_clean_tree` or similar) that calls `git status --porcelain` and dies with a CWF-prefixed message
3. **Wire into `cmd_update`** before `update_subtree` / `update_copy` dispatch, so both methods are protected
4. **Document + test**: help-text block + `Environment:`/Notes update; regression test using a `mktemp -d` + `git init` fixture (same pattern as Task 115's TC-10)

## Risk Assessment
### High Priority Risks
- **Auto-stash failure-mode messaging**: If we auto-stash and the update fails mid-way, the user is left with a stash they didn't ask for and may not notice. Mitigation: prefer **fail-fast** unless c-design surfaces a strong reason for auto-stash; if auto-stash, log every stash op (`stashed as cwf-manage-update-<ts>`, `restored from cwf-manage-update-<ts>`, `stash retained on failure: pop with git stash pop stash@{...}`).
- **Copy-method silent destruction is arguably a worse bug than the subtree noisy-fail.** The BACKLOG entry centres on the subtree path's opaque error, but the copy path's `rmtree(".cwf")` will silently shred uncommitted edits to a CWF script with no warning. Mitigation: scope the check to cover **both** paths in this task — c-design will confirm.

### Medium Priority Risks
- **What counts as "dirty"**: staged-only? unstaged-only? include untracked? `.cwf/`-scoped or repo-wide? Mitigation: c-design picks one (recommendation: anything in `.cwf/` or `.cwf-skills/` per `git status --porcelain -- .cwf .cwf-skills`; ignore unrelated dirty paths).
- **Test fixture cost**: Building a "dirty fixture" requires `mktemp -d` + `git init` + populated `.cwf/version` + a tracked + modified file. Pattern is established in Task 115's TC-10 — reuse it.

### Low Priority Risks
- **PERL5OPT=-CDSL parity**: file is now `-CDSL` clean post-Task 115. Any new error string with non-ASCII (em-dash) needs `use utf8;` already in place. Trivial, just keep it ASCII or rely on the existing pragma.

## Dependencies
- **Task 115** (in flight, not yet merged to main): branch is descended from 115's tip. `resolve_source` is unchanged by 116; no functional coupling.
- **No external dependencies** beyond `git` (already required) and the existing `cwf-manage` Perl modules.

## Constraints
- Perl-only, no new CPAN deps beyond what `cwf-manage` already uses (`File::Temp`, `File::Find`, `File::Copy`, `List::Util`).
- Must remain `-CDSL` / `use utf8;` compliant per `docs/conventions/perl-git-paths.md`.
- Must update `.cwf/security/script-hashes.json` (foreseeable; explicit in the d-impl-plan checklist this time, per Task 115's retrospective recommendation).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: <1 day — no decomposition needed
- [ ] **People**: Single contributor — no decomposition needed
- [ ] **Complexity**: One helper + two call sites; one design decision (fail-fast vs auto-stash) — single concern
- [ ] **Risk**: Auto-stash messaging is the only meaningful risk; isolated to the helper — no isolation needed
- [ ] **Independence**: Not parallelisable — no decomposition needed

**Verdict**: 0/5 signals triggered. Single-task scope.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 116
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
