# Add "Blocked" to Standard Status Values - Requirements

## Task Reference
- **Task ID**: internal-23
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/23-add-blocked-to-standard-status-values
- **Template Version**: 2.0

## Goal
Define functional and non-functional specifications for adding "Blocked" as a standard status value to the CIG workflow system.

## Functional Requirements
### Core Features
- **FR1**: Documentation must include "Blocked" status in `.cig/docs/workflow/workflow-steps.md#status-values` with clear definition
  - Status semantics: Work has started but cannot proceed until blocker is resolved
  - Completion percentage: Must be defined (recommend 15% - more than "Backlog" 0%, less than "In Progress" 25%)
  - Format consistent with existing status entries (status name, percentage, description)

- **FR2**: Status aggregator script must recognise and handle "Blocked" status
  - `status-aggregator.pl` must parse "Blocked" status from workflow files
  - Must assign correct completion percentage to "Blocked" status
  - Must maintain backward compatibility with existing status values
  - Must not break when encountering "Blocked" in task files

- **FR3**: Workflow templates must reference documentation for "Blocked" status usage
  - Templates should include HTML comment referencing workflow-steps.md
  - Follow progressive disclosure principle (reference, don't duplicate)
  - Apply to all 8 template files consistently

- **FR4**: Project configuration must include "Blocked" in valid status values
  - Update `cig-project.json` workflow.status-values section
  - Add "Blocked" with appropriate completion percentage
  - Maintain alphabetical or logical ordering of status values

### User Stories
- **As a** developer working on a CIG task **I want** to mark my task as "Blocked" **so that** I can clearly indicate work has stopped due to external dependencies without misleading stakeholders that work is "In Progress"
- **As a** project manager reviewing task status **I want** to see "Blocked" tasks distinguished from "Backlog" tasks **so that** I know which tasks need intervention to unblock vs tasks not yet started
- **As a** CIG system maintainer **I want** "Blocked" status to integrate seamlessly with existing tooling **so that** status reporting and aggregation continue to work correctly

## Non-Functional Requirements
### Performance (NFR1)
- Status aggregator parsing: Must process "Blocked" status with no measurable performance degradation (<1ms additional overhead)
- Documentation updates: No impact on file load times or command execution
- Backward compatibility: Existing tasks using current status values must continue to work without modification

### Usability (NFR2)
- Learning curve: Developers should understand when to use "Blocked" vs other statuses within 2 minutes of reading documentation
- Error recovery: If invalid status value used, provide clear error message suggesting valid values including "Blocked"
- Consistency: "Blocked" status follows same format and conventions as existing status values
- Discoverability: "Blocked" appears in all relevant documentation and command help text

### Maintainability (NFR3)
- Code clarity: Changes to status-aggregator.pl must be self-documenting with clear variable names
- Modularity: Status handling logic should remain modular and extensible for future status additions
- Testability: Status aggregator changes must be testable with sample task files using "Blocked" status
- Documentation: All changes must be documented in relevant files (workflow-steps.md, command files, templates)

### Security (NFR4)
- Input validation: Status aggregator must validate status values and reject malformed input
- No injection risks: "Blocked" status value must not introduce command injection vulnerabilities
- Sanitisation: Status parsing must safely handle "Blocked" status in all contexts

### Reliability (NFR5)
- Backward compatibility: Existing tasks continue to report correct status percentages
- Error handling: Status aggregator gracefully handles unknown status values with warning
- Data integrity: Adding "Blocked" status must not corrupt existing task status tracking
- Regression prevention: All existing status values must continue to work identically

## Constraints
- Must maintain backward compatibility with all existing tasks (no breaking changes to status aggregator)
- Completion percentage must fit within 0-100% range and not conflict with existing values
- Documentation updates must follow existing format and style conventions
- Changes must work with v2.0 CIG system (hierarchical tasks, symlink-based templates)
- Must not require migration of existing task files
- Status value name "Blocked" is fixed (from BACKLOG.md specification)

## Acceptance Criteria
- [ ] AC1: "Blocked" status documented in workflow-steps.md with clear semantics and completion percentage
- [ ] AC2: `status-aggregator.pl` correctly parses and calculates percentage for tasks with "Blocked" status
- [ ] AC3: `cig-project.json` includes "Blocked" in workflow.status-values with appropriate percentage
- [ ] AC4: Template files reference documentation (not duplicate) for "Blocked" status usage
- [ ] AC5: Existing tasks with current status values continue to report correct percentages (regression test)
- [ ] AC6: Documentation clearly distinguishes "Blocked" from "Backlog" and "In Progress"
- [ ] AC7: Status aggregator handles unknown status values gracefully without breaking
- [ ] AC8: Progressive disclosure maintained (command files already reference docs, no changes needed)

## Status
**Status**: Finished
**Next Action**: Proceed to design phase with `/cig-design 23`
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
