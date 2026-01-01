# Script-Based CIG Command Helpers - Implementation

## Task Reference
- **Task ID**: internal-2
- **Task URL**: Internal development task (no GitHub issue yet)
- **Parent Task**: Core CIG System
- **Branch**: feature/internal-2-script-based-command-helpers
- **Template Version**: 2.0
- **Migration**: v1.0 (git:migration-backup-20251213-233514) → v2.0

## Goal
Implement script-based helper system to resolve CIG command permissions issues.

## Implementation Steps
### Step 1: Create Script Directory Structure
```bash
mkdir -p .cig/scripts/command-helpers
```

### Step 2: Implement Helper Scripts
**Self-Documenting Script Names**: Each script name explicitly describes its function for LLM understanding

#### cig-load-autoload-config
**Purpose**: Load `.cig/autoload.yaml` configuration or provide fallback message
**Replaces**: `cat .cig/autoload.yaml 2>/dev/null || echo "No autoload config found"`

#### cig-load-project-config  
**Purpose**: Load `implementation-guide/cig-project.json` or provide setup guidance
**Replaces**: `cat implementation-guide/cig-project.json 2>/dev/null || echo "Run /cig-init first"`

#### cig-load-existing-tasks
**Purpose**: Discover all task section headers across implementation guide
**Replaces**: `egrep -rn '^#+ ' implementation-guide/ --include="*.md" 2>/dev/null || echo "No existing tasks"`

#### cig-find-task-numbering-structure
**Purpose**: Find numbered directories for task sequence determination
**Replaces**: `find implementation-guide -maxdepth 5 -type d -name '[0-9]*' 2>/dev/null || echo "Starting at 1"`

#### cig-load-status-sections
**Purpose**: Extract "Current Status" sections from implementation guide tasks  
**Replaces**: `egrep -rn '^## Current Status' implementation-guide/ --include="*.md" -A 3 2>/dev/null || echo "No status sections found"`

### Step 3: Script Implementation Pattern
**Standard Script Structure**:
```bash
#!/bin/sh
# Script: {script-name}
# Version: {git-tag}-{git-commit-id}
# Source: {canonical-repo-url}
# Purpose: {clear description of function}
# Replaces: {original compound operation}

{implementation with error handling}
```

**Git-Based Versioning Implementation**:
- **Format**: `git describe --tags --always` (e.g., `v0.1.1-5-gcea1c19`)
- **Security Benefit**: Version reflects exact git state when script was last modified
- **Verification**: Enables precise integrity checking against canonical repository

**SHA Verification Approach**:
- **Remote Authority**: Canonical repository is single source of truth for SHA values
- **Local Verification**: `cig-security-check` calculates local file SHA and compares with remote
- **No Self-Reference**: Scripts don't contain their own SHA to avoid circular dependency

**Error Handling Requirements**:
- Descriptive error messages for LLM consumption
- Context about what failed and why
- Actionable guidance when possible

### Step 4: Update CIG Commands
Replace all compound bash operations with single script calls:

**Pattern Transformation**:
- **Before**: `!`command1 | command2 || echo "fallback"`
- **After**: `!`.cig/scripts/command-helpers/script-name`

**Commands to Update** (only those with compound operations):
- `cig-new-task.md` - 4 context loading operations (confirmed compound bash)
- `cig-status.md` - 2 status discovery operations (confirmed compound bash)
- Other commands only if they contain compound operations like `|`, `||`, `&&`, redirections

### Step 5: Update Permissions
Simplify `allowed-tools` in all CIG command frontmatter:
- **Remove**: `Bash(cat:*)`, `Bash(egrep:*)`, `Bash(echo:*)`, `Bash(find:*)`
- **Add**: `Bash(.cig/scripts/*)`

### Step 6: Set Script Permissions
```bash
chmod 0500 .cig/scripts/command-helpers/*
```

### Step 7: Implement Security Check Command
Create `.claude/commands/cig-security-check.md` to verify CIG system integrity:

**Command Purpose**: Validate authenticity and version consistency of all CIG commands and helper scripts

**Verification Features**:
- Cross-reference versions with `cig-project.json`
- Calculate local file SHA and verify against canonical remote sources
- Support GitHub API, GitLab API, and local git repository verification
- Report integrity status with specific tamper detection warnings
- Remote repository serves as immutable source of truth for SHA comparison

**Implementation Requirements**:
- Self-contained verification logic (no external dependencies)
- Clear security status reporting for LLM consumption
- Support for multiple source verification methods
- Version correlation with project configuration

### Step 8: Update Main Repository Design Documentation
Update the main `DESIGN.md` file to reflect the script-based architecture changes:

**Changes to Document**:
- Script-based command helper system architecture
- Self-documenting script naming convention (`cig-{action}-{target}`)
- Security model with `0500` permissions and integrity verification
- Task tracking system with GitHub/GitLab/JIRA/internal numbering formats
- Command integration requirements (compound operations → scripts)
- LLM-friendly error handling requirements

**Purpose**: Ensure main project documentation reflects the architectural evolution from compound bash operations to encapsulated script helpers

## Script Naming Philosophy
**LLM-Friendly Design**: Script names are self-documenting to enable LLM understanding without external documentation

**Naming Pattern**: `cig-{action}-{target}`
- `cig-load-*` - Scripts that load/read configuration or data
- `cig-find-*` - Scripts that search/discover information  
- `cig-extract-*` - Scripts that extract specific content

**Examples**:
- `cig-load-autoload-config` immediately tells LLM this loads autoload configuration
- `cig-find-task-numbering-structure` clearly indicates task numbering discovery function
- `cig-extract-status-sections` explicitly describes status section extraction

This eliminates need for LLM to consult documentation to understand script purpose.

## Validation Criteria
- [x] All helper scripts execute without errors
- [x] All CIG commands work with single script calls
- [x] Permissions simplified to single pattern
- [x] Error messages are LLM-friendly
- [x] Script names are self-documenting
- [x] All scripts include required frontmatter headers
- [x] `cig-security-check` validates file integrity successfully
- [x] Version tracking aligned with cig-project.json

## Current Status
**Status**: Finished
**Next Action**: Feature ready for production use
**Blockers**: None

## Actual Results
- **Duration**: Completed in single session (as estimated)
- **Script Implementation**: Created 5 helper scripts with self-documenting names
- **CIG Command Updates**: Updated 6 commands to use script calls instead of compound operations
- **Permission Security Fix**: Fixed insecure wildcard `Bash(.cig/scripts/*)` pattern to specific script paths following principle of least privilege
- **Security Implementation**: Added integrity verification command with SHA256 validation
- **Documentation Updates**: Main DESIGN.md updated with complete architecture documentation
- **Cross-Platform**: All scripts use POSIX-compliant shell features
- **Git-Based Versioning**: Implemented `v0.1.1-5-gcea1c19` format for precise security anchoring

## Lessons Learned
- **Self-Documenting Names Critical**: Script names like `cig-load-autoload-config` eliminate need for LLM to consult documentation
- **Security Model Success**: 0500 permissions with remote repository verification provides robust integrity checking
- **Compound Operation Resolution**: Encapsulating complex bash operations in scripts eliminates Claude Code permission prompts
- **Template Consistency**: Standard script frontmatter with version/source/purpose enables systematic maintenance
- **Error Message Design**: Descriptive fallback messages improve LLM decision-making when files don't exist
- **Permission Security**: Wildcard patterns (`Bash(.cig/scripts/*)`) create security vulnerabilities and path matching issues - specific script paths required
- **Git-Based Versioning**: Using `git describe --tags --always` format provides precise security anchoring and enables tamper detection
