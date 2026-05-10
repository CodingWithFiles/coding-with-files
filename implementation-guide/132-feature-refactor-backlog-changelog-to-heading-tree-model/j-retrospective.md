# Refactor BACKLOG/CHANGELOG to heading-tree model - Retrospective
**Task**: 132 (feature)

## Task Reference
- **Task ID**: internal-132
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/132-refactor-backlog-changelog-to-heading-tree-model
- **Template Version**: 2.1
- **Retrospective Date**: 2026-05-10

## Executive Summary
- **Duration**: ~5 sessions (estimated 3-5; landed at the upper end of the band).
- **Scope**: Original five milestones delivered. One in-flight addition: a first-class `backlog-manager normalise` subcommand for external adopter migration (promoted from a throwaway `/tmp` script after the user asked "how about `.cwf/scripts/command-helpers/backlog-manager normalise`?"). Quality bar lifted by an unplanned `/simplify` pass after f-implementation-exec.
- **Outcome**: Success. The tree parser/serialiser ships; live BACKLOG (50 entries) and CHANGELOG (94 entries) round-trip byte-identical; the missing-entries bug that motivated the task is structurally impossible by construction; the new `/cwf-backlog-manager` skill is registered and exercised end-to-end; 412 tests green vs 408 baseline; perf 1.84-1.89× the pre-refactor baseline (NFR1 budget was 5×).

## Variance Analysis

### Time and Effort

| Phase | Estimate | Actual | Notes |
|-------|----------|--------|-------|
| Planning (a) | 0.25 sess | ~0.25 sess | On budget |
| Requirements (b) | 0.5 sess | ~0.5 sess | On budget; 7 checkpoint commits indicate iteration but each was small |
| Design (c) | 0.75 sess | ~0.75 sess | Body-placement decision (prose-before-metadata vs `### Body:` vs metadata-at-end) settled cleanly via plan-review |
| Implementation plan (d) | 0.5 sess | ~0.5 sess | On budget |
| Testing plan (e) | 0.25 sess | ~0.25 sess | On budget |
| Implementation exec (f) | 1.5-2 sess | ~2.5 sess | **Over by ~25-50%.** Drivers: live-file migration script needed three iterations (BACKLOG-007 false fire, AC5d body-byte reframing, idempotency heuristic); `/simplify` pass added but earned its keep (-82 + -40 lines); permission-prompt churn from `perl <script>` invocations cost wall-clock time |
| Testing exec (g) | 0.25 sess | ~0.25 sess | On budget; smooth because plan was concrete |
| Rollout (h) | 0.1 sess | ~0.1 sess | On budget; documentation-only |
| Maintenance (i) | 0.1 sess | ~0.1 sess | On budget; documentation-only |
| Retrospective (j) | 0.25 sess | ~0.25 sess | On budget |

### Scope Changes

**Additions**:
1. **`backlog-manager normalise` subcommand** — promoted from the throwaway migration script after the user pointed out external CWF adopters need an upgrade path. Reused the canonicalisation logic from `migrate-backlog-format.pl`. Cost: ~0.25 sess. Net win: makes the upgrade reproducible, not a one-shot script in `/tmp`.
2. **`/simplify` pass after f-implementation-exec** — three parallel review agents (reuse, quality, efficiency) over the changeset. Cost: ~0.25 sess. Net win: -122 lines across `Backlog.pm` and `backlog-manager`, shared regexes/constants extracted (`$VALID_PRIORITIES`, `$METADATA_KEY_RE`, `@CANONICAL_SUBSECTIONS`), `pre_meta_body` array slot replaced with `body_before_meta` boolean flag.
3. **AC18a/b/c subtests for `normalise`** — unplanned, added after the subcommand was promoted.

**Removals**:
- None. Every milestone shipped.

