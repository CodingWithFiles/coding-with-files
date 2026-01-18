# Separate Planning from Execution Phases with Explicit Execution Commands - Requirements

## Task Reference
- **Task ID**: internal-25
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/25-separate-planning-from-execution-phases-with-expli
- **Template Version**: 2.0

## Goal
Define functional and non-functional specifications for expanding CIG from 8-phase to 10-phase workflow with explicit execution commands and clarified planning vs execution semantics.

## Functional Requirements

### Core Workflow Expansion

**FR1: Create Execution Workflow Commands**
- **Requirement**: Create two new workflow command files: `cig-implementation-exec.md` and `cig-testing-exec.md`
- **Purpose**: Separate execution from planning for implementation and testing phases
- **Acceptance Criteria**:
  - cig-implementation-exec.md created with execution-focused guidance (read d-implementation-plan.md → execute steps → update e-implementation-exec.md with actual results)
  - cig-testing-exec.md created with execution-focused guidance (read f-testing-plan.md → run tests → record results in g-testing-exec.md)
  - Both commands include blocker handling guidance (when to revert to earlier planning phases)
  - Both commands follow existing CIG command file structure and patterns

**FR2: Create Execution Template Files and Re-letter Existing Templates**
- **Requirement**: Create new execution phase templates and re-letter existing templates to maintain sequential a-j ordering
- **New Templates**:
  - `e-implementation-exec.md.template` (NEW - execution phase)
  - `g-testing-exec.md.template` (NEW - execution phase)
- **Re-lettered Templates** (shift existing execution phases):
  - `e-testing.md` → `f-testing-plan.md` (planning phase)
  - `f-rollout.md` → `h-rollout.md` (execution phase)
  - `g-maintenance.md` → `i-maintenance.md` (execution phase)
  - `h-retrospective.md` → `j-retrospective.md` (execution phase)
- **Rationale**: Sequential lettering (a-j) is clearer than numeric suffixes (d2, e2) and maintains alphabetical workflow order
- **Acceptance Criteria**:
  - New execution templates (e, g) created with execution-focused sections
  - Existing templates (e→f, f→h, g→i, h→j) renamed in template pool
  - Templates include sections for: execution steps, actual results, blocker documentation
  - Symlinks configured per task type (feature: 10 files, bugfix: 7, hotfix: 7, chore: 6)

**FR3: Document 10-Phase Workflow Order**
- **Requirement**: Update `.cig/docs/workflow/workflow-steps.md` with new 10-phase workflow
- **New Order**:
  1. cig-task-plan - High-level planning (goals, milestones, risks)
  2. cig-requirements-plan - Define functional/non-functional requirements
  3. cig-design-plan - Architecture and design decisions
  4. cig-implementation-plan - Implementation planning (files to modify, steps, approach)
  5. cig-testing-plan - Test strategy and test case definition
  6. cig-implementation-exec - **NEW**: Execute implementation (write code, make changes)
  7. cig-testing-exec - **NEW**: Execute tests (run tests, validate results)
  8. cig-rollout - Deployment strategy and execution
  9. cig-maintenance - Ongoing support planning
  10. cig-retrospective - Capture learnings and commit
- **Acceptance Criteria**:
  - workflow-steps.md updated with 10-phase order
  - Clear distinction between planning phases (1-5) and execution phases (6-10)
  - Each phase documented with purpose, focus, avoid, key questions

**FR4: Document Blocker-Driven Workflow Reversion in workflow-steps.md**
- **Requirement**: Document the conceptual framework for workflow reversion when blockers are encountered
- **Scope**: Update `.cig/docs/workflow/workflow-steps.md` with blocker-driven reversion patterns
- **Key Principle**: Any workflow step can revert to an earlier step when blocked, then restart from reversion point
- **Examples Required**:
  - cig-implementation-exec discovers design gap → revert to cig-design-plan
  - cig-testing-exec reveals missing requirements → revert to cig-requirements-plan
  - cig-implementation-exec hits technical blocker → revert to cig-task-plan
