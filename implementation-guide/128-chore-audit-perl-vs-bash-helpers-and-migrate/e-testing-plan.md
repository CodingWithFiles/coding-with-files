# Audit Perl-vs-Bash helpers and migrate - Testing Plan
**Task**: 128 (chore)

## Task Reference
- **Task ID**: internal-128
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/128-audit-perl-vs-bash-helpers-and-migrate
- **Template Version**: 2.1

## Goal
Verify that deletion of the five dead/trivial shell helpers and inlining of the one live caller leaves the system in a working, validated state with no integrity-tracking gap and no behavioural regression in `cwf-config`.

## Test Strategy

This is a deletion task. The risks worth testing for are:
1. **Manifest-vs-filesystem desync** — orphaned entries in `script-hashes.json` or files registered nowhere.
2. **Live-caller regression** — `/cwf-config` no longer loads the autoload config equivalently after the inline.
3. **Hidden caller** — the audit missed a place that referenced a deleted helper.

Test levels used:
- **Static / coverage**: `prove t/validate-security-coverage.t` (existing dynamic-counting test).
- **Integrity gate**: `cwf-manage validate` (SHA256, perms, existence checks).
- **End-to-end**: `/cwf-config list` invocation.
- **Regression sweep**: `git ls-files | xargs grep` for the five deleted names; `prove t/`.

No new test code is required — the existing `validate-security-coverage.t` already provides a coverage guard, and `cwf-manage validate` already enforces the integrity contract.

### Test Coverage Targets
- **Integrity contract**: 100% — `cwf-manage validate` must report 0 violations.
- **Coverage regression test**: GREEN — every surviving helper still appears in `script-hashes.json`.
- **End-to-end smoke**: `/cwf-config list` produces equivalent output to pre-deletion state.

## Test Cases

### Functional Test Cases

**TC-F1**: Integrity manifest stays consistent with filesystem after deletion.
- **Given**: 5 helper files deleted from `.cwf/scripts/command-helpers/` and 5 corresponding entries removed from `.cwf/security/script-hashes.json`, all in the same commit.
- **When**: `.cwf/scripts/cwf-manage validate` runs.
- **Then**: Exit 0, "[CWF] validate: OK". No "missing file", no "unregistered file", no "sha256 drift" violations.

**TC-F2**: Coverage regression test stays GREEN through the deletion.
- **Given**: Five deletions committed.
- **When**: `prove t/validate-security-coverage.t` runs.
- **Then**: All subtests pass. TC-C1 reports 19 top-level command-helpers (24 − 5), TC-C2 unchanged at 7, TC-C3 unchanged at 2.

**TC-F3**: `/cwf-config list` continues to load autoload config after inlining.
- **Given**: `.claude/skills/cwf-config/SKILL.md` line 24 replaced from helper invocation to `cat .cwf/autoload.yaml 2>/dev/null || echo "No autoload config found"`.
- **When**: `/cwf-config list` is invoked at the repo root with `.cwf/autoload.yaml` present.
- **Then**: The autoload YAML content appears in the skill's mandatory-context output, identical to the pre-change behaviour.

**TC-F4**: `/cwf-config list` fallback still works when autoload config missing.
- **Given**: SKILL.md change applied; `.cwf/autoload.yaml` temporarily renamed (or invocation done in a directory without one).
- **When**: `/cwf-config list` is invoked.
- **Then**: Output contains "No autoload config found"; no error to user.

**TC-F5**: No remaining caller references the deleted helpers.
- **Given**: Deletions committed.
- **When**: `git ls-files | xargs grep -l 'cwf-find-task-numbering-structure\|cwf-load-autoload-config\|cwf-load-existing-tasks\|cwf-load-project-config\|cwf-load-status-sections'` runs.
- **Then**: Hits appear only in expected historical/archival files: `BACKLOG.md` (until Step 6 closes the entry), `CHANGELOG.md` Task 125 entry, `implementation-guide/12{5,6,8}-…` task docs, `implementation-guide/59-…/b-requirements-plan.md`, `implementation-guide/101-…`. **No** hits in `.claude/skills/`, `.cwf/scripts/`, `.cwf/lib/`, `.cwf/docs/`, `t/`, `scripts/`, or `install.bash`.

**TC-F6**: BACKLOG entry removed.
- **Given**: Step 6 of implementation has run.
- **When**: `grep -c "Audit Perl-vs-Bash helper scripts" BACKLOG.md` runs.
- **Then**: Returns 0 (entry removed).

### Non-Functional Test Cases

**TC-NF1**: No regression in the wider test suite.
- **When**: `prove t/` runs over the whole `t/` directory.
- **Then**: All tests GREEN. (Catches incidental breakage if any other test inspected the deleted helpers.)

**TC-NF2**: Working tree is clean and atomic at each commit boundary.
- **Given**: Implementation Step 3 completed (deletes + manifest edit staged together).
- **When**: `git diff --cached --stat` examined before commit.
- **Then**: Cached diff lists exactly: 5 file deletions under `.cwf/scripts/command-helpers/`, 1 modification of `.cwf/security/script-hashes.json`. No partial state.

**TC-NF3**: Permission model unchanged for surviving helpers.
- **Given**: Deletions committed.
- **When**: `cwf-manage validate` runs.
- **Then**: No permission-drift violations against any surviving helper. (The deletions only remove entries; nothing about other helpers' perms changes.)

## Test Environment

### Setup Requirements
- Local repo at `/home/matt/repo/coding-with-files`, branch `chore/128-audit-perl-vs-bash-helpers-and-migrate`.
- Working `perl` interpreter with `Test::More`, `JSON::PP`, `Digest::SHA` (already installed for prior tasks).
- `.cwf/autoload.yaml` present (verified in discovery).

### Automation
- Existing harness via `prove t/`; no new test files created.

## Validation Criteria
- [ ] TC-F1 passes: `cwf-manage validate` clean.
- [ ] TC-F2 passes: coverage test GREEN with auto-adjusted counts.
- [ ] TC-F3 passes: inlined `cwf-config` loads autoload identically.
- [ ] TC-F4 passes: missing-config fallback still works.
- [ ] TC-F5 passes: no orphan caller references in active code.
- [ ] TC-F6 passes: BACKLOG entry removed.
- [ ] TC-NF1 passes: full `prove t/` GREEN.
- [ ] TC-NF2 passes: atomic commit, no partial state.
- [ ] TC-NF3 passes: perms unchanged for surviving helpers.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
