# exec-changeset reviewer agents - Rollout
**Task**: 210 (feature)

## Task Reference
- **Task ID**: internal-210
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/210-exec-changeset-reviewer-agents
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for exec-changeset reviewer agents.

## Deployment Strategy
### Release Type
- **Strategy**: Ship as part of the next CWF release tag; users receive it via
  `cwf-manage update`. No staged/canary rollout — the change is additive and
  advisory (three non-blocking reviewers + one skill-prose rewrite), so it lands
  for all users at once with the rest of the release.
- **Rationale**: CWF is a file-based workflow system, not a running service.
  "Deployment" is a git tag + the user-driven `cwf-manage update`. There is no
  traffic to shift and no per-user cohorts to gate.
- **Session-cache caveat**: agent definitions and skills load at session start.
  After `cwf-manage update`, the three new reviewers and the rewritten Step 8
  take effect in the user's **next** session, not the running one. This is the
  normal CWF update behaviour, not a rollout risk.

### Pre-Deployment Checklist
- [x] Plan-reviewed across a–e (map/reduce per phase)
- [x] All tests passing — `t/exec-changeset-reviewers.t` 11/11; full `prove t/` 882 green
- [x] Changeset security review (f and g) — no findings; guard untouched
- [x] Hashes registered (`0444`) and `cwf-manage validate` OK
- [x] BACKLOG updated (verdict-block hoist candidate)
- [ ] CHANGELOG entry + `cwf-project.json` version bump — at retrospective (j), per the per-task pattern
- [ ] Tagging / release — human-only (out of model scope)

## Rollout Plan
Single-phase: the three agents, the Step-8 rewrite, and the test ship together in
the next tagged release. No phased cohorts. First live exercise of the
five-reviewer MAP happens automatically on each user's next implementation-exec
run after updating (the agents are now also live in this dev session — see
Actual Results).

## Monitoring
No telemetry — verdicts are recorded in-band. After updating, a user's
`f-implementation-exec.md` should show **five** `## … Review` sections (Security,
Best-Practice, Improvements, Robustness, Misalignment) where there were two;
`g-testing-exec.md` stays at two. The watch item is the 2→5 degradation paths
(on-main / empty-changeset emitting all five), covered deterministically by
TC-6/TC-7.

## Rollback Plan
### Triggers
- A lens reviewer blocks the workflow (it must not — they are advisory; the guard
  is name-matched to `cwf-security-reviewer-changeset` only).
- `cwf-manage validate` reports an integrity violation for a new agent.
- implementation-exec emits fewer than five sections, or testing-exec emits more
  than two.

### Procedure
1. `cwf-manage rollback <previous-tag>` to revert to the prior release; or revert
   the two task commits. The change is additive — removing the three agents and
   restoring the two-reviewer Step 8 degrades cleanly (testing-exec and the
   security guard were never touched).
2. Re-run `cwf-manage validate` to confirm a clean tree.
3. File the regression and re-enter the workflow at the failing phase.

## Success Criteria
- [x] Change is additive, advisory, non-blocking — no service deploy required
- [x] Rollback is a clean `cwf-manage rollback` / commit revert
- [ ] Post-update: five reviewer sections recorded after implementation-exec,
      two after testing-exec (verified live next session / on user update)

## Actual Results
- **Live five-reviewer MAP verified (closes deferred TC-11).** This session has
  the three new agents loaded, so the full `implementation-exec` MAP was run live
  against the task changeset (1845 lines): all five reviewers launched in parallel
  and emitted well-formed `cwf-review` verdicts —
  - Security: no findings · Best-Practice: no findings · Robustness: no findings ·
    Misalignment: no findings
  - **Improvements: findings** — flags the byte-identical verdict-block + Bash-
    withheld duplication across the five agents. This is precisely the BACKLOG
    candidate already logged in f (hoist the shared body into
    `cwf-agent-shared-rules.md`); the reviewer noted "no action required to accept
    this changeset." Advisory and **non-blocking** — the SubagentStop guard
    (name-matched to `cwf-security-reviewer-changeset` only) did not fire,
    confirming FR5 end-to-end.
- This validates the 2→5 wiring live: five sections, each with a `**State**:`
  line, recorded independently; a lens `findings` surfaces without blocking.
- No deployment action taken (release tagging is human-only). The change is ready
  to ship with the next release tag.

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
