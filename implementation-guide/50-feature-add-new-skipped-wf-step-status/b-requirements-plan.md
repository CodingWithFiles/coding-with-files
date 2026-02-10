# add-new-skipped-wf-step-status - Requirements
**Task**: 50 (feature)

## Task Reference
- **Task ID**: internal-50
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/50-add-new-skipped-wf-step-status
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for adding "Skipped" workflow step status that excludes inapplicable phases from progress calculation and displays as "N/A".

## Functional Requirements
### Core Features

- **FR1: Configuration Schema for "Skipped" Status**
  - Add "Skipped" status to `cig-project.json` workflow.status-values with `null` value
  - Null value signals: exclude from progress calculation (not 0%, not 100%, not counted)
  - Preserves existing status values (Backlog, Blocked, To-Do, In Progress, Implemented, Testing, Finished)
  - **Acceptance**: `jq '.workflow["status-values"]["Skipped"]'` returns `null` in cig-project.json

- **FR2: Status Aggregator Exclusion Logic (v2.1 Only)**
  - Modify `status-aggregator-v2.1` ONLY to skip phases with "Skipped" status
  - v2.0 format remains unchanged (historic format, no modifications)
  - Excluded phases: not included in denominator (total applicable phases)
  - Progress calculation: (completed applicable phases) / (total applicable phases)
  - Example: 9 completed + 1 skipped = 9/9 = 100% (not 9/10 = 90%)
  - **Acceptance**: v2.1 task with 1 skipped phase shows 100% when all other phases complete

- **FR3: Display Format for Skipped Phases**
  - `--workflow` output displays "Skipped" phases as "Skipped (N/A)" not percentages
  - Distinguishes "Skipped (N/A)" from "Backlog (0%)" and "Finished (100%)"
  - LLM-readable format: explicitly shows phase not applicable rather than incomplete
  - Human-readable: clear indication phase was intentionally excluded
  - **Acceptance**: `cig-status --workflow` shows "Phase: Skipped (N/A)" for skipped phases

- **FR4: Documentation and Guidance**
  - Update `.cig/docs/workflow/workflow-steps.md` with "Skipped" status definition
  - Explain when to use: any workflow step not applicable to specific task (per-task decision, may also be task-type pattern)
  - Examples: Maintenance for specific bugfix, Rollout for internal tool, Requirements for specific hotfix, Design for trivial change
  - Clarify distinction: "Skipped" (not applicable to this task) vs "Backlog" (not started yet) vs "Finished" (completed)
  - **Acceptance**: Documentation includes "Skipped" status with usage examples emphasizing per-task decisions

- **FR5: Backward Compatibility**
  - v2.0 tasks: No changes, continue using existing status values only
  - v2.1 tasks: Can optionally use new "Skipped" status
  - Existing v2.1 tasks without "Skipped" status continue working unchanged
  - No migration required for existing task directories
  - **Acceptance**: Run status aggregator on existing v2.0 and v2.1 tasks, all show correct progress

### User Stories

- **As a developer** using CIG for bugfix tasks **I want** to mark any inapplicable workflow step as "Skipped" (e.g., Requirements, Maintenance) **so that** my progress calculation reflects actual work (7/7 = 100%) instead of penalizing me for skipping inapplicable phases (7/10 = 70%)

- **As a developer** reviewing workflow status **I want** to see "Skipped (N/A)" for excluded phases **so that** I understand the phase was intentionally skipped (not forgotten or incomplete)

- **As an LLM agent** using CIG workflow **I want** clear "Skipped" status semantics **so that** I can correctly determine which phases apply to this specific task and accurately calculate progress

- **As a project maintainer** reviewing completed tasks **I want** "Skipped" phases to be explicit in the workflow history **so that** retrospectives accurately reflect which phases were applicable vs skipped for this specific task

## Non-Functional Requirements

### Performance (NFR1)
- **Zero performance degradation**: Status aggregation with "Skipped" phases must execute within same time bounds as current system (<100ms for typical task hierarchies)
- **Minimal computation overhead**: Null check for "Skipped" value adds negligible overhead (single hash lookup per phase)
- **No memory impact**: Status aggregator memory usage unchanged (same data structures, just conditional logic for null values)
- **Scalability**: Performance remains constant regardless of number of skipped phases (O(1) per phase check)

### Usability (NFR2)
- **Intuitive semantics**: "Skipped" status name clearly indicates phase not applicable (self-documenting)
- **Clear display format**: "Skipped (N/A)" explicitly shows phase excluded, no ambiguity with incomplete work
- **LLM understandability**: "N/A" label helps LLM agents distinguish skipped phases from incomplete phases
- **Documentation accessibility**: Usage examples in workflow-steps.md guide developers on when to use "Skipped"
- **Consistency with existing patterns**: Follows same status value pattern as Backlog/Finished (name + percentage)
- **Error recovery**: If "Skipped" used incorrectly, progress calculation still works (treated as valid status, just excluded from denominator)

