# Add discovery workflow - Testing

## Task Reference
- **Task ID**: internal-9
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/9-add-discovery-workflow
- **Template Version**: 2.0

## Goal
Validate discovery workflow type is correctly integrated.

## Test Strategy
### Test Levels
- **Integration Tests**: Verify discovery templates work with cig-new-task
- **System Tests**: End-to-end task creation and status tracking
- **Acceptance Tests**: Validate against requirements (AC1-AC5)

### Test Coverage Targets
- **Critical Paths**: 100% - all acceptance criteria tested
- **Regression**: Existing task types still work

## Test Cases
### Functional Test Cases
- **TC-1**: Discovery in supported-task-types
  - **Given**: cig-project.json configuration
  - **When**: Check supported-task-types array
  - **Then**: Contains "discovery"

- **TC-2**: Discovery templates exist
  - **Given**: .cig/templates/discovery/ directory
  - **When**: List symlinks
  - **Then**: Contains 6 symlinks (a, b, c, d, e, h)

- **TC-3**: Discovery task creation
  - **Given**: CIG system with discovery type
  - **When**: Copy discovery templates to test directory
  - **Then**: 6 workflow files created (not 8)

- **TC-4**: Status aggregator handles discovery
  - **Given**: Discovery task directory
  - **When**: Run status-aggregator.pl
  - **Then**: Discovery task appears in output

- **TC-5**: Existing types unaffected
  - **Given**: Existing feature/bugfix/hotfix/chore templates
  - **When**: List template symlinks
  - **Then**: All existing types unchanged

### Non-Functional Test Cases
- **Consistency**: Discovery follows same symlink pattern as other types
- **Maintainability**: No duplicate template content

## Test Environment
### Setup Requirements
- CIG repository with updated configuration
- Access to .cig/templates/ directory

### Automation
- Manual verification via command line
- Visual inspection of template symlinks

## Validation Criteria
- [x] TC-1: cig-project.json includes discovery
- [x] TC-2: .cig/templates/discovery/ has 6 symlinks
- [x] TC-3: Discovery creates 6 files (tested earlier)
- [x] TC-4: status-aggregator.pl shows task progress
- [x] TC-5: Existing types unchanged

## Status
**Status**: Finished
**Next Action**: Proceed to retrospective (no rollout for discovery tasks)
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
