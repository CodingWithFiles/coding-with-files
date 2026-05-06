# Audit Perl-vs-Bash helpers and migrate - Implementation Plan
**Task**: 128 (chore)

## Task Reference
- **Task ID**: internal-128
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/128-audit-perl-vs-bash-helpers-and-migrate
- **Template Version**: 2.1

## Goal
Resolve the unmotivated Perl-vs-shell split under `.cwf/scripts/command-helpers/` by deciding per helper whether to migrate to Perl, keep as shell, or delete — then carry out the decisions.

## Discovery: Per-Helper Audit

Each helper is small enough to quote in full. Caller column was checked with `git ls-files | xargs grep -l '<name>'`, restricting hits to active code (skills/, scripts/, lib/, hooks/) and excluding `BACKLOG.md`, `CHANGELOG.md`, historical task docs, and `script-hashes.json` self-references.

| # | Helper | LOC | Logic | Active callers | Decision |
|---|---|---|---|---|---|
| 1 | `cwf-find-task-numbering-structure` | 13 | `find … \| grep -E … \| sort` | none | **Delete** |
| 2 | `cwf-load-autoload-config` | 12 | `cat`-or-fallback for `.cwf/autoload.yaml` | `.claude/skills/cwf-config/SKILL.md` (one line) | **Delete + inline** |
| 3 | `cwf-load-existing-tasks` | 18 | `find \| head \| while read \| grep -n \| sed` | none | **Delete** |
| 4 | `cwf-load-project-config` | 12 | `cat`-or-fallback for `implementation-guide/cwf-project.json` | none | **Delete** |
| 5 | `cwf-load-status-sections` | 20 | `find -exec grep -l \| while read \| grep -A 3` | none | **Delete** |

**Rationale (uniform across all five)**: None of these helpers carries logic that justifies Perl ceremony — no path-emitting git invocation, no option parsing, no branchy error handling, no shared state. The strongest argument for migration in the backlog (testability, `die_msg`, `CWF::Options`, `use strict`) does not apply: there is nothing to test, nothing to validate, and no error paths to standardise. Migrating each to Perl would replace 1–4 lines of shell with 15+ lines of boilerplate (`#!/usr/bin/perl -CDSL`, pragmas, `FindBin`, `die_msg`) for no behavioural gain.

The stronger application of CWF's simplicity principle ("the best part is no part", `workflow-steps.md#planning`) is to delete the four unused helpers outright and inline the one-line `cat`-or-fallback that the `cwf-config` skill calls. This eliminates the language split rather than papering over it, and shrinks the integrity-tracked surface by five entries.

**Why these are dead**: helpers 1, 3, 4, 5 were created as part of an earlier autoload/config-discovery design (visible in implementation-guide/101 and implementation-guide/59); the design was never wired up by any skill that survived to v2.x. They appear only in `script-hashes.json` (registered for tampering detection by Task 125) and in historical task docs. Task 125 deliberately did not delete them — its scope was strictly integrity-tracking expansion. This task closes the loop.

## Files to Modify

### Primary Changes
- `.cwf/scripts/command-helpers/cwf-find-task-numbering-structure` — **delete**
- `.cwf/scripts/command-helpers/cwf-load-autoload-config` — **delete**
- `.cwf/scripts/command-helpers/cwf-load-existing-tasks` — **delete**
- `.cwf/scripts/command-helpers/cwf-load-project-config` — **delete**
- `.cwf/scripts/command-helpers/cwf-load-status-sections` — **delete**
- `.claude/skills/cwf-config/SKILL.md` — replace the `cwf-load-autoload-config` invocation (line 24) with an inlined `cat .cwf/autoload.yaml 2>/dev/null || echo "No autoload config found"` Bash invocation.

### Supporting Changes
- `.cwf/security/script-hashes.json` — remove the five `scripts.<name>` entries; bump `last_updated`.
- `BACKLOG.md` — remove the "Audit Perl-vs-Bash helper scripts and migrate where feasible" entry (this task fulfils it). Standard CWF practice: a task closes its own backlog entry.

### Out of Scope (no change)
- `t/validate-security-coverage.t` — counts files dynamically (`plan tests => scalar(@top_level) + 1`); no edit needed. After deletion the test auto-adjusts from 24 to 19 top-level helpers.
- All other shell scripts (`install.bash`, install bootstrap helpers under `scripts/`, hooks). The backlog explicitly excludes these — they predate the Perl runtime guarantee.
- `CWF::Validate::PerlConventions` — already only constrains Perl files; no rule changes needed.
- `CHANGELOG.md` Task 125 entry — deliberately preserved as historical record of what Task 125 did. The file references that no longer exist describe the past, not the present.
- Task 125's `j-retrospective.md` (which suggested migration as the future option) — historical; this task chose deletion after discovery, captured in the rationale above.

