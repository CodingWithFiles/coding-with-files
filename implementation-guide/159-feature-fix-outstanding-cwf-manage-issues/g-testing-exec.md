# fix outstanding cwf-manage issues - Testing Execution
**Task**: 159 (feature)

## Task Reference
- **Task ID**: internal-159
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/159-fix-outstanding-cwf-manage-issues
- **Template Version**: 2.1

## Goal
Execute the e-testing-plan.md TC matrix (TC-1..TC-12) and record results. Scope FR1/FR2/FR4 (FR3 deferred; TC-5/TC-6 AC mapping note: AC5/AC6 belong to FR3 and are out of scope).

## Test Results

| TC | AC | Test location | Result | Notes |
|----|----|---------------|--------|-------|
| TC-1 | AC1 | `t/cwf-manage-update-end-to-end.t` "FR1: update latest" | **PASS** | `cwf_version=v0.0.3` (highest tag), `cwf_ref=latest` |
| TC-2 | AC1 | `t/cwf-manage-update-end-to-end.t` "FR1: update by SHA-on-a-tag" | **PASS** | `cwf_version=v0.0.2`, `cwf_ref=<SHA>`; asserts version is NOT the bare SHA (the bug) |
| TC-3 | AC2 | `t/cwf-manage-git-capture.t` "describe: SHA past a tag → long form" | **PASS** | covered at unit level — `git_describe_version` returns `vX.Y.Z-N-gHASH`; the version-write wiring is exercised by TC-1/TC-2 |
| TC-4 | AC2 | `t/cwf-manage-git-capture.t` "describe: no tags reachable → abbreviated SHA" | **PASS** | degrade to abbreviated SHA (never a bare ref); plus bad-committish → `$sha` fallback subtest |
| TC-5 | AC3 | `t/cwf-manage-fix-security.t` "FR2 dry-run: fixable perms previewed" | **PASS** | mode unchanged, `[dry-run]`/`would chmod` printed, exit 0, no `validate: OK` |
| TC-6 | AC3 | `t/cwf-manage-fix-security.t` "FR2 dry-run: sha256 mismatch surfaced" | **PASS** | exit 1, names sha256+file, content unmutated under dry-run |
| TC-7 | AC4 | `t/cwf-manage-fix-security.t` "FR2 rejects unknown arguments" | **PASS** | `bogus`→exit1; `--dry-run extra`→rejects `extra` (proves `--dry-run` stripped first) |
| TC-8 | (regr) | `t/cwf-manage-fix-security.t` existing TC-1/TC-2 + FR2 dry-run sanity step | **PASS** | live `fix-security` repair path unchanged |
| TC-9 | AC7 | `perlcritic --single-policy InputOutput::ProhibitBacktickOperators` | **PASS** | `source OK` — no backtick violations |
| TC-10 | AC8 | `t/cwf-manage-git-capture.t` git_capture subtests | **PASS** | success→(lines,0); bad ref→non-zero + git `fatal:` NOT leaked into stdout (stderr suppression) |
| TC-11 | AC8 | inspection + suite | **PASS** | `find_git_root` now delegates to the unit-tested `git_capture`; all 61 `cwf-manage` tests invoke it successfully. No dedicated non-repo-dir case (find_git_root is a thin wrapper over the covered helper). |
| TC-12 | AC10 | full suite + `t/cwf-manage-list-releases.t` | **PASS** | see below |

## Suite Runs
- **Full suite** `prove -lr t/`: **48 files, 527 tests, all PASS** (no regressions).
- `cwf-manage` group: 7 files, 61 tests, PASS.
- `t/cwf-manage-list-releases.t`: 11 tests PASS, unchanged — confirms the FR1 `cwf_version`→semver change does not regress `parse_semver`/`filter_releases`/the `(installed)` marker (AC10).
- `t/cwf-manage-git-capture.t` (new): 6 PASS.
- `cwf-manage validate`: OK (AC9 — hash refresh consistent).

## Coverage assessment
- In-scope acceptance criteria AC1, AC2, AC3, AC4, AC7, AC8, AC9, AC10 each demonstrated by ≥1 passing TC.
- AC5/AC6 belong to the deferred FR3 — out of scope, not tested (correct).
- Non-functional: security (TC-7 fail-closed, TC-5/6 no-mutation, FR4 shell-interp removal verified by the f-phase security review), reliability (TC-4 degrade, TC-10 stderr suppression).

## Failures
None.

## Security Review

**State**: no findings

(Sentinel emitted after a one-line confirmation rather than strictly first — same known reasoning-model behaviour as the f-phase review; body has zero numbered findings and an explicit `no findings` line, so recorded as `no findings`.)

Verbatim subagent verdict:
> no findings
> Production change is sound: `git_capture` removes the shell from `find_git_root`/`cmd_list_releases` (list-form exec, stderr to /dev/null, drained pipe, `_exit(127)` in child); `cwf_ref=$ref` is gated by `validate_ref_lexical` (charset excludes newline, so no version-file injection); `fix-security --dry-run` preserves all existence/sha256 gates and only skips the chmod (fails closed on unknown args). Test harnesses write only under `tempdir`/fixture scratch dirs and use no network. One pattern note (category e): `git_in` in `t/cwf-manage-git-capture.t` uses backtick string-interpolation `` `git -C "$dir" @args 2>&1` `` — safe here because every callsite passes test-controlled literal args and `$dir` is a trusted tempdir; audit any future reuse where `@args`/`$dir` could carry untrusted or whitespace-bearing values, noting this is the exact idiom the production code was just converted away from.

Disposition: the `git_in` backtick is accepted as-is — it matches the established test-harness convention in this repo (e.g. `_run_cwf_manage` in `t/cwf-manage-fix-security.t` uses the same backtick form) and all args are literal/test-controlled. Not a defect; surfaced here for the record.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
The security reviewer's pattern note on the `git_in` test helper's backtick is the inverse of FR4: backticks are a defect in production (shell-string `$source`) but acceptable in a test harness with literal, test-controlled args — the classification depends on the trust of the inputs, not the operator. See j-retrospective.md.
