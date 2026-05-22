# fix cwf-manage-fix-security test fixture - Testing Plan
**Task**: 154 (bugfix)

## Task Reference
- **Task ID**: internal-154
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/154-fix-cwf-manage-fix-security-test-fixture
- **Template Version**: 2.1

## Goal
Validate that `build_fixture` provisions every manifest-tracked path outside `.cwf/`, so `t/cwf-manage-fix-security.t` is fully green (TC-1/2/7 fixed) with no regression elsewhere, and pin the new helper with a direct assertion that survives future manifest drift.

## Test Strategy
### Test Levels
- **Regression (primary)**: the existing TC-1…TC-7 in `t/cwf-manage-fix-security.t` — TC-1/2/7 flip red→green, TC-3/4/5/6 stay green. These are the bug's own tests.
- **Unit (new)**: one direct subtest asserting the fixture contains the manifest's non-`.cwf/` files with perms satisfying the recorded floor — pins the helper independent of TC-1's broader "validate passes" path.
- **Suite regression**: full `prove t/` green (the sibling `t/cwf-claude-settings-merge.t` has its own untouched `build_fixture`).
- **Real-repo integrity**: `cwf-manage validate` still OK (no production/hashed/manifest change).

### Test Coverage Targets
- `_provision_extra_manifest_paths`: the happy path (5 `.claude/agents/*.md` copied with existence + recorded-floor perms + byte-identical content) directly asserted; the `.cwf/`-skip and section/entry filters covered transitively (validate sees no spurious extra or missing files).
- All 7 existing subtests pass.
- Zero regression across `prove t/`.

## Test Cases
### Functional — existing regression (no logic change; assert red→green)
- **TC-1 — clean install no-op**: Given a fresh fixture. When `fix-security` runs. Then exit 0, "repaired 0 files", and `validate` passes. *(was red: 5 missing `.claude/agents` → now green.)*
- **TC-2 — stripped perms, sha intact**: Given `.cwf/scripts` perms stripped. When `fix-security` runs. Then exit 0 and post-`validate` passes. *(was red: post-validate saw missing agents → now green.)*
- **TC-7 — idempotency**: Given a stripped fixture repaired once. When `fix-security` runs again. Then exit 0, "repaired 0 files". *(was red → now green.)*
- **TC-3/4/5/6 — unchanged**: tamper / missing-file / mixed / unparseable-hashes cases still exit 1 with their recovery hints. **Must be re-run to confirm** the now-present agents don't alter their assertions (they assert on `.cwf/scripts` targets and exit code, not on agents).

### Functional — new direct assertion (added this task)
- **TC-8 — fixture provisions non-`.cwf/` manifest paths**:
  - **Given**: a fresh `build_fixture()` tempdir.
  - **When**: we read every manifest entry whose `path` is outside `.cwf/`.
  - **Then**: each such file exists under `$tmp/<path>`, its bytes equal `$REPO_ROOT/<path>` (SHA match), and `file_perms($tmp/<path>) & recorded_floor == recorded_floor`. Asserts on the derived set (≥1 path; today exactly the 5 `.claude/agents/*.md`), so it does not hard-code the count and stays correct if the manifest gains/loses a non-`.cwf/` path.

### Non-Functional
- **Security**: changeset security review (f and g phases). Expected no findings — test-only, list-form `system`, fail-closed `..`/absolute guard on `$rel`, no hashed/manifest change.
- **Reliability**: helper `die`s (naming the path) on any `mkdir`/`cp` failure or unsafe `$rel`, so a broken fixture fails loud rather than producing false greens.
- **Integrity**: `cwf-manage validate` on the real repo reports no new violations; no `sha256` entry touched.

## Test Environment
- POSIX, system Perl, core modules only (`File::Temp`, `JSON::PP`, `Fcntl`, `Cwd` — all already imported). No new deps.
- `build_fixture` provides a temp git repo + copied `.cwf/` + (new) provisioned non-`.cwf/` manifest paths; no writes to the real repo.
- Live env may carry `PERL5OPT=-CDSLA`; irrelevant — the fixture runs `cwf-manage` in a child against `$tmp`.

## Validation Criteria
- [ ] TC-1…TC-8 pass (`prove t/cwf-manage-fix-security.t` → 8/8 subtests).
- [ ] `prove t/` green (full suite, no regression).
- [ ] `cwf-manage validate` on the real repo clean.
- [ ] Security review: no new findings (f and g).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Testing plan complete; ready for exec on user approval. TC-8 (direct fixture-provisioning assertion) is the new case added this task, per plan-review consensus; TC-1…TC-7 are existing and assert red→green / unchanged. No decomposition (one test file).

## Lessons Learned
TC-8 asserts on the manifest-derived set rather than a hard-coded count, so it doubles as the drift guard the design called for. Full learnings in `j-retrospective.md`.
