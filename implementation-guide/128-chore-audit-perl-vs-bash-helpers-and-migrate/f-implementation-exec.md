# Audit Perl-vs-Bash helpers and migrate - Implementation Execution
**Task**: 128 (chore)

## Task Reference
- **Task ID**: internal-128
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/128-audit-perl-vs-bash-helpers-and-migrate
- **Template Version**: 2.1

## Goal
Execute the deletions and inline planned in d-implementation-plan.md, validating the integrity surface and `/cwf-config` smoke per e-testing-plan.md.

## Actual Results

### Step 1: Pre-flight verification
- **Planned**: Re-confirm caller surface; baseline `cwf-manage validate` and `prove t/validate-security-coverage.t`.
- **Actual**:
  - `cwf-manage validate` → "[CWF] validate: OK" (clean baseline).
  - `prove t/validate-security-coverage.t` → all subtests PASS.
  - `git ls-files | xargs grep -l '<5 helper names>'` excluding historical/archival paths → only `.claude/skills/cwf-config/SKILL.md` as active caller. Matches plan.
- **Deviations**: None.

### Step 2: Inline the live caller
- **Planned**: Replace the helper invocation on line 24 of `.claude/skills/cwf-config/SKILL.md` with inlined Bash.
- **Actual**: Edited line 24 of `.claude/skills/cwf-config/SKILL.md`:
  - Before: `` Run `.cwf/scripts/command-helpers/cwf-load-autoload-config` using the Bash tool to load current autoload configuration. ``
  - After: `` Run `cat .cwf/autoload.yaml 2>/dev/null || echo "No autoload config found"` using the Bash tool to load current autoload configuration. ``
- **Deviations**: None.

### Step 3: Delete helpers + manifest update atomically
- **Planned**: 5 `git rm`s + 5-entry removal from `script-hashes.json` + bump `last_updated`, all staged together.
- **Actual**:
  - `git rm` of all five helpers under `.cwf/scripts/command-helpers/`.
  - `script-hashes.json`: removed five entries from `scripts` map (pre: 38 keys, post: 33 keys); bumped `last_updated` to `2026-05-06`.
  - JSON parse + stale-entry check via `/tmp/task-128/check-json.pl`: "OK: 33 entries in scripts map / OK: all 5 stale entries removed from scripts".
  - All five rm-deletions and the manifest edit live in the same working-tree state, ready for a single commit (no intermediate validation gap).
- **Deviations**: None. The plan's "alphabetised, one entry at a time" Edit guidance was simplified to a single contiguous block delete — all five entries were already adjacent in the file (alphabetised by `cwf-find/load-…`), so a single Edit was clean and idempotent.

### Step 4: Validate
- **Planned**: `cwf-manage validate` clean; `prove t/validate-security-coverage.t` GREEN; full `prove t/` GREEN.
- **Actual**:
  - `cwf-manage validate` → "[CWF] validate: OK".
  - `prove t/validate-security-coverage.t` → all subtests PASS (counts auto-adjusted as predicted).
  - `prove t/` → 33 files, 325 tests, all PASS.
- **Deviations**: None.

### Step 5: End-to-end smoke
- **Planned**: Invoke the inlined Bash and confirm output equivalent to the deleted helper.
- **Actual**: Executed `cat .cwf/autoload.yaml 2>/dev/null || echo "No autoload config found"`; output is the full autoload YAML (utils, templates, skills sections), identical to what the helper emitted.
- **Deviations**: Smoke was at the Bash level rather than driving `/cwf-config list` end-to-end — the skill's mandatory-context invocation runs the same Bash command, so this is functionally equivalent and avoids the manual back-and-forth of a full skill invocation.

### Step 6: Close BACKLOG entry
- **Planned**: Remove the "Audit Perl-vs-Bash helper scripts and migrate where feasible" entry from `BACKLOG.md`.
- **Actual**: Replaced the multi-paragraph entry with a one-line `<!-- Completed: ... -->` marker mirroring the pattern used for Task 125 immediately below it.
- **Deviations**: None.

## Files Changed
- `.claude/skills/cwf-config/SKILL.md` — inline replacement (1 line).
- `.cwf/scripts/command-helpers/cwf-find-task-numbering-structure` — deleted.
- `.cwf/scripts/command-helpers/cwf-load-autoload-config` — deleted.
- `.cwf/scripts/command-helpers/cwf-load-existing-tasks` — deleted.
- `.cwf/scripts/command-helpers/cwf-load-project-config` — deleted.
- `.cwf/scripts/command-helpers/cwf-load-status-sections` — deleted.
- `.cwf/security/script-hashes.json` — 5 entries removed; `last_updated` bumped.
- `BACKLOG.md` — entry replaced with completion marker.

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met (audit decisions documented; all approved deletions done; manifest refreshed; `cwf-manage validate` GREEN; `CWF::Validate::PerlConventions` not affected since we deleted shell — no Perl files added)
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: error

error: changeset exceeds 500-line review cap; split the change or perform manual review

Note for human reviewer: the cap was hit at 1422 lines because Task 127 has not yet been merged to main (its 4 commits sit between this branch's merge-base and HEAD), inflating the diff. Task 128's actual delta on top of 127 is ~50 lines: five trivial shell-helper deletions, one SKILL.md line edit, and a five-entry pruning of `script-hashes.json`. The Task 127 portion was security-reviewed in its own exec phase. Manual review of Task 128's delta against threat categories (a)–(e):
- (a) bash injection: no shell command construction; the inlined Bash is a literal string with no interpolation.
- (b) `-z`/input validation in Perl: no Perl helpers added or modified.
- (c) prompt injection via `{arguments}`: no SKILL `{arguments}` flow added or changed.
- (d) env-var handling: no env-var reads added or modified.
- (e) pattern risk: the inlined `cat .cwf/autoload.yaml 2>/dev/null || echo …` is safe here because the path is a string literal; reusing the pattern with an interpolated path would be (a)-risky — caller would need to validate.

## Lessons Learned
*To be captured during retrospective*