- **Acceptance Criteria**:
  - Blocker-driven reversion conceptual framework documented in workflow-steps.md
  - Examples show when to revert and how to restart workflow from reversion point
  - State machine description included: forward progress + backward reversion paths
  - Guidance on identifying appropriate reversion points

### Naming and Semantic Clarity

**FR5: Rename Workflow Template Files with "-plan" Suffix and Re-letter for Sequential Ordering**
- **Requirement**: Rename planning templates to add "-plan" suffix and re-letter all templates to maintain sequential a-j ordering
- **Planning Phase Renames** (add -plan suffix):
  - `a-plan.md` → `a-task-plan.md`
  - `b-requirements.md` → `b-requirements-plan.md`
  - `c-design.md` → `c-design-plan.md`
  - `d-implementation.md` → `d-implementation-plan.md`
- **Testing Phase Rename** (planning, gets both -plan suffix AND re-lettered):
  - `e-testing.md` → `f-testing-plan.md` (was e, becomes f due to new e-implementation-exec.md)
- **Execution Phase Re-lettering** (shift letters to accommodate new e and g):
  - `f-rollout.md` → `h-rollout.md` (shift from f to h)
  - `g-maintenance.md` → `i-maintenance.md` (shift from g to i)
  - `h-retrospective.md` → `j-retrospective.md` (shift from h to j)
- **Rationale**:
  - "-plan" suffix makes planning phases explicit
  - Sequential a-j lettering maintains alphabetical workflow order
  - Avoids confusing numeric suffixes (d2, e2)
- **Final Sequence** (a-j):
  - a-task-plan.md, b-requirements-plan.md, c-design-plan.md, d-implementation-plan.md
  - e-implementation-exec.md (NEW), f-testing-plan.md, g-testing-exec.md (NEW)
  - h-rollout.md, i-maintenance.md, j-retrospective.md
- **Acceptance Criteria**:
  - All template files in `.cig/templates/pool/` renamed as specified
  - All symlinks in `.cig/templates/{feature,bugfix,hotfix,chore,discovery}/` updated
  - template-copier.pl updated to use new names
  - format-detector.pl updated to recognize new names
  - Existing tasks (1-24) continue working with old names (backward compatibility)

**FR6: Rename Workflow Commands to Include "-plan" Suffix**
- **Requirement**: Rename workflow commands to clarify they are planning commands
- **Renames**:
  - `cig-plan` → `cig-task-plan`
  - `cig-requirements` → `cig-requirements-plan`
  - `cig-design` → `cig-design-plan`
  - `cig-implementation` → `cig-implementation-plan`
  - `cig-testing` → `cig-testing-plan`
  - `cig-rollout` → `cig-rollout` (no change - already execution)
  - `cig-maintenance` → `cig-maintenance` (no change - already execution)
  - `cig-retrospective` → `cig-retrospective` (no change - already execution)
- **Rationale**: Makes explicit that these commands are for planning, not execution
- **Acceptance Criteria**:
  - All command files in `.claude/commands/` renamed
  - All references in documentation updated
  - All workflow step references in command files updated
  - Backward compatibility: consider aliases or deprecation warnings for old names

**FR7: Add Explicit Planning vs Execution Documentation to Commands**
- **Requirement**: Add prominent notices at top of command files explaining planning vs execution
- **For cig-requirements-plan and cig-design-plan**:
  - Add notice: "⚠️ PLANNING ONLY: This command is for defining requirements/design, not implementing them. No code execution happens in this phase."
- **For cig-implementation-plan and cig-testing-plan**:
  - Add notice: "⚠️ PLANNING HALF: This command is for planning implementation/testing, not executing it. Use `cig-implementation-exec` or `cig-testing-exec` to actually execute the plan."
