# Implementation Guide Commands

## Goal

Provide comprehensive command reference for Coding with Files (CWF) system to enable efficient project documentation workflow.

## Setup Command

### `/cwf-init`
**Purpose**: Initialise implementation guide system in current project

**Usage**:`/cwf-init`

**Actions**:
- Creates `<git-root>/implementation-guide/` directory structure with task categories (feature/, bugfix/, hotfix/, chore/)
- Generates `cwf-project.json` Coding with Files Project configuration file
- Creates README.md with navigation index and command reference
- Creates `.templates/` directory with category-specific template files
- Updates CLAUDE.md with section extraction hints, standard section names, and CWF system integration
- Provides command reference and next steps

**Output**: Confirmation message with available commands and setup completion status

## Unified Task Creation Command

### `/cwf-new-task <task-type> [task-id] <description>`
**Purpose**: Create new categorised implementation guide with task tracking integration

**Usage**:
- `/cwf-new-task feature JIRA-1234 "user authentication system"`
- `/cwf-new-task bugfix #567 "login validation error"`
- `/cwf-new-task hotfix "security vulnerability"`

**Creates**:
- Categorised directory: `implementation-guide/{task-type}/N-{description}/`
- Task-specific template documents based on type
- Task Reference section with tracking integration
- Suggested git branch name for development

**Output**: Implementation guide path, suggested branch name, and next steps

**Branch Name Suggestions**:
- With task ID: `feature/JIRA-1234-user-authentication-system`
- Template format: `{task-type}/{task-id}-{description-slug}`

**Task Type Templates**:

**Feature Tasks** - Full development lifecycle:
- `plan.md`, `requirements.md`, `design.md`, `testing.md`, `rollout.md`, `maintenance.md`

**Bugfix Tasks** - Streamlined fix workflow:
- `plan.md`, `implementation.md`, `testing.md`, `rollout.md`

**Hotfix Tasks** - Urgent production fixes:
- `plan.md`, `implementation.md`, `rollout.md`

**Chore Tasks** - Maintenance and improvements:
- `plan.md`, `implementation.md`, `validation.md`

## Hierarchy Management Commands

### `/cwf-substep <parent-path> <substep-name>`
**Purpose**: Create numbered subdirectory under existing feature

**Usage**: `/cwf-substep 1-auth-system user-model`

**Creates**:
- Directory: `1-auth-system/1.1-user-model/`
- Basic template files: `plan.md`, `requirements.md`, `implementation.md`

**Auto-numbering**: Automatically assigns next available number (1.1, 1.2, etc.)

## Utility Commands

### `/cwf-status [feature-path]`
**Purpose**: Show completion status across implementation guide hierarchy

**Usage**:
- `/cwf-status` - Shows all guides
- `/cwf-status 1-auth-system` - Shows specific feature status

**Output**: Progress summary with completion percentages, blockers, next actions

### `/cwf-extract <file-path> <section-name>`
**Purpose**: Extract specific section from implementation guide document

**Usage**:`/cwf-extract 1-auth-system/plan.md "Original Estimate"`

**Method**: Uses `sed -n '/^## <section-name>/,/^## /p' <file> | head -n -1`

**Common Sections**:
- "Original Estimate" - Initial planning estimates
- "Task Reference" - Task tracking integration (Task ID, URL, Parent Task, Branch)
- "Goal" - Single sentence objective
- "Success Criteria" - Measurable outcomes
- "Actual Results" - Post-completion actuals
- "Lessons Learned" - Key insights and variances
- "Current Status" - Progress tracking
- "Documentation" - Links to related documents and references

### `/cwf-retrospective <feature-path>`
**Purpose**: Facilitate post-completion analysis and variance tracking

**Usage**:`/cwf-retrospective 1-auth-system`

**Actions**:
- Prompts for Actual Results in all feature documents
- Captures variance between Original Estimate and Actual Results
- Facilitates Lessons Learned documentation
- Updates status.md with completion markers

### `/cwf-security-check [verify|report]`
**Purpose**: Verify file integrity and sources for CWF system

**Usage**:`/cwf-security-check verify`

**Actions**:
- Validates helper script integrity against canonical repository
- Checks script frontmatter for version and source information
- Calculates SHA256 checksums and compares with remote sources
- Generates security verification report
- Supports GitHub API, GitLab API, and local git verification methods

**Parameters**:
- `verify`: Perform full integrity verification against canonical source
- `report`: Generate summary report of current file status

## Workflow Integration

### Typical Command Progression

1. **Project Setup**: `/cwf-init`
2. **Task Creation**: `/cwf-new-task feature JIRA-1234 "major feature"`
3. **Break Down**: `/cwf-substep feature/1-major-feature first-component`
4. **Implementation**: Work with generated documents (plan.md → requirements.md → design.md → implementation.md)
5. **Progress Tracking**: `/cwf-status feature/1-major-feature`
6. **Section Review**: `/cwf-extract feature/1-major-feature/plan.md "Success Criteria"`
7. **Post-Completion**: `/cwf-retrospective feature/1-major-feature`

### Status Monitoring

- Use `/cwf-status` regularly to track progress
- Use `/cwf-extract` to review specific sections without loading full documents
- Update Original Estimate → Actual Results progression through implementation

## Integration with CLAUDE.md

Commands automatically update project CLAUDE.md with:
- Section extraction patterns
- Standard section names
- Directory structure navigation hints
- Command usage examples

This ensures future Claude Code instances can work efficiently with the generated documentation structure.

## Key Decisions

### Command Design Principles
- **Namespace Safety**: `cig-` prefix prevents command collisions
- **Filename Matching**: Command names correspond to generated files
- **Hierarchical Support**: Commands support nested feature breakdown
- **Template Consistency**: All commands use standardised section templates

### Directory Structure
- Numbered hierarchy encoding (1-feature/1.1-subfeature)
- Single file per concern (planning vs execution vs deployment)
- Predictable patterns for tool integration

### Section Standardisation
- Universal tracking sections across all documents
- Human-readable section names with reliable extraction patterns
- Consistent template structure for rapid navigation

