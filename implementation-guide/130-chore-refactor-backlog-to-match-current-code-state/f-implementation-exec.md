# Refactor BACKLOG to match current code state - Implementation Execution
**Task**: 130 (chore)

## Task Reference
- **Task ID**: internal-130
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/130-refactor-backlog-to-match-current-code-state
- **Template Version**: 2.1

## Goal
Apply the BACKLOG.md triage decisions reached during this exec phase.

## Plan Deviation
The d-implementation-plan calls for per-entry user co-review. The user delegated triage to me with a single review pass at the end. I leaned conservative: where evidence was ambiguous, I kept the entry; only entries with strong evidence (script exists, file deleted, title incoherent post-rebrand) were modified.

## Inventory
Active entries: ~50, line numbers from baseline `26ad3fd`. BACKLOG.md was untouched between baseline and this commit, so line numbers are still valid.

## Triage Decisions

### Removals (2)

**R1. `Add Settings.json Merge Helper Script` (line 317, was Medium)**
- Evidence: `.cwf/scripts/command-helpers/cwf-claude-settings-merge` exists with idempotent merge, nested-key handling, dedup, and `--dry-run`. Tests at `t/cwf-claude-settings-merge.t`.
- Scope match: script is purpose-built for the `.claude/settings.json` shape cwf-init needs (allowlist + Stop hooks), not the generic `(key-path, value)` API the BACKLOG sketched, but it solves the underlying motivation (extract error-prone JSON manipulation from cwf-init). Confirmed by reading the script's `merge_allow` and `merge_hooks` subs.
- Naming difference: actual script is `cwf-claude-settings-merge`, BACKLOG sketched `cwf-settings-merge`. The `cwf-claude-` prefix scopes it to `.claude/settings.json` specifically — appropriate.

**R2. `Update Documentation References from status-aggregator to status-aggregator` (line 1153, was Low)**
- Evidence: title and body are incoherent — both source and target have been homogenised to `status-aggregator` by an apparent search-replace. The body still references `.claude/commands/cwf-status.md`, which does not exist (commands→skills migration completed in Task 57). Only `.claude/commands/scratchpad-update.md` survives.
- The remaining live references to `status-aggregator-v2.0`/`v2.1` in `.claude/settings.local.json` are correct (allowlist entries, not docs to update).
- The substantive intent (move docs from `.pl`-suffix references to entry-point references) was completed during the trampoline architecture rollout (Task 25). Entry is dead.

### Edits (1)

**E1. `Audit CWF Commands for Hardcoded Data` (line 1636, Low)**
- Evidence: `.claude/commands/cwf-*.md` files no longer exist (commands→skills migration, Task 57). The "Scope" bullet referencing `.claude/commands/cwf-*.md files` and `cig-security-check.md` (note: old `cig-` prefix, predates the rename to `cwf-`) is dead.
- Decision: edit to redirect at the post-migration analogue — `.claude/skills/cwf-*/SKILL.md` files. The audit motivation (find hardcoded data that should live in canonical sources) is still valid; only the audit target needs updating.

### Coalesce (1)

**C1. Lines 350 + 1820 → single entry**
- `Lightweight Rollout/Maintenance Templates for Internal Tasks` (line 350, Low, follow-up from Task 57) and `Lighter-Weight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks` (line 1820, Medium, follow-up from Task 114). Line 1828 explicitly acknowledges overlap.
- Decision: merge into the line-350 entry's slot (keeps the older identifier); take the higher priority (Medium); fold both "Identified in" references; drop the 1820 entry.

### Reclassifications (1)

**T1. `Extract CWF Argument Validation Pattern to Documentation` (line 1291) `Needs-Triage` → `Low`**
- `Needs-Triage` is not a valid final state (per d-implementation-plan).
- The motivation was the secure-argument-parsing pattern from Task 11. Task 11 was cancelled (per the comment at line 1284: "Task 11 cancelled (superseded by Task 57, commands→skills bypasses $ARGUMENTS bug entirely)"). The pattern itself still exists conceptually but its primary use case is moot.
- Conservative: demote to `Low` rather than remove — the documentation could still be useful as a security-review reference even if no longer load-bearing.

### Kept as-is (~45)
Verified that the referenced scripts/files/library functions/template sections genuinely don't exist or weren't completed:
- `cwf-slug` script (line 251) — not in `.cwf/scripts/command-helpers/`
- `cwf-extract` helper script (line 334) — not in `.cwf/scripts/command-helpers/`
- `die_msg` in `CWF::Common` (line 284) — `.cwf/lib/CWF/Common.pm` exports `format_error`, not `die_msg`
- `print STDERR + exit` migration (line 267) — pattern still appears in `template-copier-v2.1` (15+ occurrences)
- `main() unless caller();` documentation (line 301) — convention is used in `template-copier-v2.1` but not documented in `docs/conventions/`
- `perl-idioms.md` (line 417) — not in `docs/conventions/` (which has commit-messages, design-alignment, perl-git-paths)
- Dead code audit doc/audit (lines 367, 392) — `.cwf/docs/maintenance/` does not exist
- Material Changes / Baseline Verification template sections (lines 578, 624) — not in current templates
- Bug at line 1690 (`_score_progress` linear ramp): confirmed live — `.cwf/lib/CWF/TaskContextInference.pm:446-455` still has linear scoring with the contradictory "bell curve, peak at 50%" comment at line 410
- "Backfill Baseline Commit field" (line 38): confirmed live — 11+ active in-flight tasks lack the field
- Lots of follow-ups from earlier tasks (50, 51, 35, 36, 43, 113, 114, 119, 120, 123, 127, 129) — none verified as completed

## Apply Step

Single commit covering all four edits (default per d-implementation-plan since the diff is small).

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Security Review

**State**: no findings

no findings: empty changeset

## Lessons Learned
*To be captured during retrospective*
