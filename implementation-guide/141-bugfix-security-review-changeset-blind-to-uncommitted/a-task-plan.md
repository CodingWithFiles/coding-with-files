# security-review-changeset blind to uncommitted - Plan
**Task**: 141 (bugfix)

## Task Reference
- **Task ID**: internal-141
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/141-security-review-changeset-blind-to-uncommitted
- **Baseline Commit**: f833bbf5fd110fa99136ba9daea088a3a4cba3b9
- **Template Version**: 2.1

## Goal
Make `security-review-changeset` produce a non-empty diff when invoked before the exec-phase checkpoint commit, so the exec-phase security review actually runs against the phase's changes instead of silently classifying as `no findings: empty changeset`.

## Success Criteria
- [ ] Invoking the helper on a branch with staged + unstaged + working-tree changes (and no new commits since the recorded baseline) emits a diff that includes those changes — verified by a regression test that creates exactly that state.
- [ ] The current behaviour for fully-committed branches (the existing test cases) is unchanged — verified by `prove t/` still green with no test edits required for the committed-state cases.
- [ ] The exec-phase skills (`cwf-implementation-exec`, `cwf-testing-exec`) no longer need the workaround documented in Tasks 137/138/139/140 retrospectives ("commit phase changes first, then re-run the helper"). The natural order — write code, run security review, then checkpoint commit — works on first try.
- [ ] No new permission surface introduced; the helper still only reads via `git`, never mutates working tree state.
- [ ] BACKLOG entry "security-review-changeset blind to uncommitted work" retired by this task; `cwf-manage validate` and `prove t/` green.

## Original Estimate
**Effort**: 0.5 day
**Complexity**: Low
**Dependencies**: None — single helper script, two diff-spec sites, and a new regression test.

## Major Milestones
1. **Design call between options (a) and (b)**: c-design-plan picks between dropping `..HEAD` from the diff spec (option a) vs adding a worktree-dirty warning while keeping the current diff spec (option b). The BACKLOG entry preferences (a) or (b), excludes (c).
2. **Implementation**: Two diff-spec sites in `security-review-changeset` updated; regression test for the uncommitted-changes scenario added.
3. **Verification**: Re-run security-review-changeset against this task's own working tree (mid-exec, before checkpoint) and confirm it now sees its own changes — the canonical end-to-end smoke for this fix.

## Risk Assessment

### High Priority Risks
- **Risk 1**: Option (a)'s behavioural change widens the diff window mid-phase — any uncommitted experiment, debug log, or scratch edit in the working tree now lands in the security review. Could noise up the subagent's output or push the changeset over the 500-line cap unnecessarily.
  - **Mitigation**: In c-design-plan, decide whether the helper should respect `.gitignore`-style filtering (it already does via `git diff`'s built-in handling) and whether to surface a stderr note like "includes uncommitted working-tree changes" so the reviewer is aware. Option (b)'s warning-only path is the fallback if (a) is judged too aggressive.

### Medium Priority Risks
- **Risk 2**: Existing tests in `t/security-review-changeset.t` may pin the `..HEAD` shape and break under option (a).
  - **Mitigation**: In d-implementation-plan, list the existing tests that touch this codepath and update fixtures alongside the helper edit. Should be ≤3 spots based on a grep of the test file.
- **Risk 3**: Hand-update of `.cwf/security/script-hashes.json` after the helper edit (per the Task-135 surface-don't-smooth policy) — easy to forget and breaks `cwf-manage validate`.
  - **Mitigation**: Add a checklist item to f-implementation-exec and verify via `cwf-manage validate` before checkpoint, same pattern as Task 140.

## Dependencies
- None.

## Constraints
- Perl core modules only.
- The helper's documented contract ("single source of truth for what counts as security-relevant in CWF" per `.cwf/docs/skills/security-review.md`) must not narrow — the fix may *widen* what's reviewed but must not exclude paths that today's behaviour includes.
- Backward-compatible: callers that have committed all changes before invoking must see identical output (the only difference is when uncommitted state exists).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? — No, ~0.5 day.
- [ ] **People**: Does this need >2 people working on different parts? — No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? — No, single concern (helper's diff-spec semantics).
- [ ] **Risk**: Are there high-risk components that need isolation? — No, fix is in a small Perl helper with existing test coverage to backstop the committed-state behaviour.
- [ ] **Independence**: Can parts be worked on separately? — No, helper edit + test edit + hash regen must land together.

No signals triggered — single task is appropriate.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 141
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