**Deferred**:
- AC4 grep tightening (file-wide → metadata-position-only). The current grep is a coarse syntactic proxy and surfaces 3+134 prose-bold lookalikes inside body content. Validators are clean — added to follow-up backlog.
- Test-scaffolding lift to `CWFTest::Fixtures` (`write_tmp`, `parse_and_validate_*`, `has_rule`/`get_rule`).
- `CWF::Options` adoption in `backlog-manager` arg parsing.
- Single `parse_tree($path, $kind)` collapsing the kind-specific public functions.

### Quality Metrics
- **Test Coverage**: 100% validator-rule coverage (positive + negative for every active rule, regression coverage for the two retired rules); 100% mutator coverage; 100% subcommand coverage.
- **Defect Rate**: zero post-merge defects (task not yet merged at retrospective time). Three bugs found and fixed during f-implementation-exec — all caught by the test suite or `validate` gates before commit.
- **Performance**: BACKLOG 4.02ms (1.84× baseline), CHANGELOG 7.49ms (1.89× baseline). Well inside the 5× NFR1 budget.
- **Net test count**: 412 tests vs 408 baseline (+4).

## What Went Well
- **Postel's Law payoff**: liberal parser + strict serialiser meant the migration script's job was small (canonicalise, then trust the round-trip). Round-trip byte-identity on live files is the cleanest possible regression alarm.
- **Tree-shape eliminates the bug class**: the missing-entries bug from Task 131 was *structurally impossible* by construction in the new model — not "patched", removed. This is the platonic outcome of a "the data model is the bug" diagnosis.
- **Plan-review subagents caught real defects**: design-phase plan-review surfaced the body-placement decision as the design decision; implementation-phase plan-review caught a phase-sequence assumption that would have required rework.
- **`/simplify` paid for itself**: ~0.25 sess investment, -122 lines, single-source-of-truth constants, simpler validator helpers. The diff was tighter and easier to review afterwards.
- **First-class `normalise` over a throwaway script**: the user's suggestion to promote the migration logic into a subcommand cost almost nothing (the code already existed) and gave external adopters a documented, idempotent, dry-runnable upgrade path.
- **Snapshot durability**: `/tmp/task-132/BACKLOG.md.pre-migration` and `CHANGELOG.md.pre-migration` were the right safety net; the refuse-overwrite guard added during the third migration iteration made them properly durable.

