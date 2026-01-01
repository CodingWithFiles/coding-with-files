# Script-Based CIG Command Helpers - Design

## Task Reference
- **Task ID**: internal-2
- **Task URL**: Internal development task (no GitHub issue yet)
- **Parent Task**: Core CIG System
- **Branch**: feature/internal-2-script-based-command-helpers
- **Template Version**: 2.0
- **Migration**: v1.0 (git:migration-backup-20251213-233514) → v2.0

## Goal
Define architecture and design decisions for script-based CIG command helpers.

## Key Decisions
### Architecture Choice
- **Decision**: Encapsulated shell scripts in `.cig/scripts/command-helpers/`
- **Rationale**: Eliminates compound operations, enables extension, simplifies permissions
- **Trade-offs**: Additional files vs cleaner permission model

### Technology Stack
- **Scripts**: POSIX shell for maximum compatibility
- **Tools**: Standard Unix utilities (egrep, find, cat, test)
- **Permissions**: Single pattern `Bash(.cig/scripts/*)` covers all scripts
- **File Permissions**: Scripts set to `0500` (read/execute only, no write)

## System Design
### Component Overview
- **Context Loaders**: Scripts that gather project context information
- **Helper Scripts**: Utility functions for common operations
- **Command Integration**: Updated CIG commands call scripts instead of inline bash
- **Task Tracking**: Hybrid numbering system for GitHub issues integration

### Script Naming Convention
**Self-Documenting Names**: Script names explicitly describe their function for LLM clarity
```
.cig/scripts/command-helpers/
├── cig-load-autoload-config         # Loads .cig/autoload.yaml or provides fallback
├── cig-load-project-config          # Loads implementation-guide/cig-project.json
├── cig-load-existing-tasks          # Discovers all task headers across implementation guide
├── cig-find-task-numbering-structure # Finds numbered directories for task sequencing
└── cig-load-status-sections         # Extracts "Current Status" sections from tasks
```

**Security Command**:
```
.claude/commands/
└── cig-security-check.md            # Verifies integrity of CIG commands and scripts
```

**Naming Philosophy**: 
- **Verb-Noun Pattern**: `cig-{action}-{target}` (e.g., `cig-load-config`, `cig-find-task-numbering-structure`)
- **LLM-Readable**: Names immediately convey purpose without documentation lookup
- **Consistent Prefix**: All helper scripts start with `cig-` for clear identification

### Task ID and Branch Naming Strategy
**Task ID Formats by System**:
- **GitHub Issues**: `issues-{{number}}` (e.g., `issues-42`)
- **GitLab Issues**: `issues-{{number}}` (e.g., `issues-123`) 
- **JIRA Tickets**: `{{project-key}}-{{number}}` (e.g., `PROJ-456`)
- **Internal/Fallback**: `internal-{{number}}` (e.g., `internal-2`)

**Branch Naming Convention**: `{{task-type}}/{{task-id}}-{{description-slug}}`

**Examples by Task Tracking System**:
- **GitHub**: `feature/issues-42-script-based-command-helpers`
- **GitLab**: `feature/issues-123-script-based-command-helpers`
- **JIRA**: `feature/PROJ-456-script-based-command-helpers`
- **Internal**: `feature/internal-2-script-based-command-helpers`

**Current Project Configuration**:
- Using GitHub issues format with internal fallback
- Example: `bugfix/internal-1-cig-command-permissions` (existing internal task)

**Migration Path**: When external issue created, update task references:
- `internal-2` → `issues-42` (GitHub)
- `internal-2` → `issues-123` (GitLab)  
- `internal-2` → `PROJ-456` (JIRA)
- Branch can optionally be renamed for consistency

### Data Flow
1. CIG command invoked → calls helper script
2. Helper script processes → returns formatted output
3. Command displays → context information to user

## Interface Design
### Script Interface
- **Input**: No parameters (scripts read environment)
- **Output**: Formatted text or fallback messages
- **Exit Codes**: 0 for success, non-zero for errors

