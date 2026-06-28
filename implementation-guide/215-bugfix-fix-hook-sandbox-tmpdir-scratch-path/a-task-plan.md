# fix hook sandbox tmpdir scratch path - Plan
**Task**: 215 (bugfix)

## Task Reference
- **Task ID**: internal-215
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/215-fix-hook-sandbox-tmpdir-scratch-path
- **Baseline Commit**: ba88c179a78a131d84a8aa25c653fc95359675e3
- **Template Version**: 2.1

## Goal
Make CWF's per-task scratch directory resolve to the correct writable location when Claude Code's bash sandbox is active, by fixing the context-inject hook that currently emits a stale `$TMPDIR`-free `/tmp/cwf-…` path.

## Problem
Claude Code **hooks run outside the bash sandbox** (host env, `$TMPDIR` unset) while the **Bash tool runs inside it** (`$TMPDIR=/tmp/claude-1000`, `/tmp` read-only). The `userpromptsubmit-context-inject` hook resolves scratch via `${TMPDIR:-/tmp}` in the host env → emits `/tmp/cwf-…` and instructs "do not re-resolve". Inside the sandbox `/tmp` is read-only, so the agent's `mkdir` of that path fails (`Read-only file system`). CWF runtime helpers (`scratch_dir`/`scratch_parent`) are already correct — they re-resolve `$TMPDIR` in-sandbox. The defect is the hook freezing a host-env literal. Reproduced live during Task 215 creation.

## Success Criteria
- [ ] With the sandbox **enabled**, the scratch base the agent receives resolves to the in-sandbox writable temp and `mkdir` of the task scratch succeeds (no read-only failure).
- [ ] With the sandbox **disabled**, behaviour is unchanged (`/tmp/cwf-…`).
- [ ] A regression test asserts the hook's emitted base honours `$TMPDIR` (and the symbolic fallback) — fails before the fix, passes after; test self-verifies sandbox preconditions and skips/fails loudly when not actually sandboxed.
- [ ] No machine-specific path is committed; any new gitignored runtime file is added via the existing `install-manifest.json` `gitignore-entries` artefact (not a new `.cwf/.gitignore`) and kept out of `script-hashes.json` (`cwf-manage validate` clean). (N/A if the chosen approach adds no new file.)
- [ ] Full test suite passes; `cwf-manage validate` reports no violations.

## Original Estimate
**Effort**: ~1 day
**Complexity**: Medium
**Dependencies**: None external (relies on the documented Claude Code sandbox `$TMPDIR` contract)

## Major Milestones
1. **Design** (c): resolution mechanism — `.cwf/config.local.json` last-seen-`$TMPDIR` cache (writer) + hook reader with symbolic `${TMPDIR:-/tmp}` fallback for cold-start.
2. **Implement** (f): writer in `CWF::Common` (persist via `atomic_write_json`, read-merge-write), hook reader + symbolic fallback, hashed-hook + same-commit hash refresh.
3. **Install/integrity**: shipped `.cwf/.gitignore`; confirm allowlist-based `validate` ignores the unrecorded cache file.
4. **Test** (e/g): sandbox on/off + cold-start, self-verifying preconditions, `validate` clean.

## Risk Assessment
### High Priority Risks
- **Cold-start / toggle-lag**: the first turn after enabling the sandbox (and first-ever use, no cache yet) still emits a stale cached path.
  - **Mitigation**: hook falls back to unexpanded `${TMPDIR:-/tmp}/cwf<dash>` which the in-sandbox shell resolves at use time; document the residual one-turn lag for non-shell tool uses.
- **Integrity / accidental commit of `.cwf/` cache**: a mutable file under `.cwf/` could trip `validate` or be committed.
  - **Mitigation**: never record it in `script-hashes.json` (validate is allowlist-based, so it is invisible); ship `.cwf/.gitignore`.

### Medium Priority Risks
- **Concurrent writers** (parallel reviewers) racing the cache file.
  - **Mitigation**: reuse `CWF::ArtefactHelpers::atomic_write_json` (tmpfile+rename); read-merge-write so a human-set override key is not clobbered.
- **Sandbox cannot be forced per-call**: tests may silently run unsandboxed and pass without exercising the fix.
  - **Mitigation**: self-verifying test preconditions (assert `$TMPDIR` set + `/tmp` read-only) that skip/fail loudly when not sandboxed.

### Low Priority Risks
- **Sandbox-state tests need a session restart** (settings load at session start).
  - **Mitigation**: document; gate the sandbox-specific test on detected sandbox state.

## Dependencies
- Documented Claude Code sandbox contract: `$TMPDIR` is the temp-discovery mechanism (code.claude.com/docs/en/sandboxing.md).
- Out of scope: broken-sandbox cases where `/tmp` is read-only **and** `$TMPDIR` is unset (Claude Code #36759/#43096) — addressed only by an optional user-set fallback base, not core to this fix.

## Constraints
- Core Perl only (`JSON::PP` is core — compliant); reuse existing config/JSON/atomic-write plumbing rather than adding new code.
- The hook (`userpromptsubmit-context-inject`) is a hashed script → hash refresh in the **same commit** as the edit (hash-updates convention).
- Never commit machine-/uid-/OS-specific paths; the cache file is local-only.

## Decomposition Check
- [ ] **Time**: <1 week — no
- [ ] **People**: one person — no
- [ ] **Complexity**: single concern (scratch resolution under sandbox) — no
- [ ] **Risk**: risks are mitigable in-task — no
- [ ] **Independence**: parts are interdependent (writer/reader/test) — no

0 signals triggered → no decomposition; proceed as a single bugfix.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Fixed as scoped, but via **Approach A** (self-validating uid probe in
`scratch_parent`) rather than the Approach B cache this plan anticipated. The pivot
(decided in c-design-plan) removed the `.cwf/config.local.json` cache, the hook edit,
and the `.cwf/.gitignore` artefact — eliminating three of this plan's risks
(cold-start/toggle-lag, accidental cache commit, concurrent writers) outright.
Success criterion 4 (no machine path / gitignore artefact) became **N/A** — Approach
A adds no file. All other criteria met: live end-to-end verification, full suite (937)
green, `cwf-manage validate` clean. ~0.5 day vs ~1 day estimated.

## Lessons Learned
Where a bugfix's mechanism is genuinely open, keeping the a-plan's risk section
mechanism-neutral (and deferring mechanism-specific risk to design) avoids the plan
ageing the moment design picks a different approach. See j-retrospective.md.
