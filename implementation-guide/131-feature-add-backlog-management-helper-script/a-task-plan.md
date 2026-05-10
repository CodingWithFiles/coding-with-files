# Add backlog management helper script - Plan
**Task**: 131 (feature)

## Task Reference
- **Task ID**: internal-131
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/131-add-backlog-management-helper-script
- **Baseline Commit**: 1734366a8dbaa7a425627126dd1134d1166ec5a4
- **Template Version**: 2.1

## Goal
Replace manual BACKLOG.md / CHANGELOG.md editing with a single Perl helper — `.cwf/scripts/command-helpers/backlog-manager` — and codify a strict separation of concerns: **BACKLOG holds active work only; CHANGELOG holds history**. `retire` moves an entry across the boundary; nothing is ever marked-in-place.

## Re-plan rationale (post-original-impl)

The first pass through this task implemented `retire` as "leave a `<!-- Completed: -->` HTML-comment tombstone in BACKLOG and append a one-line bullet in CHANGELOG". The user rejected that model on review:

> "BACKLOG shouldn't be a dumping ground … if it's finished (or rejected, or similar) it's in the changelog"

The "marker tombstone" pattern was an over-clever attempt to preserve cross-references. It violates the simpler, correct mental model: BACKLOG = future, CHANGELOG = past. There are 61 such markers already in the live BACKLOG (legacy from manual editing across many tasks); they all get migrated out. The plans below are rewritten against this corrected model.

## Success Criteria
- [ ] `.cwf/scripts/command-helpers/backlog-manager` exists with six subcommands; each has a deterministic exit-code contract (`0` success, non-zero on validation/IO error).
- [ ] **`add`**: appends a new entry to BACKLOG.md; rejects entries that would fail `validate`.
- [ ] **`delete`**: removes an entry outright from BACKLOG (no CHANGELOG impact); for typos / accidental dupes only. Refuses without explicit confirmation flag.
- [ ] **`modify`**: edits an existing entry's title/body/priority in-place; preserves entry order.
- [ ] **`list`**: groups by priority (Very High → High → Medium → Low → Very Low). Default cap: 20 items, but never split a priority band — if the highest band has >20 items, show the whole band. `--all-items` shows everything.
- [ ] **`validate`**: structural check on both files. BACKLOG must contain zero HTML comments (no `<!-- Completed: -->`, no `<!-- Removed: -->`, no others); HTML comments are permitted in CHANGELOG (commentary on implementation deviations from the original entry). Non-zero exit on malformation.
- [ ] **`retire`**: transactional move from BACKLOG → CHANGELOG. The full entry body (minus fields that don't make sense in a changelog — Priority, Identified-in) is appended under the implementing task's CHANGELOG section. The BACKLOG entry is **deleted**, not replaced with a marker. Atomic across the two files.
- [ ] All six subcommands have prove-style tests under `t/backlog-manager.t` end-to-end; library has unit tests under `t/backlog.t`.
- [ ] **The 61 existing `<!-- Completed: -->` / `<!-- Removed: -->` markers are removed from BACKLOG.md** during rollout, after spot-checking that the corresponding CHANGELOG entries already capture the relevant information.
- [ ] After rollout, `backlog-manager validate` exits 0 against both live files.
- [ ] Script registered in `.cwf/security/script-hashes.json` with `0500` permissions.

## Original Estimate
**Effort**: 1–2 days (already largely built; this re-plan covers the simplification + migration).
**Complexity**: Medium — the simplification removes the historical-marker classifier and tightens validator, plus a one-shot migration of 61 entries.
**Dependencies**: None — pure Perl, existing CWF::ArtefactHelpers patterns.

## Major Milestones
1. **Strip the marker pattern** (b-requirements, c-design): drop `historical` parser classification, drop `make_completed_marker`, drop BACKLOG-004 (unclosed marker) and BACKLOG-005 (orphan reason). Tighten the new BACKLOG-006 to flag *any* HTML comment in BACKLOG.
2. **Simplify `retire`** (c-design, f-impl): two operations, transactional — delete BACKLOG entry; append CHANGELOG entry containing entry title, body, optional `--note`. Atomicity preserved via existing two-file write pattern.
3. **Define what carries across** (b-requirements, c-design): which entry fields go to CHANGELOG and which are dropped. Default: Title and Body carry; Priority, Identified-in are dropped (changelog reader does not care about pre-completion state); Status field replaced with the implementing-task reference.
4. **Bulk migration** (h-rollout): remove the 61 existing markers from BACKLOG.md, after a per-marker check that the implementing-task's CHANGELOG section exists and is non-empty. Anything missing gets added before the marker is removed.
5. **Re-run tests + dogfood** (g-testing-exec): full prove run; dogfood by retiring at least one real entry through the new path.

## Risk Assessment

### Medium Priority Risks
- **Information loss during the 61-marker migration**: Some markers may reference Tasks whose CHANGELOG entries are thin or missing (early CWF tasks predate the convention). Bulk-deletion would silently drop the marker's "Reason" trailer.
  - **Mitigation**: build a one-shot audit script that, for each marker, locates the implementing task's CHANGELOG section and warns if missing. The h-rollout step is "audit then delete"; any gaps get filled in CHANGELOG first. The audit script is throwaway (`/tmp/task-131/`), not committed.
- **Field-mapping ambiguity for `retire`**: BACKLOG entries have Priority, Identified-in, Status, Title, Body. Which subset belongs in CHANGELOG and in what shape? Get this wrong and the CHANGELOG becomes inconsistent with manually-written entries.
  - **Mitigation**: c-design surveys ~10 existing CHANGELOG entries for the canonical shape, then specifies the exact field mapping. `retire` produces output indistinguishable from a hand-written CHANGELOG entry.

### Low Priority Risks
- **Atomicity in `retire`'s two-file write**: existing pattern (write CHANGELOG atomically, then BACKLOG atomically) leaves a window where a crash drops the entry from BACKLOG without it appearing in CHANGELOG, or vice-versa.
  - **Mitigation**: write BACKLOG temp first, write CHANGELOG, then rename BACKLOG temp into place. Worst case: CHANGELOG gains a new entry but BACKLOG retains the old one — recoverable via `delete`. Document the failure mode; don't over-engineer.
- **Validator strictness regression**: tightening BACKLOG-006 to "any HTML comment" could break editor workflows that legitimately use comments (e.g. Markdown TOC generators).
  - **Mitigation**: project doesn't use any such tooling; `cwf-manage validate` against the live file post-migration is the regression test.

## Dependencies
- None — internal helper, no external systems.

## Constraints
- **Perl 5.14+**, core modules only (per CWF helper conventions). `use utf8;` mandatory.
- **Permissions `0500`** on the helper script.
- **BACKLOG = active items only** (post-migration). The validator enforces this; the helper produces conformant output by construction.
- **CHANGELOG may contain commentary** (HTML comments or regular prose) noting implementation deviations from the original BACKLOG entry. The validator does not flag these.

## Decomposition Check
- [ ] **Time**: >1 week? No — most code already exists; this is simplification + a one-shot migration.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? Borderline — helper, validator, migration. But all share the parser/library, single domain.
- [ ] **Risk**: High-risk components needing isolation? No — fully reversible (markdown edits under git).
- [ ] **Independence**: Parts that can be worked on separately? No — the simplification and migration are tightly coupled; splitting introduces an intermediate state where the validator and the file disagree.

No decomposition warranted.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