- **Acceptance Criteria**:
  - All 4 planning commands have prominent notices at top
  - Notices explain what phase does and what it doesn't do
  - References to execution commands included where appropriate

### Infrastructure Updates

**FR8: Update status-aggregator.pl for 10-Phase Workflow**
- **Requirement**: Recognize new workflow files and handle both 8-phase and 10-phase tasks
- **Detection Strategy**: If `e-implementation-exec.md` exists → 10-phase (v2.1), else if `a-plan.md` exists → 8-phase (v2.0), else legacy (v1.0)
- **Acceptance Criteria**:
  - status-aggregator.pl recognizes e-implementation-exec.md and g-testing-exec.md files
  - Progress calculation works for both 8-phase (Tasks 1-24) and 10-phase (Task 25+)
  - No regression: existing tasks still calculate correctly
  - Correctly identifies v2.0 (a-h) vs v2.1 (a-j) workflow versions

**FR9: Update template-copier.pl for New File Counts**
- **Requirement**: Handle new file counts per task type with sequential a-j workflow files
- **New Counts** (10-phase v2.1):
  - Feature: 10 files (a-task-plan, b-requirements-plan, c-design-plan, d-implementation-plan, e-implementation-exec, f-testing-plan, g-testing-exec, h-rollout, i-maintenance, j-retrospective)
  - Bugfix: 7 files (a-task-plan, c-design-plan, d-implementation-plan, e-implementation-exec, f-testing-plan, g-testing-exec, j-retrospective)
  - Hotfix: 7 files (a-task-plan, d-implementation-plan, e-implementation-exec, f-testing-plan, g-testing-exec, h-rollout, j-retrospective)
  - Chore: 6 files (a-task-plan, d-implementation-plan, e-implementation-exec, f-testing-plan, g-testing-exec, j-retrospective)
  - Discovery: 8 files (a-task-plan, b-requirements-plan, c-design-plan, d-implementation-plan, e-implementation-exec, f-testing-plan, g-testing-exec, j-retrospective)
- **Acceptance Criteria**:
  - template-copier.pl handles new file counts for v2.1 workflow
  - Symlink structure in `.cig/templates/{type}/` updated to point to correct a-j templates
  - Variable substitution works for new template files

**FR10: Add Blocker Handling Guidance to All Workflow Commands**
- **Requirement**: Update all workflow command files to include blocker handling sections with phase-specific guidance
- **Scope**: All 10 workflow commands (after renaming):
  - Planning commands: cig-task-plan, cig-requirements-plan, cig-design-plan, cig-implementation-plan, cig-testing-plan
  - Execution commands: cig-implementation-exec, cig-testing-exec
  - Rollout commands: cig-rollout, cig-maintenance, cig-retrospective
- **Content Requirements**:
  - Dedicated "Blocker Handling" section in each command file
  - Phase-specific examples of common blocker scenarios
  - Guidance on when to revert to earlier phases
  - Examples of appropriate reversion points for that specific phase
- **Rationale**: Separates conceptual framework (FR4: workflow-steps.md documentation) from practical implementation (FR10: command file updates with actionable guidance)
- **Acceptance Criteria**:
  - All 10 command files include "Blocker Handling" section
  - Examples are specific to each phase's common blockers
  - Reversion guidance is consistent with workflow-steps.md state machine
  - Each command provides actionable next steps when blocked

### Implementation Process

**FR11: Checkpoint Commits at Implementation Boundaries**
- **Requirement**: Implementation plan must define checkpoint commits at suitable boundaries to improve traceability
- **Rationale**: Due to tight coupling and architectural refactoring, checkpoint commits provide granular tracking and facilitate rollback if issues arise
- **Checkpoint Requirements**:
  - Each checkpoint represents a logically complete, testable unit of work
  - Commits must pass all existing tests (no broken intermediate states)
  - Commit messages explain what changed, why, and what remains
  - Checkpoints align with major functional boundaries
