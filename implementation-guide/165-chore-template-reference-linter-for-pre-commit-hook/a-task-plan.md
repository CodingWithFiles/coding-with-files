# Template Reference Linter for Pre-Commit Hook - Plan
**Task**: 165 (chore)

## Task Reference
- **Task ID**: internal-165
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/165-template-reference-linter-for-pre-commit-hook
- **Baseline Commit**: 5598ec0331883e1d256cfe27fd3cca2fb394f7ad
- **Template Version**: 2.1

## Goal
Provide an automated checker that flags template-filename references which no longer match a current template-pool name, so template renames cannot silently leave orphaned references across the codebase.

## Success Criteria
- [ ] A validation-only checker exists under `.cwf/scripts/command-helpers/` that scans tracked `.md`/`.pl`/`.pm` files for template-filename references and exits non-zero with `file:line` for any reference that does not correspond to a current `.cwf/templates/pool/` name.
- [ ] Running the checker against the current repo HEAD reports **zero** violations (clean baseline) — intentional v2.0-specific references (e.g. in `CWF/WorkflowFiles/V20.pm`) are not flagged.
- [ ] The checker has a `t/*.t` test covering at least one passing tree and one synthetic orphaned-reference tree (exit-code + message assertions).
- [ ] The checker is wired into a concrete enforcement point (test suite and/or documented invocation) — the exact mechanism is fixed in design, given no git pre-commit framework currently exists.

## Original Estimate
**Effort**: 0.5–1 day
**Complexity**: Medium (low code volume; the difficulty is correctly distinguishing legitimate version-specific references from genuine orphans)
**Dependencies**: Template pool contents as the source of truth for "current" names; existing `cwf-check-tree-symlinks` as the structural model.

## Major Milestones
1. **Requirements + design**: Pin the reference grammar, the source of truth for "current" names, the v2.0 carve-out rule, and the enforcement point.
2. **Implement checker + test**: Perl command-helper following the `cwf-check-tree-symlinks` pattern, plus a `t/*.t` covering pass/fail; register the script hash.
3. **Wire enforcement + verify clean baseline**: Hook into the chosen enforcement point and confirm zero violations on HEAD.

## Risk Assessment
### High Priority Risks
- **No git pre-commit framework exists**: The backlog title says "pre-commit hook", but CWF has no `.pre-commit-config.yaml` or custom `.git/hooks`; the only hooks are Claude Code stop/subagentstop hooks. Building a literal git hook would introduce new, uninstalled infrastructure.
  - **Mitigation**: Treat "enforcement point" as an open design question — most likely a standalone command-helper invoked from the test suite / CI / documented manual run, mirroring `cwf-check-tree-symlinks`. Confirm the intended integration with the user during requirements.
- **False positives on intentional version-specific references**: `CWF/WorkflowFiles/V20.pm`, migration docs, and CHANGELOG legitimately name old/renamed templates (e.g. `e-implementation-exec.md`). A naïve linter would flag these.
  - **Mitigation**: Define an explicit context/allowlist rule (e.g. V20.pm and historical-record files are exempt) and gate on a clean HEAD baseline as an acceptance criterion.

### Medium Priority Risks
- **Reference-pattern ambiguity**: Separating a genuine template-filename reference from incidental prose risks both misses and false hits.
  - **Mitigation**: Anchor on the canonical `[a-j]-<phase>.md` grammar derived from actual pool contents rather than free-text heuristics.
- **Value vs maintenance cost**: v2.1 names are now stable, so the linter may rarely fire; over-engineering would not pay back.
  - **Mitigation**: Keep it minimal — reuse the existing checker pattern, add no heavy infrastructure, prefer the smallest solution that satisfies the criteria.

## Dependencies
- `.cwf/templates/pool/` as the authoritative list of current template names.
- `.cwf/security/script-hashes.json` — new executable script requires a hash entry in the same commit (per hash-updates convention).
- Existing `cwf-check-tree-symlinks` + `t/cwf-check-tree-symlinks.t` as the implementation/test model.

## Constraints
- Core-Perl only; POSIX portability; `use utf8;` + `-CDSL`/`PERL5OPT=-CDSLA`; `git ... -z` for path output (per project conventions).
- Pure validation — no filesystem mutation, no auto-rewrite of references (surface, never smooth).
- Must classify by file content/grammar, not by extension alone where avoidable.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: >1 week? No — estimated 0.5–1 day.
- [ ] **People**: >2 people on different parts? No — single contributor.
- [ ] **Complexity**: 3+ distinct concerns? No — one concern (a single checker script + test + wiring).
- [ ] **Risk**: High-risk components needing isolation? No — pure validation, no mutation.
- [ ] **Independence**: Separable parts? No — script, test, and wiring are one cohesive unit.

**Conclusion**: 0 signals triggered. No decomposition — proceed as a single chore.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
The biggest risk flagged here ("no pre-commit framework exists") resolved cleanly to the `CWF::Validate::*` + `cwf-manage validate` pattern. The second flagged risk (false positives on version-specific references) proved deeper than anticipated and drove a deliberate scope narrowing — see j-retrospective.md.
