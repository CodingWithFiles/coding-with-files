# expand script-hashes to helpers and hooks - Plan
**Task**: 125 (chore)

## Task Reference
- **Task ID**: internal-125
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/125-expand-script-hashes-to-helpers-and-hooks
- **Template Version**: 2.1

## Goal
Close the SHA256 integrity gap surfaced by Task 124 by registering every executable Perl script under `.cwf/scripts/command-helpers/` (including `*.d/` subcommand directories) and `.cwf/scripts/hooks/` in `.cwf/security/script-hashes.json`, so `cwf-manage validate` detects tampering on the full execution surface.

## Success Criteria
- [ ] Every script under `.cwf/scripts/command-helpers/` (top-level + every `*.d/` subcommand) and `.cwf/scripts/hooks/` is registered in `.cwf/security/script-hashes.json` with correct path, permissions, and SHA256.
- [ ] `cwf-manage validate` passes cleanly with the expanded surface.
- [ ] Planted-breakage smoke (single-byte mutation on one new entry) triggers `[SECURITY] sha256` violation; reverting clears it.
- [ ] No end-user-runnable hash recompute facility added; `script-hashes.json` remains a maintainer-only artefact.
- [ ] Hash-key naming for `*.d/` entries is unambiguous (no collisions with existing top-level keys).

## Original Estimate
**Effort**: 1 session (mechanical hash registration + tests + validate sweep)
**Complexity**: Low
**Dependencies**: Task 124 closed (already merged: 91a7a86)

## Major Milestones
1. **Inventory & key naming**: enumerate every file to register; settle the key-naming convention for `.d/` entries (avoid collisions with top-level keys).
2. **Register entries**: extend `script-hashes.json` with permissions + SHA256 for each new file; refresh `cwf-manage`'s own hash if its invocation changes (it should not).
3. **Validate & planted-breakage smoke**: `cwf-manage validate` green; flip one byte on each new entry, confirm violation, revert.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Existing `Validate::Security` may rely on a flat key namespace and reject `.d/`-style keys (e.g. embedded dots).
  - **Mitigation**: Read `CWF::Validate::Security` before deciding the key shape; if the validator restricts keys, use `<parent>-<subcommand>` flat naming (e.g. `context-manager-hierarchy`) rather than `context-manager.d/hierarchy`.

### Medium Priority Risks
- **Risk 2**: Out-of-scope unregistered helpers (`cwf-find-task-numbering-structure`, `cwf-load-*`) tempt scope creep.
  - **Mitigation**: Note them in the implementation plan as an explicit scope question for the user; do not silently expand. If the user wants them in, register in the same task; otherwise log a follow-up.
- **Risk 3**: Adding entries could change observed behaviour of `cwf-manage validate` if the validator iterates entries lazily and a perms mismatch is recorded incorrectly.
  - **Mitigation**: Record `permissions` from `stat` on each file (don't guess); run `validate` after each batch addition rather than all at once.

## Dependencies
- `CWF::Validate::Security` (must accept the new keys/paths without code changes)
- `cwf-manage validate` end-to-end behaviour (no other change required)

## Constraints
- Must not introduce an end-user `refresh-hashes` command (BACKLOG out-of-scope clause); recomputation stays a maintainer-only operation.
- Must not break the existing Task 124 convention check (`CWF::Validate::PerlConventions`).
- Must not change file contents of the registered scripts (this task is purely about the manifest; convention compliance was Task 124's job).

## Decomposition Check
- [x] **Time**: <1 day. No decomposition.
- [x] **People**: Single-author. No decomposition.
- [x] **Complexity**: One concern (manifest expansion + validate). No decomposition.
- [x] **Risk**: Low — well-bounded mechanical edit + targeted tests. No decomposition.
- [x] **Independence**: Inseparable — entries must land together to close the gap. No decomposition.

No signals triggered. Single task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All success criteria met. Single-session estimate held. Scope expanded mid-task from 12 → 17 entries (added 5 POSIX shell helpers under user direction) and folded in 4 perms-drift fixes; no estimate revision needed.

## Lessons Learned
Decomposition check correctly returned single-task. The mid-task scope expansion was scope clarification, not creep — the underlying integrity rule was always meant to be language-agnostic.