## Implementation Steps

### Step 1: Pre-flight verification
- [ ] Re-confirm caller surface for all 5 helpers immediately before deletion. Run `git ls-files | xargs grep -l '<name>'` for each helper; spot-check skills/ and .cwf/ directories. Document any new caller as a stop-the-line condition.
- [ ] Capture pre-state of `t/validate-security-coverage.t` runs (expected: GREEN at 22 + 7 + 2).
- [ ] Confirm `cwf-manage validate` is GREEN before any change (so any post-change failure is attributable).

### Step 2: Inline the only live caller
- [ ] Edit `.claude/skills/cwf-config/SKILL.md` line 24:
  - **Before**: ``Run `.cwf/scripts/command-helpers/cwf-load-autoload-config` using the Bash tool to load current autoload configuration.``
  - **After**: ``Run `cat .cwf/autoload.yaml 2>/dev/null || echo "No autoload config found"` using the Bash tool to load current autoload configuration.``
- [ ] Verify the line still parses as a Mandatory-context bullet within the skill.

### Step 3: Delete the five helpers AND update the manifest atomically
**Atomicity requirement**: file deletion and manifest entry removal MUST land in the same commit. Otherwise `cwf-manage validate` fails between steps with "missing file" violations against orphaned manifest entries (the manifest is the source-of-truth for what scripts must exist; see `CWF::Validate::Security`).

Sequence:
- [ ] `git rm .cwf/scripts/command-helpers/cwf-find-task-numbering-structure`
- [ ] `git rm .cwf/scripts/command-helpers/cwf-load-autoload-config`
- [ ] `git rm .cwf/scripts/command-helpers/cwf-load-existing-tasks`
- [ ] `git rm .cwf/scripts/command-helpers/cwf-load-project-config`
- [ ] `git rm .cwf/scripts/command-helpers/cwf-load-status-sections`
- [ ] Edit `.cwf/security/script-hashes.json`: remove the five entries from `scripts` (Edit tool, one entry at a time, alphabetised); bump `last_updated` to today (2026-05-05).
- [ ] Verify JSON parses via probe script `/tmp/task-128/check-json.pl` (no inline scripts, per memory).
- [ ] Stage manifest with `git add .cwf/security/script-hashes.json` together with the `git rm`s above — single working-tree state, single commit.

### Step 4: Validate
- [ ] Run `.cwf/scripts/cwf-manage validate` → expect 0 violations.
- [ ] Run `prove t/validate-security-coverage.t` → expect GREEN. Test counts dynamically; no test edit required.
- [ ] Run full `prove t/` to catch any other regressions.

### Step 5: End-to-end smoke
- [ ] Invoke `/cwf-config list` with the inlined Bash and confirm the autoload config is still loaded into context (i.e., the skill produces equivalent output to before).

### Step 6: Close the BACKLOG entry
- [ ] Remove the "Audit Perl-vs-Bash helper scripts and migrate where feasible" entry from `BACKLOG.md` (lines ~32–58). This task fulfils it — leaving it open invites duplicate effort.

## Code Changes

### `.claude/skills/cwf-config/SKILL.md` (line 24)
**Before**:
```
- Run `.cwf/scripts/command-helpers/cwf-load-autoload-config` using the Bash tool to load current autoload configuration.
```
**After**:
```
- Run `cat .cwf/autoload.yaml 2>/dev/null || echo "No autoload config found"` using the Bash tool to load current autoload configuration.
```

### `.cwf/security/script-hashes.json`
Remove keys (in `scripts`): `cwf-find-task-numbering-structure`, `cwf-load-autoload-config`, `cwf-load-existing-tasks`, `cwf-load-project-config`, `cwf-load-status-sections`. Bump `last_updated`.

### `t/validate-security-coverage.t`
No edit required. Counts files dynamically (`plan tests => scalar(@top_level) + 1`); the test auto-adjusts after the five files are deleted.

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Defer-list watch: do NOT defer any of the five deletions. Partial deletion (e.g. "deleted 3, will do other 2 next task") leaves the integrity manifest in a broken state and undermines the audit's outcome.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
