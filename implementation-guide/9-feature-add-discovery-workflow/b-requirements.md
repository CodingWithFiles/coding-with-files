# Add discovery workflow - Requirements

## Task Reference
- **Task ID**: internal-9
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/9-add-discovery-workflow
- **Template Version**: 2.0

## Goal
Add "discovery" as a new supported task type for research, analysis, and exploratory tasks.

## Functional Requirements
### Core Features
- **FR1**: Add `discovery` to `supported-task-types` in cig-project.json
- **FR2**: Create `.cig/templates/discovery/` directory with 6 template symlinks
- **FR3**: Update `/cig-new-task` command to accept `discovery` as valid type
- **FR4**: Update documentation to describe discovery workflow

### User Stories
- **As a** developer **I want** to create discovery tasks **so that** I can track research and analysis work separately from feature development
- **As a** developer **I want** discovery tasks to skip rollout/maintenance phases **so that** the workflow matches exploratory work patterns

## Non-Functional Requirements
### Consistency (NFR1)
- Discovery templates must use same symlink pattern as other task types
- Discovery must integrate with existing `/cig-status` and `/cig-extract` commands

### Maintainability (NFR2)
- Use symlinks to pool templates (no duplicate content)
- Follow existing naming conventions (a-plan, b-requirements, etc.)

## Constraints
- Must use existing pool templates (no new template content)
- Must skip f-rollout.md and g-maintenance.md (discovery doesn't deploy)
- Must follow lensman reference implementation structure

## Acceptance Criteria
- [ ] AC1: `cig-project.json` includes `discovery` in supported-task-types
- [ ] AC2: `.cig/templates/discovery/` contains 6 symlinks (a, b, c, d, e, h)
- [ ] AC3: `/cig-new-task 1 discovery "test"` creates valid task directory
- [ ] AC4: Created discovery task has 6 workflow files (not 8)
- [ ] AC5: `/cig-status` correctly shows discovery task progress

## Status
**Status**: Finished
**Next Action**: Begin design phase
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
