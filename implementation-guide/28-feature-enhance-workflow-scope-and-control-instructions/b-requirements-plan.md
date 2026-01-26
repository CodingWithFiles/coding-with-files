# Enhance workflow scope and control instructions - Requirements

## Task Reference
- **Task ID**: internal-28
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/28-enhance-workflow-scope-and-control-instructions
- **Template Version**: 2.0

## Goal
Define functional and non-functional specifications for consolidating workflow scope instructions and implementing workflow control logic.

## Functional Requirements
### Core Features
- **FR1**: Each workflow command must have a "Scope & Boundaries" section appearing immediately after frontmatter (before "## Context")
  - **Acceptance**: Section present in all 10 workflow commands (task-plan, requirements-plan, design-plan, implementation-plan, implementation-exec, testing-plan, testing-exec, rollout, maintenance, retrospective)

- **FR2**: "Scope & Boundaries" section must be 5-6 lines maximum and include:
  - What this step does (positive scope)
  - What this step does NOT do (boundaries/exclusions)
  - What to do if blocked or finished (reference to workflow-control)
  - **Acceptance**: Section fits in 5-6 lines, includes all 3 elements

- **FR3**: workflow-control helper script must accept arguments: `--current-step <step> --task-path <path>`
  - Script internally resolves task directory and reads status from workflow file
  - **Acceptance**: Script parses arguments correctly, resolves task path, reads status field from workflow file

- **FR4**: workflow-control must return appropriate guidance based on status read from workflow file:
  - Status "Finished" → "ask-user\nSuggest next workflow step"
  - Status "Blocked" → "ask-user\nNeed user feedback on blocker"
  - Other statuses → "continue\nIf workflow step complete: update status to 'Finished' and re-run workflow-control. Otherwise: continue this workflow step."
  - **Acceptance**: Script reads status from correct workflow file and returns correct output for each status category

- **FR5**: Detailed blocker handling guidance must be extracted to `.cig/docs/workflow/blocker-patterns.md`
  - **Acceptance**: New doc created with patterns from all workflow phases, commands reference this doc instead of inline duplication

- **FR6**: workflow-control helper script must re-use common functions from CIG Perl modules
  - Use `CIG::Options::parse` for argument parsing (not manual parsing)
  - Use `CIG::TaskPath::validate` and `CIG::TaskPath::resolve` for task path operations (not external hierarchy-resolver calls)
  - Use `CIG::MarkdownParser::extract_status` for status extraction (not inline regex parsing)
  - **Acceptance**: Script imports and uses CIG::Options, CIG::TaskPath, and CIG::MarkdownParser modules
  - **Note**: This requirement was missed during initial requirements phase and discovered during implementation. Should be included in retrospective as process improvement (always review available CIG modules before designing new helper scripts).

### User Stories
- **As a** workflow command user **I want** concise scope instructions at the top **so that** I immediately understand what this step does without reading verbose warnings

- **As an** LLM agent **I want** centralized workflow-control logic **so that** I can determine whether to continue autonomously or ask the user based on consistent rules

- **As a** developer **I want** blocker patterns documented separately **so that** I can reference detailed guidance without cluttering command files

## Non-Functional Requirements
### Performance (NFR1)
- workflow-control script execution: < 100ms (negligible overhead)
- No performance impact on workflow command execution
- Token usage reduction: ~27 lines removed per command × 10 commands = ~270 lines saved in context

### Usability (NFR2)
- Learning curve: Scope section readable in < 30 seconds
- "Scope & Boundaries" section uses clear, active voice language
- Consistent format across all 10 workflow commands (copy-paste template)
- workflow-control output is human-readable and actionable

### Maintainability (NFR3)
- workflow-control script is self-documenting with clear variable names
- "Scope & Boundaries" template can be copied to new workflow commands
- Blocker patterns doc is easily updatable as new patterns emerge
- Single source of truth for workflow continuation logic (workflow-control script)

### Security (NFR4)
- workflow-control validates task-path format (hierarchical numbers only)
- No security requirements beyond existing command injection protections
- Script uses same security model as other helper scripts (0500 permissions)

### Reliability (NFR5)
- workflow-control returns deterministic output for given inputs
- Graceful handling of invalid status values (default to "continue")
- Zero breaking changes to existing workflow commands (backward compatible)
- Template changes only affect new tasks created after implementation

## Constraints
- Must maintain backward compatibility: existing tasks using old format continue to work
- Cannot modify existing task workflow files (only templates for new tasks)
- Must work in both user-driven mode (current) and future LLM-driven mode
- "Scope & Boundaries" format must be concise (5-6 lines max) to avoid bloat
- workflow-control interface must be extensible for future config matrix feature

## Acceptance Criteria
- [ ] AC1: All 10 workflow command files have "Scope & Boundaries" section in correct location
- [ ] AC2: workflow-control script exists at `.cig/scripts/command-helpers/workflow-control` with 0500 permissions
- [ ] AC3: workflow-control correctly reads status from workflow file and returns correct output for all 3 status categories (Finished, Blocked, other)
- [ ] AC4: blocker-patterns.md exists at `.cig/docs/workflow/blocker-patterns.md` with content from all phases
- [ ] AC5: All workflow commands reference blocker-patterns.md instead of inline duplication
- [ ] AC6: Run existing workflow command (e.g., `/cig-task-plan 29`) and verify it works correctly
- [ ] AC7: "Scope & Boundaries" section is 5-6 lines in all commands (not exceeded)
- [ ] AC8: workflow-control script uses CIG::Options, CIG::TaskPath, and CIG::MarkdownParser modules (not manual parsing or external scripts)

## Status
**Status**: Finished
**Next Action**: Move to design phase
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Requirements phase completed with 6 functional requirements and 8 acceptance criteria defined.

**Missed During Requirements**: FR6 (re-use CIG common modules) was not identified during initial requirements phase. This was discovered during implementation when manually parsing arguments/status, and reviewer asked if common CIG modules exist. This gap should be addressed in retrospective.

## Lessons Learned
**Process Improvement**: Requirements phase should include explicit step to review available CIG Perl modules (`.cig/lib/CIG/`) before designing new helper scripts. This would prevent reinventing functionality that already exists in common libraries.

**For Retrospective**: Document this as "What Could Be Improved" - add checklist item to requirements workflow: "Review existing CIG modules for relevant functionality before defining implementation approach"
