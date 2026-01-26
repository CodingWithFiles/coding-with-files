# Enhance workflow scope and control instructions - Design

## Task Reference
- **Task ID**: internal-28
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/28-enhance-workflow-scope-and-control-instructions
- **Template Version**: 2.0

## Goal
Define architecture for consolidating verbose workflow instructions into concise "Scope & Boundaries" sections and implementing workflow-control helper script.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice
- **Decision**: Template-based documentation pattern with external helper script
- **Rationale**:
  - Template approach maintains consistency across all 10 workflow commands
  - External helper script (workflow-control) centralizes control logic instead of duplicating in each command
  - Separation of concerns: commands focus on workflow steps, helper script handles continuation logic
  - Future extensible: workflow-control can read config file without changing commands
- **Trade-offs**:
  - **Benefits**: DRY principle, consistent UX, easy to update logic centrally
  - **Drawbacks**: Adds one more helper script to maintain, requires documentation of template format

### Technology Stack
- **Documentation**: Markdown files (existing format, no change)
- **Helper Script**: Perl (consistent with other helper scripts: hierarchy-resolver, context-inheritance, format-detector)
- **Interface**: Command-line arguments (--current-step, --task-path)

## System Design
### Component Overview
- **"Scope & Boundaries" Section Template**: Standardized 5-6 line markdown section appearing in all workflow commands
  - Purpose: Provide immediate clarity on what the workflow step does/doesn't do
  - Responsibility: Replace 33 lines of verbose instructions (12-line "CRITICAL" + 21-line "Blocker Handling")

- **workflow-control Helper Script**: Perl script at `.cig/scripts/command-helpers/workflow-control`
  - Purpose: Centralize workflow continuation logic
  - Responsibility: Read workflow file status, return appropriate guidance (ask-user vs continue)
  - Input: --current-step, --task-path arguments
  - Output: Multi-line response (control action + human-readable message)

- **blocker-patterns.md Documentation**: Reference document at `.cig/docs/workflow/blocker-patterns.md`
  - Purpose: Centralize detailed blocker handling patterns extracted from all workflow phases
  - Responsibility: Provide detailed guidance without cluttering command files
  - Content: Common blockers by phase, reversion guidance, when to decompose

### Data Flow
1. User runs workflow command (e.g., `/cig-design-plan 28`)
2. LLM reads "Scope & Boundaries" section → understands what to do/not do
3. LLM works on workflow file, updates status field when done
4. LLM calls `workflow-control --current-step c-design-plan --task-path 28`
5. workflow-control reads `c-design-plan.md` → parses status field
6. workflow-control returns guidance:
   - "ask-user" + message → LLM suggests next step to user
   - "continue" + message → LLM continues working or updates status
7. LLM follows guidance (either suggests next step or continues working)

## Interface Design
### "Scope & Boundaries" Section Format
Template to be inserted after frontmatter in each workflow command:

```markdown
## Scope & Boundaries

**This step**: [Brief description of what this workflow step does]

**Not this step**: [What this step explicitly does NOT do - clarify common confusion points]

**If blocked or finished**: Call `workflow-control --current-step <step-name> --task-path <path>` to determine next action.
```

**Example for c-design-plan.md**:
```markdown
## Scope & Boundaries

**This step**: Complete the design planning document (c-design-plan.md) with architecture decisions, component design, and interface specifications.

**Not this step**: Implementation (that's d-implementation-plan + e-implementation-exec), testing, or deployment.

**If blocked or finished**: Call `workflow-control --current-step c-design-plan --task-path <path>` to determine next action.
```

### workflow-control Script Interface
**Command Line**:
```bash
workflow-control --current-step <step-name> --task-path <task-path>
```

**Arguments**:
- `--current-step`: Workflow file name (e.g., "a-task-plan", "c-design-plan", "e-implementation-exec")
- `--task-path`: Hierarchical task number (e.g., "28", "1.2", "3.1.4")

**Output Format**:
```
<action>
<human-readable-message>
```

**Output Examples**:
```
ask-user
Suggest next workflow step
```

```
ask-user
Need user feedback on blocker
```

```
continue
If workflow step complete: update status to 'Finished' and re-run workflow-control. Otherwise: continue this workflow step.
```

### blocker-patterns.md Document Structure
```markdown
# Blocker Patterns

## By Workflow Phase

### Planning Phase (a-task-plan)
**Common Blockers**:
- [List of common blockers with resolution strategies]

### Requirements Phase (b-requirements-plan)
**Common Blockers**:
- [List of common blockers with resolution strategies]

[... etc for all 10 phases ...]

## General Reversion Guidance
[Cross-phase guidance on when/how to revert to earlier phases]

## Decomposition Signals
[When blockers indicate task should be split into subtasks]
```

## Constraints
- **Backward Compatibility**: Cannot modify existing task workflow files, only templates (affects new tasks only)
- **Line Count Limit**: "Scope & Boundaries" section must be ≤6 lines to avoid bloat
- **Consistency**: Format must be identical across all 10 workflow commands
- **Extensibility**: workflow-control interface must support future config matrix feature (reading `.cig/settings.local.json`)
- **Security**: workflow-control must validate task-path format (hierarchical numbers only) to prevent command injection
- **Performance**: workflow-control must execute in <100ms (negligible overhead)
- **File Permissions**: workflow-control requires 0500 permissions (consistent with other helper scripts)

## Validation
- [ ] "Scope & Boundaries" template reviewed and approved (5-6 lines, clear language)
- [ ] workflow-control interface design reviewed (simple, extensible)
- [ ] blocker-patterns.md structure reviewed (organized by phase, comprehensive)
- [ ] Design satisfies all 5 functional requirements from b-requirements-plan.md
- [ ] Design satisfies all 5 non-functional requirements (Performance, Usability, Maintainability, Security, Reliability)

## Status
**Status**: Finished
**Next Action**: Move to implementation planning phase
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
