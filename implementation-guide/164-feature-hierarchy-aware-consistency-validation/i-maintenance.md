# hierarchy-aware consistency validation - Maintenance
**Task**: 164 (feature)

## Task Reference
- **Task ID**: internal-164
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/164-hierarchy-aware-consistency-validation
- **Template Version**: 2.1

## Goal
Define ongoing maintenance, monitoring, and support requirements for hierarchy-aware consistency validation.

## Monitoring Requirements
No runtime monitoring: `validate` is a local, read-only, advisory CLI check — no service,
uptime, telemetry, or resource budget. The standing health signal is the test suite
(`prove t/`, specifically `t/validate-consistency.t`), run in CWF's CI and on every checkpoint
commit via `cwf-manage validate`. A regression here is the only "alert" that applies.

## Maintenance Tasks
### Coupling to watch (these ripple into this module)
- **`CWF::TaskPath::get_parent` semantics**: `_is_ancestor` builds the ancestry chain from
  `get_parent` and exact `eq`. If `get_parent`'s dotted-number contract changes (e.g. a new
  separator, normalisation rule), revisit `_is_ancestor` and the near-miss guarantee (TC-2c).
- **Status vocabulary (`$TERMINAL_STATUSES`)**: active/complete classification keys off the
  Finished/Skipped/Cancelled set. Adding or renaming a terminal status changes which parents are
  "complete" (FR4) and which tasks are "active" (FR2/FR3). Update the set and the FR4 fixtures
  together.
- **Nested on-disk layout**: traversal assumes subtask dirs are physically nested inside parents
  (the canonical layout). A move to flat-dotted dirs would require reworking `_collect_nodes`.
- **Hash coupling**: `Consistency.pm` is hash-tracked — any future edit needs the same-commit
  `script-hashes.json` refresh (`docs/conventions/hash-updates.md`).
- Dead-code audit (see `.cwf/docs/dead-code-audit.md`) — periodic sweep using documented methodology.

## Incident Response
### Common Issues
- **A parent task is flagged for a branch mismatch while I'm on its subtask branch.** This is the
  class Task 164 fixed; it should no longer occur *if* the subtask's own `**Branch**` field
  records the current branch. Diagnosis: leaf identification keys off the recorded `**Branch**`,
  not the branch name — if the on-branch task's `**Branch**` is wrong/absent, no leaf is found,
  suppression is disabled (fail-closed, FR3), and ancestors get flagged. Resolution: correct the
  leaf task's `**Branch**` field (do **not** mutate the parent's accurate field — surface, never
  smooth).
- **A subtask is newly flagged after updating CWF.** Subtask dirs were unvalidated before this
  change; a wrong `**Task**`/`**Branch**` field in a subtask now surfaces as a *correct* new
  violation. Resolution: fix the subtask field to match its directory.
- **A new `**Status**` completeness violation appeared.** A task in a terminal status has a
  descendant still active (impossible completion state). Resolution: reopen the parent or finish
  the descendant — the violation names the nearest active descendant.

### Diagnosis tooling
`cwf-manage validate` prints each violation's `category`/`file`/`field`/`actual`/`expected`/`fix`.
To reproduce in isolation, construct a nested fixture tree and call
`CWF::Validate::Consistency::validate($root)` — see `t/validate-consistency.t` for the pattern.

## Known Limitations (carried from f-implementation-exec.md deviations)
- **Inter-category violation ordering**: `**Task**` violations are emitted during collection,
  then all `**Branch**`, then all `**Status**` (the directional rule needs the whole node set
  before judging any node). Byte-identical to pre-change output for flat repos and for any repo
  whose only findings are branch mismatches; diverges only in a multi-dir repo with *both* a
  task-num and a branch mismatch. `validate` output is an advisory unordered set, so no consumer
  depends on inter-category order.
- **No explicit recursion depth cap** in `_collect_nodes`: bounded in practice by the on-disk
  directory tree (and `get_parent` strictly shortens each step, so `_is_ancestor` always
  terminates). Add a cap only if this is ever pointed at an untrusted/attacker-shaped tree —
  not a CWF use case today.

## Success Criteria
- [x] Standing regression guard identified (`prove t/`, `cwf-manage validate`)
- [x] Coupling points documented (TaskPath ancestry, status vocab, nested layout, hash tracking)
- [x] Common false-positive/new-violation scenarios documented with resolutions
- [x] Known limitations recorded with their invariants

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Maintenance notes recorded: no runtime monitoring; coupling points (TaskPath ancestry,
status vocabulary, nested layout, hash-tracking); troubleshooting for the
leaf-Branch-field / fail-closed case; the two accepted known limitations.

## Lessons Learned
The coupling list is the key artefact: correctness depends on `get_parent` semantics and
the terminal-status set, so a future change must keep those in sync.
