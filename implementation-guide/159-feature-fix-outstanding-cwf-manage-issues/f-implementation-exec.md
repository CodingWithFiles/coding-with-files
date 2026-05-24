# fix outstanding cwf-manage issues - Implementation Execution
**Task**: 159 (feature)

## Task Reference
- **Task ID**: internal-159
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/159-fix-outstanding-cwf-manage-issues
- **Template Version**: 2.1

## Goal
Execute FR1/FR2/FR4 per d-implementation-plan.md (FR3 deferred). Order FR4 → FR1 → FR2.

## Actual Results

### FR4 — `git_capture` + backtick conversion
- **Planned**: shared `git_capture` via `open '-|'` fork-and-reopen-STDERR; convert `find_git_root` and `cmd_list_releases`.
- **Actual**: added `git_capture(@argv)` (`.cwf/scripts/cwf-manage`) — `open my $fh, '-|'`, child reopens STDERR→`/dev/null` then `exec('git', @argv) or POSIX::_exit(127)`, parent drains to EOF before `close`, returns `(\@lines, $? >> 8)`. Added `use POSIX ()`. `find_git_root` and `cmd_list_releases` now call it; `$source` passed as a list element (shell-string interpolation removed). `resolve_ref`/`resolve_sha` left untouched.
- **Deviation**: none from d (d already superseded c-design D4's IPC::Open3 with the fork pattern). One in-flight fix: the first draft had a bare `POSIX::_exit(127)` after `exec`, which triggered perl's "Statement unlikely to be reached" warning; collapsed to `exec(...) or POSIX::_exit(127)` (one statement) — warning gone, confirmed via direct run.

### FR1 — `git_describe_version` + version/ref write
- **Planned**: derive `cwf_version` from `git describe --tags --always` of the resolved SHA (fallback to `$sha`); `cwf_ref` ← requested `$ref`.
- **Actual**: added `git_describe_version($clone_dir, $sha)` (calls `git_capture`, returns `$sha` on non-zero exit / empty). `cmd_update` version-write: `cwf_version = git_describe_version($clone_dir, $sha)`, `cwf_ref = $ref`. No other version-file fields changed.
- **Deviation**: none.

### FR2 — `--dry-run` + unknown-arg + help
- **Planned**: thread `$dry_run` through `_apply_recorded_perms`; `cmd_fix_security` strips `--dry-run` then rejects leftovers; `[dry-run]` prefix; dry-run summary distinct from `validate: OK`; document in `cmd_help`.
- **Actual**: `_apply_recorded_perms` gained a 4th `$dry_run` param — when set, the would-be repair is recorded and `chmod` skipped (existence/sha256 gates unchanged; `apply_exact_perms_or_die` calls it without the param → unaffected). `cmd_fix_security` parses global `@ARGV` (strip `--dry-run`, `die_msg` on any leftover), prints `would chmod`/`[dry-run]` lines, prints `[dry-run] … would repair N file(s); 0 unfixable (no changes made)` and exits 0 when only would-be repairs exist, exits 1 on genuine unfixables. `cmd_help` documents `fix-security [--dry-run]` + an example.
- **Deviation**: none.

### FR5 — integrity refresh
- `sha256sum .cwf/scripts/cwf-manage` → `1dc8cb06…30972`; written to `.cwf/security/script-hashes.json` `cwf-manage.sha256`. `cwf-manage validate` → OK.

### Tests written
- `t/cwf-manage-git-capture.t` (new): 6 subtests — `git_capture` success/failure+stderr-suppression; `git_describe_version` exact-tag / long-form / no-tags-SHA / bad-committish-fallback.
- `t/cwf-manage-fix-security.t`: +3 subtests — dry-run no-mutation (exit 0, no `validate: OK`), sha-mismatch surfaced under dry-run (exit 1, no mutation), unknown-arg fail-closed (`bogus`; `--dry-run extra` rejects only `extra`).
- `t/cwf-manage-update-end-to-end.t`: +2 subtests — `latest` → `cwf_version`=highest tag, `cwf_ref`=latest; SHA-on-a-tag → `cwf_version`=tag, `cwf_ref`=SHA (and NOT the bare SHA).

### Validation results
- Full suite: `prove -lr t/` → **48 files, 527 tests, all pass**.
- `cwf-manage` suite: 7 files, 61 tests, pass (incl. `cwf-manage-list-releases.t` unchanged — AC10 knock-on).
- `perlcritic --single-policy InputOutput::ProhibitBacktickOperators .cwf/scripts/cwf-manage` → `source OK` (AC7).
- `cwf-manage validate` → OK (AC9).
- Smoke tests: `fix-security --dry-run` previews + exit 0; `fix-security bogus`/`--dry-run extra` → exit 1 with `unknown argument`.

## Deviation: unrelated working-tree changes (not committed by this task)
`COMMANDS.md` and `DESIGN.md` carry uncommitted edits (swapping `sed`-based cwf-extract guidance for grep+read) that appeared during the session and are **out of scope** for Task 159. They were deliberately **excluded** from this phase's commit (only `cwf-manage`, `script-hashes.json`, and the three test files were staged). Flagged to the maintainer for separate handling.

## Security Review

**State**: no findings

Note on classification: the `cwf-security-reviewer-changeset` subagent emitted its `no findings` sentinel after its analysis prose rather than on the first line (the known reasoning-model behaviour tracked in BACKLOG: "cwf-security-reviewer-changeset sentinel-first contract not honoured"). The body contains zero numbered findings and an explicit standalone `no findings` line, so State is recorded as `no findings` (explicit body-scan, not a silent default).

Verbatim subagent verdict:
> no findings
> The git-capture conversion removes a shell-string interpolation of `$source` (FR4) and replaces it with a list-form `exec('git', @argv)` that never reaches `/bin/sh`; the `--dry-run` addition preserves the existence/sha256 integrity gates before skipping only the `chmod`, and unknown args fail closed. Reviewed source at `.cwf/scripts/cwf-manage` (git_capture, find_git_root, cmd_list_releases, git_describe_version, _apply_recorded_perms, cmd_fix_security) and both test files.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
Extracting `git_capture` first (FR4) made the FR1 version write a one-line wiring delta atop an already-unit-tested primitive. The `POSIX::_exit`-after-`exec` warning is a reminder that a forked child's bail-out must be a single statement perl can see as terminal. See j-retrospective.md.
