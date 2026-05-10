# Add backlog management helper script - Retrospective
**Task**: 131 (feature)

## Task Reference
- **Task ID**: internal-131
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/131-add-backlog-management-helper-script
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-10

## Executive Summary
- **Duration**: ~3 sessions (Pass 1 ship → user rejection → Pass 2 re-plan/re-exec). Original estimate 1–2 days; actual ~2.5 days, variance +25–50%, almost entirely the Pass 2 cycle.
- **Scope**: Original — six-subcommand `backlog-manager` helper with `<!-- Completed: -->` marker tombstones for retire. Final — same six subcommands but `retire` *moves* entries out of BACKLOG into a CHANGELOG `### Retired Backlog Items` block; the marker model is gone, and 61 legacy markers were migrated out of the live BACKLOG.md as part of rollout. Validator tightened (BACKLOG-004/005/006, CHANGELOG-003) to enforce the new contract by construction.
- **Outcome**: Success. `backlog-manager validate` clean against live files; `prove t/` 408/408 PASS; BACKLOG.md slimmed 1646 → 1482 lines (-164, -10%); zero HTML comments and zero struck-through entries remain in BACKLOG. The j-retrospective skill (Step 8) can now invoke `backlog-manager retire` instead of editing the two files by hand.

## Variance Analysis

### Time and Effort
- **Estimated**: 1–2 days end-to-end; re-plan estimate (post-rejection) 1 day for simplification + migration.
- **Actual**: Pass 1 ~1 day (a–h shipped on the marker model). Pass 2 ~1.5 days (re-plan a/b/c/d/e + re-exec f/g/h + 61-marker migration). i-maintenance Skipped, j today.
- **Variance**: +25–50% from re-plan rework. The Pass 1 wf step files survived as input to the re-plan — the variance was the cost of inverting the central design decision (marker tombstone vs. move-on-retire) after implementation, not Pass 2 execution itself, which was efficient.

### Scope Changes
- **Removed (Pass 2 vs Pass 1)**: `historical` / `struckthrough_completed` / `struckthrough_tick` parser classifications; `make_completed_marker()`; `insert_changelog_bullet()`; old BACKLOG-004 (unclosed marker) and BACKLOG-005 (orphan reason).
- **Added (Pass 2 vs Pass 1)**: `_build_fence_map()` shared fence-parity helper; `find_changelog_task()`, `find_retired_subsection()`, `block_exists_in_retired()`, `append_retired_block()` mutators; generalised BACKLOG-004 (any HTML comment in BACKLOG outside fence), BACKLOG-005 (struck-through), BACKLOG-006 (`^####` in active body), CHANGELOG-003 (subsection order); `--note` flag with printable-ASCII + explicit `-->` rejection; one-shot `/tmp/task-131/migrate-markers.pl` for the 61-marker migration.
- **Surviving Pass 1 work**: section-based two-pass parser, byte-preserving `raw_lines` round-trip, on-demand metadata extraction, `generate_slug` lift to `CWF::Common`, `find_active_by_*`, `set_priority_field`, atomic two-file write pattern, `make_isolated()` test helper. The amend strategy (rather than full rewrite) saved most of the Pass 2 budget.
- **Impact**: Re-plan cycle paid for itself — Pass 2 caught a step-ordering bug (delete-mutators-before-rewriting-caller) and a classifier-name mismatch in the d-impl plan via subagent review *before* code touched. Net: zero rework in Pass 2 exec.

### Quality Metrics
- **Test Coverage**: `prove t/` 408 tests PASS (Pass 1 baseline 399; Pass 2 +9). All 17 AC subtests in `t/backlog-manager.t` PASS; library subtests in `t/backlog.t` cover the 4 new mutators + fence-parity invariant (TC-LIB-9). AC1 (live BACKLOG/CHANGELOG passes validate) wrapped in TODO during Pass 2 f/g, lifted in h after the marker migration.
- **Defect Rate**: One Pass 2 deviation noted: the printable-ASCII regex `^[\x20-\x7E]+$` accepts `-->` (each char printable). Caught by AC13b test; added explicit `die_user("--note must not contain '-->'")` second check. No defects post-rollout.
- **Performance**: `backlog-manager validate` runs in 37–40 ms on the live files (1482 + ~3000 lines). No NFR target was set; well under interactive budget.

