# Drop perl -I prefix from script invocations - Testing Plan
**Task**: 121 (chore)

## Task Reference
- **Task ID**: internal-121
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/121-drop-perl-i-prefix-from-script-invocations
- **Template Version**: 2.1

## Goal
Validate the invocation-style cleanup: confirm zero `perl -I.cwf/lib` hits in active source after the change, confirm `cwf-manage validate` is clean (no hash drift), and confirm `cwf-manage-fix-security.t` still passes after switching from `perl -I.cwf/lib …` to `chmod u+x` + direct invocation.

## Test Strategy

### Test Levels
- **Static analysis** (grep): the load-bearing gate. Confirms the inventory is fully cleaned.
- **Existing automated tests** (`prove t/`): the existing 7-case `t/cwf-manage-fix-security.t` continues to be the regression net. Its scaffolding (`run_fix_security`, `run_validate`, `_ensure_cwf_manage_executable`) changes; its assertions don't.
- **Self-validation** (`cwf-manage validate`): confirms no tracked-file hash drift.
- **Manual smoke** (skill-level): one user-driven invocation of `/cwf-security-check` to confirm the SKILL change still produces working bash; deferred for `/cwf-init` per the same rationale as Task 120 (requires a scratch checkout).

### Test Coverage Targets
- **Static**: 100% — every active `perl -I.cwf/lib` hit removed (test surface = repo-wide grep).
- **Regression**: 253/253 existing tests continue to pass.
- **Self-validate**: `cwf-manage validate` exits 0.

## Test Cases

### TC-1: Static — repo-wide grep returns zero hits in active code
- **Given**: Implementation Steps 2–5 from d-implementation-plan.md applied.
- **When**: `grep -rn "perl -I.cwf/lib" .claude/ INSTALL.md README.md CLAUDE.md docs/ .cwf/docs/ .cwf/templates/ .cwf/scripts/ .cwf/lib/ t/`
- **Then**: Zero hits. (Hits inside `implementation-guide/`, `CHANGELOG.md`, `BACKLOG.md` remain — those are historical, deliberately excluded from the grep scope.)

### TC-2: `t/cwf-manage-fix-security.t` — all 7 subtests still pass
For each existing TC: the assertion *invariants* are unchanged (perms restored to recorded values, refusal on tamper/missing, idempotency). The values themselves are now derived from `script-hashes.json` via `_read_recorded_perms`, not hardcoded literals. The bootstrap helper (`_ensure_cwf_manage_executable`) sets `cwf-manage` to its recorded permission directly (read from JSON), so fix-security's chmod path is exercised by other targets — TC-4 and TC-5 retarget from `cwf-manage` to `command-helpers/cwf-version-tag` to keep that coverage.

- **TC-fixture-1 (clean install)**: `cwf-manage` is at recorded perms from `cp -rp`. Helper sees user-x set, skips chmod. Direct exec works. fix-security: no-op. → `repaired 0 file(s)`.
- **TC-fixture-2 (stripped perms)**: `strip_perms_recursive` sets every script to `0644`. Helper reads `cwf-manage`'s recorded perm from JSON and chmods. Direct exec works. fix-security chmods every other tracked script to its recorded value. → `cwf-manage` perms equal `_read_recorded_perms($tmp, 'cwf-manage')`.
- **TC-fixture-3 (sha mismatch on `cwf-set-status`)**: `cwf-manage` perms intact; helper skips. Direct exec works. fix-security refuses to chmod the tampered file; output names the file with `sha256` field plus recovery hint. → `cwf-set-status` stays at `0644` (no chmod), output mentions `git pull` and `cwf-manage update`.
- **TC-fixture-4 (missing `task-stack`)**: `cwf-manage` perms intact; helper skips. `command-helpers/cwf-version-tag` chmod-stripped (target swap from cwf-manage). Direct exec works. fix-security: best-effort chmod on `cwf-version-tag`; refuses to act on missing file; exits 1. → `cwf-version-tag` perms equal recorded value; output names missing path with `existence` field plus recovery hint.
- **TC-fixture-5 (mixed)**: `cwf-manage` perms intact; helper skips. `cwf-version-tag` chmod-stripped (file A); `task-stack` tampered (file B). Direct exec works. fix-security: repairs A, refuses B. → exit 1; A perms equal recorded value for `cwf-version-tag`; B content unchanged.
- **TC-fixture-6 (unparseable hashes)**: `cwf-manage` perms intact; helper skips. Direct exec works. fix-security: exits 1 immediately on JSON parse error. → output names hashes file plus recovery hint.
- **TC-fixture-7 (idempotency)**: First run repairs every tracked file to its recorded perm. Helper on second run: sees user-x set, skips. fix-security: no-op. → `repaired 0 file(s)`.

### TC-3: `cwf-manage validate` exits 0
- **Given**: All implementation steps applied.
- **When**: `.cwf/scripts/cwf-manage validate`
- **Then**: `[CWF] validate: OK`. No tracked file's hash has drifted (we touched no `.cwf/lib/**` or `.cwf/scripts/**`).

### TC-4: `prove t/` — full regression
- **Given**: All implementation steps applied.
- **When**: `prove t/`
- **Then**: `Files=27, Tests=253, Result: PASS`. No new failures.

### TC-5 (manual smoke): `/cwf-security-check` runs the new direct invocation
- **Given**: implementation applied, repo clean.
- **When**: User invokes `/cwf-security-check` in this checkout.
- **Then**: SKILL step 1 runs `.cwf/scripts/cwf-manage validate` (no `perl -I` prefix). Exit 0; report `OK`.
- **Status**: User-runnable; not part of the automated `prove` gate.

### TC-6 (manual smoke, deferred): `/cwf-init` with stripped perms
- Same rationale as Task 120's TC-8/TC-9: requires a scratch checkout and a separate Claude Code session. Reproduction steps recorded in `g-testing-exec.md`. Result expected: step 1a invokes `chmod u+x .cwf/scripts/cwf-manage && .cwf/scripts/cwf-manage fix-security`; init proceeds.

### Non-Functional
- **Reliability**: TC-2's full pass implies the bootstrap-via-chmod approach preserves every error path the test exercises (sha-mismatch refusal, missing-file refusal, unparseable JSON early-exit). No new failure modes introduced.
- **Maintainability**: After this task, the codebase has a single idiomatic invocation pattern (`.cwf/scripts/cwf-manage <subcmd>`), with one self-documenting bootstrap exception (the `chmod u+x` pre-step in `/cwf-init` step 1a and its mirror in the test helper). Any future contributor sees a consistent pattern.

## Test Environment

### Setup Requirements
- Repo at HEAD of `chore/121-drop-perl-i-prefix-from-script-invocations`
- Perl 5.10+, core modules (`Digest::SHA`, `JSON::PP`, `Test::More`, `File::Temp`)
- For TC-6: separate scratch checkout (deferred; user-runnable).

### Automation
- `prove t/cwf-manage-fix-security.t` — TC-2 exhaustive
- `prove t/` — TC-4 regression
- Direct shell: `grep -rn "perl -I.cwf/lib" …` (TC-1), `.cwf/scripts/cwf-manage validate` (TC-3)

## Validation Criteria
- [ ] TC-1 grep returns zero hits in active source
- [ ] TC-2 all 7 subtests in `t/cwf-manage-fix-security.t` pass
- [ ] TC-3 `cwf-manage validate` exits 0
- [ ] TC-4 `prove t/` shows 253/253 pass
- [ ] TC-5 manual smoke confirmed user-side (or noted as not yet run)
- [ ] TC-6 manual smoke documented with reproduction steps (deferred to user)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 121
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
