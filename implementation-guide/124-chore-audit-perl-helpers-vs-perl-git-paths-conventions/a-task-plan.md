# audit perl helpers vs perl-git-paths conventions - Plan
**Task**: 124 (chore)

## Task Reference
- **Task ID**: internal-124
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/124-audit-perl-helpers-vs-perl-git-paths-conventions
- **Template Version**: 2.1

## Goal
Bring all Perl helpers and hooks under `.cwf/` into compliance with `docs/conventions/perl-git-paths.md`, and add a regression-prevention check so future drift is caught at commit time.

## Success Criteria
- [ ] Every executable Perl helper that consumes git path output uses `#!/usr/bin/perl -CDSL` (grandfathered exceptions explicitly documented in the conventions doc).
- [ ] Every `git status|diff|ls-files` invocation that reads paths uses `-z`, with `split /\0/` parsing.
- [ ] Every Perl source file (script or module) containing non-ASCII literals declares `use utf8;`.
- [ ] An automated check (either `cwf-manage validate` soft-check or `prove t/perl-conventions.t`) fails on a planted convention breakage.
- [ ] BACKLOG.md item removed; "Existing usage" section in `perl-git-paths.md` reflects the post-audit state.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Low (mechanical audit + small fixes + one new check)
**Dependencies**: None external; touches `.cwf/security/script-hashes.json` (refreshed via routine `cwf-manage fix-security`).

## Major Milestones
1. **Audit pass**: Per-script conformance table (shebang, `use utf8;`, git `-z` usage, non-ASCII literals) covering everything under `.cwf/scripts/` and `.cwf/lib/CWF/`.
2. **Bring into line**: Non-conformant scripts updated, security hashes refreshed in the same commits.
3. **Regression check**: New automated check added and proven to fail on a planted breakage; conventions doc updated.

## Risk Assessment
### High Priority Risks
- **Shebang change surfacing latent I/O bugs**: Switching `env perl` → `perl -CDSL` changes STDIN/STDOUT/STDERR/`@ARGV` decoding. Scripts that round-tripped raw bytes accidentally may now mis-handle non-UTF-8 input.
  - **Mitigation**: Run each script's primary flow after the shebang change (smoke tests + existing test suite). Stage one script per commit so any regression is bisectable.

### Medium Priority Risks
- **`script-hashes.json` churn**: Every shebang/source edit invalidates the hash and cascades to `cwf-manage fix-security` warnings until users re-sync.
  - **Mitigation**: Refresh hashes in the same commit as each script change; surface in retrospective.
- **Regression check false positives**: A naive grep for `git diff` without `-z` will flag invocations that don't read paths.
  - **Mitigation**: Scope the check to `git (status|diff|ls-files|diff-tree|diff-index|...)` calls whose output is consumed (assigned, piped, captured) — match on syntactic patterns, not on the bare command name. Allow an opt-out comment for justified exceptions (mirroring the grandfathered hook).

## Dependencies
- None external. Scoped entirely within `.cwf/`.

## Constraints
- Audit-only refactor: do not rewrite scripts beyond convention compliance.
- Preserve the grandfathered exception for `.cwf/scripts/hooks/stop-stale-status-detector`; document it explicitly in whatever check is added.
- Don't introduce new dependencies (Perl modules outside core / what's already vendored).

## Decomposition Check
- [ ] **Time**: Will this take >1 week? No — 1-2 days.
- [ ] **People**: Does this need >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No — single concern (convention compliance + check).
- [ ] **Risk**: High-risk components needing isolation? No — risk is mechanical, mitigated by per-script commits.
- [ ] **Independence**: Can parts be worked on separately? Marginally (audit vs. check), but the split adds overhead without benefit.

→ No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