## What Went Well
- **Re-plan amend strategy beat rewrite-from-scratch.** Identifying which Pass 1 artefacts were independent of the marker model (parser, fence-tracking, raw_lines, mutator helpers, slug lift, atomic write) and keeping them — only inverting the retire semantics + validator rules + tests — saved ~half the Pass 2 budget that a full rewrite would have cost.
- **Plan-review subagents earned their keep again.** The d-impl plan-review caught: (a) Pass 2 Step 1 originally deleted `make_completed_marker` and `insert_changelog_bullet` while `cmd_retire` still called them — re-ordered to add-fence-helper → add-mutators → rewrite-cmd_retire → trim-marker-code; (b) the d-impl text still referenced the old classifier names (`historical`, `struckthrough_*`) — corrected before f began. Both would have surfaced as broken builds in implementation; both caught pre-code.
- **Fence-parity invariant hardened by a dedicated test.** TC-LIB-9 asserts all four validator rules silent on a single fixture with `<!-- -->`, `## ~~`, `^#### `, and `### Changes` ALL inside one fenced code block. One source of truth (`_build_fence_map`) used by all four rules and the two retired-subsection mutators; the invariant test guarantees that source stays canonical.
- **Atomic two-file write semantics survived re-design.** Decision 6 (CHANGELOG first, BACKLOG second) and the dedup check via `block_exists_in_retired()` make crash-recovery a deterministic re-run — no file lock, no ledger, no out-of-band state.
- **Migration was reversible end-to-end.** `/tmp/task-131/BACKLOG.md.before` snapshot + `git revert` of the migration commit + `git revert` of the Pass 2 squash — three independent rollback points, the migration script kept throwaway.
- **Dogfood validates the design loop closes.** `backlog-manager validate` exits 0 against the live files post-migration, and the j-retrospective skill (Step 8) will invoke `backlog-manager retire` from this task forward instead of hand-editing two markdown files.

## What Could Be Improved
- **The marker-tombstone design should have surfaced the rejection earlier.** Pass 1's c-design did note the BACKLOG-as-history concern but rationalised it as cross-reference preservation. Spot-checking the proposal against the user's mental model in c-review (not just c-plan-review subagents) would have caught the rejection ~1 day earlier and saved Pass 1 exec entirely.
- **Stale numerical references in plans surfaced twice.** "47 markers" in b-requirements (live count was 61); "Step 4/8/11" in d-impl after the step-ordering fix. Both fixed via follow-up commits (`717769d`, `a76145a`) but both should have been caught by re-reading the plan end-to-end after each material edit. A "freshness check" step before each plan checkpoint commit would catch this.
- **`-->` rejection regex was a footgun.** "Printable ASCII" intuitively excludes structural markers but `^[\x20-\x7E]+$` doesn't. The fix (explicit second check) is correct but reactive. A general lesson: when validating user input against a control-character set, also enumerate the *structural* substrings being rejected.
- **i-maintenance template still doesn't fit internal helpers.** Same Skipped-with-rationale boilerplate as Tasks 119, 123, 127 — the template's uptime/SLA/incident-response framing has no purchase on developer-tool tasks. The "Lightweight Rollout/Maintenance Templates" BACKLOG entry (Medium priority) covers this; it's been waiting since Task 84.

## Key Learnings

### Technical Insights
- **Move-not-mark mental model wins for active/historical separation.** Marker tombstones look elegant (one line, preserves cross-references) but they degrade signal-to-noise: a 1646-line BACKLOG carrying 61 historical markers is substantially harder to scan than a 1482-line BACKLOG of pure active items, and the "did I already complete this?" question is now answered by two-file search instead of one. Lesson: when a system has a clear active/historical split, prefer move semantics over annotation semantics.
- **Shared fence-tracking is a parser invariant, not a per-rule concern.** Every BACKLOG validator rule and every mutator that walks the file must agree on what counts as "in a fence" — otherwise rule N flags content that mutator M placed there legitimately. A single `_build_fence_map($lines)` helper + a TC-LIB-9-style invariant test makes the parity machine-checkable. Worth replicating wherever multiple consumers share a fence-aware view of the same file.
- **Two-file atomic write via dedup-on-retry beats a lock.** "CHANGELOG first, BACKLOG second; check existing block on re-run" is simpler than `flock` + temp-file dance and recovers from any crash/interrupt by re-running the same command. Works because the operation is idempotent at the block level. Don't reach for locking until idempotency is genuinely impossible.

