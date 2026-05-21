# move PERL5OPT to project-local settings - Testing Plan
**Task**: 153 (bugfix)

## Task Reference
- **Task ID**: internal-153
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/153-move-perl5opt-to-project-local-settings
- **Template Version**: 2.1

## Goal
Validate that `merge_env` writes `env.PERL5OPT` into project `.claude/settings.json` with correct add-if-absent / warn-on-mismatch / type-guard semantics, that the docs/warning no longer point at `~/.claude/settings.json`, and that integrity (`cwf-manage validate`) stays clean.

## Test Strategy
### Test Levels
- **Unit**: `merge_env` branch coverage, extending `t/cwf-claude-settings-merge.t` (reuse its `build_fixture` tempdir harness).
- **Integration**: run `cwf-claude-settings-merge` end-to-end against a temp settings.json; assert file content + report line.
- **Regression**: existing `t/` suite green (esp. `t/common.t` `check_perl5opt`, `t/cwf-claude-settings-merge.t` allowlist/hook cases); `cwf-manage validate` clean.
- **Doc/static**: repo-wide grep for surviving `~/.claude/settings.json` PERL5OPT references.

### Coverage Targets
- `merge_env`: 100% of the four branches + sibling-preservation.
- No regression in the helper's existing allowlist/hook behaviour.
- Zero surviving `~/.claude/settings.json` PERL5OPT references outside `implementation-guide/` and `CHANGELOG.md`.

## Test Cases
### Functional (unit — `merge_env`, in `t/cwf-claude-settings-merge.t`)
- **TC-1 — absent → adds**: Given settings with no `env`. When `merge_env` runs. Then `env.PERL5OPT == "-CDSLA"`, returns 1, no warning.
- **TC-2 — equal → no-op**: Given `env.PERL5OPT == "-CDSLA"`. When run. Then unchanged, returns 0, no warning.
- **TC-3 — mismatch → warn + untouched**: Given `env.PERL5OPT == "-CDSL"`. When run. Then value stays `-CDSL`, returns 0, `[CWF] WARN:` emitted naming both values.
- **TC-4 — non-hash `env` → warn + untouched**: Given `env` is a string/array (not object). When run. Then `env` unchanged, returns 0, `[CWF] WARN:` emitted.
- **TC-5 — non-scalar `PERL5OPT` → warn + untouched**: Given `env.PERL5OPT` is an array/object. When run. Then unchanged, returns 0, `[CWF] WARN:` emitted.
- **TC-6 — sibling keys preserved**: Given `env` has another key (e.g. `FOO=bar`) and no `PERL5OPT`. When run. Then `PERL5OPT` added **and** `FOO` still present.

### Functional (integration — end-to-end helper run)
- **TC-7 — fresh project gains PERL5OPT**: Given a temp git repo with a manifest and no `.claude/settings.json` (or `{}`). When `cwf-claude-settings-merge` runs. Then the written file contains `env.PERL5OPT=-CDSLA` alongside merged allowlist/hooks, and the report line includes the env count (`… , 1 env keys`).
- **TC-8 — idempotent re-run**: Given TC-7's output. When the helper runs again. Then `env keys` added = 0 and the file is unchanged in its `env` block.
- **TC-9 — `--dry-run` warns on mismatch and writes nothing**: Given a temp settings.json with `env.PERL5OPT=-CDSL`. When run with `--dry-run`. Then the mismatch `[CWF] WARN:` fires, the previewed blob is printed, and the on-disk file is **not** modified.

### Functional (doc/static)
- **TC-10 — no surviving global references**: `git grep -nE '~/\.claude/settings\.json' -- ':!implementation-guide/' ':!CHANGELOG.md'` returns no PERL5OPT-related hits.
- **TC-11 — dogfood file is env-only**: `git show :.claude/settings.json` (staged) is exactly `{"env":{"PERL5OPT":"-CDSLA"}}` — no `permissions`/`hooks`.

### Non-Functional
- **Security**: changeset security review (f- and g-phase) — no new findings expected; the written value is the compile-time constant `-CDSLA` (FR4(e)).
- **Integrity**: `cwf-manage validate` reports no new violations; the two hashed files (`cwf-claude-settings-merge`, `CWF::Common`) have refreshed `sha256` entries.
- **Reliability**: unparseable settings.json still dies cleanly via existing `read_settings` (no new handling); confirmed by an existing helper test or a targeted case.

## Test Environment
- POSIX, system Perl, core modules only. Live env may carry `PERL5OPT=-CDSLA`; unit tests for `merge_env` operate on in-memory hashes so are env-independent. `check_perl5opt` regression in `t/common.t` already controls `$ENV{PERL5OPT}` in-child.
- `cwf-claude-settings-merge.t` `build_fixture` provides a temp git repo + manifest; no writes to the real repo config.

## Validation Criteria
- [ ] TC-1…TC-11 pass.
- [ ] `prove t/` green (full suite, no regression).
- [ ] `cwf-manage validate` clean (modulo pre-existing unrelated `cwf-plan-reviewer-misalignment.md` permission drift).
- [ ] Security review: no new findings.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Testing plan complete; ready for exec on user approval.

## Lessons Learned
The merge_env branch coverage (TC-1…TC-6) was realised as `t/cwf-claude-settings-merge.t` TC-U7…TC-U13; the doc zero-hit grep (TC-10) doubled as the regression guard. Full learnings in `j-retrospective.md`.
