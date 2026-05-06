# Audit Perl-vs-Bash helpers and migrate - Plan
**Task**: 128 (chore)

## Task Reference
- **Task ID**: internal-128
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/128-audit-perl-vs-bash-helpers-and-migrate
- **Template Version**: 2.1

## Goal
Decide per-helper whether each of the five POSIX-shell command-helpers should migrate to Perl, then carry out the approved migrations so the language split under `.cwf/scripts/command-helpers/` is deliberate rather than incidental.

## Success Criteria
- [ ] Each of the five shell helpers (`cwf-find-task-numbering-structure`, `cwf-load-autoload-config`, `cwf-load-existing-tasks`, `cwf-load-project-config`, `cwf-load-status-sections`) has a documented migrate-or-keep decision with a one-line rationale captured in `d-implementation-plan.md`.
- [ ] All helpers chosen for migration are reimplemented in Perl with `use strict; use warnings; use utf8;`, `die_msg` for errors, `CWF::Options` where option parsing is non-trivial, and conformance to `docs/conventions/perl-git-paths.md`.
- [ ] `.cwf/security/script-hashes.json` is refreshed for every migrated helper; `cwf-security-check verify` passes.
- [ ] All callers of migrated helpers continue to produce byte-identical (or behaviourally equivalent and reviewed) output; verified by exercising the call sites end-to-end.
- [ ] `CWF::Validate::PerlConventions` accepts every migrated helper.

## Original Estimate
**Effort**: 0.5–1 day
**Complexity**: Low–Medium (mechanical reimplementation; risk is in caller surface, not in the helpers themselves)
**Dependencies**: `CWF::Options`, `CWF::Common`/`die_msg`, `script-hashes.json` regeneration tooling, `cwf-security-check`.

## Major Milestones
1. **Discovery**: read all five helpers, map inputs/outputs/callers, classify each as branchy-logic (migrate) vs simple env-probe (keep).
2. **Decision matrix**: produce per-helper migrate-or-keep decision with rationale; record in d-implementation-plan.md before any code changes.
3. **Migration**: reimplement chosen helpers in Perl, refresh `script-hashes.json`, exercise call sites, run convention checks.

## Risk Assessment
### High Priority Risks
- **Behavioural drift between shell and Perl reimplementation**: Output format (whitespace, trailing newlines, exit codes) consumed by other helpers and skills must match exactly.
  - **Mitigation**: Capture current output for representative inputs before migration; diff against new output; treat any divergence as a defect requiring sign-off.

### Medium Priority Risks
- **Missed call sites**: A helper may be invoked from skills, docs, or other helpers in ways `grep` doesn't catch (alias, variable indirection).
  - **Mitigation**: Search skills/, docs/, scripts/ exhaustively; smoke-test the workflow end-to-end (a `/cwf-status` and a `/cwf-new-task` dry run) post-migration.
- **Hash-refresh forgotten for one helper**: Migration changes bytes; stale hash breaks `cwf-security-check`.
  - **Mitigation**: Make hash refresh part of the same commit as the migration; verify `cwf-security-check verify` before each checkpoint.

## Dependencies
- `CWF::Options`, `CWF::Common::die_msg`, `CWF::Validate::PerlConventions`.
- `.cwf/security/script-hashes.json` and the regeneration command used by Task 125.
- `docs/conventions/perl-git-paths.md` (canonical Perl conventions).

## Constraints
- Helpers must remain executable as standalone scripts (called from skills via Bash).
- Permissions stay at u+rx (≥0500) per security model.
- No backwards-compat shims: callers may be edited but old shell helpers are removed, not renamed-and-stubbed.
- Out of scope: shell scripts outside `.cwf/scripts/command-helpers/` (install bootstrap, migration scripts) — they predate the Perl runtime guarantee.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? If yes, consider decomposition — No, est. 0.5–1 day.
- [ ] **People**: Does this need >2 people working on different parts? If yes, consider decomposition — No, single maintainer.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? If yes, consider decomposition — No, single concern (helper migration).
- [ ] **Risk**: Are there high-risk components that need isolation? If yes, consider decomposition — No, helpers are leaf-level.
- [ ] **Independence**: Can parts be worked on separately? If yes, consider decomposition — Helpers are independent but small enough to batch.

No decomposition signals triggered; proceed as a single task.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
