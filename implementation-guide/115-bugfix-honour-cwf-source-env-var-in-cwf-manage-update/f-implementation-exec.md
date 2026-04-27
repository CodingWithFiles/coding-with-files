# Honour CWF_SOURCE env var in cwf-manage update - Implementation Execution
**Task**: 115 (bugfix)

## Task Reference
- **Task ID**: internal-115
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/115-honour-cwf-source-env-var-in-cwf-manage-update
- **Template Version**: 2.1

## Goal
Execute the implementation following d-implementation-plan.md and verify integration end-to-end.

## Files Changed
- `.cwf/scripts/cwf-manage` — added `resolve_source` helper; routed `cmd_update` and `cmd_list_releases` through it; added `Environment:` block to header comment and `cmd_help` heredoc. **Boy-scout fix**: changed shebang to `#!/usr/bin/perl -CDSL` and added `use utf8;` to bring the script into compliance with `docs/conventions/perl-git-paths.md`. Pre-existing em-dashes on what were lines 54 and 107 were emitting double-encoded mojibake under `PERL5OPT=-CDSL` because the source pragma was missing; companion scripts (e.g. `stop-uncommitted-changes-warning`) already follow this convention.
- `.cwf/security/script-hashes.json` — updated `cwf-manage`'s `sha256` to match the modified script.
- `t/cwf-manage-resolve-source.t` — new file. Six subtests (TC-1..TC-6) covering the env×file matrix.

## Actual Results

### Step 1: Setup
- **Planned**: Confirm task branch checked out and clean.
- **Actual**: On `bugfix/115-...`, no tracked modifications. Three untracked workflow templates (f/g/j) present from `/cwf-new-task` scaffold — expected.

### Step 2: Test first (TDD)
- **Planned**: Create `t/cwf-manage-resolve-source.t` with six subtests; run; expect all-fail because `resolve_source` does not exist.
- **Actual**: Wrote the test file. First run failed at *load* (not at the assertions): `Can't locate CWF/Common.pm in @INC`.
- **Deviation**: The d-impl-plan's test skeleton omitted `use lib File::Spec->catdir($FindBin::Bin, '..', '.cwf', 'lib')`, which `t/cwf-manage-list-releases.t:13` does include. Without it, `cwf-manage`'s own `use CWF::Common` fails inside `do $SCRIPT`. Added the line; second run failed correctly with `Undefined subroutine &main::resolve_source` (expected red state).
- **Secondary**: Perl emitted `Name "main::die_msg" used only once: possible typo` for the symbol-table override. Silenced with `no warnings 'redefine', 'once';`.

### Step 3: Add the helper
- **Planned**: Insert `sub resolve_source` after `write_version_file`, before `# --- Ref resolution ---`.
- **Actual**: Done verbatim per d-impl-plan's "Code Changes — Helper" snippet. Re-ran `prove t/cwf-manage-resolve-source.t` — **6/6 subtests pass**.

### Step 4: Wire into `cmd_list_releases`
- **Planned**: Replace line 124's direct read with `my ($source, $origin) = resolve_source(\%v);` and update line 127 log to include `(from: $origin)`.
- **Actual**: Done verbatim. `prove t/cwf-manage-list-releases.t` — still **9/9 subtests pass** (existing pure-function tests unaffected).

### Step 5: Wire into `cmd_update`
- **Planned**: Same substitution at line 201; update line 208 log; leave lines 232–236 untouched (Decision 2 — no persistence).
- **Actual**: Done verbatim. `cmd_update` write-back block (now lines ~241–245 after helper insertion) untouched — `cwf_source` continues to round-trip from `read_version_file` to `write_version_file` without modification.

### Step 6: Update help and header documentation
- **Planned**: Add `Environment:` block to file-header comment block; add `Environment:` section between `Commands:` and `Examples:` in `cmd_help` heredoc.
- **Actual**: Done verbatim. `cwf-manage help` output verified — see Smoke Tests below.

### Step 7: Smoke tests
- **Planned**: Full `prove t/`; `cwf-manage validate`; `cwf-manage help` Environment grep; manual env-override and default-source smokes.
- **Actual**:
  - `prove t/` — **24 files, 235 tests, all PASS** (no regressions).
  - `cwf-manage validate` — **initially failed** (security hash mismatch, expected). Recomputed sha256, updated `.cwf/security/script-hashes.json`, re-ran — **OK**.
  - `cwf-manage help | head -25` — Environment block present, exact wording matches d-impl-plan.
  - **End-to-end smoke fixture**: built a throwaway repo via `mktemp -d`/`git init` with a synthetic `.cwf/version` (the dev checkout itself has no `.cwf/version` — it's the source repo, not an installed copy). Ran `cwf-manage update` and `list-releases` against the fixture from absolute path:
    - `CWF_SOURCE=file:///tmp/cwf-nonexistent cwf-manage update` → log line: `[CWF] Cloning CWF source from file:///tmp/cwf-nonexistent (from: CWF_SOURCE env var)...` followed by expected git clone failure. ✓ TC-8
    - `unset CWF_SOURCE; cwf-manage list-releases` → log line: `[CWF] Available releases from https://github.com/CodingWithFiles/coding-with-files.git (from: .cwf/version)`. ✓ TC-9
  - TC-10 (no-persistence assertion) deferred to g-testing-exec — needs a real cloneable source to run a successful `update` and inspect post-state of `.cwf/version`.

### Step 8: Validation
- **Planned**: All success-criteria checkboxes verifiable; `.cwf/version` `cwf_source` field unchanged after env-driven update.
- **Actual**: All a-task-plan success criteria met by code or by tests. The `cwf_source`-unchanged assertion is the load-bearing TC-10, deferred to g.

## Deviations from Plan

1. **Test file required `use lib '.cwf/lib'`**: Not in d-impl-plan's test skeleton. Pre-existing pattern in `t/cwf-manage-list-releases.t:13` was the right reference — followed it. Plan was accurate about the *harness shape* but missed this one line.
2. **`no warnings 'once'`**: Added alongside `'redefine'` to silence the symbol-table-override typo warning. Trivial; mentioned for completeness.
3. **Security hash update**: Modifying `.cwf/scripts/cwf-manage` requires updating `.cwf/security/script-hashes.json`. Foreseeable but not called out in d-impl-plan's "Files to Modify" — added to the diff. Worth noting in the retrospective: any task touching a script in `.cwf/scripts/` will need this.
4. **TC-10 deferred to g-testing-exec**: f-exec's smoke-test slot exercised TC-8 and TC-9 (log-line shape). TC-10 (no-persistence) requires a successful update against a real source and is more naturally part of g.
5. **Boy-scout: UTF-8 source pragma + `-CDSL` shebang**: While running TC-9's smoke, the legacy em-dash error messages emitted as double-encoded mojibake under `PERL5OPT=-CDSL`. Root cause: `cwf-manage` was non-conformant with `docs/conventions/perl-git-paths.md` — neither `-CDSL` shebang nor `use utf8;` was present. Pre-existing bug, not introduced by this task, but trivially fixable while we were already in the file: changed shebang from `#!/usr/bin/env perl` to `#!/usr/bin/perl -CDSL`, added `use utf8;` after `use warnings;`. Verified: legacy em-dash error message now emits as `e2 80 94` (single-encoded UTF-8). All 235 tests still pass; `cwf-manage validate` OK after re-hash.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (TC-10 verification will close the loop in g)
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval (TC-10 is a test-execution concern, not implementation work)
- [x] No follow-up tasks needed beyond those already filed in BACKLOG.md during a-plan

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 115
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