### Example Script Pattern
```bash
#!/bin/sh
# Load autoload configuration or provide fallback
if [ -f ".cig/autoload.yaml" ]; then
    cat ".cig/autoload.yaml"
else
    echo "No autoload config found"
fi
```

## Constraints
- POSIX compatibility for Linux/macOS
- No external dependencies beyond standard tools
- Preserve exact existing output format
- Must handle missing files/directories gracefully

## Security Model
### Script Integrity Verification
**Canonical Source**: GitHub repository serves as authoritative source
- **Remote Verification**: `curl -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/OWNER/REPO/contents/PATH/TO/FILE?ref={TAG_NAME|COMMIT_SHA}"`
- **Local Verification**: `git ls-tree {TAG_NAME|COMMIT_SHA} -- path/to/file`

### File Security
- **Script Permissions**: `0500` (read/execute only, prevents accidental modification)
- **Write Protection**: Scripts cannot be modified during execution
- **Canonical Authority**: GitHub repository is single source of truth for script content
- **Integrity Verification**: `cig-security-check` command validates file authenticity

### Script Frontmatter Format
**Required Header Comments** for all helper scripts:
```bash
#!/bin/sh
# Script: {script-name}
# Version: {version-from-cig-project.json}
# Source: {canonical-repo-url}
# Purpose: {clear description}
```

**Note**: SHA verification is performed against the canonical remote repository, not stored in file headers to avoid circular dependency

### Security Check Command (`cig-security-check`)
**Verification Process**:
1. **File Discovery**: Find all CIG commands (`.claude/commands/cig-*.md`) and helper scripts (`.cig/scripts/command-helpers/cig-*`)
2. **Version Cross-Reference**: Compare script versions with `implementation-guide/cig-project.json`
3. **SHA Verification**: Calculate local file SHA and compare with canonical remote source:
   - **Remote Authority**: GitHub/GitLab API provides authoritative SHA for comparison
   - **Local Calculation**: `sha256sum` or `shasum` calculates local file hash
   - **Comparison**: Local SHA must match remote canonical SHA
   - **Tamper Detection**: Any mismatch indicates local file modification
4. **Report Results**: Show verification status for each file with specific tamper warnings

## Integration with Existing Commands
### Command Integration Requirements
- **Compound Operation Rule**: Any compound bash operations (pipes, logical operators, redirections) in CIG commands MUST be encapsulated in helper scripts
- **Single Command Policy**: CIG command files may only contain single bash command calls to avoid permission issues
- **Script Call Pattern**: Replace `!`command1 | command2 || echo "fallback"`` with `!`.cig/scripts/command-helpers/script-name``

### Error Handling for LLM Integration
**Script Error Output Requirements**:
- **Descriptive Messages**: Scripts must output human-readable error descriptions when failing
- **Context Information**: Include what the script was trying to do and why it failed
- **Actionable Guidance**: Provide specific steps for resolution when possible

**Example Error Output**:
```bash
# Good LLM-friendly error
echo "ERROR: Cannot load project configuration - file 'implementation-guide/cig-project.json' not found. Run '/cig-init' to initialize project structure."

# Poor error (exit code only)
exit 1
```

### Current Commands Requiring Script Integration
Only CIG commands with compound operations need helper scripts:
- `cig-new-task.md` - Context loading operations (has compound bash)
- `cig-status.md` - Status and task discovery operations (has compound bash)
- `cig-extract.md` - Section extraction operations (if using compound bash)
- `cig-subtask.md` - Hierarchy and parent task operations (if using compound bash)  
- `cig-retrospective.md` - Project analysis operations (if using compound bash)

**Note**: Commands using only single bash operations require no changes

## Validation
- [ ] Design review completed
- [ ] POSIX compliance verified
- [ ] Integration points identified

## Current Status
**Status**: Finished
**Next Action**: Design validated through successful implementation
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