- **Suggested Checkpoint Boundaries** (6-9 recommended):
  1. Extract Core modules from existing scripts (trampoline foundation)
  2. Implement trampoline entry points and v2.0 orchestration scripts
  3. Deprecate v1.0 (remove V10 modules, add deprecation errors)
  4. Rename and re-letter v2.0 templates (a-e with -plan suffix, e→f, f→h, g→i, h→j)
  5. Create v2.1 execution templates and infrastructure (e, g templates + V21 modules)
  6. Rename workflow commands with -plan suffix and add notices
  7. Add blocker handling sections to all 10 workflow commands
  8. Create new execution commands (cig-implementation-exec, cig-testing-exec)
  9. Update documentation and finalize (workflow-steps.md, status-aggregator v2.1 detection)
- **Benefits**:
  - Easier identification of what changed when issues arise
  - Clear audit trail for backward compatibility verification
  - Facilitates code review by logical groupings
  - Enables partial rollback if specific changes cause problems
  - Trampoline architecture changes isolated from workflow changes
- **Acceptance Criteria**:
  - Implementation plan (d-implementation-plan.md) defines checkpoint boundaries
  - Each checkpoint listed with specific files/changes included
  - Minimum 6-9 checkpoints identified (increased from 4-6 due to trampoline refactoring)
  - Checkpoint sequence ensures no breaking changes in intermediate states
  - Each checkpoint includes validation that existing Tasks 1-24 still work

**FR12: Implement Trampoline Architecture for Version Management**
- **Requirement**: Refactor helper scripts to use trampoline pattern with version-specific implementations and shared Core modules
- **Rationale**: Enables clean version deprecation while maintaining DRY principles; provides defined process for managing multiple workflow versions as CIG evolves
- **Deprecation Note**: v1.0 format support will be deprecated in this task (remove v1.0 orchestration scripts). v1.0→v2.0 migration tools will be preserved for users still migrating from v1.0
- **Architecture Pattern**:
  - **Entry point scripts** (thin, ~20 lines): Call format-detector, trampoline to version-specific implementation
  - **Version-specific orchestration** (~50 lines each): Load appropriate data modules, call Core modules, handle version quirks
  - **Shared Core modules** (bulk of logic): Common algorithms, formatting, validation shared across versions
  - **Version-specific data modules**: File mappings, version-specific constants
- **Scripts to Refactor**:
  - `status-aggregator` → `status-aggregator-v2.0`, `status-aggregator-v2.1` + `CIG::StatusAggregator::Core`
  - `template-copier` → `template-copier-v2.0`, `template-copier-v2.1` + `CIG::TemplateCopier::Core`
  - `context-inheritance` → `context-inheritance-v2.0`, `context-inheritance-v2.1` + `CIG::ContextInheritance::Core`
  - Note: v1.0-specific scripts will be removed as part of deprecation
- **Core Modules** (shared logic, 80% of code):
  - `CIG::StatusAggregator::Core` - Progress calculation, output formatting, hierarchy traversal
  - `CIG::TemplateCopier::Core` - Variable substitution, file copying, symlink resolution
  - `CIG::ContextInheritance::Core` - Structural maps, status parsing, parent aggregation
- **Version Data Modules** (file mappings):
  - `CIG::WorkflowFiles::V20` - v2.0 workflow file mappings (a-plan.md through h-retrospective.md)
  - `CIG::WorkflowFiles::V21` - v2.1 workflow file mappings (a-task-plan.md through j-retrospective.md)
  - Note: `CIG::WorkflowFiles::V10` will be removed as part of v1.0 deprecation
- **Deprecation Path**: Delete version-specific script + data module, update entry point to show deprecation notice
- **v1.0 Deprecation in This Task**:
  - Remove `*-v1.0` orchestration scripts for status-aggregator, template-copier, context-inheritance
  - Remove `CIG::WorkflowFiles::V10` module
  - Update entry points to error with deprecation message if v1.0 task detected
  - Preserve v1.0→v2.0 migration tools (separate scripts, not touched by this task)
