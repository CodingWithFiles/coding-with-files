# Build uncommitted changes warning Stop hook - Plan
**Task**: 113 (feature)

## Task Reference
- **Task ID**: internal-113
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/113-build-uncommitted-changes-warning-stop-hook
- **Template Version**: 2.1

## Goal
Build a Stop event hook shell script that detects uncommitted changes (staged or unstaged) to wf files in `implementation-guide/` and emits a one-line warning as a system reminder.

## Success Criteria
- [ ] SC1: Shell script exists at `.cwf/scripts/hooks/stop-uncommitted-changes-warning` and exits cleanly (always 0)
- [ ] SC2: Hook outputs valid JSON with `systemMessage` listing dirty wf files when any are found
- [ ] SC3: Hook produces no output when the working tree is clean with respect to `implementation-guide/*/[a-j]-*.md` (zero tokens on clean stops)
- [ ] SC4: Hook registered in `.claude/settings.json` under `hooks.Stop` alongside the stale-status detector (Task 104)
- [ ] SC5: Total output stays within ~20-30 tokens when warnings present (cap displayed filenames, summarise remainder)

## Original Estimate
**Effort**: 1 session
**Complexity**: Low
**Dependencies**: Task 103 (framework), Task 104 (sibling Stop hook establishing conventions) — both completed

## Major Milestones
1. **Script**: Shell/Perl script that detects uncommitted wf file changes via `git status --porcelain`
2. **Hook registration**: Stop hook appended in settings.json
3. **Verification**: Hook fires on stop and produces correct output for both dirty and clean cases

## Risk Assessment
### Medium Priority Risks
- **Risk 1**: Stop hooks fire on every stop (`/clear`, resume, compact, natural pauses) — the vast majority of stops have clean wf files. Noise from false positives would erode trust and waste tokens.
  - **Mitigation**: Emit zero output when `git status --porcelain` returns no wf file entries; only warn when the filter matches.
- **Risk 2**: Double-counting with the Task 104 stale-status detector. A file that is both uncommitted AND has stale status would trigger both hooks, producing overlapping warnings.
  - **Mitigation**: Design phase to decide whether the two detectors should be coordinated (shared library call) or remain independent (two warnings acceptable since they highlight different problems).
- **Risk 3**: `git status --porcelain` is relative to the working directory; a hook invoked from an unexpected cwd could miss changes.
  - **Mitigation**: Run git commands from git root (mirror Task 104's approach; `git` resolves root automatically unless cwd is outside the repo).

### Low Priority Risks
- **Risk 4**: New untracked wf files (e.g., files just created by `/cwf-new-task`) would be flagged as uncommitted even when that's the correct state immediately after task creation.
  - **Mitigation**: Design phase to decide whether to warn on untracked (`??`) entries or only on modified/staged entries.

## Dependencies
- `.cwf/docs/workflow/stop-hooks-framework.md` (Candidate B) — completed
- Task 104 conventions: script location under `.cwf/scripts/hooks/`, Perl with `CWF::TaskState` lib pattern, always-exit-0 error handling
- Claude Code Stop hook mechanics (stdin JSON, stdout JSON, `systemMessage` field)

## Constraints
- Output goes into system reminders — tokens consumed on every subsequent turn until compaction
- Target ~20-30 tokens when warnings present; 0 tokens when clean
- Must not duplicate `cwf-manage validate` (structural integrity), `cwf-status` (progress tracking), or the Task 104 stale-status detector (different failure mode: committed-but-stale vs uncommitted)
- Hook must always exit 0 — non-zero exit surfaces as an error to the user

## Decomposition Check
- [x] **Time**: No — 1 session estimate
- [x] **People**: No — single developer
- [x] **Complexity**: No — 2 concerns (script + hook config), below threshold of 3
- [x] **Risk**: No — low risk, trivially reversible (remove hook entry)
- [x] **Independence**: No — script and config are tightly coupled

**Result**: 0/5 signals triggered. No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 113
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
