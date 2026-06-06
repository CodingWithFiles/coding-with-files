# Harden security-review-changeset agent contract - Rollout
**Task**: 182 (feature)

## Task Reference
- **Task ID**: internal-182
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/182-harden-security-review-changeset-agent-contract
- **Template Version**: 2.1

## Goal
Define deployment strategy and rollout plan for Harden security-review-changeset agent contract.

## Deployment Strategy
### Release Type
- **Strategy**: In-place file change shipped through CWF's normal distribution path. There is no server/runtime to deploy; the artefacts are the hashed helper script, the two exec SKILLs, the agent definition, and the canonical doc. They reach the CWF repo's main branch via the maintainer's squash + `git branch -f` (the archaeological-main process), and reach CWF *consumers* via `.cwf/scripts/cwf-manage update`.
- **Rationale**: CWF is a self-hosted documentation/tooling system, not a multi-tenant service — phased/canary user rollout does not apply. The single meaningful staging boundary is the **session cache**: edited SKILLs and agent definitions are read once per Claude Code session, so the new contract takes effect for a given operator only after their next session start (or `cwf-manage update` + restart for consumers).
- **Rollback Plan**: `git revert` the squashed commit on the task branch (or, post-merge, a follow-up revert task), then `cwf-manage update`. Because the hash refresh is in the same commit, a revert restores both the file *and* its recorded hash atomically — `cwf-manage validate` stays consistent before and after.

### Pre-Deployment Checklist
- [x] Code review completed (4-agent plan review in b/c/d; exec-phase security review in f and g — both `no findings`)
- [x] All tests passing (`prove t/security-review-changeset.t` — 35 subtests, 0 failures)
- [x] Security scan completed with no critical issues (`cwf-security-reviewer-changeset` on both exec changesets → `no findings`)
- [x] Performance validated (TC-NF5: O(diff) not O(repo); one extra `mkdir` + one file write vs the prior stdout emit — NFR1 neutral)
- [x] Documentation updated (`security-review.md` canonical doc, both SKILLs, agent definition, script header/usage)
- [x] Integrity verified (`cwf-manage validate: OK` — script + agent hashes refreshed in-commit)
- [x] Rollback path identified (in-commit hash refresh makes `git revert` clean)

## Rollout Plan
This change ships as one unit; there is no percentage-based ramp. The "phases" are the distribution boundaries:

### Phase 1: This task branch
- **Scope**: `feature/182-harden-security-review-changeset-agent-contract`. The new contract is already exercised end-to-end here — both f and g ran the migrated helper (`--wf-step=…`, `.out` file, confirmation line) and the migrated agent (Read `{changeset_file}`).
- **Validation**: full test suite green; both exec security reviews `no findings`; `cwf-manage validate: OK`.

### Phase 2: CWF main (maintainer-gated)
- **Scope**: merge to main via squash + `git branch -f` (human-only action — not performed by the model).
- **Effect**: the new contract becomes the CWF default. Operators pick it up on their next session; the session-cache note above is the only lag.

### Phase 3: CWF consumers
- **Scope**: downstream repos run `.cwf/scripts/cwf-manage update` to receive the new script/SKILLs/agent/doc, then restart Claude Code so the session cache reloads.
- **Compatibility note**: the `settings.local.json` allowlist entry `security-review-changeset *` is a wildcard, so the flag rename needs no allowlist change. No consumer config migration is required (no caller passed anything but `--phase`/`--max-lines=500`, both now handled by the default/removal).

## Monitoring
### Key Signals (not metrics dashboards — this is a CLI tool)
- **Integrity**: `cwf-manage validate` must stay `OK` after distribution (catches any hash/permission drift).
- **Contract adherence**: the originating complaint — agents bolting `> /tmp/…; wc -l; grep` boilerplate onto the invocation — should disappear. The stricter SKILL wording ("run exactly as below, no boilerplate") plus the self-managed file + confirmation line remove the reason to.
- **Exec-phase behaviour**: Step 8 of both exec SKILLs should branch cleanly on exit-code + reported count (no empty-stdout heuristic).

### Alerting
- No automated alerting surface. The standing guard is `cwf-manage validate` (run at every checkpoint commit) and the `SubagentStop` security-verdict guard hook, both unchanged by this task.

## Rollback Plan
### Triggers
- `cwf-manage validate` reports a violation for `security-review-changeset` or `cwf-security-reviewer-changeset` after distribution.
- An exec-phase Step 8 cannot parse the confirmation line (would surface as `error`, never a silent skip).
- A consumer reports the helper failing to write its `.out` (e.g. an unwritable `/tmp`).

### Procedure
1. **Assess**: confirm the failure is from this change, not pre-existing drift (`git log` the affected file).
2. **Revert**: `git revert` the task's squashed commit (file + hash together), or land a follow-up revert task if already on main.
3. **Redistribute**: consumers run `cwf-manage update` + restart; verify `cwf-manage validate: OK`.
4. **Analysis**: capture the cause in a retrospective / backlog item before re-attempting.

## Success Criteria
- [x] Change exercised end-to-end on the task branch (f + g ran the new contract)
- [x] `cwf-manage validate: OK` with the in-commit hash refresh
- [x] No consumer config/allowlist migration required (wildcard allowlist; default-equivalent behaviour for today's callers)
- [ ] Merged to main by the maintainer (human-only; out of model scope)
- [ ] Consumers updated via `cwf-manage update` (downstream, post-merge)

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Change validated on the task branch and ready for the maintainer's merge to main. No runtime deployment; distribution is `cwf-manage update` + session restart. Merge and any downstream `cwf-manage update` are out of model scope.

## Lessons Learned
- The same-commit hash refresh (hash-updates convention) is what makes rollback clean: reverting one commit restores the file and its recorded hash together, so `cwf-manage validate` never sees a torn state. Deferring the hash refresh would have made rollback a two-step, drift-prone operation.
