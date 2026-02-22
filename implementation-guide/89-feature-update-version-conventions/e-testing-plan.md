# Update version conventions - Testing Plan
**Task**: 89 (feature)

## Task Reference
- **Task ID**: internal-89
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/89-update-version-conventions
- **Template Version**: 2.1

## Goal
Validate the versioning section in `CLAUDE.md` and the `cwf-manage list-releases` filtered
view, including `parse_semver`, `filter_releases`, and the `--all` flag.

## Test Strategy

### Test Levels
- **Unit**: `parse_semver` and `filter_releases` in isolation, using constructed tag lists
  (no network call). Run via `prove t/cwf-manage-list-releases.t`.
- **System**: `cwf-manage validate` against the live repo. Manual smoke-test of
  `cmd_list_releases` output format (no live remote needed for content correctness).
- **Acceptance**: Check all acceptance criteria from b-requirements-plan.md.

### Test Coverage Targets
- **`parse_semver`**: 100% — all valid/invalid input classes covered
- **`filter_releases` edge cases**: 100% — all 6 NFR1 cases covered
- **`--all` flag path**: verified unchanged
- **Regression**: `prove t/` full suite passes

### Test File
`t/cwf-manage-list-releases.t` — new unit test file, no network dependency.

---

## Test Cases

### TC-1: `parse_semver` — valid semver with `v` prefix
- **Given**: tag `v1.2.3`
- **When**: `parse_semver('v1.2.3')` called
- **Then**: returns `(1, 2, 3)` as integers

### TC-2: `parse_semver` — tag without `v` prefix
- **Given**: tag `1.2.3`
- **When**: `parse_semver('1.2.3')` called
- **Then**: returns `()` (empty list — not strict `v\d+.\d+.\d+` form)

### TC-3: `parse_semver` — 2-part tag
- **Given**: tag `v1.2`
- **When**: `parse_semver('v1.2')` called
- **Then**: returns `()` (not 3 parts)

### TC-4: `parse_semver` — non-numeric component
- **Given**: tag `vabc`
- **When**: `parse_semver('vabc')` called
- **Then**: returns `()`

### TC-5: `parse_semver` — empty string
- **Given**: tag `''`
- **When**: `parse_semver('')` called
- **Then**: returns `()`

### TC-6: `filter_releases` — already on latest (NFR1 case 1)
- **Given**: `$current = 'v0.1.90'`, `@tags = ('v0.1.90')`
- **When**: `filter_releases($current, @tags)` called
- **Then**: returns `()` — no upgrades; footer suppressed when caller builds display list

### TC-7: `filter_releases` — new patch on same minor (NFR1 case 2 variant)
- **Given**: `$current = 'v0.1.88'`, `@tags = ('v0.1.90', 'v0.1.89', 'v0.1.88')`
- **When**: `filter_releases($current, @tags)` called
- **Then**: returns `('v0.1.90')` — only highest patch on same minor; `v0.1.89` hidden

### TC-8: `filter_releases` — multiple higher minors (NFR1 case 5)
- **Given**: `$current = 'v0.1.88'`,
  `@tags = ('v0.3.95', 'v0.2.90', 'v0.2.89', 'v0.1.88')`
- **When**: `filter_releases($current, @tags)` called
- **Then**: returns `('v0.3.95', 'v0.2.90')` — one entry per higher minor, sorted descending

### TC-9: `filter_releases` — higher major (NFR1 case 3/4)
- **Given**: `$current = 'v0.1.88'`,
  `@tags = ('v1.0.103', 'v0.1.90', 'v0.1.88')`
- **When**: `filter_releases($current, @tags)` called
- **Then**: returns `('v1.0.103', 'v0.1.90')` — major bucket + same-minor bucket

### TC-10: `filter_releases` — multiple higher majors (NFR1 case 6)
- **Given**: `$current = 'v0.1.88'`,
  `@tags = ('v2.0.5', 'v1.0.103', 'v0.1.88')`
- **When**: `filter_releases($current, @tags)` called
- **Then**: returns `('v2.0.5', 'v1.0.103')` — one entry per major

### TC-11: `filter_releases` — non-semver tags silently excluded
- **Given**: `$current = 'v0.1.88'`,
  `@tags = ('latest', 'v0.1.90', 'nightly', 'v0.1.88')`
- **When**: `filter_releases($current, @tags)` called
- **Then**: returns `('v0.1.90')` — `latest` and `nightly` not in output, no error

### TC-12: `cmd_list_releases --all` — unchanged behaviour
- **Given**: tags `('v0.1.90', 'v0.1.89', 'v0.1.88')`, current `v0.1.88`
- **When**: `list-releases --all` called (or `$show_all = 1`)
- **Then**: all three tags printed descending; `v0.1.88` marked `(installed)`; no footer line

### TC-13: `CLAUDE.md` versioning section present (AC1)
- **Given**: `CLAUDE.md` in repo root
- **When**: `grep "## Versioning" CLAUDE.md`
- **Then**: match found; section contains `v{major}.{minor}.{task_num}`,
  definitions of major/minor/patch, and explicit human-only statement

### TC-14: Convention isolation (AC2)
- **Given**: implementation complete
- **When**: `grep -r "Versioning" .cwf/`
- **Then**: no matches

### TC-15: `cwf-manage validate` passes (AC5)
- **Given**: implementation complete
- **When**: `.cwf/scripts/cwf-manage validate`
- **Then**: exits 0, no errors reported

---

## Non-Functional Test Cases

### Performance
- `filter_releases` with 100 constructed tags completes in <1 s (local list, no I/O)

### Reliability
- TC-2 through TC-5 confirm malformed tags never cause `die` — silent skip only

### Regression
- `prove t/` full suite passes — no existing tests broken

---

## Test Environment
- **Runtime**: Perl 5 (already installed), `prove` test runner
- **Dependencies**: `List::Util` (core module — no CPAN install needed)
- **Network**: not required — unit tests use constructed tag arrays
- **Test data**: inline in `t/cwf-manage-list-releases.t` via `Test::More`

---

## Validation Criteria
- [ ] TC-1 through TC-5: `parse_semver` returns correct values for all input classes
- [ ] TC-6 through TC-11: `filter_releases` returns correct buckets for all NFR1 edge cases
- [ ] TC-12: `--all` output unchanged
- [ ] TC-13: `CLAUDE.md` versioning section present with all required content
- [ ] TC-14: `grep -r "Versioning" .cwf/` returns no matches
- [ ] TC-15: `cwf-manage validate` passes
- [ ] `prove t/` full suite passes (regression)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 89
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 15 test cases executed and passed. TC-2 caught a real bug in parse_semver.
prove t/ (173 tests across 18 files) clean. cwf-manage validate OK.

## Lessons Learned
TC-2 (no-v-prefix rejection) was essential — it exposed a latent bug in the
plan's implementation before the code reached main.
