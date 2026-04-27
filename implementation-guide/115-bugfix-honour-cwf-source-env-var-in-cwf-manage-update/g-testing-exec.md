# Honour CWF_SOURCE env var in cwf-manage update - Testing Execution
**Task**: 115 (bugfix)

## Task Reference
- **Task ID**: internal-115
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/115-honour-cwf-source-env-var-in-cwf-manage-update
- **Template Version**: 2.1

## Goal
Execute every test case defined in e-testing-plan.md and record results.

## Test Environment
- Working tree: `bugfix/115-honour-cwf-source-env-var-in-cwf-manage-update` at HEAD `876b144` (f-impl-exec checkpoint)
- Perl: system Perl with `PERL5OPT=-CDSL` (live user env — same conditions that surfaced the boy-scout em-dash bug)
- Locale: `LANG=C.UTF-8`
- Test fixtures: tempdir-based test repos created via `mktemp -d` + `git init`, populated with synthetic `.cwf/version`, torn down after each smoke

## Test Results

### Functional Tests — `resolve_source` unit subtests

Run: `prove t/cwf-manage-resolve-source.t` (and full `prove t/`)

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | env set + file present → env wins | `('file:///env/path', 'CWF_SOURCE env var')` | matches | **PASS** |
| TC-2 | env unset + file present → file wins | `('file:///file/path', '.cwf/version')` | matches | **PASS** |
| TC-3 | env empty + file present → file wins | `('file:///file/path', '.cwf/version')` | matches | **PASS** |
| TC-4 | env set + file missing key → env still wins | `('file:///env/path', 'CWF_SOURCE env var')` | matches | **PASS** |
| TC-5 | env unset + file missing key → dies | error matches `qr{No CWF source: CWF_SOURCE unset and cwf_source missing/empty}` | matches | **PASS** |
| TC-6 | env empty + file empty → dies | same error pattern as TC-5 | matches | **PASS** |

### Functional Tests — call-site routing & end-to-end smokes

| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-7 | `cmd_list_releases` line-124 substitution does not break existing tests | `prove t/cwf-manage-list-releases.t` — 9 subtests pass | 9/9 PASS | **PASS** |
| TC-8 | env-override log line on `cmd_update` (env=`file:///tmp/cwf-nonexistent`, fixture `.cwf/version`) | log includes `Cloning CWF source from file:///tmp/cwf-nonexistent (from: CWF_SOURCE env var)...` then expected git-clone failure | exact match: `[CWF] Cloning CWF source from file:///tmp/cwf-nonexistent (from: CWF_SOURCE env var)...` | **PASS** |
| TC-9 | default-source log line on `cmd_list_releases` (`unset CWF_SOURCE`, fixture `.cwf/version` with github URL) | log includes `Available releases from <url> (from: .cwf/version)` | exact match: `[CWF] Available releases from https://github.com/CodingWithFiles/coding-with-files.git (from: .cwf/version)` | **PASS** |
| TC-10 | env-driven update does **not** persist `cwf_source` to `.cwf/version` (load-bearing, Decision 2) | `cwf_source` field unchanged after `CWF_SOURCE=<override> cwf-manage update <tag>` | see detail below | **PASS** |

#### TC-10 detail (load-bearing — Decision 2 / no persistence)

**Setup**: tempdir test repo, `.cwf/version` populated with sentinel:
```
cwf_method=copy
cwf_source=https://example.com/SENTINEL
cwf_version=v0.0.1
cwf_ref=v0.0.1
```

**Action**: `CWF_SOURCE=file:///home/matt/repo/coding-with-files cwf-manage update v1.0.114`

**Result** — log lines:
```
[CWF] Updating CWF (method: copy, ref: v1.0.114)
[CWF] Cloning CWF source from file:///home/matt/repo/coding-with-files (from: CWF_SOURCE env var)...
[CWF] Copied .cwf/
[CWF] Copied .cwf-skills/
[CWF] Fixed script permissions
[CWF] Created 18 skill symlinks in .claude/skills/
[CWF] Updated to v1.0.114 (0c119639550600ccfc124497df595b0992aeaf12)
```

**Result** — post-update `.cwf/version`:
```
cwf_installed=2026-04-27T08:24:27Z
cwf_method=copy
cwf_ref=v1.0.114
cwf_sha=0c119639550600ccfc124497df595b0992aeaf12
cwf_source=https://example.com/SENTINEL    ← unchanged ✓
cwf_version=v1.0.114
```

**Assertion**: `cwf_source` is still `https://example.com/SENTINEL` despite the env override successfully driving the update from a different URL. `cwf_version`, `cwf_ref`, `cwf_sha`, `cwf_installed` correctly updated; `cwf_source` correctly preserved. Decision 2 holds.

### Non-Functional Tests

| Aspect | Test | Result | Status |
|--------|------|--------|--------|
| **Usability** — help text | `cwf-manage help` includes `Environment:` block listing `CWF_SOURCE` with the same wording as `install.bash:10–15` | block present, formatted consistently with surrounding sections | **PASS** |
| **Reliability** — error clarity | TC-5 / TC-6 confirm the helper dies with a single, specific message when both source candidates are absent | covered above | **PASS** |
| **Backwards compatibility** — existing-user steady state | TC-2 (env unset + file present, unit) and TC-9 (env unset + file present, end-to-end) confirm default behaviour is preserved with only the addition of `(from: .cwf/version)` log suffix | covered above | **PASS** |
| **No-persistence regression** — Decision 2 invariant | TC-10 — load-bearing | covered above | **PASS** |
| **Boy-scout fix verification** — em-dash legacy errors | Trigger `read_version_file` failure path inside a fixture without `.cwf/version`. Expect: `[CWF] ERROR: No .cwf/version file found — is CWF installed?` rendered with a real em-dash | rendered correctly: `— is CWF installed?` (verified `e2 80 94` bytes via `xxd`). Pre-fix output was `c3a2 c280 c294` (double-encoded mojibake) | **PASS** |

Performance and security testing are not relevant to this change — the helper is a pair of `defined && ne ''` checks; there is no network surface change beyond honouring an additional env var that `install.bash` already accepted.

## Test Failures
None.

## Coverage Report
- **`resolve_source`** (the only new code path): 100% — every branch of the helper is exercised by TC-1..TC-6.
- **Modified call sites** (`cmd_update`, `cmd_list_releases`): regression-covered by existing `t/cwf-manage-list-releases.t` (TC-7) and end-to-end smokes (TC-8, TC-9, TC-10).
- **Full suite**: `prove t/` — 24 files, 235 tests, all PASS, no regressions.

## Validation Criteria — closed-loop check from e-testing-plan
- [x] `prove t/cwf-manage-resolve-source.t` — all six subtests pass
- [x] `prove t/` — full suite passes with no regressions (235/235)
- [x] `cwf-manage validate` — passes on the modified script (after sha256 update for both env-var feature and boy-scout `-CDSL`+`use utf8;` change)
- [x] TC-8: env-override log line observed in `cmd_update` smoke
- [x] TC-9: file-default log line observed in `cmd_list_releases` smoke
- [x] TC-10: `cwf_source` field unchanged in `.cwf/version` after env-driven update
- [x] `cwf-manage help` output includes the `Environment: CWF_SOURCE` block

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 115
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
