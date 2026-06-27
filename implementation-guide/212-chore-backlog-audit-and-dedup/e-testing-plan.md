# Backlog audit and dedup - Testing Plan
**Task**: 212 (chore)

## Task Reference
- **Task ID**: internal-212
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/212-backlog-audit-and-dedup
- **Template Version**: 2.1

## Goal
Validate that the audit mutated BACKLOG/CHANGELOG correctly: the format stays valid, no
item is silently lost, and every change is traceable to a recorded verdict.

## Test Strategy
This is a data-mutation chore with no source-code change, so testing is **invariant
verification** over the before/after backlog, not unit/integration testing. The checks run
manually after Step 5 of the implementation, against the live `BACKLOG.md` / `CHANGELOG.md`
on the task branch (git diff is the audit trail). No test database applies — the only
mutated state is the two tracked markdown files, reversible via git.

### Coverage targets
- 100% of mutations traceable: every removed/added entry maps to a verdict row in f.
- Format: `backlog-manager validate --all` exits 0 on both files.
- Conservation: the item-count ledger balances exactly (TC-2).

## Test Cases
### Functional Test Cases
- **TC-1 — Format validity after mutation**
  - **Given**: all approved verdicts applied via `backlog-manager`.
  - **When**: `backlog-manager validate --all` is run.
  - **Then**: exit 0, no errors on either file (the heading-tree contract holds).

- **TC-2 — Conservation ledger balances**
  - **Given**: baseline count 91; the f worksheet records counts of keep / reprioritise /
    retire / drop / merge-source / merge-survivor / resize-residual.
  - **When**: `after = 91 − retired − dropped − merge_sources + merge_survivors + resize_residuals`
    is computed and compared to the live active-item count.
  - **Then**: computed `after` equals the actual `backlog-manager list --all-items` count;
    no item is unaccounted (every original title is keep / reprioritise / retired / dropped /
    merged).

- **TC-3 — Retire round-trip**
  - **Given**: each retired/resized item names a `--task=N`.
  - **When**: `CHANGELOG.md` is inspected under each `## Task N:` → `### Retired Backlog Items`.
  - **Then**: every retired title appears exactly once with its original body; no retired
    title remains active in `BACKLOG.md`.

- **TC-4 — Merge survivors are complete and unique**
  - **Given**: each merge cluster's survivor entry.
  - **When**: the survivor body is compared against its source acceptance criteria and its
    `Identified in` provenance.
  - **Then**: the survivor unions every source's AC and provenance; no source title remains
    active; the survivor title does not slug-collide with any active entry.

- **TC-5 — No verdict on assertion alone**
  - **Given**: every retire / resize / drop verdict in f.
  - **When**: each is checked for a cited evidence token (SHA / file path / convention doc).
  - **Then**: none is evidence-free; the security-verification item (worked example #1)
    cites its superseding mechanisms.

### Non-Functional Test Cases
- **Reliability — re-run safety**: re-running `validate --all` is idempotent and clean; the
  applied state is committed per-batch so git is the rollback boundary.
- **Approval gate**: confirm no mutation was applied before the user approved the Step 4
  action list (verified by commit ordering: action-list surfaced before any apply commit).

## Test Environment
### Setup Requirements
- The task branch `chore/212-backlog-audit-and-dedup` with the audit applied.
- `backlog-manager` helper at `.cwf/scripts/command-helpers/backlog-manager`.
- No external services, no database, no fixtures — operates on the two tracked files.

### Automation
- All checks are manual helper invocations + git diff inspection; no CI hook is added.

## Validation Criteria
- [ ] TC-1 `validate --all` exits 0
- [ ] TC-2 conservation ledger balances; zero unaccounted items
- [ ] TC-3 every retired item round-trips into CHANGELOG, absent from BACKLOG
- [ ] TC-4 merge survivors union sources; no collisions; sources removed
- [ ] TC-5 every retire/resize/drop cites concrete evidence
- [ ] Approval gate honoured (no apply before approval)

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned checks ran in g-testing-exec: TC-1…TC-5 + both non-functional checks PASS.
The conservation ledger (TC-2) proved the most valuable — it is what guarantees no item
was silently lost across 12 removals and 3 additions.

## Lessons Learned
For a data-mutation chore, invariant verification (format + conservation + round-trip) is
the right test model; there is nothing to unit-test, but "did we lose anything?" is the
question that matters.
