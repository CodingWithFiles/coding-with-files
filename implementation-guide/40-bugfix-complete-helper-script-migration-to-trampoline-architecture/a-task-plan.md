# complete helper script migration to trampoline architecture - Plan

## Task Reference
- **Task ID**: internal-40
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/40-complete-helper-script-migration-to-trampoline-architecture
- **Template Version**: 2.1

## Goal
Complete the migration of all remaining CIG helper scripts to the trampoline/module architecture established in Task 39, consolidating permission patterns from 7+ to 3 semantic trampolines (context-manager, workflow-manager, task-workflow) for consistent, extensible helper script management.

## Success Criteria
- [ ] **SC1: Helper Script Migration** - All 6 remaining helper scripts migrated to 7 trampoline subcommands with proper version routing (hierarchy, inheritance, version, status, control, create)
- [ ] **SC2: Trampoline Creation** - Two new trampolines created and operational (workflow-manager, task-workflow) with proper module organization
- [ ] **SC3: Context-Manager Enhancement** - Expand context-manager with 3 new subcommands (hierarchy, inheritance, version) where version COMBINES format-detector + template-version-parser
- [ ] **SC4: CIG Command Updates** - All CIG commands (.claude/commands/cig-*.md) updated to use new semantic trampoline calls instead of direct script calls
- [ ] **SC5: Permission Simplification** - Frontmatter consolidated to 3 permission patterns: context-manager:*, workflow-manager:*, task-workflow:*
- [ ] **SC6: Zero Permission Prompts** - All CIG commands execute without triggering permission prompts (validated through testing)
- [ ] **SC7: Backward Compatibility** - Existing tasks (1-39) continue to function correctly with new architecture
- [ ] **SC8: Version Routing** - 3 modules preserve version routing (inheritance, status, control) while 4 are version-agnostic

## Original Estimate
**Effort**: 3-4 hours (Based on Task 39 experience: 4 hours for 1 trampoline + 17 commands; this is 2 trampolines + similar command updates)
**Complexity**: Medium
- Follows established pattern from Task 39 (context-manager trampoline)
- Requires careful coordination of 6 helper script migrations
- Multiple CIG commands affected (17 files, some need multiple helper calls updated)
- Must maintain backward compatibility with Tasks 1-39

**Dependencies**:
- Task 39 complete (context-manager trampoline establishes pattern)
- All 6 existing helper scripts functional (hierarchy-resolver, context-inheritance, format-detector, status-aggregator, workflow-control, template-version-parser, template-copier)
- Unix conventions for Perl scripts (no extensions, executable permissions, proper shebang)

## Major Milestones
1. **Context-Manager Expansion** (45 min)
   - Migrate 3 helpers to context-manager subcommands: hierarchy, inheritance, version
   - COMBINE format-detector + template-version-parser into single `version` subcommand
   - Create 3 module files in context-manager.d/ directory
   - Update context-manager trampoline dispatch logic (add 3 entries)

2. **Workflow-Manager Creation** (60 min)
   - Create workflow-manager trampoline (copy context-manager pattern)
   - Create workflow-manager.d/ directory
   - Migrate status-aggregator and workflow-control to status/control modules
   - Preserve version routing for both modules (read/write version-specific workflow files)

3. **Task-Workflow Creation** (30 min)
   - Create task-workflow trampoline (semantic naming: "create workflow" vs "copy templates")
   - Create task-workflow.d/ directory
   - Migrate template-copier to create module (ALWAYS v2.1, no version routing)
   - Single subcommand architecture

4. **CIG Command Updates** (60 min)
   - Update all 17 CIG commands to use new semantic trampoline calls
   - Simplify frontmatter permission patterns to 3 trampolines
   - Remove direct calls to old standalone scripts

5. **Testing & Validation** (30 min)
   - Execute comprehensive test suite (functional + non-functional)
   - Verify zero permission prompts across all commands
   - Validate backward compatibility with existing tasks
   - Verify version routing works correctly for 3 modules

## Risk Assessment
### High Priority Risks
- **R1: Breaking Backward Compatibility** - Updating helper calls might break existing tasks (1-39) that rely on current script behavior
  - **Impact**: Tasks 1-39 fail to execute, blocking all current work
  - **Mitigation**:
    - Keep old standalone scripts until migration verified working
    - Test against representative sample tasks (v2.0 and v2.1 formats)
    - Implement trampoline routing to maintain identical module behavior
    - Remove old scripts only after comprehensive testing confirms success

