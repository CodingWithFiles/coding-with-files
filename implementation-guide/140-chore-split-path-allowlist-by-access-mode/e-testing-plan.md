# Split path-allowlist by access mode - Testing Plan
**Task**: 140 (chore)

## Task Reference
- **Task ID**: internal-140
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/140-split-path-allowlist-by-access-mode
- **Template Version**: 2.1

## Goal
Validate the API split — `validate_path_allowlist` → `validate_write_path_allowlist` + `validate_read_path_allowlist` — at unit and integration level, with explicit regression coverage for the three migrated call sites.

## Test Strategy

### Test Levels
- **Unit**: New helper functions in `CWF::ArtefactHelpers` — accept/reject matrices for both variants. Existing module under `t/artefacthelpers.t`.
- **Integration**: `backlog-manager add --body-file=...` exercised end-to-end with isolated `BACKLOG.md` (via `make_isolated`/`run_bm` helpers from `t/backlog-manager.t`). Verifies the read-validator wiring and the dropped prefix list.
- **Regression**: Full `prove t/` to confirm `cwf-apply-artefacts` and `cwf-claude-settings-merge` write-path tests still pass after the rename.
- **System smoke**: One manual `backlog-manager add ... --body-file=/tmp/cwf-smoke/body.md` then `delete --confirm` against the live repo BACKLOG.md, executed during g-testing-exec.

### Test Coverage Targets
- **New functions**: every documented failure mode (`undef`, empty, absolute, `..`, missing prefix, non-existent, unreadable) plus at least one accept case.
- **Migrated call sites**: each call site has at least one test that exercises the new validator path. `cwf-apply-artefacts` and `cwf-claude-settings-merge` are covered by their existing manifest-rejection tests (no new test required, just rename in assertions if any pin to the function name).
- **Regression**: 100% of existing `prove t/` cases must pass.

## Test Cases

### Functional Test Cases — `validate_write_path_allowlist` (in `t/artefacthelpers.t`)
- **TC-W1**: accepts allowed prefix
  - **Given**: prefixes `('.cwf/', 'CLAUDE.md')`, path `'.cwf/foo'`
  - **When**: `validate_write_path_allowlist($path, \@prefixes)`
  - **Then**: returns 1, no die.
- **TC-W2**: rejects absolute path
  - **Given**: any prefix list, path `'/etc/passwd'`
  - **Then**: dies, message matches `/absolute/`.
- **TC-W3**: rejects path containing `..`
  - **Given**: prefix `'.cwf/'`, paths `'.cwf/../etc/passwd'`, `'../etc/passwd'`
  - **Then**: dies, message matches `/'\.\.'/`.
- **TC-W4**: rejects path outside allowlist
  - **Given**: prefix `'.cwf/'`, path `'not/allowed'`
  - **Then**: dies, message matches `/allowed prefix/`.
- **TC-W5**: rejects undef / empty path
  - **Given**: prefix list `('.cwf/')`, path `undef` or `''`
  - **Then**: dies with `/undef/` or `/empty/` respectively.

### Functional Test Cases — `validate_read_path_allowlist` (in `t/artefacthelpers.t`)
- **TC-R1**: accepts an existing readable file
  - **Given**: a freshly-created tempfile via `File::Temp::tempfile`
  - **Then**: returns 1.
- **TC-R2**: accepts an absolute path under `/tmp/`
  - **Given**: tempfile path inside `tempdir(CLEANUP => 1)`
  - **Then**: returns 1 (regression guard against re-introducing a prefix list).
- **TC-R3**: rejects undef / empty
  - **Then**: dies with `/undef/` and `/empty/` respectively.
- **TC-R4**: rejects non-existent path
  - **Given**: `"$tmp/never-created"`
  - **Then**: dies, message matches `/does not exist/`.
- **TC-R5**: rejects unreadable file
  - **Given**: tempfile then `chmod 0000`
  - **When**: validator called
  - **Then**: dies, message matches `/not readable/`. **Skip if `$> == 0`** (root bypasses `-r`).

### Functional Test Cases — `backlog-manager --body-file` (new file `t/backlog-manager-body-file.t`)
Reuse `make_isolated` + `run_bm` from `t/backlog-manager.t:30-71` (copy or extract on rule-of-three).
- **TC-B1**: positive — `/tmp/...` body file accepted
  - **Given**: `make_isolated` repo with valid BACKLOG.md/CHANGELOG.md, body file written to `tempdir(CLEANUP => 1)/body.md` containing `"Smoke 140 body\n"`
  - **When**: `run_bm($dir, qw(add --title=Smoke140 --task-type=chore --priority=Low), "--body-file=$tmp/body.md")`
  - **Then**: exit 0; `BACKLOG.md` content includes `"Smoke 140 body"` and a `## Task: Smoke140` heading.
- **TC-B2**: negative — non-existent body file
  - **When**: `--body-file=/nonexistent/path`
  - **Then**: exit non-zero; stderr matches `/does not exist/`.
- **TC-B3**: negative — unreadable body file (skip-if-root)
  - **Given**: tempfile chmod 0000
  - **Then**: exit non-zero; stderr matches `/not readable/`.
- **TC-B4**: negative — empty `--body-file=''`
  - **Then**: exit non-zero; stderr matches `/empty/`.

### Regression
- **TC-RG1**: full `prove t/` is green pre- and post-change. Specific re-run targets after migration:
  - `t/artefacthelpers.t` — new exports load, old export is gone.
  - `t/backlog-manager.t`, `t/backlog-manager-argv-utf8.t` — unchanged behaviour for non-body-file flows.
  - Any `t/cwf-apply-artefacts*.t` and `t/cwf-claude-settings-merge*.t` if present (verify during exec).

### Non-Functional Test Cases
- **Security**: `.cwf/scripts/command-helpers/security-review-changeset --phase=f --task-num=140` reports zero new findings. Threat-model regression check: confirm write-side allowlist semantics for `cwf-apply-artefacts` and `cwf-claude-settings-merge` are byte-for-byte identical (the new function body is a verbatim copy).
- **Maintainability**: source-level grep `grep -rn validate_path_allowlist .cwf/ t/ docs/ .claude/` returns zero hits after migration (orphan-symbol guard).
- **Reliability**: `cwf-manage validate` is OK after script-hash regeneration.
- **Performance**: not applicable — change is in argument-validation hot path of CLI tools, well below any user-perceptible threshold.

## Test Environment

### Setup Requirements
- Standard repo checkout. No external services, no databases.
- POSIX `chmod` and a non-root effective UID for TC-R5/TC-B3 (skip otherwise).
- `File::Temp` (core).

### Automation
- All unit + integration tests run under `prove t/` via the existing harness.
- No CI integration changes needed; tests slot into the existing test set.
- Manual smoke (one `add` + `delete` against live BACKLOG) runs in g-testing-exec.

## Validation Criteria
- [ ] All TC-W1..TC-W5 pass.
- [ ] All TC-R1..TC-R5 pass (TC-R5 may be skipped under root).
- [ ] All TC-B1..TC-B4 pass (TC-B3 may be skipped under root).
- [ ] TC-RG1: `prove t/` exit 0.
- [ ] Source grep for `validate_path_allowlist` returns zero hits.
- [ ] `security-review-changeset` reports no new findings.
- [ ] `cwf-manage validate` is OK.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 140
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
