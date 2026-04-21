# Discover best gotchas for skills via LMM memory analysis - Implementation Execution
**Task**: 107 (discovery)

## Task Reference
- **Task ID**: internal-107
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/107-discover-best-gotchas-for-skills-via-lmm-mem
- **Template Version**: 2.1

## Goal
Execute LMM queries, cross-reference with secondary sources, and produce ranked backlog items.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md
- [x] Execute LMM queries (broad then targeted)
- [x] Cross-reference with MEMORY.md and retrospectives
- [x] Analyse and rank findings
- [x] Draft backlog items

## Step 1: LMM Queries

### Broad queries executed
1. `"CWF skill mistake error wrong rework correction frustrated"` — 6 results
2. `"cwf workflow problem repeated failure rework agent skipped forgot missed step"` — 15 results
3. `"checkpoint commit retrospective merge staging git status forgotten unstaged files"` — 18 results

### Key findings from LMM
- **Stale status is the #1 recurring error**: "most frequently recurring error in CWF history — at least 6 occurrences across 4 separate cleanup tasks" (Tasks 65, 67, 81, 84, 98, 103)
- **Agent skips workflow phases**: Task 84 backfilled wf files retrospectively instead of calling skills; Task 98 jumped from g-testing-exec to creating a new task without completing retrospective
- **Invalid status values**: Task 84 used "Implemented" (not in allowed set); cwf-implementation-exec SKILL.md itself had wrong status instruction
- **Unstaged files at commit time**: Task 81 missed c-design-plan.md; pattern of forgetting `git status` before committing

## Step 2: Secondary Sources

### MEMORY.md Recurring Process Errors (mapped to skills)
| Error Pattern | Skill(s) Affected |
|---|---|
| Checkpoint commits delayed | All wf step skills |
| Retrospective auto-flow skipped | cwf-retrospective |
| Status sweep skipped before retrospective | cwf-retrospective |
| Merge to main executed (should only suggest) | cwf-retrospective |
| `git status` not run before commit | cwf-implementation-exec, all wf step skills |
| Stale strings after rename | cwf-implementation-exec |
| Workflow shortcuts (skills skipped) | cwf-task-plan (entry point) |

### Retrospective analysis (Tasks 84-105)
Agent searched 22 retrospective files. Key patterns:

**cwf-implementation-plan / cwf-design-plan** (5 occurrences):
Plans written without first verifying codebase state. Tasks 88, 101, 102, 104, 105 all had plans that assumed wrong file paths, missed existing utilities, or chose wrong approach because the codebase wasn't grepped first.

**cwf-implementation-exec** (4 occurrences):
Rename/rebrand tasks leave stale references. Tasks 59→90, 91→94, 92 all had stale strings that survived source-level grep but appeared in generated output.

**cwf-retrospective** (3 occurrences):
Phases skipped or status fields left stale. Tasks 84, 98, 102.

## Step 3: Analysis and Ranking

### Skills with 2+ distinct failure occurrences

| Rank | Skill | Gotcha Count | Impact | Occurrences |
|---|---|---|---|---|
| 1 | cwf-retrospective | 3 gotchas | High | 6+ tasks (65,67,81,84,98,103) |
| 2 | cwf-implementation-exec | 2 gotchas | High | 5+ tasks (59,81,90,91,94) |
| 3 | cwf-implementation-plan | 2 gotchas | High | 5 tasks (88,101,102,104,105) |
| 4 | cwf-design-plan | 1 gotcha | Medium | Same 5 tasks as impl-plan |

### Skills with insufficient data or no patterns
- cwf-task-plan: No specific failures (1 indirect: workflow shortcuts)
- cwf-requirements-plan: No failures found
- cwf-testing-plan: 2 occurrences of over-specification, but low impact
- cwf-testing-exec: No failures found
- cwf-rollout: Insufficient data (most tasks skip)
- cwf-maintenance: Insufficient data (most tasks skip)
- cwf-new-task: No failures found
- cwf-new-subtask: No failures found
- cwf-init: No failures found
- cwf-status: No failures found
- cwf-extract: No failures found
- cwf-config: No failures found
- cwf-current-task: No failures found
- cwf-security-check: No failures found
- test-cwf-skill: No failures found

**19 skills total**: 4 with actionable gotchas, 15 with no patterns or insufficient data.

## Step 4: Draft Backlog Items

### Backlog Item 1: Add Gotchas to cwf-retrospective

**Task-Type**: chore
**Priority**: High
**Status**: Follow-up from Task 107

Gotchas to add near top of SKILL.md:
1. **Stale status fields**: Before writing j-retrospective.md, run `workflow-manager status {task_num} --workflow` and fix any non-terminal statuses. This is the most recurring error in CWF history (6+ occurrences across Tasks 65, 67, 81, 84, 98, 103). The stop-hook (Task 104) catches some cases, but the retrospective skill itself must enforce the check.
2. **Never execute merge to main**: The skill says "Suggest Merge" — output the command, never run it. Caused problems at Tasks 81 and 84.
3. **Don't skip the retrospective**: After testing-exec (g), always proceed to retrospective (j). Task 98 jumped to creating a new task instead. Task 84 backfilled wf files retrospectively instead of calling skills in order.

**Identified in**: Task 107 (LMM memory analysis)

### Backlog Item 2: Add Gotchas to cwf-implementation-exec

**Task-Type**: chore
**Priority**: High
**Status**: Follow-up from Task 107

Gotchas to add near top of SKILL.md:
1. **Run `git status` before every commit**: Check for untracked or unstaged files. Task 81 missed c-design-plan.md. The checkpoint-commit docs say this, but the implementation-exec skill should reinforce it because this is where most commits happen.
2. **After any rename/rebrand, grep the entire codebase AND generate a sample output artefact**: Source-level grep misses stale strings in generated output. This pattern recurred from Task 59 through Tasks 90, 91, 92, and 94 — four consecutive tasks fixing the same class of bug.

**Identified in**: Task 107 (LMM memory analysis)

### Backlog Item 3: Add Gotchas to cwf-implementation-plan

**Task-Type**: chore
**Priority**: Medium
**Status**: Follow-up from Task 107

Gotchas to add near top of SKILL.md:
1. **Grep the codebase before writing the plan**: 5 tasks (88, 101, 102, 104, 105) had plans that assumed wrong paths, missed existing utilities, or chose the wrong approach because no one checked the code first. Pattern: `grep -r "relevant_function" .cwf/` before deciding to create something new.
2. **Check for existing reusable code before proposing new scripts**: Tasks 101 and 104 initially designed standalone scripts when existing library modules could be extended. The plan should explicitly list "Existing code reviewed" with what was checked.

**Identified in**: Task 107 (LMM memory analysis)

### Backlog Item 4: Add Gotchas to cwf-design-plan

**Task-Type**: chore
**Priority**: Medium
**Status**: Follow-up from Task 107

Gotchas to add near top of SKILL.md:
1. **Verify assumptions against the codebase before committing to an approach**: Tasks 104 and 105 chose implementation approaches (bash over Perl; delete module vs generalise it) without checking what existing code could be leveraged. Read 3 similar implementations before proposing a new one.

**Identified in**: Task 107 (LMM memory analysis)

## Blockers Encountered

- LMM user email was `github@mattkeenan.net` (git config), not `claude@mattkeenan.net` (auto-memory). Minor — resolved by checking `git config user.email`.

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 107
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
*To be captured during retrospective*
