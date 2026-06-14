# report whether parent branch is direct ancestor - Plan
**Task**: 202 (feature)

## Task Reference
- **Task ID**: internal-202
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/202-report-whether-parent-branch-is-direct-ancestor
- **Baseline Commit**: 2933eba88cc0936d612bb0024537e63bde3861d1
- **Template Version**: 2.1

## Goal
Extend `context-manager hierarchy` to report whether a task's parent branch is
an ancestor of the current branch, so callers can detect at a glance whether
history is strictly linear (the archaeological-main invariant).

## Success Criteria
- [ ] `context-manager hierarchy <task> --format=json` emits a new field stating
      whether the parent branch is an ancestor of the current branch
      (`true` / `false`, or a null/absent marker when undecidable).
- [ ] The markdown format reports the same fact human-readably.
- [ ] Undecidable cases (no parent, parent branch missing, detached/no current
      branch) yield a defined null result, never a hard error or false positive.
- [ ] Tests cover ancestor, diverged (non-ancestor), and no-parent cases.
- [ ] Existing `hierarchy` output fields and exit codes are unchanged
      (additive only — no regression for current callers).

## Original Estimate
**Effort**: <1 day
**Complexity**: Low
**Dependencies**: None (uses git already present in the environment)

## Major Milestones
1. **Requirements**: pin down parent-branch derivation, the precise ancestry
   semantics ("direct ancestor" ⇒ linear-history check), the output schema, and
   every undecidable edge case.
2. **Design**: choose the git mechanism (`git merge-base --is-ancestor`), the
   integration point in `context-manager.d/hierarchy`, and the JSON/markdown
   field shape.
3. **Implement + test**: add the check, extend both output formats, cover the
   three core cases.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Parent-branch name derivation is implicit. The resolver knows the
  parent *task path* (e.g. `28`), not its branch; the branch must be derived
  from the parent dir (`<type>/<num>-<slug>`) and may be renamed or already
  merged/deleted.
  - **Mitigation**: Treat a missing/unresolvable parent branch as the
    undecidable (null) case — surface it, never fail hard or report a false
    ancestry result.

### Medium Priority Risks
- **Risk 2**: Ambiguous semantics of "direct ancestor" vs git reachability.
  - **Mitigation**: Settle the exact definition in requirements before design;
    default position is `git merge-base --is-ancestor <parent> HEAD` (linearity
    check that underpins ff-only merge to the parent).
- **Risk 3**: git edge cases (detached HEAD, no current branch, brand-new repo).
  - **Mitigation**: Enumerate in requirements; each maps to the null result.

## Dependencies
- git available in PATH (already assumed throughout CWF helpers).

## Constraints
- Perl core modules only; follow `docs/conventions/perl.md` and git-path output
  conventions; additive change to one helper plus its test.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one helper.
- [ ] **Risk**: Are there high-risk components that need isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No.

No decomposition signals triggered — proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All five success criteria met. The additive `parent_branch_is_ancestor` field
(JSON) and `Parent branch ancestor of HEAD:` line (markdown) shipped; undecidable
cases resolve to `null`/`unknown` (never a hard error); tests cover ancestor,
diverged, no-parent and missing-branch. No decomposition was needed — single task,
under the <1 day estimate. Risk 1 (implicit parent-branch derivation) materialised
exactly as anticipated and was handled by the planned null fallback.

## Lessons Learned
*Consolidated in j-retrospective.md.*
