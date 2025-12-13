# Hierarchical Workflow System with Dynamic Step Transitions - Requirements

## Task Reference
- **Task ID**: internal-3
- **Type**: Feature
- **Status**: Not Started

## Functional Requirements

### FR1: Hierarchical Task Structure
- **FR1.1**: Support infinite task nesting using decimal numbering (1, 1.1, 1.1.1, etc.)
- **FR1.2**: Directory format: `<num>-<type>-<slug>/`
- **FR1.3**: Flat top-level structure (no type-based segregation)
- **FR1.4**: Mixed task types at any hierarchy level
- **FR1.5**: Numeric prefix maintains sort order

### FR2: Workflow Steps
- **FR2.1**: Eight standardised workflow files with lettered naming:
  - `a-plan.md` - Goals, success criteria, milestones
  - `b-requirements.md` - Functional/non-functional requirements
  - `c-design.md` - Architecture and component design
  - `d-implementation.md` - Code implementation
  - `e-testing.md` - Test strategy and execution
  - `f-rollout.md` - Deployment and validation
  - `g-maintenance.md` - Operational procedures
  - `h-retrospective.md` - Lessons learned
- **FR2.2**: Optional workflow steps (create only what's needed)
- **FR2.3**: Consistent structure across all task types
- **FR2.4**: Standardised status markers in workflow files:
  - Minimum status types: `Backlog`, `To-Do`, `In Progress`, `Implemented`, `Testing`, `Finished`
  - Status markers enable dynamic workflow transitions (FR6)
  - Status format: `## Status: <status-type>` or `**Status**: <status-type>`
  - Helper scripts and commands can parse status to determine workflow state
  - Additional project-specific status types permitted beyond minimum set

### FR3: Task Creation Commands
- **FR3.1**: `/cig-new-task <num> <type> "description"` creates top-level task
  - **Breaking change** from old signature: `<task-type> [task-id] <description>`
  - Command frontmatter `argument-hint` field updated to reflect new signature
- **FR3.2**: `/cig-subtask <parent-path> <num> <type> "description"` creates hierarchical subtask
  - Command frontmatter `argument-hint` field shows correct hierarchical signature
- **FR3.3**: Automatic template population based on task type (templates define structure per FR15)
- **FR3.4**: All updated commands have accurate `argument-hint` fields for UI guidance

### FR4: Workflow Commands
- **FR4.1**: Eight workflow commands:
  - `/cig-plan <task-path>` - Start/update planning
  - `/cig-requirements <task-path>` - Gather requirements
  - `/cig-design <task-path>` - Create design
  - `/cig-implementation <task-path>` - Implement code
  - `/cig-testing <task-path>` - Write and run tests
  - `/cig-rollout <task-path>` - Deploy/rollout
  - `/cig-maintenance <task-path>` - Document maintenance
  - `/cig-retrospective <task-path>` - Analyse outcomes
- **FR4.2**: Each command provides context from parent tasks
- **FR4.3**: Each command includes next-step decision logic
- **FR4.4**: Each command checks universal decomposition signals

### FR5: Context Inheritance
- **FR5.1**: Automatic reading of parent task files (plan, requirements, design)
- **FR5.2**: Structured summary of ancestor context
- **FR5.3**: Prevents duplicate information across hierarchy
- **FR5.4**: Context provided at start of each workflow step

### FR6: Dynamic Workflow Transitions
- **FR6.1**: Non-linear state machine based on step outcomes
- **FR6.2**: Suggest next command based on actual results
- **FR6.3**: Provide alternative paths with reasoning
- **FR6.4**: Handle failures by returning to appropriate step

### FR7: Universal Decomposition
- **FR7.1**: Five "too big" signals:
  - Time: >1 week for step, >1 month for subtask
  - People: >2 people work on different parts
  - Complexity: 3+ distinct concerns
  - Risk: High risk requiring isolation
  - Independence: Parts can be worked separately
- **FR7.2**: Suggest subtasks AFTER thinking but BEFORE detailed work
- **FR7.3**: Apply at ALL workflow steps
- **FR7.4**: User decides: decompose or continue monolithically

### FR8: Status Display
- **FR8.1**: `/cig-status` shows tree view of all tasks
- **FR8.2**: `/cig-status <path>` shows task and descendants
- **FR8.3**: Progress aggregation (completion percentages)
- **FR8.4**: Visual hierarchy with proper indentation
- **FR8.5**: Status indicators (✓, in-progress, pending)
- **FR8.6**: `/cig-extract` updated to use task-based paths and helper scripts
  - New signature: `/cig-extract <task-path> <section-name>`
  - Example: `/cig-extract 1/1.1 goal` instead of `/cig-extract path/to/file.md "Goal"`
  - Backward compatibility: Also accepts full file paths for migration period
- **FR8.7**: `/cig-extract` uses helper scripts for path resolution:
  - `hierarchy-resolver.sh` to resolve task path (e.g., "1/1.1" → full directory path)
  - `format-detector.sh` to determine old vs new format
  - Maps section name to correct file based on format (e.g., "goal" → a-plan.md or plan.md)
- **FR8.8**: `/cig-extract` LLM remains in the loop for intelligent error handling:
  - Helper scripts resolve paths and detect format (automation)
  - LLM receives helper script output and extracts section content
  - LLM detects corrupted/badly edited files and suggests fixes
  - LLM provides meaningful error messages and recovery suggestions
  - LLM can diagnose structural issues in task files
- **FR8.9**: `/cig-extract` section name mapping supports both formats:
  - Deterministic mapping based on template structure (FR15.5)
  - Common sections: goal, requirements, design, implementation, testing, rollout, maintenance, retrospective
  - Case-insensitive matching for user convenience

### FR9: Backward Compatibility
- **FR9.1**: Support old structure: `<type>/<num>-<slug>/`
- **FR9.2**: Support old file names: `plan.md`, `implementation.md`, etc.
- **FR9.3**: Detection logic based on file existence
- **FR9.4**: Both structures work indefinitely
- **FR9.5**: Commands automatically detect and adapt

### FR10: Migration Support
- **FR10.1**: Preserve git history via `git mv`
- **FR10.2**: Isolated migration commits
- **FR10.3**: Validation checklist post-migration
- **FR10.4**: No broken references after migration

### FR11: Workflow File Content Guidance
- **FR11.1**: `/cig-new-task` command includes guidance on what content belongs in each workflow file
- **FR11.2**: `/cig-subtask` command references `/cig-new-task` for workflow file content guidance
- **FR11.3**: Each workflow file type has clear "Focus" guidelines (what to include)
- **FR11.4**: Each workflow file type has clear "Avoid" guidelines (what not to include)
- **FR11.5**: Separation of concerns enforced:
  - `a-plan.md`: Project management planning only (goals, milestones, risks, estimates)
  - `b-requirements.md`: What needs to be built (functional/non-functional requirements)
  - `c-design.md`: How it will be built (architecture, components, APIs)
  - `d-implementation.md`: Actual code and implementation details
  - `e-testing.md`: Testing strategy and validation
  - `f-rollout.md`: Deployment procedures
  - `g-maintenance.md`: Operational procedures
  - `h-retrospective.md`: Lessons learned and variance analysis

### FR12: Command Refactoring - Progressive Disclosure
- **FR12.1**: `/cig-subtask` command references `.claude/commands/cig-new-task.md` for shared details
- **FR12.2**: `/cig-subtask` does not duplicate content from `/cig-new-task`
- **FR12.3**: Progressive disclosure principle applied: basic info in main command, details via reference
- **FR12.4**: Common template population logic centralized in `/cig-new-task`
- **FR12.5**: `/cig-subtask` focuses only on hierarchical-specific concerns (numbering, parent linking)

### FR13: Helper Script Infrastructure
- **FR13.1**: Helper scripts located in `.cig/scripts/command-helpers/`
- **FR13.2**: Context inheritance script (`context-inheritance.pl`):
  - Implementation: Perl-based for efficient text processing and header extraction
  - Input: `<task-path>` (e.g., "1/1.1/1.1.1")
  - Optional flag: `--format=json` for JSON output (default: markdown)
  - Purpose: Provide structural map of parent task context with navigable links and status markers
  - Functionality:
    - Recursive upward search from task path to project root to find all parent tasks
    - For each parent, locate workflow files: a-plan.md, b-requirements.md, c-design.md, d-implementation.md (or old format equivalents)
    - Extract document structure via header parsing (markdown headers with line numbers)
    - Calculate section boundaries (start line, end line) for each header
    - Parse status markers from each file (patterns: `## Status: <status>` or `**Status**: <status>`)
    - Output structural map with: file paths, status markers, section headers, line ranges, Read tool parameters (offset, limit)
  - Output (default markdown): Structural map with headers, line ranges (Lstart-end), and Read tool parameters for LLM navigation
  - Output (JSON with --format=json): Programmatically parseable structure for automation
  - Benefits: Token-efficient (~50-100 tokens per parent vs 500-1000 for full files), LLM decides what to read in detail
  - Exit codes: 0=success, 1=invalid path, 2=task not found, 3=no parent tasks (top-level task)
- **FR13.3**: Hierarchy resolver script (`hierarchy-resolver.sh`):
  - Input: `<task-path>` (e.g., "1/1.1")
  - Optional flag: `--format=json` for JSON output (default: markdown)
  - Output (default markdown): Human/LLM-readable summary of task resolution
  - Output (JSON with --format=json): Structured data with fields: full_path, format, task_num, task_type, task_slug, parent_path, depth
  - Purpose: Resolve short task paths to full filesystem paths with metadata
- **FR13.4**: Format detector script (`format-detector.sh`):
  - Input: `<task-directory> <workflow-file>`
  - Optional flag: `--format=json` for JSON output (default: markdown)
  - Purpose: Version comparison and upgrade assistant for workflow files
  - Functionality:
    - Parse `**Template Version**` field from workflow file (pattern: `grep "^\- \*\*Template Version\*\*:"`)
    - Compare current version against expected version embedded in format-detector.sh script itself
    - Check workflow file version against CIG software version expectations
    - Detect missing required fields for current version
    - Display discrepancies in workflow file headers
    - Provide open-ended upgrade question for LLM to present to user
  - Output (default markdown): Version comparison report with current version, expected version, missing required fields, and upgrade options
  - Output (JSON with --format=json): Programmatically parseable version metadata
  - Exit codes: 0=success, 1=invalid directory, 2=file not found, 3=cannot parse version
- **FR13.5**: Status aggregator script (`status-aggregator.sh`):
  - Input: `<task-path>` (optional, defaults to all tasks)
  - Optional flag: `--format=json` for JSON output (default: markdown)
  - Output (default markdown): Markdown tree with progress percentages and status for task and descendants
  - Output (JSON with --format=json): Programmatically parseable hierarchical structure with progress data
  - Functionality: Aggregates completion up hierarchy tree using status marker parsing and progress formula
  - Exit codes: 0=success, 1=invalid path, 2=task not found, 3=no tasks found
- **FR13.6**: All helper scripts have minimum permissions of 0500 (u+rx - readable and executable by owner)
- **FR13.7**: All helper scripts verified via SHA256 in `/cig-security-check`
- **FR13.8**: Helper scripts self-document with header comments (purpose, usage, version)
- **FR13.9**: Template version parser script (`template-version-parser.sh`):
  - Input: `<workflow-file-path>`
  - Optional flag: `--format=json` for JSON output (default: markdown)
  - Purpose: Utility script for parsing Template Version field from workflow files
  - Output (default markdown): Version number (e.g., "2.0" or "1.0")
  - Output (JSON with --format=json): Structured version metadata
  - Functionality:
    - Parse `**Template Version**` field from workflow file
    - Pattern: `grep "^\- \*\*Template Version\*\*:" <file>`
    - Default to version 1.0 if field is missing (backward compatibility)
  - Exit codes: 0=success, 1=file not found, 2=cannot parse version
- **FR13.10**: Template version parsing pattern for all helper scripts:
  - All helper scripts that need version information should use template-version-parser.sh or implement the same pattern
  - Ensures consistent version detection across all scripts

### FR14: Workflow System Documentation
- **FR14.1**: Workflow documentation stored in `.cig/docs/workflow/`
- **FR14.2**: Documentation explains why and how the hierarchical workflow system works
- **FR14.3**: Documentation covers:
  - Purpose of each workflow step (a-plan through h-retrospective)
  - When to use each workflow step
  - Focus/Avoid guidelines for each step
  - Universal decomposition principle and "too big" signals
  - Dynamic workflow transitions (non-linear flow)
  - Hierarchical task structure rationale
- **FR14.4**: Documentation is concise (LLM-friendly):
  - Clear enough for LLM to follow workflow commands
  - Brief enough to avoid wasting token context
  - Approximately 100-300 words per workflow step
- **FR14.5**: Progressive disclosure - documentation referenced by:
  - `/cig-new-task` command (overview of workflow system)
  - `/cig-subtask` command (references workflow documentation)
  - 8 workflow commands (each references relevant workflow step docs)
- **FR14.6**: Documentation format: Markdown files in `.cig/docs/workflow/`
- **FR14.7**: Core documentation files:
  - `workflow-overview.md` - System overview and principles
  - `workflow-steps.md` - Detailed step-by-step guide
  - `decomposition-guide.md` - When and how to create subtasks

### FR15: Workflow File Templates
- **FR15.1**: Central template pool in `.cig/templates/pool/`
- **FR15.2**: Eight workflow file templates stored in pool with lettered naming:
  - `a-plan.md.template` - Planning template (based on current `plan.md.template`)
  - `b-requirements.md.template` - Requirements template (based on current `requirements.md.template`)
  - `c-design.md.template` - Design template (based on current `design.md.template`)
  - `d-implementation.md.template` - Implementation template (based on current `implementation.md.template`)
  - `e-testing.md.template` - Testing template (based on current `testing.md.template`)
  - `f-rollout.md.template` - Rollout template (based on current `rollout.md.template`)
  - `g-maintenance.md.template` - Maintenance template (based on current `maintenance.md.template`)
  - `h-retrospective.md.template` - New template (no current equivalent, created from requirements)
- **FR15.2.1**: Use existing templates as starting point:
  - Current templates in `.cig/templates/<type>/` are the foundation
  - Adapt existing structure and content to new format requirements
  - Preserve proven patterns and sections from current templates
  - New requirements/design override existing content where conflicts exist
  - This ensures continuity and leverages existing refinements
- **FR15.3**: Task type directories contain symlinks to pool templates:
  - `.cig/templates/feature/a-plan.md.template` → `../pool/a-plan.md.template`
  - `.cig/templates/bugfix/a-plan.md.template` → `../pool/a-plan.md.template`
  - `.cig/templates/hotfix/a-plan.md.template` → `../pool/a-plan.md.template`
  - `.cig/templates/chore/a-plan.md.template` → `../pool/a-plan.md.template`
  - (Pattern repeated for all 8 workflow steps)
- **FR15.4**: Symlink structure benefits:
  - DRY: Single source of truth for each template
  - Consistency: All task types use identical templates for each step
  - Maintainability: Update once in pool, affects all task types
  - Progressive disclosure: Clear separation between template content (pool) and task type usage (symlinks)
- **FR15.5**: Each template defines structure and content requirements:
  - Task Reference section with metadata fields (template defines fields, command populates values)
  - **Template Version** field in Task Reference section for all templates (format: `**Template Version**: X.Y`)
  - New hierarchical workflow templates start at version 2.0 (distinguishes from old format v1.0)
  - Template version enables helper scripts to parse files correctly and detect format changes
  - Version is parseable via: `grep "^\- \*\*Template Version\*\*:" <file>`
  - Section structure appropriate for that workflow step
  - Guidance comments explaining what belongs in each section
  - Status marker section with standardised status types (per FR2.4)
  - Status tracking checkboxes where appropriate
  - Note: Templates are the authoritative specification for file structure
- **FR15.6**: Templates used by `/cig-new-task` and `/cig-subtask` when creating tasks
- **FR15.7**: Task type determines which templates are copied (not all 8 required for every task type)
- **FR15.8**: Templates support both old and new formats during transition period

## Non-Functional Requirements

### NFR1: Performance
- **NFR1.1**: Status display renders in <2 seconds for 100 tasks
- **NFR1.2**: Context inheritance reads complete in <1 second
- **NFR1.3**: Command execution feels instantaneous

### NFR2: Usability
- **NFR2.1**: Clear error messages with actionable guidance
- **NFR2.2**: Examples in command documentation
- **NFR2.3**: Intuitive command naming and structure
- **NFR2.4**: Consistent patterns across all commands

### NFR3: Maintainability
- **NFR3.1**: Shared helper scripts for common operations
- **NFR3.2**: Self-documenting script names
- **NFR3.3**: Comments explaining complex logic
- **NFR3.4**: Modular design for easy updates

### NFR4: Security
- **NFR4.1**: Scripts have minimum permissions of 0500 (u+rx - readable and executable by owner)
- **NFR4.2**: SHA256 verification for helper scripts
- **NFR4.3**: Git-based version tracking
- **NFR4.4**: No execution of untrusted code

### NFR5: Reliability
- **NFR5.1**: Graceful handling of missing files
- **NFR5.2**: Validation before destructive operations
- **NFR5.3**: Rollback capability for migrations
- **NFR5.4**: No data loss during format transitions

## Constraints

### Technical Constraints
- Must work within Claude Code slash command system
- Bash scripts for helper functionality
- Markdown format for all task files
- Git repository required for version tracking

### Compatibility Constraints
- Support both old and new task structures indefinitely
- Maintain existing task numbering (1, 2, 3 already used)
- Preserve all existing task content and history

### Process Constraints
- Use dogfooding approach (build CIG with CIG)
- Migration via subtask during rollout phase (recommended but not deterministically verifiable)
- No breaking changes to existing workflows

### Process Guidelines (Non-Deterministic)
- **Dogfooding migration**: Create subtask 3.1 for migration during rollout phase
  - Demonstrates the hierarchical workflow system in action
  - Isolates migration work for focused execution and testing
  - Provides real-world example of subtask creation
  - Note: This is a manual process requiring user verification at completion
  - User will be prompted to verify migration subtask was used appropriately

## Acceptance Criteria

### AC1: Task Creation
- [ ] Can create top-level task with new format
- [ ] Can create subtasks at any depth
- [ ] Can mix task types at same level
- [ ] Directory and file structure correct
- [ ] Templates properly populated
- [ ] `/cig-new-task` argument-hint shows new signature: `<num> <type> "description"`
- [ ] `/cig-subtask` argument-hint shows correct signature: `<parent-path> <num> <type> "description"`
- [ ] All workflow commands have accurate argument-hint fields

### AC2: Workflow Execution
- [ ] All 8 workflow commands functional
- [ ] Context inheritance working
- [ ] Next-step suggestions appropriate
- [ ] Decomposition signals detected correctly

### AC2.1: Extract Command
- [ ] `/cig-extract` accepts task-based paths (e.g., `1/1.1 goal`)
- [ ] `/cig-extract` uses hierarchy-resolver.sh for path resolution
- [ ] `/cig-extract` uses format-detector.sh for format detection
- [ ] Section name mapping works for both old and new formats
- [ ] Backward compatibility with full file paths maintained
- [ ] LLM detects and reports file corruption issues
- [ ] LLM provides helpful error messages and recovery suggestions
- [ ] Case-insensitive section name matching works

### AC2.2: Status Markers
- [ ] Templates include standardised status marker sections
- [ ] All minimum status types supported: Backlog, To-Do, In Progress, Implemented, Testing, Finished
- [ ] Status format consistent across all workflow files
- [ ] Helper scripts can parse status markers
- [ ] Workflow commands detect current status from markers
- [ ] Status markers enable dynamic workflow transitions

### AC3: Backward Compatibility
- [ ] Old structure tasks remain accessible
- [ ] Commands detect format automatically
- [ ] No functionality lost for old tasks
- [ ] Can create both formats

### AC3.1: Content Guidance
- [ ] `/cig-new-task` includes focus/avoid guidance for each workflow file
- [ ] `/cig-subtask` references `/cig-new-task` for workflow file content guidance
- [ ] Separation of concerns clearly documented in commands
- [ ] Users understand what belongs in each file type

### AC3.2: Command Refactoring
- [ ] `/cig-subtask` references `/cig-new-task` for shared details
- [ ] No duplicated content between commands
- [ ] Progressive disclosure principle implemented
- [ ] Commands remain maintainable and DRY

### AC3.3: Helper Scripts
- [ ] All 5 helper scripts exist and are executable (minimum 0500)
- [ ] context-inheritance.pl returns structural map with headers, line ranges, and status markers
- [ ] context-inheritance.pl provides token-efficient parent context (~50-100 tokens per parent)
- [ ] hierarchy-resolver.sh resolves task paths to full filesystem paths with metadata
- [ ] format-detector.sh performs version comparison and displays workflow file header discrepancies
- [ ] format-detector.sh checks workflow doc version vs CIG software version
- [ ] status-aggregator.sh calculates progress accurately using status marker parsing
- [ ] template-version-parser.sh parses Template Version field correctly
- [ ] All helper scripts support both markdown (default) and JSON output via --format=json flag
- [ ] All scripts pass SHA256 verification
- [ ] Scripts include self-documenting headers
- [ ] Helper scripts correctly parse Template Version field when present
- [ ] Helper scripts default to version 1.0 when Template Version field is missing

### AC3.4: Workflow Documentation
- [ ] Documentation exists in `.cig/docs/workflow/`
- [ ] All 3 core documentation files created (overview, steps, decomposition)
- [ ] Each workflow step has focus/avoid guidelines documented
- [ ] Documentation is LLM-friendly (clear but concise, ~100-300 words per step)
- [ ] Task creation commands reference workflow documentation
- [ ] 8 workflow commands reference relevant step documentation
- [ ] Progressive disclosure principle applied in references

### AC3.5: Workflow File Templates
- [ ] Central template pool exists in `.cig/templates/pool/`
- [ ] All 8 workflow file templates created in pool (a-plan through h-retrospective)
- [ ] New templates based on existing templates where applicable (7 templates adapted, 1 new)
- [ ] Proven patterns and sections from current templates preserved
- [ ] Each template has proper structure (Task Reference, sections, guidance comments)
- [ ] Each template includes `**Template Version**` field in Task Reference section
- [ ] Template version follows X.Y format (e.g., 2.0)
- [ ] Helper scripts can parse template version from files
- [ ] Templates include status tracking where appropriate
- [ ] Task type directories contain symlinks to pool templates
- [ ] Symlinks are valid and point to correct pool files
- [ ] Task type determines which templates are copied
- [ ] Updating pool template affects all task types (verifies symlinks work)

### AC4: Migration
- [ ] All existing tasks migrated successfully
- [ ] Git history preserved
- [ ] No broken references
- [ ] All commands work with migrated tasks
- [ ] **User verification**: Migration subtask 3.1 created during rollout (manual check)
- [ ] **User verification**: Dogfooding approach demonstrated effectively (manual check)

### AC5: Documentation
- [ ] All commands documented with examples
- [ ] Architecture explained clearly
- [ ] Migration guide provided
- [ ] Maintenance procedures documented

## Dependencies
- Scratchpad design document (complete)
- Existing CIG system (operational)
- Git repository (in good state)
- Existing tasks (3 feature, 1 bugfix, 1 chore)

## Out of Scope
- Automated workflow orchestration
- Real-time collaboration
- Web-based UI
- Integration with external PM tools (beyond basic GitHub issues)
- Undo/redo functionality
- Task templates beyond the 8 workflow steps