## What Could Be Improved
- **Permission-prompt friction from `perl <script>` invocations**: I repeatedly invoked Perl scripts via `perl /tmp/.../script.pl` instead of `chmod +x` then direct shebang execution. The user called this out sharply ("this is unix not windows... why do you keep following windows idioms?") — each invocation triggered a permission prompt and stalled wall-clock progress. Memory captured at `feedback_chmod_and_execute.md`. The fix is mechanical; the cost was real (~20× slowdown on the migration step per the user's own measurement).
- **Migration script needed three iterations**: BACKLOG-007 false fire (caused by all body in `body_raw` regardless of position relative to metadata), AC5d's body-byte ratio failing on legitimate body→metadata promotion, and the idempotency heuristic tripping on a `### Solution:` body line. Each was small; cumulatively they ate the f-phase overrun. Better up-front pre-mortem of the migration's failure modes would have surfaced at least the first two.
- **Implementation phase had 12 checkpoint commits**: more than ideal. Some were genuine phase boundaries (each migration iteration), some were bookkeeping (`In Progress` flips). Tighter "checkpoint when state is durable" discipline would help.
- **AC4 grep gate was too coarse**: file-wide `^\*\*[A-Z][\w\- ]*\*\*:` finds prose-bold body content as well as metadata. Should have been "in metadata position only" from the start. Captured as follow-up.

## Key Learnings

### Technical Insights
- **Body-position vs body-content are different invariants**: BACKLOG-007 ("body before metadata") needs a *flag* set at parse time, not a separate body slot. The first cut used a `pre_meta_body` array slot which fragmented the body across two buckets and complicated serialisation; `/simplify` collapsed it to a `body_before_meta` boolean and a single `body_raw`, with the validator checking the flag. Single boolean > redundant slot.
- **Cache the parser's source on the tree** (`_source_lines`, `_source_fence`): validators that need the raw lines (e.g. fence-aware checks) shouldn't have to re-tokenise + rebuild the fence map. Cached at parse time, fall back to serialise-and-tokenise only when the tree was constructed in-memory. Cheap, big payoff.
- **Single-source fence map** (`_build_fence_map`): every fence-aware rule queries the same map. Two consumers of "is this line inside a fence?" must never compute it independently or they will disagree on edge cases.

### Process Learnings
- **The user's principle "the data model is the bug"** is operationally cheaper than the dual ("fix the splitter"). The "fix the splitter" version of this task would have been a one-day chore with a fragile heuristic; the data-model version was a five-session refactor with a structurally impossible recurrence. Choose the larger task when the bug class is structural.
- **Eat-your-own-dog-food + workflow discipline catches things humans miss**: the test fixture conversion, the snapshot durability guard, the AC5d reframing — all caught by the workflow's own gates (plan-review, security-review, post-commit `cwf-manage validate`), not by ad-hoc inspection.
- **Promote helpful one-off scripts into first-class commands when the user asks**: `normalise` cost almost nothing once the migration script existed; the lift turned a maintainer-only tool into an adopter-facing capability.

### Risk Mitigation Strategies
- **Snapshot before migration**: required, not optional. The refuse-overwrite guard added in iteration 3 was the missing piece that made the snapshot truly durable across re-runs.
- **Round-trip byte-identical on live files** is the strongest regression alarm available; everything weaker is either flaky or insensitive.
- **Plan-review subagents** are not optional; both the design and implementation phases benefited.

## Recommendations

### Process Improvements
- **`chmod +x` reflex**: every `/tmp` script invocation must `chmod +x` then exec directly via shebang. No `perl <script>`. (Memory `feedback_chmod_and_execute.md` covers this; the lesson here is making sure that memory is consulted *before* the next throwaway script is written, not just after the next infraction.)
- **Migration pre-mortem**: before writing a migration script, write a one-paragraph "what could the validator falsely fire on" exercise. Would have saved ~1 session here.
- **Tighter checkpoint discipline**: checkpoint when *state is durably worth keeping*, not after every Edit. The 12 f-phase checkpoints could have been ~5 with no information loss.

### Tool and Technique Recommendations
- **`/simplify` after exec phases is now standard practice for this codebase**: clear payoff, low cost. Worth folding into the workflow guidance for f-implementation-exec.
- **Cached parser-state slots on parse trees** (`_source_*`) is a pattern worth reusing in any future parser/validator combo.

### Future Work
- AC4 grep tightening — file-wide → metadata-position-only.
- Lift test scaffolding to `CWFTest::Fixtures` (`write_tmp`, `parse_and_validate_*`, `has_rule`/`get_rule`).
- Adopt `CWF::Options` in `backlog-manager` arg parsing.
- Collapse `parse_backlog_tree` / `parse_changelog_tree` to a single `parse_tree($path, $kind)` (touches public surface — needs care).
- Cleanup: `/tmp/task-132/` and `/tmp/task-132-g/` throwaway scripts can be deleted now that the work is recorded here.

## Status
**Status**: Finished
**Next Action**: Task complete — maintainer to fast-forward `main` and tag.
**Blockers**: None identified
**Completion Date**: 2026-05-10
**Sign-off**: the maintainer

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Workflow files in this directory: `a-task-plan.md` through `i-maintenance.md`.
- Final squash commit: see `git log main` after the maintainer's fast-forward.
- Checkpoints branch: `checkpoints/feature/132-refactor-backlog-changelog-to-heading-tree-model` (created at Step 10 below).
- Pre-migration snapshots: `/tmp/task-132/BACKLOG.md.pre-migration` (74,014 B), `/tmp/task-132/CHANGELOG.md.pre-migration` (231,373 B) — to be removed after final merge.