- **Acceptance Criteria**:
  - Entry point scripts detect version and dispatch correctly to v2.0 or v2.1
  - Version-specific orchestration scripts exist for v2.0 and v2.1 only
  - Core modules contain shared logic (no duplication of algorithms)
  - Version data modules contain only version-specific mappings (V20, V21)
  - v2.0 and v2.1 work correctly via trampoline
  - v1.0 tasks show clear deprecation error with migration instructions
  - Code duplication < 25% (vs 100% without shared modules)

**FR13: Comprehensive Testing for Multi-Version Support**
- **Requirement**: Test suite must validate supported workflow versions (v2.0, v2.1) and architectural components independently
- **Rationale**: Two-version support requires systematic testing to prevent regressions; trampoline architecture creates new test boundaries
- **Test Coverage Requirements**:
  - **Version detection**: format-detector correctly identifies v2.0 and v2.1 (and shows deprecation error for v1.0)
  - **Core modules**: Unit tests for shared logic (status calculation, template substitution, context inheritance)
  - **Version-specific orchestration**: Integration tests for v2.0 and v2.1 scripts
  - **Backward compatibility**: Tasks 1-24 (v2.0) still work after changes
  - **New version validation**: v2.1 workflow files recognized and processed
  - **Trampoline dispatch**: Entry points correctly route to v2.0 or v2.1 implementations
  - **v1.0 deprecation**: Entry points show clear error message for v1.0 tasks with migration instructions
- **Test Task Requirements**:
  - Create test task with v2.0 format (a-plan.md through h-retrospective.md)
  - Create test task with v2.1 format (a-task-plan.md through j-retrospective.md)
  - Optionally create v1.0 test task to verify deprecation error message
  - Run all helper scripts against test tasks
- **Validation Scripts**:
  - Test runner that validates v2.0 and v2.1 work correctly
  - Regression test against existing Tasks 1-24 (v2.0)
  - Format detection accuracy test (v2.0, v2.1, v1.0 deprecation)
- **Acceptance Criteria**:
  - All Core modules have unit tests
  - All version-specific scripts (v2.0, v2.1) have integration tests
  - Test tasks exist for v2.0 and v2.1
  - All tests pass before each checkpoint commit
  - Existing Tasks 1-24 verified working after implementation
  - v1.0 deprecation error message tested and documented
  - Test coverage documented in f-testing-plan.md

### User Stories

**US1**: As a developer implementing a feature, I want separate planning and execution commands so I can plan my approach before coding and avoid mixing planning with execution.

**US2**: As a developer hitting a blocker during implementation, I want clear guidance on when to revert to earlier planning phases so I can fix the root cause instead of working around it.

**US3**: As a developer new to CIG, I want workflow file names that clearly indicate planning vs execution so I understand what each phase does without reading documentation.

**US4**: As a developer running planning commands, I want prominent notices explaining this is planning-only so I don't accidentally start implementing before planning is complete.

**US5**: As a developer working on existing tasks, I want backward compatibility so my Task 1-24 workflows continue working even after the 10-phase system is introduced.

## Non-Functional Requirements

### Performance (NFR1)
- **Requirement**: No noticeable performance degradation from additional workflow files
- **Acceptance Criteria**:
  - status-aggregator.pl completes in <500ms for tasks with 10 files
  - template-copier.pl completes in <1s when copying 10 files
  - No memory issues with 10-file tasks

### Usability (NFR2)
- **Requirement**: Clear distinction between planning and execution phases
- **Acceptance Criteria**:
  - File names clearly indicate purpose (task-plan, requirements-plan, implementation-exec)
  - Command names clearly indicate purpose (cig-task-plan, cig-implementation-exec)
  - Prominent notices in command files prevent confusion
  - Blocker handling examples are actionable and specific

