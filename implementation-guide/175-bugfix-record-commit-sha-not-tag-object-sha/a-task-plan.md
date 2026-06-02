# record commit sha not tag-object sha - Plan
**Task**: 175 (bugfix)

## Task Reference
- **Task ID**: internal-175
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/175-record-commit-sha-not-tag-object-sha
- **Baseline Commit**: 7e376bc274bfa52a706fd3de7b5b774611345dd1
- **Template Version**: 2.1

## Goal
Record the resolved ref's **commit** SHA in `.cwf/version`, not the annotated-tag object SHA, so an install/update against a tag records a SHA that matches `git log`.

## Background
`git rev-parse <ref>` returns the *tag object* SHA for an annotated tag, not the
commit it points to. Two sites record `cwf_sha` this way:
- `scripts/install.bash:310` — `resolved_sha="$(git -C … rev-parse "$resolved_ref")"`
- `.cwf/scripts/cwf-manage:225` — `resolve_sha()` runs `git rev-parse $ref`

Result: a tagged install (e.g. `v1.1.169`) records `cwf_sha=473baea…` (tag object)
while the tag's commit is `0764380…`. The field is display-only — `cwf-manage status`
prints it (`cwf-manage:346`) and nothing verifies against it — but the false mismatch
misled a real upgrade session into wrongly concluding "subtree installs HEAD, can't pin
a tag" (it pins correctly). The friction is the cost: a misleading recorded SHA sends
readers/agents down a rabbit hole.

## Success Criteria
- [ ] Both sites resolve the recorded SHA via commit-peel (`<ref>^{commit}`), so an annotated-tag install records the tag's **commit** SHA
- [ ] Non-tag refs (branch, lightweight tag, raw SHA, `HEAD`) record the same SHA as before (peel is a no-op for commit-ish refs)
- [ ] A regression test asserts a tagged install records `rev-parse <tag>^{commit}`, not `rev-parse <tag>`
- [ ] `cwf-manage` hash refresh committed in the same commit as the edit; `cwf-manage validate` passes

## Original Estimate
**Effort**: <0.5 day
**Complexity**: Low
**Dependencies**: None

## Major Milestones
1. **Confirm scope**: pin both sites; confirm branch/lightweight-tag/SHA/HEAD paths are unaffected by the peel
2. **Apply fix**: commit-peel at both sites
3. **Regression test**: annotated-tag case asserts commit SHA
4. **Integrity**: refresh `cwf-manage` hash in the same commit; `validate` passes

## Risk Assessment
### High Priority Risks
- **Risk 1**: `cwf-manage` is a hashed script; editing without refreshing `.cwf/security/script-hashes.json` in the same commit breaks `cwf-manage validate`.
  - **Mitigation**: Follow the hash-updates convention — refresh the hash in the same commit as the edit; restore working perms to the recorded value (0500), not 0700.

### Medium Priority Risks
- **Risk 2**: `^{commit}` peel could alter behaviour for non-tag refs.
  - **Mitigation**: `<commitish>^{commit}` is a no-op for branches, lightweight tags, raw SHAs, and `HEAD`; it only changes annotated tags. Test each ref form.
- **Risk 3**: Existing installs already carry tag-object SHAs; the fix is forward-only.
  - **Mitigation**: No migration — the field is display-only. Document as forward-only, consistent with the existing INSTALL.md recovery-is-forward-only note.

## Dependencies
- None (self-contained two-line fix plus test)

## Constraints
- `scripts/install.bash` is the bootstrap installer (repo-root, served via raw URL / `git archive`); `.cwf/scripts/cwf-manage` is hashed. Keep the two resolutions consistent so subtree-path (install.bash) and update-path (cwf-manage) record identical SHAs.
- Perl/Bash conventions per CLAUDE.md; core Perl modules only.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? No — under half a day
- [x] **People**: Does this need >2 people working on different parts? No
- [x] **Complexity**: Does this involve 3+ distinct concerns? No — one concern (SHA resolution) in two co-located sites
- [x] **Risk**: Are there high-risk components that need isolation? No — display-only field, forward-only fix
- [x] **Independence**: Can parts be worked on separately? No — single coherent change

**Verdict**: No decomposition. Zero signals triggered.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four success criteria met. Both sites peel with `<ref>^{commit}`; non-tag refs unchanged (TC-4, no-op); annotated-tag regression test added; `cwf-manage` hash refreshed in-commit, `validate` clean. See `j-retrospective.md`.

## Lessons Learned
A display-only field still caused real harm (a phantom "subtree can't pin a tag" conclusion). See `j-retrospective.md` §Key Learnings.
