# Workflow Steps

Detailed guidance for workflow steps in the CWF system. Each step includes purpose, focus/avoid guidelines, key questions, typical structure, and transition triggers.

Per-step guidance lives in its own file under [`workflow-steps/`](workflow-steps/) — see the [Steps](#steps) index below. Read the single file for the phase you are in; there is no need to read this whole document.

## Version Differences

**v2.0 Format** (8 phases): a-task-plan, b-requirements-plan, c-design-plan, d-implementation-plan, f-testing-plan, h-rollout, i-maintenance, j-retrospective

**v2.1 Format** (10 phases): v2.0 phases + e-testing-plan (moved from f), f-implementation-exec, g-testing-exec (note: e and f swapped from v2.0 order)
- Separates planning from execution for implementation and testing
- Enables clear distinction between "what we'll do" (planning) and "what we did" (execution)
- Planning phases focus on approach, execution phases focus on actual results

This document covers all phases for both v2.0 and v2.1 formats.

## Status Values

When updating the **Status** field in workflow files, use ONLY valid status values from `cwf-project.json`.

### Valid Status Values

The following status values are defined in the project configuration:

- **Backlog** (0%): Task not started, queued for future work
- **Blocked** (15%): Task started but cannot proceed until blocker resolved
- **To-Do** (0%): Task ready to begin, prioritized
- **In Progress** (25%): Work actively underway
- **Testing** (75%): Testing in progress, validation ongoing
- **Finished** (100%): Fully complete, all criteria met
- **Cancelled** (0%): Task abandoned or superseded; terminal status, no further work expected. Document cancellation reason separately. Works with both v2.0 and v2.1 formats.
- **Skipped** (N/A): Phase not applicable to this specific task (may also apply to entire task type) (v2.1 only)

**Using "Skipped" Status** (v2.1 only):

Mark any workflow step as "Skipped" when it's not applicable. This is typically a **per-task decision** (this specific task doesn't need this phase) but may also be a **task-type pattern** (e.g., most bugfixes skip rollout).

Examples:
- **Maintenance** for a specific bugfix (this fix doesn't need ongoing monitoring)
- **Rollout** for internal tools (this tool has no external deployment)
- **Requirements** for a specific hotfix (requirements already clear for this fix)
- **Design** for a trivial change (this change needs no architecture)

"Skipped" phases are excluded from progress calculation. Example: 9 completed + 1 skipped = 9/9 = 100% (not 9/10 = 90%).

**Distinction**: "Skipped" (not applicable to this task) ≠ "Backlog" (not started yet) ≠ "Finished" (completed).

**IMPORTANT**: Do not use arbitrary status values. Always select from this list. If you encounter an unknown status value, the system will warn you and default to 0% completion.

**Source**: `implementation-guide/cwf-project.json` → `.workflow["status-values"]`

## Steps

Each phase's detailed guidance is a standalone document:

- [Planning](workflow-steps/planning.md) — establish objectives, success criteria, and high-level approach
- [Requirements](workflow-steps/requirements.md) — define functional and non-functional requirements with acceptance criteria
- [Design](workflow-steps/design.md) — architecture decisions, component design, and interface contracts
- [Implementation Planning](workflow-steps/implementation-planning.md) — plan steps, files to modify, and validation criteria
- [Implementation Execution](workflow-steps/implementation-execution.md) — execute the plan, recording actual results and deviations
- [Testing Planning](workflow-steps/testing-planning.md) — test strategy, coverage targets, and test cases
- [Testing Execution](workflow-steps/testing-execution.md) — run the test plan, record PASS/FAIL and failures
- [Rollout](workflow-steps/rollout.md) — phased deployment, monitoring, and rollback plan
- [Maintenance](workflow-steps/maintenance.md) — ongoing monitoring, support, and optimization
- [Retrospective](workflow-steps/retrospective.md) — capture learnings, variances, and recommendations