### Maintainability (NFR3)
- **Requirement**: Code changes follow existing CIG patterns
- **Acceptance Criteria**:
  - New command files follow existing command file structure
  - New template files follow existing template structure
  - Script changes use same patterns as existing helper scripts
  - File naming conventions consistent (lettered templates: a-h, d2, e2)

### Security (NFR4)
- **Requirement**: Security verification for new files
- **Acceptance Criteria**:
  - New command files added to `.cig/security/script-hashes.json`
  - New template files added to security verification
  - Script permissions maintained (u+rx, minimum 0500)

### Reliability (NFR5)
- **Requirement**: Backward compatibility with existing 8-phase tasks
- **Acceptance Criteria**:
  - Tasks 1-24 continue working without modification
  - status-aggregator.pl handles both 8-phase and 10-phase tasks
  - format-detector.pl distinguishes v2.0 (8-phase) from v2.1 (10-phase) if needed
  - No breaking changes to existing workflows

## Constraints

### Technical Constraints
- **Backward Compatibility Required**: Cannot break existing Tasks 1-24 that use v2.0 (8-phase a-h workflow)
- **File Naming Conventions**: Must follow CIG sequential lettered pattern (v2.1 uses a-j)
- **Symlink-Based Templates**: Must work with existing symlink template system
- **Script Permissions**: All scripts must maintain u+rx (minimum 0500) permissions
- **Trampoline Architecture**: Entry points must remain lightweight, Core modules must be version-agnostic

### Integration Constraints
- **Template Pool Structure**: Changes must work with `.cig/templates/pool/` symlink architecture
- **format-detector.pl**: Must distinguish v2.0 and v2.1 accurately, show deprecation for v1.0
- **Security Verification**: Must integrate with existing `.cig/security/script-hashes.json` system
- **Version Management**: Must support 2 versions simultaneously (v2.0, v2.1) and deprecate v1.0
- **Migration Tools**: Must preserve existing v1.0→v2.0 migration tools (not modified in this task)

### Resource Constraints
- **Timeline**: 5-8 days estimated (increased due to trampoline architecture refactoring)
- **Scope**: Very high complexity - core architecture refactor plus workflow expansion plus v1.0 deprecation
- **Testing**: Must validate v2.0 and v2.1 plus existing Tasks 1-24 backward compatibility
- **Follow-up Required**: v2.0→v2.1 migration tools needed (separate task, highest priority)

## Acceptance Criteria

### Command Creation
- [ ] AC1: cig-implementation-exec.md command created with execution-focused guidance
- [ ] AC2: cig-testing-exec.md command created with execution-focused guidance
- [ ] AC3: Both execution commands include blocker handling sections with examples

### Template Infrastructure
- [ ] AC4: Execution template files created (d2, e2) or execution sections added to existing templates
- [ ] AC5: Symlinks configured for all task types with correct file counts
- [ ] AC6: template-copier.pl handles new file counts per task type

### Documentation
- [ ] AC7: workflow-steps.md updated with 10-phase workflow order (FR3)
- [ ] AC8: Blocker-driven reversion conceptual framework documented in workflow-steps.md (FR4)
- [ ] AC9: State machine description added to workflow-steps.md with forward/backward transitions (FR4)

### Blocker Handling
- [ ] AC10: All 10 workflow command files include "Blocker Handling" section (FR10)
- [ ] AC11: Blocker examples are phase-specific and actionable (FR10)
- [ ] AC12: Reversion guidance consistent across all commands and workflow-steps.md (FR10)

### Implementation Process
- [ ] AC13: Implementation plan defines checkpoint commit boundaries (FR11)
- [ ] AC14: Minimum 6-9 checkpoints identified with specific files/changes (FR11)
- [ ] AC15: Each checkpoint commit passes all tests (no broken states) (FR11)
- [ ] AC16: Checkpoint sequence documented in implementation plan (FR11)
- [ ] AC16a: Each checkpoint validates Tasks 1-24 backward compatibility (FR11)

