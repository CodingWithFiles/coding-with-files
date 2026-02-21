# fix install script latest tag resolution and local dev UX - Testing Plan
**Task**: 80 (bugfix)

## Task Reference
- **Task ID**: internal-80
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/80-fix-install-latest-and-env-handling
- **Template Version**: 2.1

## Goal
Verify the `file://` default-to-HEAD fix and the INSTALL.md local clone section.

## Test Strategy
The install script cannot be unit-tested in isolation without a real git repo, so
tests are manual integration tests using a temporary git repo. Two critical paths:

1. **Happy path (file:// → HEAD)**: the bug scenario — must now succeed
2. **Regression (remote source → latest tag)**: existing behaviour must be unchanged

`prove t/` regression check confirms no Perl library regressions from the
bash/docs-only change.

## Test Cases

### TC-1 — file:// source defaults to HEAD
- **Given**: A temp git repo with one commit, `CWF_SOURCE=file:///home/matt/repo/coding-with-files`, no `CWF_REF` set
- **When**: `bash /tmp/cwf-install.bash` is run from the temp repo
- **Then**:
  - Log contains `file:// source detected — defaulting CWF_REF to HEAD`
  - Install succeeds (exit 0)
  - `.cwf/` directory exists in the temp repo with current structure (not v0.2.1)

### TC-2 — file:// source with explicit CWF_REF still honoured
- **Given**: Same setup as TC-1, but with `CWF_REF=HEAD` explicitly set
- **When**: `CWF_SOURCE=file:///... CWF_REF=HEAD bash /tmp/cwf-install.bash`
- **Then**: Install succeeds; log does NOT show the "defaulting" message (explicit ref used directly)

### TC-3 — resolve_ref() file:// guard is source-aware (code inspection)
- **Given**: Read `scripts/install.bash` `resolve_ref()` function
- **When**: Check the condition for `file://` guard
- **Then**: Pattern is `"$CWF_SOURCE" == file://*`, not a broader match that could catch `https://`

### TC-4 — INSTALL.md local clone section present
- **Given**: `INSTALL.md`
- **When**: `grep -n "local clone" INSTALL.md`
- **Then**: At least one match; section includes `file://` example and explains HEAD default

### TC-5 — prove t/ no regressions
- **Given**: Current test suite
- **When**: `prove t/`
- **Then**: All tests pass (158+, exit 0)

## Test Environment
- Temp repo: `mktemp -d` + `git init` + `git commit --allow-empty -m "init"`
- Install script extracted to `/tmp/cwf-install.bash` via `git archive`
- Run from temp repo root (install.bash requires git root)
- Cleanup: `rm -rf <tmpdir>`

## Validation Criteria
- [ ] TC-1: file:// install succeeds with HEAD default
- [ ] TC-2: Explicit CWF_REF still works
- [ ] TC-3: Guard condition doesn't catch remote URLs
- [ ] TC-4: INSTALL.md has local clone section with file:// example
- [ ] TC-5: prove t/ exits 0

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 80
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
5/5 TCs passed. TC-1 reproduced the original bug scenario end-to-end and confirmed
the fix. TC-2 confirmed the explicit-ref path is unaffected.

## Lessons Learned
Including a live end-to-end TC (full install into temp repo) gives strong confidence
for install script changes where unit testing is impractical.