### Process Learnings
- **Re-plan with amend, not rewrite, when ≥50% of the existing work is design-independent.** The marker model touched the validator, retire flow, and tests but left the parser, mutators, and atomic-write infrastructure intact. Identifying that boundary in the re-plan a-task-plan section ("surviving artefacts") meant Pass 2 was a series of targeted edits, not a green-field rebuild.
- **Plan-review catches step-ordering bugs that compile-time would miss.** Both a-plan-review (47-vs-61 markers) and d-plan-review (delete-before-rewrite ordering, classifier-name mismatch) caught defects that would have cost a rebuild cycle in exec. The map/reduce subagent pattern is now load-bearing for any non-trivial task.
- **TODO-wrapped live-file assertions during Pass 2 are the right pattern for ordering rollout against test changes.** AC1 needed the live file migrated before it could pass; wrapping it in `TODO {}` during f/g and lifting the wrapper in h kept the suite green throughout and made the migration's rollout-readiness machine-verifiable.

### Risk Mitigation Strategies
- **Snapshot-before-mutate for one-shot scripts.** `/tmp/task-131/BACKLOG.md.before` + grep verification before/after made the 61-marker migration reversible without git, and re-runnable independently of the Pass 2 squash. Cheap insurance for any throwaway transformation script.
- **Validator-as-contract.** BACKLOG-004/005/006 + CHANGELOG-003 mean any future regression — manual edit, helper bug, ill-formed `retire` — is caught by `prove t/backlog-manager.t::AC1` and `cwf-manage validate`. Format invariants are now machine-checked, not convention-trusted.

## Recommendations

### Process Improvements
- **Add a "freshness sweep" step to the checkpoint commit for plan files.** After material edits to a/b/c/d/e plans, grep the file for stale numerical references against current ground truth (live counts, step numbers, file paths, function names) before committing. Catches the Task 131 47-vs-61 and Step 4/8/11 class of bug.
- **For tasks with strong active/historical semantics, force a c-design review pass against the user's mental model before c-checkpoint.** Plan-review subagents are good at internal consistency but won't catch "the user fundamentally disagrees with this design choice". A short prose summary reflected back to the user pre-checkpoint adds <5 minutes and prevents Pass 1/Pass 2 cycles.

### Tool and Technique Recommendations
- **`_build_fence_map()` pattern for any multi-rule file validator.** Centralise fence-aware indexing in one helper; require all rules and mutators to consume it; add an invariant test that exercises every rule on a fenced fixture.
- **`make_isolated()` per-test temp git repo for inline fixtures.** Already used heavily in `t/backlog.t` and `t/backlog-manager.t`; should be the default scaffold for any test that mutates files.

### Future Work
- The two follow-ups from Pass 1 c-design plan-review remain in BACKLOG (both Low priority): "Resolve symlinks in validate_path_allowlist" and "Close TOCTOU window in atomic_write_text via O_NOFOLLOW". Both are still relevant under the Pass 2 design.
- The "Lightweight Rollout/Maintenance Templates for Internal/Developer-Tool Tasks" BACKLOG entry (Medium) becomes more valuable with each i-maintenance Skipped — would let internal helpers ship without the SLA/incident-response boilerplate.

## Status
**Status**: Finished
**Next Action**: Task complete
**Blockers**: None identified
**Completion Date**: 2026-05-10
**Sign-off**: Maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Wf step files: `implementation-guide/131-feature-add-backlog-management-helper-script/{a..j}-*.md`
- Helper: `.cwf/scripts/command-helpers/backlog-manager`
- Library: `.cwf/lib/CWF/Backlog.pm`
- Tests: `t/backlog.t`, `t/backlog-manager.t`
- Pre-migration snapshot: `/tmp/task-131/BACKLOG.md.before` (throwaway, for safety)
- Migration script: `/tmp/task-131/migrate-markers.pl` (throwaway, not committed)
