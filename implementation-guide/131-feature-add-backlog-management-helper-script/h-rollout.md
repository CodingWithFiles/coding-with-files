# Add backlog management helper script - Rollout
**Task**: 131 (feature)

## Task Reference
- **Task ID**: internal-131
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/131-add-backlog-management-helper-script
- **Template Version**: 2.1

## Goal
Dogfood the new helper against the live BACKLOG.md and CHANGELOG.md, surfacing any rough edges and capturing the immediate cleanup opportunities.

## Deployment Strategy
Internal developer-tool change — "deployment" means the helper is on disk, registered in `script-hashes.json`, and discoverable. No services to roll out.

## Pre-deployment Checklist
- [x] `prove t/` clean — 399 tests pass (398 + 1 BACKLOG-006 warning subtest added during rollout).
- [x] `cwf-manage validate` clean.
- [x] `backlog-manager validate` exits 0 against live files.
- [x] `chmod 0500 .cwf/scripts/command-helpers/backlog-manager`.
- [x] `script-hashes.json` registers `backlog-manager` (script) and `CWF::Backlog` (lib); refreshes `template-copier-v2.1` and `CWF::Common` after `generate_slug` lift.

## Rollout Activities

### 1. Add `BACKLOG-006` validator rule (warning, non-fatal)

Reasoning (from user): "we should ideally never have struck-through items in the backlog, and we should warn on struck-through items".

Implementation:
- `validate_backlog` flags `struckthrough_completed` and `struckthrough_tick` sections with `severity => 'warning'`.
- `cmd_validate` partitions errors and warnings; emits `[CWF] WARN:` for warnings, `[CWF] ERROR:` for errors. Warnings do not affect exit code.
- Test added in `t/backlog.t` (BACKLOG-006: severity warning, message hints migration).

### 2. Migrate the two existing struckthrough entries

The live BACKLOG had two entries that the validator tolerated but the new BACKLOG-006 rule would warn on. Migrated via `/tmp/task-131/migrate.pl` (one-shot Perl substitution; not committed):

| Before (struckthrough) | After (canonical marker) |
|------------------------|--------------------------|
| `## ~~Task: Standardize Task Context Inference Output Format~~ ✓ COMPLETED` (line 659–799, ~140 lines incl. body) | `<!-- Completed: "Standardize Task Context Inference Output Format" — Task 37 (2026-02-06) -->` (1 line) |
| `## ✓ Task: Fix CWF Commands to Work from Any Directory` (line 1287–1353, ~67 lines incl. body) | `<!-- Completed: "Fix CWF Commands to Work from Any Directory" — Task 36 (2026-02-06) -->` (1 line) |

Net BACKLOG.md trim: ~206 lines removed (the bodies were historical, captured in commit history of Tasks 36/37).

### 3. Add follow-up entries via `backlog-manager add` (dogfood)

Two follow-ups identified during this task's plan-review subagent run:

```
backlog-manager add --priority=Low --task-type=chore \
  --title="Resolve symlinks in validate_path_allowlist" \
  --status="Follow-up from Task 131" \
  --identified-in="Task 131 c-design-plan plan-review (security)" \
  --body-file=t/fixtures/backlog-manager/body1.md

backlog-manager add --priority=Low --task-type=chore \
  --title="Close TOCTOU window in atomic_write_text via O_NOFOLLOW" \
  --status="Follow-up from Task 131" \
  --identified-in="Task 131 c-design-plan plan-review (security)" \
  --body-file=t/fixtures/backlog-manager/body2.md
```

Body files were placed under `t/fixtures/` (path-allowlist-permitted) for the `add` invocations, then deleted. Both calls exited 0; subsequent `validate` exits 0.

### 4. Rough edges surfaced and fixed

- **`cmd_add` produced sections without a leading blank line**, so the serialised output was `---\n## Task:` instead of the project-conventional `---\n\n## Task:`. Fixed by prepending `\n` to `raw_lines` in `cmd_add`. SHA refreshed.
- **Body files containing their own `**Identified in**:` line, when paired with the `--identified-in` flag, produced duplicate trailers**. Cleaned up post-hoc via Edit; no code change. Worth a future enhancement: `cmd_add` could detect and refuse the duplication.

### 5. Hashes refreshed (post-rollout edits)

- `backlog-manager`: `b30965038f…`
- `CWF::Backlog`: `f6ab004c29…`

## Monitoring
None — internal helper. Future invocations of `backlog-manager validate` (or eventually `cwf-manage validate` if the integration follow-up lands) are the monitoring surface.

## Rollback Plan
Single-file revert. The helper is self-contained:

```
git revert <task-131-squash-sha>
```

No external state, no dependencies on the helper from other tooling yet. The lift of `generate_slug` to `CWF::Common` is the only cross-cutting change; reverting puts it back in `template-copier-v2.1` and re-imports the old test path.

