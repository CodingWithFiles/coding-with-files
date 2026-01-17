# Add "Blocked" to Standard Status Values - Design

## Task Reference
- **Task ID**: internal-23
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/23-add-blocked-to-standard-status-values
- **Template Version**: 2.0

## Goal
Define architecture and design decisions for adding "Blocked" as a standard status value with 15% completion percentage.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice
- **Decision**: Configuration-driven status system with centralized status mapping
- **Rationale**:
  - CIG already uses `cig-project.json` as source of truth for status values
  - `CIG::WorkflowFiles::status_to_percent()` loads status map from config (line 119-144)
  - Adding "Blocked" to config automatically propagates to all status aggregation
  - Documentation updates provide human-readable semantics
  - Template updates guide correct usage
- **Trade-offs**:
  - **Benefits**: Single source of truth, automatic propagation, backward compatible, minimal code changes
  - **Drawbacks**: Requires updates across multiple file types (JSON, markdown, templates)

### Completion Percentage Decision
- **Decision**: Set "Blocked" to 15% completion
- **Rationale**:
  - Must be > 0% (distinguishes from "Backlog" and "To-Do" which are 0%)
  - Must be < 25% (distinguishes from "In Progress" which is 25%)
  - 15% indicates work has started but is stalled, positioning it between "not started" and "actively progressing"
  - Provides clear semantic gap: 0% (not started) → 15% (started but blocked) → 25% (actively progressing)
- **Trade-offs**:
  - **Benefits**: Clear semantic meaning, no conflicts with existing percentages
  - **Drawbacks**: Introduces new percentage value (existing values are 0%, 25%, 50%, 75%, 100%)

### Technology Stack
- **Configuration**: JSON (`cig-project.json`) - already established pattern
- **Scripts**: Perl modules (`CIG::WorkflowFiles`) - existing infrastructure
- **Documentation**: Markdown - consistent with existing docs
- **Templates**: Markdown templates - consistent with existing workflow files

## System Design

### Component Overview

1. **Configuration Layer** (`cig-project.json`)
   - Purpose: Single source of truth for status values
   - Responsibility: Define "Blocked" status with 15% completion
   - Location: `implementation-guide/cig-project.json` (if exists) or fallback to default

2. **Status Aggregation Layer** (`CIG::WorkflowFiles::status_to_percent()`)
   - Purpose: Convert status strings to completion percentages
   - Responsibility: Load config, cache status map, return percentage for "Blocked"
   - Location: `.cig/lib/CIG/WorkflowFiles.pm:119-144`
   - Current behavior: Loads from config, falls back to defaults, returns 0 for unknown statuses

3. **Documentation Layer** (`.cig/docs/workflow/workflow-steps.md`)
   - Purpose: Single source of truth for status value semantics (progressive disclosure)
   - Responsibility: Document when to use "Blocked" vs other statuses
   - Location: `.cig/docs/workflow/workflow-steps.md:23-33`
   - Note: Command files already reference this documentation (no changes needed)

4. **Template Layer** (workflow templates)
   - Purpose: Provide HTML comments referencing documentation
   - Responsibility: Follow progressive disclosure (reference, don't duplicate)
   - Locations: `.cig/templates/pool/{a-plan,b-requirements,c-design,d-implementation,e-testing,f-rollout,g-maintenance,h-retrospective}.md.template`
   - Pattern: HTML comment with link to workflow-steps.md, not hardcoded list

### Data Flow

1. **User sets status** → Writes "Status: Blocked" to workflow file (e.g., `d-implementation.md`)
2. **Status aggregator reads** → Calls `extract_status()` from workflow file
3. **Status lookup** → Calls `status_to_percent("Blocked")`
4. **Config loading** → Loads `cig-project.json` workflow.status-values
5. **Percentage returned** → Returns 15 for "Blocked"
6. **Progress calculation** → Aggregates percentages across workflow files
7. **Display** → Shows task progress including "Blocked" status

**Key architectural property**: No changes needed to status-aggregator.pl core logic because it already loads from config dynamically.

## Interface Design

### Configuration Schema (cig-project.json)
```json
{
  "workflow": {
    "status-values": {
      "Backlog": 0,
      "Blocked": 15,
      "To-Do": 0,
      "In Progress": 25,
      "Implemented": 50,
      "Testing": 75,
      "Finished": 100
    }
  }
}
```

### Documentation Format (workflow-steps.md)
```markdown
### Valid Status Values

The following status values are defined in the project configuration:

- **Backlog** (0%): Task not started, queued for future work
- **Blocked** (15%): Task started but cannot proceed until blocker resolved
- **To-Do** (0%): Task ready to begin, prioritized
- **In Progress** (25%): Work actively underway
- **Implemented** (50%): Code complete, not yet tested
- **Testing** (75%): Testing in progress, validation ongoing
- **Finished** (100%): Fully complete, all criteria met
```

### Status Module Interface (CIG::WorkflowFiles)
Existing interface already supports new status:
```perl
# No changes needed to status_to_percent() signature
my $pct = status_to_percent("Blocked");  # Returns 15
```

### Template Status Section
```markdown
## Status
**Status**: Backlog
**Next Action**: [Action description]
**Blockers**: [Blocker description or "None identified"]

<!-- See .cig/docs/workflow/workflow-steps.md#status-values for valid status values and usage guidance -->
```

## Constraints

### Technical Constraints
- Must use existing config structure (`workflow.status-values` in `cig-project.json`)
- Must maintain backward compatibility with existing status lookup logic
- Cannot modify status-aggregator.pl core algorithm (already correct)
- Must follow existing status value format (name: percentage as integer)

### Consistency Constraints
- Alphabetical ordering preference in documentation (optional)
- Percentage value must be integer 0-100
- Status name must be single word or hyphenated phrase matching existing pattern
- Documentation must follow existing format (name, percentage, description)

### Performance Constraints
- Status map caching must continue to work (no performance degradation)
- Config loading happens once per aggregator invocation (acceptable)

### Usability Constraints
- Developers must understand difference between "Blocked" (15%), "Backlog" (0%), and "In Progress" (25%)
- Templates must reference documentation (not duplicate content) following progressive disclosure principle
- Error messages for invalid status must include "Blocked" in suggestions

### Design Constraints
- **Progressive Disclosure**: Documentation is single source of truth; command files and templates reference it, don't duplicate
- **DRY Principle**: Status value list appears only in cig-project.json (config) and workflow-steps.md (human documentation)
- Command files already follow this pattern (no changes needed)

## Validation
- [x] Design review completed - configuration-driven approach is simplest
- [x] Architecture approved - leverages existing infrastructure
- [x] Integration points verified - status_to_percent() already supports dynamic lookup

## Status
**Status**: Finished
**Next Action**: Proceed to implementation phase with `/cig-implementation 23`
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
