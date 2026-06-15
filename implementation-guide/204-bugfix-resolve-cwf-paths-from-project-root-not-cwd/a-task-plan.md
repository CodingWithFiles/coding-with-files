# Resolve .cwf paths from project root, not cwd - Plan
**Task**: 204 (bugfix)

## Task Reference
- **Task ID**: internal-204
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/204-resolve-cwf-paths-from-project-root-not-cwd
- **Baseline Commit**: 186d539cbed996ce47ddc03842d071131ee5b75a
- **Template Version**: 2.1

## Goal
Make CWF skills and helper scripts resolve `.cwf/...` paths from the project (git) root rather than the current working directory, so they work when an agent's cwd is not the repo root.

## Problem Statement
Skill instructions and some scripts reference `.cwf/...` as bare relative paths,
which only resolve when `cwd == git root`. When an agent runs from a subdirectory
(e.g. a nested task folder) the relative paths silently fail.

Survey of the bug (Task-204 research):
- **~138 bare `.cwf/...` references across 20 of 21 `SKILL.md` files** — agent
  instructions like "Run `.cwf/scripts/command-helpers/...`".
- **A few helper scripts** (e.g. `cwf-claude-settings-merge`) still use bare
  relative `.cwf/...` instead of resolving the root.

The repo already ships the canonical fix: `find_git_root()` in
`.cwf/lib/CWF/Common.pm` (Task 173) — **worktree-safe** because it derives the
*main* root from `--git-common-dir`, not `--show-toplevel`. Five helper scripts
already use it correctly. This task standardises on that pattern.

**Note on `CLAUDE_PROJECT_DIR`** (the originally-suggested approach): it is
*hooks-only* — confirmed missing from the general Bash tool environment
(claude-code issue #33815) and undocumented under worktrees. It is therefore
**not** a dependency to introduce; `find_git_root()` remains authoritative. The
design phase will decide whether the env var has any role as an opportunistic
fast-path.

## Success Criteria
- [ ] No CWF skill or script relies on `cwd == git root` to find `.cwf/...`; root is resolved via the canonical `find_git_root()` strategy (or env-var fast-path falling back to it).
- [ ] A skill/script invoked with cwd set to a subdirectory still locates and runs `.cwf/...` correctly (demonstrated by a test).
- [ ] Worktree case verified: resolution returns the main root, not a linked worktree root, consistent with existing `find_git_root()` behaviour.
- [ ] No regression: existing helper-script test suite (`t/`) and `cwf-manage validate` pass; hashes refreshed in the same commit for any hashed file changed.

## Original Estimate
**Effort**: 1-2 days
**Complexity**: Medium (low conceptual difficulty, broad surface — 20+ files)
**Dependencies**: Existing `find_git_root()` in `CWF::Common` (already present)

## Major Milestones
1. **Design the fix pattern**: One canonical instruction form for SKILL.md and one resolution idiom for scripts; decide env-var fast-path question.
2. **Apply to scripts**: Convert remaining bare-relative scripts to `find_git_root()`.
3. **Apply to skills**: Roll the canonical preamble/path form across the 20 affected SKILL.md files.
4. **Verify**: Subdirectory-cwd test + output-level smoke test + suite + validate green.

## Risk Assessment
### High Priority Risks
- **Risk 1**: Broad mechanical change across 20 skills risks inconsistency / missed sites.
  - **Mitigation**: Define one canonical form in design; grep the output surface after applying (memory: rebrands need output-level smoke test, source grep alone insufficient).

### Medium Priority Risks
- **Risk 2**: Changing how skills instruct the agent could alter token cost or be ignored at runtime.
  - **Mitigation**: Prefer the lightest-weight consistent form; favour scripts self-resolving so skill instructions stay simple.
- **Risk 3**: Editing hashed scripts requires same-commit hash refresh and correct working perms.
  - **Mitigation**: Follow hash-updates convention; restore recorded perms; run `cwf-manage validate`.

## Dependencies
- `find_git_root()` (`.cwf/lib/CWF/Common.pm`) — present, worktree-safe.

## Constraints
- Perl core-only; POSIX; British prose; no `CLAUDE_PROJECT_DIR` hard dependency.
- This repo eats its own dog food — change must flow through the CWF workflow.

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? No.
- [x] **People**: >2 people? No.
- [x] **Complexity**: 3+ distinct concerns? No — single concern (root resolution) applied across many files.
- [x] **Risk**: High-risk components needing isolation? No.
- [x] **Independence**: Can parts be worked on separately? Scripts vs skills are separable but trivially small; not worth splitting.

**Verdict**: No decomposition. Single coherent bugfix; 0 signals triggered.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered within the 1–2 day estimate. All four success criteria met: no CWF skill
relies on `cwd == git root` (20 skills carry the worktree-safe anchor); subdirectory
and worktree cases proven by `t/skill-root-anchor.t`; suite (860 tests) and
`cwf-manage validate` green with the one hashed file refreshed in-commit. Scope grew
by one surface (hook registration) discovered live and folded in; see j-retrospective.

## Lessons Learned
The decomposition verdict (0 signals, no split) held — a single coherent bugfix even
after the fold-in. The estimate's "broad surface" call was right; the design-phase
spike is what kept the breadth from becoming a schedule risk.