### Trampoline Architecture
- [ ] AC17: Entry point scripts created for status-aggregator, template-copier, context-inheritance (FR12)
- [ ] AC18: Version-specific orchestration scripts exist for v2.0 and v2.1 for each helper (FR12)
- [ ] AC19: Core modules created (StatusAggregator::Core, TemplateCopier::Core, ContextInheritance::Core) (FR12)
- [ ] AC20: Version data modules created (WorkflowFiles::V20, V21) (FR12)
- [ ] AC21: Code duplication < 25% (shared logic in Core modules) (FR12)
- [ ] AC22: v2.0 and v2.1 work correctly via trampoline dispatch (FR12)

### v1.0 Deprecation
- [ ] AC23: v1.0 orchestration scripts removed (*-v1.0 deleted) (FR12)
- [ ] AC24: WorkflowFiles::V10 module removed (FR12)
- [ ] AC25: Entry points show clear deprecation error for v1.0 tasks (FR12)
- [ ] AC26: v1.0→v2.0 migration tools preserved and untouched (FR12)

### Testing & Validation
- [ ] AC27: Test tasks created for v2.0 and v2.1 formats (FR13)
- [ ] AC28: Unit tests exist for all Core modules (FR13)
- [ ] AC29: Integration tests exist for v2.0 and v2.1 orchestration scripts (FR13)
- [ ] AC30: Format detection correctly identifies v2.0 and v2.1 (FR13)
- [ ] AC31: v1.0 deprecation error message tested (FR13)
- [ ] AC32: Backward compatibility verified (Tasks 1-24 still work) (FR13)
- [ ] AC33: Test coverage documented in f-testing-plan.md (FR13)

### Naming and Semantics
- [ ] AC34: All workflow template files renamed with -plan suffix and re-lettered (FR5)
- [ ] AC35: All workflow commands renamed with -plan suffix (FR6)
- [ ] AC36: Prominent planning vs execution notices added to command files (FR7)

### Infrastructure
- [ ] AC37: status-aggregator entry point recognizes 10-phase workflow files (FR8)
- [ ] AC38: All helper scripts handle v2.0 and v2.1 correctly (FR8, FR12)
- [ ] AC39: template-copier updated for new file counts (FR9)

### Backward Compatibility
- [ ] AC40: Existing Tasks 1-24 continue working without modification (NFR5)
- [ ] AC41: No regression in status calculation for v2.0 (8-phase) tasks (NFR5)
- [ ] AC42: format-detector.pl correctly distinguishes v2.0 and v2.1 (NFR5, FR12)

### Security
- [ ] AC43: New command files added to script-hashes.json (NFR4)
- [ ] AC44: All new scripts maintain u+rx minimum 0500 permissions (NFR4)

## Status
**Status**: Finished
**Next Action**: Update design phase with trampoline architecture and sequential a-j naming
**Blockers**: None identified

**Update Notes**:
1. **Sequential lettering (a-j)**: Updated FR2, FR5, FR8, FR9 to use a-j workflow files instead of d2/e2 numeric suffixes
2. **Trampoline architecture (FR12)**: Added requirement for version-specific scripts with shared Core modules to enable clean version management and deprecation
3. **v1.0 deprecation**: This task will deprecate v1.0 format support (remove v1.0 orchestration scripts, show error for v1.0 tasks). v1.0→v2.0 migration tools preserved.
4. **Comprehensive testing (FR13)**: Added requirement for multi-version test suite validating v2.0 and v2.1 (v1.0 deprecated)
5. **Follow-up task required**: v2.0→v2.1 migration tools need to be created (added to BACKLOG with highest priority)
6. **Total**: 13 functional requirements, 5 non-functional requirements, 44 acceptance criteria

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
