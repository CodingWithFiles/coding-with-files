# refactor template generation system - Testing

## Task Reference
- **Task ID**: internal-44
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/44-refactor-template-generation-system
- **Template Version**: 2.1

## Goal
Define test strategy and validation approach for refactor template generation system.

## Test Strategy
### Test Levels
- **Unit Tests**: Template copier functions in isolation (`get_phase_sequence`, `compute_next_action`)
- **Integration Tests**: Template generation end-to-end (copier + symlinks + variable substitution)
- **System Tests**: Full workflow execution (task creation → workflow phases → retrospective)
- **Acceptance Tests**: Validate all 12 acceptance criteria from requirements

### Test Coverage Targets
- **Overall Coverage**: 100% of 14 modified files verified
- **Critical Paths**: 100% coverage - template generation, phase progression, git workflow
- **Edge Cases**: All 5 task types, missing symlinks, invalid inputs, backward compatibility
- **Regression**: All existing CIG commands + Tasks 1-43 continue working

## Test Cases
### Functional Test Cases

**Phase 1: Template Content**

- **TC-1**: Template headers include task type
  - **Given**: All 10 pool templates updated with task type header
  - **When**: Generate task using `/cig-new-task 99 feature "test task"`
  - **Then**: All generated files have `**Task**: 99 (feature)` on line 2

- **TC-2**: Next Action fields use inference (no `<task>` param)
  - **Given**: All templates use `{{nextAction}}` variable
  - **When**: Read generated a-task-plan.md Next Action field
  - **Then**: Next Action shows `/cig-requirements-plan` without `<task>` parameter

- **TC-3**: Cross-references use correct filenames
  - **Given**: d-implementation-plan.md references `e-testing-plan.md`
  - **When**: Generate feature task and read d-implementation-plan.md
  - **Then**: Cross-references resolve to `e-testing-plan.md` (not `e-testing.md`)

- **TC-4**: Decomposition checks in planning phases only
  - **Given**: Templates updated with decomposition in a,b,c
  - **When**: Generate feature task and read all workflow files
  - **Then**: Decomposition section present in a,b,c and absent in d-j

**Phase 2: Template Copier Logic**

- **TC-5**: Symlink-based phase sequence inference (feature)
  - **Given**: Feature task type with 10 symlinks (a-j)
  - **When**: Call `get_phase_sequence('feature')`
  - **Then**: Returns `['a','b','c','d','e','f','g','h','i','j']`

- **TC-6**: Symlink-based phase sequence inference (bugfix)
  - **Given**: Bugfix task type with 7 symlinks (a,c,d,e,f,g,j)
  - **When**: Call `get_phase_sequence('bugfix')`
  - **Then**: Returns `['a','c','d','e','f','g','j']` (skips b,h,i)

- **TC-7**: Next-action computation for feature task
  - **Given**: Feature task, current phase = 'a'
  - **When**: Call `compute_next_action('feature', 'a-task-plan.md.template')`
  - **Then**: Returns `/cig-requirements-plan`

- **TC-8**: Next-action computation for bugfix task
  - **Given**: Bugfix task, current phase = 'a' (skips b, goes to c)
  - **When**: Call `compute_next_action('bugfix', 'a-task-plan.md.template')`
  - **Then**: Returns `/cig-design-plan` (skips requirements)

- **TC-9**: Next-action for final phase
  - **Given**: Any task type, current phase = last in sequence
  - **When**: Call `compute_next_action(type, last-phase-template)`
  - **Then**: Returns `Task complete → /cig-retrospective`

- **TC-10**: Template variable substitution
  - **Given**: Template copier with new variables
  - **When**: Generate task 99, type feature, description "test"
  - **Then**: Files contain `{{taskNum}}=99`, `{{taskType}}=feature`, `{{nextAction}}=/cig-requirements-plan`

**Phase 3: Git Workflow Automation**

- **TC-11**: Workflow docs include checkpoint commit instructions
  - **Given**: `.cig/docs/workflow/workflow-steps.md` updated
  - **When**: Read each workflow phase section
  - **Then**: Each phase includes checkpoint commit instruction with example

- **TC-12**: Auto-branch creation in cig-new-task
  - **Given**: `/cig-new-task` skill updated with auto-branch logic
  - **When**: Run `/cig-new-task 99 feature "test task"`
  - **Then**: Branch `feature/99-test-task` created and checked out automatically

- **TC-13**: Checkpoints branch creation in retrospective
  - **Given**: Task branch with multiple checkpoint commits
  - **When**: Run `/cig-retrospective` skill
  - **Then**: Checkpoints branch created: `git branch "$(git rev-parse --abbrev-ref HEAD)-checkpoints"`

