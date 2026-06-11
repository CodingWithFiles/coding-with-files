# Fresh-session reviewer grant acceptance (TC-8/9/10) - Plan
**Task**: 192 (chore)

## Task Reference
- **Task ID**: internal-192
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/192-fresh-session-reviewer-grant-acceptance-tc-8910
- **Baseline Commit**: d676e232e3a88c83997bc625316a825476140e5f
- **Template Version**: 2.1

## Goal
Run Task 186's three deferred fresh-session acceptance checks (TC-8/9/10) to confirm the
`allowed-tools:`→`tools: Read, Grep, Glob, LSP, Bash` reviewer-agent grant change is live in
the agent registry and that the reviewers still function, then retire the backlog item.

## Success Criteria
- [ ] **TC-8**: each of the five reviewer agents shows *exactly* `Read, Grep, Glob, LSP, Bash`
      in the live registry, excludes `Edit`/`Write`, and `LSP` was accepted as a grant token
      (no load error).
- [ ] **TC-9**: a plan reviewer (e.g. `cwf-plan-reviewer-misalignment`) runs against an
      existing plan file and can reach the markdown-reader skill (or run its script via Bash).
- [ ] **TC-10**: `cwf-security-reviewer-changeset` emits exactly one well-formed `cwf-review`
      block that `security-review-classify` parses.
- [ ] Outcomes recorded in g-testing-exec.md; if all pass, the backlog item is retired to
      CHANGELOG against Task 192. Any discrepancy is surfaced as a finding (does not get smoothed).

## Original Estimate
**Effort**: <0.5 day
**Complexity**: Low
**Dependencies**: Task 186 grant change merged to main (done — present on baseline `d676e23`);
a session whose agent-definition cache reflects the post-change defs.

## Major Milestones
1. **Confirm session freshness**: establish whether this session's registry reflects the
   post-change defs (it appears to — all five reviewers already show the granted set), or
   whether a genuinely new session is required to make TC-8 a valid read.
2. **Run TC-8/9/10**: inspect the registry (TC-8), invoke a plan reviewer (TC-9), invoke the
   changeset reviewer and classify its verdict (TC-10).
3. **Record and retire**: write outcomes to g-testing-exec.md; retire the backlog item if clean.

## Risk Assessment
### High Priority Risks
- **Stale agent-def cache invalidates TC-8**: if this session still holds pre-change cached
  defs, the registry read is not a valid acceptance signal (`feedback_agent_def_session_cache`).
  - **Mitigation**: cross-check the live registry against the on-disk frontmatter; if they
    diverge, defer the run to a genuinely fresh session rather than record a false pass.

### Medium Priority Risks
- **TC-9 markdown-reader unreachable at runtime**: the reviewer cannot invoke the skill.
  - **Mitigation**: Task 186's documented fallback — a `skills:` frontmatter field — still
    leaves the core grant fix valid; record the fallback path, do not fail the grant check on it.
- **A discrepancy surfaces (grant not as recorded / verdict malformed)**: turns a
  verification-only task into a real fix.
  - **Mitigation**: surface as an explicit finding and scope a corrective follow-up; do not
    paper over it. No code change is in scope unless a discrepancy forces one.

## Dependencies
- Task 186 changeset (reviewer grant) — present on the baseline commit.
- `security-review-classify` helper for TC-10 verdict parsing.

## Constraints
- **Verification-only**: no production code change is in scope unless TC-8/9/10 surface a defect.
- Must run on this task branch (carries the merged grant via the baseline).

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? No — under half a day.
- [ ] **People**: Does this need >2 people working on different parts? No.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — one concern (grant acceptance),
      three checks against the same change.
- [ ] **Risk**: Are there high-risk components that need isolation? No.
- [ ] **Independence**: Can parts be worked on separately? No — TC-8/9/10 are one verification set.

**Conclusion**: 0 signals triggered. Single atomic verification task; no decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All four success criteria met in-session (freshness option 1): TC-8/9/10 + TC-REG PASS;
backlog item retired against Task 192. See g-testing-exec.md for the matrix.

## Lessons Learned
The freshness gate's discriminating signal (restricted grant vs pre-change all-tools
inheritance) made an in-session run sound. See j-retrospective.md for full learnings.