### Maintainability (NFR3)
- **Code clarity**: Status aggregator v2.1 logic uses explicit null check (`if (defined $status_value)`) rather than magic values
- **DRY principle**: Single source of truth in cig-project.json for "Skipped" status definition
- **Modularity**: Aggregation logic change isolated to status-aggregator-v2.1 only, no changes to v2.0 or display tools
- **Version isolation**: v2.0 aggregator unchanged (reduces risk, maintains historic format stability)
- **Testability**: Status exclusion logic testable via v2.1 tasks with different status combinations
- **Minimal code changes**: <15 lines of code changed in 1 aggregator script + 1 config file + 1 doc file

### Security (NFR4)
- **No security impact**: Status aggregation change does not affect system security model
- **Hash verification**: Updated script hashes in `.cig/security/script-hashes.json` after aggregator modifications
- **Permission model unchanged**: Status aggregator scripts retain u+rx (0500) permissions
- **No new attack surface**: Null value handling follows existing Perl idioms, no eval or dynamic code

### Reliability (NFR5)
- **Backward compatibility**: Existing tasks without "Skipped" status continue working (graceful degradation)
- **Forward compatibility**: New "Skipped" status works with existing CIG commands (no tool changes required)
- **Error handling**: Status aggregators handle missing status values gracefully (default to 0% if not found)
- **Data integrity**: cig-project.json remains valid JSON with null value (JSON spec allows null)
- **Rollback safety**: Change reversible by removing "Skipped" from config and reverting aggregator scripts

## Constraints

### Technical Constraints
- **JSON null value handling**: Perl status aggregator v2.1 must correctly handle JSON null values (not undefined, not empty string, not 0)
- **v2.1 only**: "Skipped" status only available in v2.1 format (v2.0 is historic, no modifications)
- **v2.0 unchanged**: status-aggregator-v2.0 requires no changes, continues with existing status values
- **Display tool compatibility**: `cig-status --workflow` output format must distinguish "Skipped (N/A)" from numeric percentages
- **String-based status matching**: Workflow files contain "Status: Skipped" as text, aggregators parse via regex/pattern matching

### Integration Constraints
- **No breaking changes**: Existing v2.0 and v2.1 tasks must continue working without modification
- **v2.1 only feature**: "Skipped" status only available for v2.1 tasks (documentation must clarify)
- **Consistent behavior across tools**: cig-status, workflow-manager, and status-aggregator-v2.1 must all handle "Skipped" identically
- **Documentation synchronisation**: workflow-steps.md must align with cig-project.json status definitions and note v2.1 requirement

### Resource Constraints
- **Time**: 1-2 days (8-16 hours) as per planning estimate
- **Scope**: Limited to status aggregation system (config, aggregators, display, docs) - no workflow template changes
- **Testing**: Must validate with existing v2.0 and v2.1 tasks to ensure backward compatibility

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - estimated 1-2 days (8-16 hours)
- [ ] **People**: Does this need >2 people working on different parts? **NO** - single developer task
- [ ] **Complexity**: Does this involve 3+ distinct concerns? **YES** - config, aggregator logic, display, docs (4 concerns) BUT tightly coupled
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** - changes are straightforward with comprehensive testing
- [ ] **Independence**: Can parts be worked on separately? **NO** - config, aggregators, and display must work together atomically

**Decomposition Decision**: No subtasks. While complexity signal triggers (4 concerns), requirements clarify they're tightly coupled and must be implemented atomically. Config defines null value, aggregators use it, display shows it, docs explain it - breaking apart adds coordination overhead without benefit.

## Acceptance Criteria

### Functional Acceptance Criteria
- [ ] **AC1: Configuration updated**: `jq '.workflow["status-values"]["Skipped"]' implementation-guide/cig-project.json` returns `null`
- [ ] **AC2: Status aggregator v2.1 excludes skipped phases**: v2.1 task with 1 skipped phase + 9 finished phases shows 9/9 = 100% progress
- [ ] **AC3: Status aggregator v2.0 unchanged**: v2.0 tasks continue showing correct progress with existing status values (no "Skipped" support)
- [ ] **AC4: Display format correct**: `cig-status --workflow` shows "Phase: Skipped (N/A)" for skipped phases in v2.1 tasks
- [ ] **AC5: Documentation complete**: `.cig/docs/workflow/workflow-steps.md` includes "Skipped" status definition with v2.1 requirement noted

### Non-Functional Acceptance Criteria
- [ ] **AC6: Backward compatibility**: v2.0 tasks unchanged, v2.1 tasks without "Skipped" status show correct progress (no regression)
- [ ] **AC7: Performance**: Status aggregation with "Skipped" phases in v2.1 executes within same time bounds (<100ms)
- [ ] **AC8: Security**: Updated script hash recorded in `.cig/security/script-hashes.json` for status-aggregator-v2.1 only

### Integration Acceptance Criteria
- [ ] **AC9: Format isolation**: v2.0 aggregator unchanged, v2.1 aggregator handles "Skipped" with null check and exclusion logic
- [ ] **AC10: BACKLOG resolution**: "Clarify Maintenance Phase Applicability" BACKLOG item addressed (v2.1 developers can now mark any workflow step as "Skipped" when not applicable)

## Status
**Status**: Finished
**Next Action**: /cig-design-plan 50
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