## Rollback Triggers
- `validate` produces false positives that block legitimate BACKLOG edits.
- `retire`'s two-file write atomicity proves insufficient under realistic concurrent-edit scenarios.
- Performance degradation against larger BACKLOG/CHANGELOG (current files are small; budget is generous).

None observed.

## Outcome

- Helper available, registered, validated.
- BACKLOG cleaned of struckthrough format inconsistencies (-206 lines).
- Two follow-up entries added via the helper itself (positive dogfood).
- One small `cmd_add` formatting bug found and fixed during rollout.
- Test count: 338 → 399 (+61).

## Status
**Status**: Finished
**Next Action**: /cwf-maintenance
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Pass 2 Results

The Pass 1 rollout shipped the helper with the marker-tombstone model. The user rejected that model on review; Pass 2 of the workflow rebuilt the helper around `### Retired Backlog Items` blocks (BACKLOG = active only, retire moves entries). The new rollout step is the bulk migration of the 61 legacy HTML-comment lines that remain in BACKLOG.md from before this task.

### 1. Migration of 61 legacy markers

Built a one-shot migration script at `/tmp/task-131/migrate-markers.pl` (not committed). Three passes:

1. Drop every line matching `^<!--\s*(?:Completed|Removed|Coalesced|Reason|Produced)\b`.
2. Collapse consecutive blank lines (max 2).
3. Remove orphan `---` separators (consecutive separators with no `## Task:` / `## Bug:` between them) plus another blank-line collapse afterwards.

Snapshot saved to `/tmp/task-131/BACKLOG.md.before` for safety. The migration reduced BACKLOG.md from 1646 to 1482 lines (-164 lines net; the 61 markers themselves plus orphan separators and double-blank lines).

The 61 markers' content was reviewed before deletion. Two categories:
- **Pointers**: `<!-- Completed: "Title" — Task N (date) -->` — pure cross-references; the implementing task's CHANGELOG entry already documents the work. Information-preserving deletion (git history retains the marker text).
- **Markers with reasoning**: about half carry an explanation after the date (e.g. `Task 128: all 5 shell helpers were dead/trivial; deleted, with the one live caller (cwf-config skill) inlined`). Almost all of these are summaries of facts already documented in the implementing task's CHANGELOG entry; the few that aren't are recoverable via `git blame` on BACKLOG.md or `git log -- BACKLOG.md`. No `<!-- Note: -->` annotations were back-filled to CHANGELOG entries — the existing CHANGELOG was judged self-contained and the per-marker prose did not warrant the duplication.

### 2. Two `^####` headings demoted

After the marker strip, `backlog-manager validate` flagged BACKLOG-006 against two `#### ` headings inside one entry's body (the "interface-based dispatch pattern" entry):

```
1064:#### Architecture          → **Architecture**:
1127:#### Usage in Unified Script → **Usage in Unified Script**:
```

Demoted to bold-paragraph form per the BACKLOG-006 message hint ("rephrase or wrap in code fence"). No semantic loss — these were just visual section headers inside a freeform body.

### 3. Validation post-migration

```
$ backlog-manager validate
[CWF] validate: OK
$ cwf-manage validate
[CWF] validate: OK
$ prove t/
Files=36, Tests=408, Result: PASS
```

AC1 (live BACKLOG/CHANGELOG passes validate) now passes. Lifted the `TODO {}` wrappers in `t/backlog.t::validate_backlog: live BACKLOG passes` and `t/backlog-manager.t::AC1` — they're real pass assertions now, not deferred ones.

### 4. No code/perm/hash changes in this rollout

The Pass 2 helper and library SHAs registered at the end of f-implementation-exec are still current. `cwf-manage validate` confirms.

### 5. Outcome

- BACKLOG.md migrated from 1646 → 1482 lines (-164 lines, -10%); zero HTML comments, zero struck-through entries, zero `^####` body lines.
- `backlog-manager validate` enforces the contract going forward; any future regression is caught by `prove t/backlog-manager.t::AC1` and `cwf-manage validate`.
- Test count: 408 → 408 (TODO wrappers lifted in place; same assertion count).
- The existing follow-up entries from Pass 1 ("Resolve symlinks in validate_path_allowlist", "Close TOCTOU window in atomic_write_text via O_NOFOLLOW") remain in BACKLOG; both are still relevant for the new design.

### Pass 2 Rollback

Single-snapshot revert: `cp /tmp/task-131/BACKLOG.md.before BACKLOG.md` restores the file. The migration script does not touch any other file. For the wider helper redesign, `git revert` of the Pass 2 squash commit puts the marker model back; the resurrected `cmd_retire` and library helpers keep working unmodified.
