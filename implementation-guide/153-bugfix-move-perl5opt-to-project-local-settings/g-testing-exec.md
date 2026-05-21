# move PERL5OPT to project-local settings - Testing Execution
**Task**: 153 (bugfix)

## Task Reference
- **Task ID**: internal-153
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/153-move-perl5opt-to-project-local-settings
- **Template Version**: 2.1

## Goal
Execute the test cases from `e-testing-plan.md` and record PASS/FAIL.

## Test Execution Summary
11 planned test cases (TC-1…TC-11). All executed. All PASS. The merge_env
branch coverage (e-plan TC-1…TC-6) is realised as `t/cwf-claude-settings-merge.t`
subtests TC-U7…TC-U13. 0 FAIL. One pre-existing, unrelated suite failure
(`t/cwf-manage-fix-security.t`) confirmed at baseline — see below.

## Test Results

### Unit — `merge_env` (`t/cwf-claude-settings-merge.t`, 16 subtests PASS)
- **TC-1 absent→adds** (TC-U7) — **PASS**: `env.PERL5OPT=-CDSLA`, returns 1, no warn, summary "1 env keys".
- **TC-2 equal→no-op** (TC-U8) — **PASS**: unchanged, "0 env keys", no warn.
- **TC-3 mismatch→warn+untouched** (TC-U9) — **PASS**: value stays `-CDSL`, `[CWF] WARN:` names both values.
- **TC-4 non-hash env→warn+untouched** (TC-U10) — **PASS**: `env` left as string, warn emitted.
- **TC-5 non-scalar PERL5OPT→warn+untouched** (TC-U11) — **PASS**: value stays arrayref, warn emitted.
- **TC-6 sibling preserved** (TC-U12) — **PASS**: `PERL5OPT` added, `FOO` retained.
- Pre-existing TC-U1…TC-U6 (allowlist/hooks) still PASS — no regression.

### Integration — end-to-end helper
- **TC-7 fresh project gains PERL5OPT** (TC-U7) — **PASS**: written file has `env.PERL5OPT=-CDSLA`; report line shows the env count.
- **TC-8 idempotent re-run** (TC-U2 byte-identical + TC-U8 equal→no-op) — **PASS**.
- **TC-9 `--dry-run` warns on mismatch, writes nothing** (TC-U13) — **PASS**: warning fires under `--dry-run`; on-disk value unchanged; "0 env keys (dry-run)".

### Doc / static
- **TC-10 no surviving global refs** — **PASS**: `git grep -nE '~/\.claude/settings\.json' -- ':!implementation-guide/' ':!CHANGELOG.md'` → no matches.
- **TC-11 dogfood file env-only** — **PASS**: `git show HEAD:.claude/settings.json` is exactly `{"env":{"PERL5OPT":"-CDSLA"}}` — no `permissions`/`hooks`.

## Non-Functional Test Results
- **Security**: f-phase and g-phase changeset reviews both returned **no findings** (see Security Review below + f-implementation-exec.md).
- **Integrity**: `cwf-manage validate` → OK (after in-commit sha256 refresh of the two hashed files + the permission-only repair of the unrelated `cwf-plan-reviewer-misalignment.md`).
- **Reliability**: unparseable-settings die path unchanged (existing TC-U5d covers it); `merge_env` inherits `read_settings` symlink + parse guards (no new handling).

## `prove t/` Result
- Full suite green **except** `t/cwf-manage-fix-security.t` (TC-1, TC-2, TC-7).
- **Pre-existing, unrelated, baseline-confirmed**: that test's `build_fixture` copies only `.cwf/`, but `script-hashes.json` lists 5 `.claude/agents/*` paths (hash-tracked since ~Task 148/149), so the fixture lacks those files and `fix-security`/`validate` report missing-file. Reproduced identically at baseline `b5b8739` via a throwaway `git worktree`. Not introduced by Task 153; filed as a Medium BACKLOG bugfix.

## Failures / Reproduction
None attributable to this task. The `cwf-manage-fix-security.t` failure is pre-existing (above).

## Security Review

**State**: no findings

no findings
Testing-phase additions are test-only; harness is cwd-scoped File::Temp tempdir with CLEANUP, no network, no shell interpolation of untrusted input, and the dry-run assertion change matches the production summary string.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 153
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**
