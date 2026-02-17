# Fix template-copier undef warnings for unresolved variables - Retrospective
**Task**: 63 (bugfix)

## Task Reference
- **Task ID**: internal-63
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/63-fix-template-copier-undef-warnings
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-17

## Executive Summary
- **Duration**: 1 session (estimated: 1 session = on target)
- **Scope**: Expanded from 2 undef guards to 5 fixes + documentation + 3 additional guards found during testing
- **Outcome**: Success — zero warnings on template creation, sparse-checkout bootstrap documented

## Variance Analysis

### Scope Changes
- **Additions**:
  - D4: Sparse-checkout bootstrap documentation in README.md and INSTALL.md (design expanded during session)
  - Fixed 3 pre-existing perlcritic stern violations (`print_usage`, `output_results`, `return sort`)
  - Fixed fatal `@{$config->{'supported-task-types'}}` deref when config key missing (found during external testing)
- **Impact**: Task scope approximately doubled, but all additions were low-complexity and caught in the same session

### Quality Metrics
- **Test Coverage**: 10/10 test cases PASS
- **Defects**: 1 additional bug found during external testing (array deref guard, line 198) — fixed inline

## What Went Well
- The `// ''` defined-or pattern is simple, idiomatic, and correct — zero ambiguity about intent
- Fixing perlcritic violations at point of discovery rather than deferring kept the codebase clean
- External agent install testing caught the `supported-task-types` fatal error before merge — good validation loop
- Leave-it-better-than-you-found-it principle applied consistently (perlcritic, array guard)

## What Could Be Improved
- The original task scope missed the `supported-task-types` array deref at line 198 — same class of bug, same file. A more thorough initial grep for all undef-unsafe patterns in template-copier-v2.1 would have caught it upfront
- Testing plan was written before D4 (sparse-checkout) was added to design, requiring a plan update mid-session. Design should be stable before testing plan is written

## Key Learnings

### Technical
- When fixing undef safety in a file, grep for ALL undef-unsafe patterns (`@{...}`, `%{...}`, `->{...}`) in one pass rather than addressing them reactively
- `git archive --remote=<url> <ref> -- <file> | tar -xO` is a cleaner agent install mechanism than sparse checkout — works with any host that supports the protocol (not GitHub)

### Process
- Scope creep via external testing is healthy: the install test caught a real bug. Keep the testing window open before closing the task
- When design expands, cascade updates to implementation plan and testing plan immediately — don't let them diverge

## Recommendations

### Future Work
- **Harden install script**: Initial commit pre-flight check + replace sparse-checkout with `git archive` one-liner (backlog)
- **`cwf-manage validate`**: Comprehensive format and schema checker to catch missing config keys at boundaries (backlog)
- **`/cwf-init` improvements**: Skill permissions, enforcement preamble, v1.0 category dirs (backlog)
- **Status aggregator**: Percentage model doesn't fit non-linear task-type-specific workflows (backlog)

## Status
**Status**: Finished
**Next Action**: Merge to main
**Blockers**: None
**Completion Date**: 2026-02-17

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Archived Materials
- Branch: `bugfix/63-fix-template-copier-undef-warnings`
- Files changed: `template-copier-v2.1`, `script-hashes.json`, `README.md`, `INSTALL.md`, `BACKLOG.md`
