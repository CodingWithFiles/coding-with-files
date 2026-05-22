# fix cwf-manage-fix-security test fixture - Testing Execution
**Task**: 154 (bugfix)

## Task Reference
- **Task ID**: internal-154
- **Branch**: bugfix/154-fix-cwf-manage-fix-security-test-fixture
- **Template Version**: 2.1

## Goal
Execute e-testing-plan.md: confirm TC-1…TC-7 (TC-1/2/7 red→green), author + run the new TC-8 drift pin, full-suite regression, real-repo integrity.

## Test Results

### Functional Tests
| Test ID | Test Case | Expected | Actual | Status |
|---------|-----------|----------|--------|--------|
| TC-1 | clean install no-op | exit 0, "repaired 0 files", validate passes | as expected | PASS (red→green) |
| TC-2 | stripped perms, sha intact | exit 0, post-validate passes, recorded perms | as expected | PASS (red→green) |
| TC-3 | sha mismatch | exit 1, recovery hint, no chmod | as expected | PASS (unchanged) |
| TC-4 | missing tracked file | exit 1, hint, best-effort fix others | as expected | PASS (unchanged) |
| TC-5 | mixed fixable/unfixable | exit 1, repair A, refuse B | as expected | PASS (unchanged) |
| TC-6 | unparseable hashes | exit 1, recovery hint | as expected | PASS (unchanged) |
| TC-7 | idempotency | second run "repaired 0 files" | as expected | PASS (red→green) |
| TC-8 | fixture provisions non-`.cwf/` manifest paths (NEW) | ≥1 path; each exists, byte-identical, perms ≥ recorded floor | 5 `.claude/agents/*.md`, floor 0444; 16 assertions | PASS |

`prove t/cwf-manage-fix-security.t` → **8/8 subtests** (TC-8 = 16 assertions, all green).

### Non-Functional Tests
- **Suite regression**: `prove t/` → **45 files, 500 tests, all PASS** (was 499; +1 for TC-8). No regression.
- **Integrity**: `.cwf/scripts/cwf-manage validate` on the real repo → **OK** (no hashed/manifest change).
- **Security**: changeset review (testing phase) below.

## Test Failures
None.

## Coverage Report
TC-8 derives its assertion set from the manifest (not a hard-coded count), so it covers the helper's happy path directly and doubles as the drift guard: any future non-`.cwf/` manifest path is asserted automatically; the `.cwf/`-skip and section/entry filters are covered transitively by TC-1's validate-passes path.

## Security Review

**State**: no findings

The diff is a test fixture helper plus a drift-pin test. Both `system()` calls are list-form (`"mkdir","-p",$dir` / `"cp","-p",$src,$dst`) — no shell. The manifest is read from the trusted `$REPO_ROOT` integrity-tracked source and parsed via `decode_json` (no newline-splitting). No new env vars, no LLM-context flow. The fail-closed path-traversal guard `m{(?:^/|(?:^|/)\.\.(?:/|$))}` correctly rejects absolute paths and `..` segments before the `cp` destination is built.

no findings

Pattern-risk note (category (e), advisory, not a defect): the guard at `t/cwf-manage-fix-security.t` is safe here because manifest paths are repo-controlled and integrity-tracked (regex is belt-and-braces, not sole defence) and the destination is string-concatenated, not shell-passed. Audit future reuse where `$rel` might come from an untrusted manifest or flow into a shell-form command — the regex does not screen embedded NUL/newline bytes, which only matters outside the current trust boundary. The inline comment already documents the invariant.

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None

## Lessons Learned
TC-8 asserts on the manifest-derived path set (never a hard-coded count), so it doubles as the drift guard the design called for — any future non-`.cwf/` tracked path is provisioned and asserted automatically. Full learnings in j-retrospective.md.