- **TC-14**: Commit squashing in retrospective
  - **Given**: Checkpoints branch created, multiple commits exist
  - **When**: Follow retrospective squashing instructions
  - **Then**: All task commits squashed to single commit with brief "why"-focused message

### Non-Functional Test Cases

- **Performance Tests (NFR1)**:
  - Template generation completes in < 2 seconds for all task types
  - Symlink discovery + variable substitution < 1 second
  - No measurable performance regression vs baseline

- **Usability Tests (NFR2)**:
  - Error messages from template copier clearly indicate failure cause
  - Users can still pass task numbers explicitly if desired
  - No learning curve change for existing CIG users

- **Maintainability Tests (NFR3)**:
  - DRY principle maintained (single source of truth in pool)
  - No hardcoded phase sequences (inferred from symlinks)
  - Code changes are self-documenting and testable

- **Security Tests (NFR4)**:
  - Generated files have 0600 permissions
  - Template variable substitution sanitizes inputs (no injection)
  - Script integrity verifiable via SHA256

- **Reliability Tests (NFR5)**:
  - Backward compatibility: Tasks 1-43 continue working
  - Graceful degradation: Symlink discovery failure shows clear error
  - Data integrity: Variable substitution doesn't corrupt files
  - Idempotency: Running copier twice produces identical results

## Test Environment
### Setup Requirements
- **Git Repository**: Clean working tree on test branch
- **Test Tasks**: Create temporary tasks 97, 98, 99 for each phase test
- **Symlink Verification**: Ensure `.cig/templates/{type}/` symlinks intact
- **Baseline**: Capture current behavior of Tasks 1-43 for regression testing
- **Perl Environment**: Verify Perl available with required modules

### Test Data
- **Task Types**: Test all 5 types (feature, bugfix, hotfix, chore, discovery)
- **Task Numbers**: Use 97-99 for disposable test tasks
- **Descriptions**: Simple test descriptions for reproducibility

### Automation
- **Manual Testing**: Primary approach for template content verification
- **Script Testing**: Direct Perl function calls for unit tests
- **Integration Testing**: Generate tasks and inspect output files
- **Regression Testing**: Run all existing `/cig-*` commands on test tasks
- **Cleanup**: Remove test tasks 97-99 after validation complete

## Validation Criteria
### Functional Validation (14 test cases)
- [ ] TC-1: Template headers include task type (all 10 templates)
- [ ] TC-2: Next Action fields use inference (no `<task>` param)
- [ ] TC-3: Cross-references use correct filenames
- [ ] TC-4: Decomposition checks in a,b,c only (not d-j)
- [ ] TC-5: Phase sequence inference for feature (10 phases)
- [ ] TC-6: Phase sequence inference for bugfix (7 phases, skips b,h,i)
- [ ] TC-7: Next-action computation for feature task
- [ ] TC-8: Next-action computation for bugfix task (skips requirements)
- [ ] TC-9: Next-action for final phase returns retrospective
- [ ] TC-10: Template variables populated correctly
- [ ] TC-11: Workflow docs include checkpoint commit instructions
- [ ] TC-12: Auto-branch creation works in cig-new-task
- [ ] TC-13: Checkpoints branch created in retrospective
- [ ] TC-14: Commit squashing works correctly

### Non-Functional Validation (5 dimensions)
- [ ] Performance: Template generation < 2s, copier < 1s
- [ ] Usability: Clear error messages, no learning curve change
- [ ] Maintainability: DRY maintained, no hardcoded sequences
- [ ] Security: 0600 permissions, no injection vulnerabilities
- [ ] Reliability: Backward compatible, graceful degradation, idempotent

### Acceptance Criteria Mapping (12 from requirements)
- [ ] AC1: Test task headers show task type (all 5 types)
- [ ] AC2: Next Action lacks `<task>` parameter
- [ ] AC3: Cross-references resolve correctly
- [ ] AC4: Decomposition in a,b,c templates
- [ ] AC5: No decomposition in d-j templates
- [ ] AC6: Phase sequences inferred from symlinks (all 5 types)
- [ ] AC7: All CIG commands work on new tasks
- [ ] AC8: Workflow docs have checkpoint instructions
- [ ] AC9: Branch auto-created in cig-new-task
- [ ] AC10: Checkpoints branch created in retrospective
- [ ] AC11: Squashed commit is brief and "why"-focused
- [ ] AC12: No regressions in Tasks 1-43

## Status
**Status**: Finished
**Next Action**: Move to implementation execution → `/cig-implementation-exec 44`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