- **R2: Permission Prompt Regression** - New trampoline implementation might still trigger permission prompts despite architectural changes
  - **Impact**: Primary goal (zero permission prompts) not achieved, Task 40 fails
  - **Mitigation**:
    - Test permission behavior immediately after each trampoline creation
    - Follow Task 39's proven pattern exactly (Perl dispatcher + module routing)
    - Add specific test cases for permission prompt detection
    - Validate with actual command execution, not just unit tests

### Medium Priority Risks
- **R3: Incomplete Migration** - Missing helper script calls in CIG commands leaves inconsistent architecture
  - **Impact**: Some commands use old patterns, some use trampolines (architectural inconsistency)
  - **Mitigation**:
    - Create comprehensive inventory of all helper script calls before starting
    - Use grep to find all references: `.cig/scripts/command-helpers/{script-name}`
    - Verify each CIG command updated with test execution
    - Document mapping: old script call → new trampoline call

- **R4: Trampoline Dispatch Logic Errors** - Incorrect routing in trampolines causes wrong subcommand execution
  - **Impact**: Helper functions fail or execute wrong behavior
  - **Mitigation**:
    - Test each subcommand independently after creation
    - Follow context-manager pattern exactly (hash table dispatch, error handling)
    - Add error messages for unknown subcommands
    - Validate dispatch logic with edge cases (missing args, invalid subcommands)

## Dependencies
### External Requirements
- **Task 39 Complete**: context-manager trampoline establishes the architectural pattern that Task 40 follows
- **Existing Helper Scripts**: All 6 target scripts must be functional and tested
  - hierarchy-resolver
  - context-inheritance
  - format-detector
  - status-aggregator
  - workflow-control
  - template-version-parser
  - template-copier

### Technical Prerequisites
- **Perl Environment**: Perl interpreter available with required modules
- **Unix Conventions**: File system supports executable permissions (u+rx minimum 0500)
- **Git Repository**: Must be in git repository root for testing

### No Team Dependencies
- Single-agent task, no coordination required
- No external API or service dependencies
- No waiting on user input during implementation (design decisions already established in Task 39)

## Constraints
### Technical Constraints
- **Pattern Adherence**: Must follow exact trampoline/module pattern from Task 39 (Perl dispatcher with hash table routing)
- **Unix Conventions**: No file extensions, executable permissions, proper shebang (`#!/usr/bin/env perl`)
- **Backward Compatibility**: Cannot break existing tasks (1-39) - new architecture must be transparent to existing workflows
- **Permission Model**: Must maintain zero permission prompts - trampoline invocation is only permission boundary

### Architectural Boundaries
- **Scope Limit**: Only migrate existing helper scripts, do not add new functionality or refactor module internals
- **Module Preservation**: Keep module logic identical to current implementations - this is a structural migration, not a rewrite
- **Directory Structure**: Follow .cig/scripts/command-helpers/{trampoline}.d/{module} pattern established by context-manager

### Timeline Constraints
- **Target**: 3-4 hours total (based on Task 39 experience and BACKLOG estimate)
- **Batching**: Part of Task 35-40 batch merge to main, should complete before batch merge
- **No Blockers**: All dependencies met (Task 39 complete, all helpers functional)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** - Estimated 3-4 hours, well under 1 week threshold
- [ ] **People**: Does this need >2 people working on different parts? **NO** - Single-agent task, no coordination needed
- [x] **Complexity**: Does this involve 3+ distinct concerns? **YES** - Three distinct concerns:
  - Concern 1: Context-manager expansion (3 subcommands)
  - Concern 2: Workflow-manager creation (2 subcommands)
  - Concern 3: Template-manager creation (2 subcommands)
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** - Risks manageable through incremental testing, no need for isolation
- [x] **Independence**: Can parts be worked on separately? **PARTIAL** - Trampolines are independent (could work on workflow-manager while context-manager is complete), but CIG command updates depend on all trampolines being ready

**Decomposition Decision**: **NO DECOMPOSITION NEEDED**

**Reasoning**:
- Only 2/5 signals triggered (Complexity + Partial Independence)
- Time estimate well within acceptable range (3-4 hours << 1 week)
- All 3 concerns follow identical pattern (create trampoline, migrate modules, test)
- Sequential implementation is more efficient than parallel subtasks due to pattern reuse
- Risk of breaking changes is mitigated by incremental testing, not isolation
- CIG command updates must wait for all trampolines anyway, so no parallelization benefit

**Alternative Considered**: Create 3 subtasks (40.1 context-manager, 40.2 workflow-manager, 40.3 template-manager)
**Rejected Because**: Overhead of subtask management exceeds benefit. Pattern is established (Task 39), implementation is straightforward repetition, and there's no waiting/coordination needed. Better to implement sequentially in single task with clear milestones.

## Status
**Status**: Finished
**Completion**: Task completed successfully - all trampolines created, CIG commands updated, testing passed
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
