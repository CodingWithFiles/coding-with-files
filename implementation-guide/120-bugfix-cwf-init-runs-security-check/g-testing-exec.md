# cwf-init runs security check - Testing Execution
**Task**: 120 (bugfix)

## Task Reference
- **Task ID**: internal-120
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/120-cwf-init-runs-security-check
- **Template Version**: 2.1

## Goal
Execute tests from e-testing-plan.md against the implementation in f-implementation-exec.md.

## Test Results

### Automated — `t/cwf-manage-fix-security.t`

```
ok 1 - TC-1: clean install — no-op, exit 0
ok 2 - TC-2: stripped perms, sha intact — repair to recorded perms
ok 3 - TC-3: sha mismatch — refuse, no chmod, recovery hint
ok 4 - TC-4: missing tracked file — refuse, recovery hint, best-effort fix on others
ok 5 - TC-5: mixed — repair fixable, refuse unfixable
ok 6 - TC-6: unparseable hashes file — exit 1, recovery hint
ok 7 - TC-7: idempotency — second run is a no-op
All tests successful.
```

| Case | Outcome | Notes |
|------|---------|-------|
| TC-1 | PASS | Clean install: exit 0, "repaired 0 file(s); validate: OK" |
| TC-2 | PASS | Stripped perms restored to *exact* recorded values (verified `cwf-manage` perms restored to `0700`, not blanket `0755`) |
| TC-3 | PASS | sha256 mismatch on `cwf-set-status`: exit 1, no chmod attempted, recovery hint contains both `git pull` and `cwf-manage update` |
| TC-4 | PASS | Missing `task-stack`: exit 1, output names `existence`/missing path, recovery hint present, *other* file (`cwf-manage`) repaired (best-effort fix) |
| TC-5 | PASS | Mixed: file A repaired to `0700`, file B (tampered) skipped, exit 1 |
| TC-6 | PASS | `not-json` in hashes file → exit 1 immediately, recovery hint present |
| TC-7 | PASS | Second run is a no-op, exit 0, "repaired 0 file(s)" |

### Regression — `prove t/`
```
Files=27, Tests=253,  6 wallclock secs
Result: PASS
```
- Baseline before task: 26 files, 246 tests (recorded in f-implementation-exec.md Step 1)
- Post-task: 27 files (+1: `cwf-manage-fix-security.t`), 253 tests (+7 new)
- Zero regressions in pre-existing tests.

### Self-validation — dev repo
```
$ .cwf/scripts/cwf-manage validate
[CWF] validate: OK

$ .cwf/scripts/cwf-manage fix-security
[CWF] fix-security: repaired 0 file(s); validate: OK
```

### Non-functional checks
- **Determinism**: TC-2 verifies fix-security restores the *exact* recorded perms (e.g. `0700` for `cwf-manage`), not a blanket `0755`. Confirmed by `stat`-ing the repaired file.
- **Reliability**: TC-3 confirms tampered files are not chmod-ed (perms remain `0644` after fix-security exits 1) and content is unchanged.
- **Usability**: Output for unfixable entries includes `field`/`actual`/`expected` lines plus a `Recovery:` line — same shape as `cwf-manage validate` for familiarity, with the user-facing recovery hint added.
- **Security**: fix-security never chmods a file whose sha256 doesn't match its recorded value; TC-3 verifies this directly.

## Manual Smoke (TC-8/9/10) — Deferred

Skill-level end-to-end exec requires invoking `/cwf-init` from a separate Claude Code session in a scratch checkout. The LLM cannot self-loop the SKILL under `prove`. Reproduction steps for the user to run before retrospective:

### TC-8: End-to-end repair flow
```bash
# In a scratch directory (not the dev repo):
git clone <CWF source> task-120-smoke && cd task-120-smoke
git checkout bugfix/120-cwf-init-runs-security-check

# Simulate the file-copy install scenario
find .cwf/scripts -type f -exec chmod 0644 {} \;

# In Claude Code (this directory):
/cwf-init
```
**Expected**: Step `1a` invokes `cwf-manage fix-security`. Output shows multiple `chmod ... (was 0644)` lines and `repaired N file(s); validate: OK`. Init proceeds through steps 2–8. Final perms on `.cwf/scripts/` files match recorded values in `script-hashes.json`.

### TC-9: End-to-end abort on tampering
```bash
# Same scratch checkout:
git checkout .                                    # restore perms
echo "tamper" >> .cwf/scripts/command-helpers/cwf-set-status

# In Claude Code:
/cwf-init
```
**Expected**: Step `1a` exits 1. LLM relays the subcommand's stdout/stderr verbatim — including `Field: sha256`, recovery hint mentioning `git pull` / `cwf-manage update`, and the appended abort line `[CWF] /cwf-init aborted: run 'cwf-manage update' or reinstall, then re-run /cwf-init.` No CLAUDE.md edit, no `.claude/settings.json` edit, no init commit.

### TC-10: Idempotency via second `/cwf-init`
```bash
# After TC-8 succeeded:
/cwf-init   # invoke a second time
```
**Expected**: Step `1a` is a no-op (`repaired 0 file(s); validate: OK`). Subsequent steps are idempotent per existing skill behaviour. No duplicate `.claude/settings.json` entries, no second init commit.

**Tracking**: results to be recorded back into this file before retrospective.

## Validation Criteria — Status
- [x] All TC-1 through TC-7 pass under `prove t/cwf-manage-fix-security.t`
- [x] `prove t/` shows no new failures vs the baseline
- [x] `cwf-manage validate` and `cwf-manage fix-security` both exit 0 on the development repo
- [ ] TC-8 manual smoke — **DEFERRED to user run before retrospective**
- [ ] TC-9 manual smoke — **DEFERRED to user run before retrospective**
- [ ] TC-10 manual smoke — **DEFERRED to user run before retrospective**

## Status
**Status**: Finished
**Next Action**: /cwf-rollout 120 (or run manual smoke TC-8/9/10 first)
**Blockers**: None — manual smoke is the user's call

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
