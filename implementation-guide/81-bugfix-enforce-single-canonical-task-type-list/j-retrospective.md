# enforce single canonical task type list across CWF modules - Retrospective
**Task**: 81 (bugfix)

## Task Reference
- **Task ID**: internal-81
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/81-enforce-single-canonical-task-type-list
- **Template Version**: 2.1
- **Retrospective Date**: 2026-02-21

## Executive Summary
- **Duration**: 1 session (estimated: <1 session, variance: on target)
- **Scope**: Delivered exactly as planned — `supported_types()` export, bidirectional validation, template fix, doc fix
- **Outcome**: Success. `cwf-manage validate` now enforces the canonical type list bidirectionally. No regressions.

## Variance Analysis

### Time and Effort
- **Estimated**: <1 session across planning + implementation + testing
- **Actual**: 1 session (planning, implementation, testing all completed sequentially)
- **Variance**: On target. The scope was tight and well-defined going in.

### Scope Changes
- **Additions**:
  - `decomposition-guide.md` file count table updated (was not in original plan; discovered during audit)
  - Rewrite of `Validate::Config` validation block after user feedback ("not very Perlish") — added extra hash recompute cycle
- **Removals**: None
- **Impact**: Minor. The doc fix was a few minutes. The Perl style rewrite was correct feedback; final code is cleaner.

### Quality Metrics
- **Test Coverage**: 8 TCs defined and executed — all pass. 2 new subtests in `workflowfiles-v21.t`, 2 new in `validate-config.t`; 3 existing subtests updated.
- **Defect Rate**: 0 bugs post-implementation. 1 test approach error (TC-7 initial attempt using `cwf-manage validate "$TMPDIR"` — script ignores passed arg, uses `find_git_root()` internally).
- **Performance**: N/A — library-level change, no performance concern.

## What Went Well

- **Audit was thorough**: Full recursive grep at task start found all 7 locations with type lists before writing a single line of code. No late-stage surprises.
- **Single source of truth design**: Deriving `supported_types()` from `%WORKFLOW_FILES` keys dynamically means the canonical list can never drift from the actual workflow definitions.
- **Bidirectional validation**: Both directions (unknown types, missing types) are now caught. The original one-directional check was silently accepting `docs`, `refactor`, `test` — the new logic is strictly correct.
- **Test suite coverage**: All 8 planned TCs passed on first run after implementation (excluding the TC-7 approach fix which was an environment understanding issue, not a code bug).
- **No regressions**: Full 162-test suite passes unchanged.

## What Could Be Improved

- **TC-7 test design**: Assumed `cwf-manage validate` accepted a git root argument. It uses `find_git_root()` internally. A brief read of the script beforehand would have avoided the false-OK result. For future end-to-end validate tests, always write to the actual repo path and restore.
- **Perl idiom iteration**: The first version of the bidirectional check iterated `keys %project` and `keys %canonical` rather than the original arrays. This was less clear about the intent of each direction. The postfix-`if` and array-based final version is more idiomatic — worth noting as a Perl code review point for future validators.

## Key Learnings

### Technical Insights
- **`sort SUBNAME LIST` Perl parsing trap**: `sort supported_types()` is parsed as sort with `supported_types` as a named comparator and `()` as the (empty) list — result is always `('')`. Use `for my $type (supported_types())` to iterate, or assign to a variable first: `my @t = supported_types(); my @sorted = sort @t`.
- **`cwf-manage validate` uses internal git root detection**: Cannot be pointed at an arbitrary directory. End-to-end tests must manipulate the actual repo config and restore it.
- **Postfix `if` is idiomatic Perl for conditional push**: `push @list, ... if @items;` is cleaner than wrapping in a block.

### Process Learnings
- **Recursive grep before coding**: Confirmed that doing the full grep audit before implementation is the right approach — avoids mid-stream discoveries of additional fix sites.
- **User code review during implementation**: The user's "not very Perlish" feedback mid-implementation caught a style issue that was worth fixing before the checkpoint. Having the rewrite happen before the commit (rather than as a follow-up) kept the history clean.

### Risk Mitigation
- **Ghost types in existing projects**: The intentional design choice to make this a hard violation (not a warning) is correct — any project using `docs`/`refactor`/`test` should fix its config. The violation message names the offending types and suggests the fix.

## Recommendations

### Process Improvements
- For future `cwf-manage validate` end-to-end tests: read the script's `find_git_root()` to understand what root it will use before designing the test scenario.

### Future Work
- No follow-up tasks identified. The template, validator, and docs are now all consistent.

## Status
**Status**: Finished
**Next Action**: Squash and merge to main
**Blockers**: None
**Completion Date**: 2026-02-21

## Archived Materials
- Task branch: `bugfix/81-enforce-single-canonical-task-type-list`
- Checkpoints branch: `bugfix/81-enforce-single-canonical-task-type-list-checkpoints`
- Key commits: `9c9372d` (implementation), `d4dea3f` (testing exec)
- Files changed: `CWF/WorkflowFiles/V21.pm`, `CWF/Validate/Config.pm`, `cwf-project.json.template`, `decomposition-guide.md`, `script-hashes.json`, `t/workflowfiles-v21.t`, `t/validate-config.t`
