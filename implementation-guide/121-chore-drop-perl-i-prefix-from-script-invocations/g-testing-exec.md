# Drop perl -I prefix from script invocations - Testing Execution
**Task**: 121 (chore)

## Task Reference
- **Task ID**: internal-121
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/121-drop-perl-i-prefix-from-script-invocations
- **Template Version**: 2.1

## Test Results — Automated

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | Repo-wide grep returns zero `perl -I.cwf/lib` hits in active source | `grep -rn` over `.claude/ INSTALL.md README.md CLAUDE.md docs/ .cwf/docs/ .cwf/templates/ .cwf/scripts/ .cwf/lib/ t/` produces no output | (empty output) | **PASS** |
| TC-2 | `t/cwf-manage-fix-security.t` — all 7 fixture subtests pass with new chmod-via-recorded-perms bootstrap and JSON-driven assertions | `1..7  ok  All tests successful.` | `1..7  ok  All tests successful.` | **PASS** |
| TC-3 | `cwf-manage validate` exits 0 (no hash drift) | `[CWF] validate: OK`, exit 0 | `[CWF] validate: OK` | **PASS** |
| TC-4 | Full regression: `prove t/` | `Files=27, Tests=253, Result: PASS` | `Files=27, Tests=253, Result: PASS` | **PASS** |

### TC-2 detail (per fixture subtest)

| Sub | Subject | Result |
|-----|---------|--------|
| TC-fixture-1 | clean install, no-op | PASS — helper skipped (user-x set), fix-security reported `repaired 0 file(s)` |
| TC-fixture-2 | stripped perms, repair to recorded | PASS — helper chmodded `cwf-manage` to recorded JSON value, fix-security restored every other tracked file; assertion verified `cwf-manage` perms equal `_read_recorded_perms($tmp, 'cwf-manage')` |
| TC-fixture-3 | sha mismatch on `cwf-set-status` | PASS — fix-security exit 1, output names file with `sha256` field, recovery hint contains both `git pull` and `cwf-manage update`; tampered file's perms unchanged |
| TC-fixture-4 | missing `task-stack` + chmod-stripped `cwf-version-tag` (retargeted from `cwf-manage`) | PASS — fix-security exit 1 on missing entry; `cwf-version-tag` repaired to recorded perms (best-effort); output names missing path with `existence` field plus recovery hint |
| TC-fixture-5 | mixed: `cwf-version-tag` chmod-stripped, `task-stack` tampered | PASS — exit 1; `cwf-version-tag` repaired to recorded perms; tampered `task-stack` content unchanged |
| TC-fixture-6 | unparseable hashes JSON | PASS — exit 1 immediately, output names hashes file, recovery hint present |
| TC-fixture-7 | idempotency, second run no-op | PASS — second run helper skipped (perms now correct), fix-security reported `repaired 0 file(s)` |

## Test Results — Manual Smoke (Deferred)

### TC-5: `/cwf-security-check` runs the new direct invocation
- **Status**: Deferred to user run before retrospective merge.
- **Reproduction**: invoke `/cwf-security-check` in this checkout. SKILL step 1 should run `.cwf/scripts/cwf-manage validate` (no `perl -I` prefix); expected `OK`.

### TC-6: `/cwf-init` end-to-end with stripped perms
- **Status**: Deferred — requires a separate Claude Code session in a scratch checkout (same rationale as Task 120's TC-8/9/10).
- **Reproduction**:
  ```bash
  # In a scratch checkout:
  git clone <CWF source> task-121-smoke && cd task-121-smoke
  git checkout chore/121-drop-perl-i-prefix-from-script-invocations
  find .cwf/scripts -type f -exec chmod 0644 {} \;

  # In Claude Code (this directory):
  /cwf-init
  ```
- **Expected**: SKILL step 1a runs `perl -MJSON::PP -e ...` to extract recorded perms, chmods `cwf-manage`, then runs `cwf-manage fix-security`. Init proceeds through steps 2–8.

## Non-Functional
- **Reliability**: TC-2's full pass implies no failure paths are broken — sha-mismatch refusal, missing-file refusal, and unparseable-JSON early-exit all still work.
- **Maintainability**: Repo now has a single idiomatic invocation pattern (`.cwf/scripts/cwf-manage <subcmd>`); the bootstrap exception in `/cwf-init` step 1a and the test helper both derive their chmod value from `script-hashes.json`, keeping the JSON as the single source of truth.

## Coverage
- **Static**: 100% — repo-wide grep clean (TC-1).
- **Existing tests**: 253/253 pass (TC-4).
- **Added tests**: zero (this task only changed scaffolding; TC count unchanged at 7 in `cwf-manage-fix-security.t`).

## Validation Criteria — Status
- [x] TC-1 grep returns zero hits in active source
- [x] TC-2 all 7 subtests in `t/cwf-manage-fix-security.t` pass
- [x] TC-3 `cwf-manage validate` exits 0
- [x] TC-4 `prove t/` shows 253/253 pass
- [ ] TC-5 manual smoke — deferred to user
- [ ] TC-6 manual smoke — deferred to user

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 121 (or user-run TC-5/TC-6 first)
**Blockers**: None — manual smoke is the user's call

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
