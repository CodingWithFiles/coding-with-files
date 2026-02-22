# Update version conventions - Testing Execution
**Task**: 89 (feature)

## Task Reference
- **Task ID**: internal-89
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/89-update-version-conventions
- **Template Version**: 2.1

## Goal
Execute all test cases from e-testing-plan.md and record results.

## Test Run Summary

| Metric | Value |
|--------|-------|
| Total TCs | 15 |
| Passed | 15 |
| Failed | 0 |
| Blocked | 0 |
| `prove t/cwf-manage-list-releases.t` | 11/11 subtests PASS |
| `prove t/` (regression) | 18 files, 173 tests PASS |
| `cwf-manage validate` | OK |

---

## TC Results

### TC-1: `parse_semver` — valid v-prefixed semver
**Result**: PASS — `parse_semver('v1.2.3')` → `(1, 2, 3)`

### TC-2: `parse_semver` — no v prefix
**Result**: PASS — `parse_semver('1.2.3')` → `()`
*(Bug found and fixed during impl: original plan's `s/^v//` accepted this; regex approach enforces strict form)*

### TC-3: `parse_semver` — 2-part tag
**Result**: PASS — `parse_semver('v1.2')` → `()`

### TC-4: `parse_semver` — non-numeric
**Result**: PASS — `parse_semver('vabc')` → `()`

### TC-5: `parse_semver` — empty string
**Result**: PASS — `parse_semver('')` → `()`

### TC-6: `filter_releases` — already on latest
**Result**: PASS — `filter_releases('v0.1.90', 'v0.1.90')` → `()`

### TC-7: `filter_releases` — new patch on same minor
**Result**: PASS — returns `('v0.1.90')` only; `v0.1.89` hidden

### TC-8: `filter_releases` — multiple higher minors
**Result**: PASS — returns `('v0.3.95', 'v0.2.90')`, descending

### TC-9: `filter_releases` — higher major plus same-minor patch
**Result**: PASS — returns `('v1.0.103', 'v0.1.90')`

### TC-10: `filter_releases` — multiple higher majors
**Result**: PASS — returns `('v2.0.5', 'v1.0.103')`

### TC-11: `filter_releases` — non-semver tags silently excluded
**Result**: PASS — `latest` and `nightly` absent from output; no error

### TC-12: `cmd_list_releases --all` — unchanged behaviour
**Result**: PASS — all tags printed descending; `v0.1.88 (installed)` marked; no footer line

### TC-13: `CLAUDE.md` versioning section present (AC1)
**Result**: PASS
- `## Versioning` heading: present (1 match)
- `v{major}.{minor}.{task_num}`: present
- Human-only statement: present
- Internal-only constraint: present

### TC-14: Convention isolation (AC2)
**Result**: PASS — `grep -r "Versioning" .cwf/` returns no matches

### TC-15: `cwf-manage validate` (AC5)
**Result**: PASS — exits 0, no violations

---

## Regression
`prove t/` — 18 files, 173 tests, all pass. No regressions.

## Status
**Status**: Finished
**Next Action**: /cwf-rollout 89
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 15 test cases passed. One implementation bug found and fixed during execution (TC-2:
`parse_semver` accepting no-`v`-prefix tags). Documented in f-implementation-exec.md.

## Lessons Learned
All 15 planned TCs were sufficient — no gaps found during execution. The inline
perl-based TC-12 check (no live remote) was a clean way to validate --all logic.
