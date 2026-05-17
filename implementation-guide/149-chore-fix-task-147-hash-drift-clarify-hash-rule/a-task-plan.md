# Fix Task 147 hash drift, clarify hash rule - Plan
**Task**: 149 (chore)

## Task Reference
- **Task ID**: internal-149
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/149-fix-task-147-hash-drift-clarify-hash-rule
- **Baseline Commit**: 95c32d8f092dc7435347fd9750a08d3728df2c08
- **Template Version**: 2.1

## Goal
Refresh the two Task 147 hash entries (`CWF::Backlog.pm`, `backlog-manager`) and tighten the workflow-skill instructions so the in-task hash-update rule is no longer ambiguous about deferral.

## Success Criteria
- [ ] `.cwf/scripts/cwf-manage validate` no longer reports sha256 drift on `CWF::Backlog.pm` or `backlog-manager` (the misalignment-agent permission violation remains — see §Constraints).
- [ ] Implementation-exec and retrospective skill instructions explicitly state hash refreshes are in-task, in-diff, and never deferred across task boundaries — wording is testable by grep.
- [ ] A canonical convention doc captures the rule (one file, linked from the two skill instruction sets) so future skill rewrites can't drift the rule.
- [ ] Pre-refresh verification of `CWF::Backlog.pm` and `backlog-manager` confirms the only modifications since the previous hash entry are those introduced by Task 147 (commit `246e6c4`) — no unrelated drift smuggled in.
- [ ] Root cause documented: Task 147 added two CWF::Backlog public helpers and one private, plus 4 lines in cmd_retire, but did not refresh `.cwf/security/script-hashes.json` — making this the canonical historical example the convention doc cites.

## Original Estimate
**Effort**: ~1 hour (two hash recomputes + targeted doc tightening)
**Complexity**: Low
**Dependencies**: None. Task 148 just landed; `cwf-manage validate` reports the exact drift to fix.

## Major Milestones
1. **Verify the diff is Task 147's only** — `git log` and `git show 246e6c4` cross-checked against the working-tree state of the two files; no unrelated content drift.
2. **Refresh hashes in-diff** — `sha256sum` both files, edit `.cwf/security/script-hashes.json` in the same commit as no other change; `cwf-manage validate` returns clean for those two entries.
3. **Tighten skill instructions** — implementation-exec and retrospective skills each gain an explicit, testable line; the underlying rule lives in one convention doc the two skills link.

## Risk Assessment
### High Priority Risks
- **Risk: Refreshing a hash without first verifying the diff masks an unrelated modification**: if anything beyond Task 147 changed in `CWF::Backlog.pm` or `backlog-manager`, recomputing the hash silently absorbs it. Per the [[feedback_surface_security_dont_smooth]] rule, this is exactly the failure mode the integrity check exists to prevent.
  - **Mitigation**: Before refreshing, run `git log -p <pre-task-147-sha>..HEAD -- <file>` and confirm every hunk is attributable to commit `246e6c4`. Record the verification step explicitly in f-implementation-exec.

### Medium Priority Risks
- **Risk: Over-broad rule wording forbids legitimate batch refreshes** (e.g., a future task whose purpose is bulk re-permissioning of hashed files). Scoping the rule too tightly would force that task to violate the rule by construction.
  - **Mitigation**: Scope the rule to "modifications made *during* the task's own work" — explicitly excludes hash-bookkeeping tasks whose deliverable IS the hash table itself. The convention doc names the carve-out.
- **Risk: Convention doc location not chosen carefully** could create a second drift vector (skill instructions diverge from the convention doc over time).
  - **Mitigation**: Single source of truth — convention doc holds the rule; skill instructions link only and don't restate the rule body.

## Dependencies
- None. All inputs (validate output, Task 147 commit, hash file format) are in-repo.

## Constraints
- **Misalignment-agent permission violation (0600 vs 0444) is out of scope.** Git tracks only the executable bit; chmod 0444 doesn't survive `git checkout`, so this violation will reappear after every fresh clone or branch switch. Solving it requires changing the expected permission in `script-hashes.json` (or rethinking how the perm bit is enforced) — a structural concern separate from Task 147's hash drift. Flag in Future Work; do not touch in this task.
- The convention doc must be POSIX-friendly and link-resolvable without context inheritance (per the universal "agents won't read what they aren't pointed to" lesson).
- No new helper scripts. Mechanical fix + doc edit only.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? — No, ~1 hour estimated.
- [ ] **People**: Does this need >2 people working on different parts? — No, solo.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? — No, 2 (hash refresh + rule clarification), both small.
- [ ] **Risk**: Are there high-risk components that need isolation? — No, the one High risk is mitigated by a verification step, not by isolation.
- [ ] **Independence**: Can parts be worked on separately? — They could be, but the combined effort is short and the rule clarification is *evidence* that the hash refresh is principled rather than expedient. Splitting would weaken the lesson.

Zero signals triggered. No decomposition.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 149
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
