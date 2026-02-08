# complete helper script migration to trampoline architecture - Design

## Task Reference
- **Task ID**: internal-40
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/40-complete-helper-script-migration-to-trampoline-architecture
- **Template Version**: 2.1

## Goal
Define the trampoline/module architecture for migrating all remaining CIG helper scripts, establishing a consistent permission model with 3 trampolines (context-manager, workflow-manager, template-manager) that decouple invocation permissions from functional implementation.

## Design Priorities
Consistency → Simplicity → Readability → Testability → Reversibility
- **Consistency**: Follow Task 39's proven trampoline pattern exactly
- **Simplicity**: Structural migration only, preserve module logic unchanged
- **Readability**: Clear subcommand names, self-documenting architecture

## Architecture Preferences
Composition over inheritance. Explicit over implicit. Convention over configuration.
- Follow Unix conventions: Perl scripts, no extensions, executable permissions
- Follow golang/git/docker pattern: trampoline + subcommands
- Progressive disclosure: Error messages guide users to correct usage

## Key Decisions

### Architecture Choice: Complete Trampoline/Module Migration
- **Decision**: Migrate all 6 remaining helper scripts to trampoline/module architecture under 3 trampolines
  - **context-manager**: hierarchy, inheritance, version (adds 3 subcommands to existing trampoline)
  - **workflow-manager**: status, control (new trampoline + 2 subcommands)
  - **task-workflow**: create (new trampoline + 1 subcommand)

- **Rationale**:
  - **Architectural consistency**: Task 39 established pattern, Task 40 completes migration for uniform architecture
  - **Permission simplification**: Consolidate from 7+ permission patterns to 3 trampolines
  - **Extensibility**: Easy to add future subcommands without new permission patterns
  - **Maintainability**: All helper scripts follow same pattern, easier to understand and modify
  - **Zero permission prompts**: Trampoline invocation is only permission boundary

- **Trade-offs**:
  - **Benefit**: Consistent architecture, simpler permissions, extensible, zero prompts
  - **Drawback**: More files (trampolines + modules), but organized in .d/ directories
  - **Benefit**: Self-documenting (subcommand names describe purpose)
  - **Drawback**: Requires updating all CIG commands, but improves clarity

### Technology Stack
- **Language**: Perl (established convention from Task 39)
  - No extensions (Unix convention, not "brain-dead Windows file extensions")
  - Executable permissions (u+rx, minimum 0500)
  - Proper shebang (`#!/usr/bin/env perl`)
- **Pattern**: Hash table dispatch in trampolines (proven in context-manager)
- **Module Organization**: Trampoline.d/ directories (e.g., workflow-manager.d/)
- **Error Handling**: Clear error messages for unknown subcommands, missing arguments

## System Design

### Component Overview

This task creates 2 new trampolines, adds 6 modules, updates 1 existing trampoline, and modifies 17 CIG commands.

#### 1. Context-Manager Expansion (Existing Trampoline)
**File**: `.cig/scripts/command-helpers/context-manager`
- **Current State**: Has 1 subcommand (location)
- **Changes**: Add 3 new subcommands to dispatch hash
- **New Subcommands**:
  - `hierarchy <task-path>` → `.../context-manager.d/hierarchy` (replaces hierarchy-resolver)
  - `inheritance <task-path>` → `.../context-manager.d/inheritance` (replaces context-inheritance)
  - `version <task-dir> <workflow-file>` → `.../context-manager.d/version` (replaces format-detector + template-version-parser COMBINED)
- **Purpose**: Centralize all context-related operations (location, hierarchy, inheritance, version detection)

#### 2. Workflow-Manager Creation (New Trampoline)
**File**: `.cig/scripts/command-helpers/workflow-manager`
- **Pattern**: Copy context-manager trampoline structure
- **Subcommands**:
  - `status [task-path]` → `.../workflow-manager.d/status` (replaces status-aggregator)
  - `control --current-step=X --task-path=Y` → `.../workflow-manager.d/control` (replaces workflow-control)
- **Purpose**: Centralize workflow operations (status aggregation, workflow control)
- **Module Directory**: `.cig/scripts/command-helpers/workflow-manager.d/`

#### 3. Task-Workflow Creation (New Trampoline)
**File**: `.cig/scripts/command-helpers/task-workflow`
- **Pattern**: Copy context-manager trampoline structure
- **Subcommands**:
  - `create --task-type=X --destination=Y --task-num=Z --description=D` → `.../task-workflow.d/create` (replaces template-copier)
- **Purpose**: Create task workflow files (always v2.1 format)
- **Naming**: Semantic focus on "what" (create task workflow) vs implementation detail ("copy templates")
- **Module Directory**: `.cig/scripts/command-helpers/task-workflow.d/`

#### 4. Module Files (7 total: 1 existing + 6 new)
All modules preserve existing logic exactly - this is structural migration only:

**Context Manager Modules** (3 new + 1 existing):
- `context-manager.d/location` - Existing (from Task 39)
- `context-manager.d/hierarchy` - New (copy hierarchy-resolver logic, no version routing)
- `context-manager.d/inheritance` - New (copy context-inheritance logic, WITH version routing to -v2.0/-v2.1)
- `context-manager.d/version` - New (COMBINES format-detector + template-version-parser logic, no version routing)

**Workflow Manager Modules** (2 new):
- `workflow-manager.d/status` - New (copy status-aggregator logic, WITH version routing to -v2.0/-v2.1)
- `workflow-manager.d/control` - New (copy workflow-control logic, WITH version routing to -v2.0/-v2.1)

**Task Workflow Modules** (1 new):
- `task-workflow.d/create` - New (copy template-copier logic, ALWAYS v2.1 - no version routing)

#### 5. CIG Command Updates (17 files)
**Files**: `.claude/commands/cig-*.md`
- **Change Pattern**: Replace direct helper calls with trampoline calls
- **Example Mappings**:
  - `hierarchy-resolver 40` → `context-manager hierarchy 40`
  - `context-inheritance 40` → `context-manager inheritance 40`
  - `format-detector $DIR $FILE` → `context-manager version $DIR $FILE`
  - `template-version-parser $DIR $FILE` → `context-manager version $DIR $FILE` (SAME as format-detector)
  - `status-aggregator` → `workflow-manager status`
  - `workflow-control --args` → `workflow-manager control --args`
  - `template-copier --args` → `task-workflow create --args`

### Data Flow

#### Trampoline Dispatch Pattern (All 3 Trampolines)
```
User invokes CIG command → Bash tool call → Trampoline script
   ↓
Trampoline parses subcommand argument
   ↓
Trampoline looks up subcommand in dispatch hash
   ↓
Trampoline execs module with remaining arguments
   ↓
Module executes (no additional permission prompts)
   ↓
Module returns output to CIG command
```

#### Example: context-manager hierarchy 40
```
1. CIG command: `!{bash} .cig/scripts/command-helpers/context-manager hierarchy 40`
2. Permission check: Claude Code checks if `context-manager:*` allowed (yes)
3. Trampoline: context-manager receives ["hierarchy", "40"]
4. Dispatch: Looks up "hierarchy" in %commands hash
5. Exec: Executes context-manager.d/hierarchy with args ["40"]
6. Module: hierarchy runs hierarchy-resolver logic, outputs task path
7. Return: Output flows back to CIG command
```

#### Version Routing (Where Needed)
Some modules (inheritance, status, copy) need version-specific logic:
```
Module entry point (e.g., context-manager.d/inheritance)
   ↓
Detect task format version (v2.0 vs v2.1)
   ↓
Route to version-specific implementation OR
   ↓
Use unified version-agnostic implementation
   ↓
Return results
```

**Design Decision**: Keep existing version routing patterns from current scripts. Don't refactor module internals - this is structural migration only.

## Interface Design

### Trampoline CLI Interfaces

#### context-manager (Enhanced)
```bash
# Existing
context-manager location
  → Shows git root and current directory

# New subcommands
context-manager hierarchy <task-path>
  → Resolves task path to full directory (e.g., "40" → ".../40-bugfix-.../")
  → Outputs: Task number, type, full path, format version

context-manager inheritance <task-path>
  → Loads parent context structural maps for subtasks
  → Outputs: Parent file paths, headers, line ranges, status markers
  → Error: "No parent tasks found" for top-level tasks
  → Version routing: Routes to -v2.0 or -v2.1 based on task format

context-manager version <task-dir> <workflow-file>
  → COMBINES format-detector + template-version-parser functionality
  → Detects workflow file format version (v2.0 vs v2.1) based on file naming
  → Parses "Template Version:" header from file
  → Outputs: File name, format version, template version, CIG software version
  → Warnings: Version discrepancies, upgrade recommendations
```

#### workflow-manager (New)
```bash
workflow-manager status [task-path]
  → Aggregates task completion status across hierarchy
  → Outputs: Task tree with progress percentages
  → Optional: Specify task path for subtree status
  → Version routing: Routes to -v2.0 or -v2.1 based on task format
  → Reason: Workflow file names differ (a-plan.md vs a-task-plan.md)

workflow-manager control --current-step=<step> --task-path=<path>
  → Determines next workflow action based on current step and state
  → Outputs: Recommended next step, rationale, alternative paths
  → Used by workflow commands to suggest next actions
  → Version routing: Routes to -v2.0 or -v2.1 based on task format
  → Reason: Next-step logic differs between v2.0 (8 phases) and v2.1 (10 phases)
```

#### task-workflow (New)
```bash
task-workflow create --task-type=<type> --destination=<path> --task-num=<num> --description=<desc>
  → Creates task workflow step files from templates
  → ALWAYS uses v2.1 format (latest) - no version routing
  → Creates destination directory if needed
  → Substitutes template variables ({{description}}, {{taskId}}, etc.)
  → Sets file permissions (0600 for workflow files)
  → Outputs: List of files created, total count
  → Semantic naming: "create task workflow" vs "copy templates"
```

### Module Implementation Pattern

All modules follow this pattern (established in Task 39):

```perl
#!/usr/bin/env perl
use strict;
use warnings;

# Module-specific logic here (copied from existing helper script)
# Preserve all existing functionality
# No refactoring of module internals - structural migration only

exit 0;
```

### Error Handling

**Trampoline Errors** (All 3 Trampolines):
- Missing subcommand: `Usage: <trampoline> {subcommand1|subcommand2|...}`
- Unknown subcommand: `Unknown subcommand: <name>`
- Exec failure: `Failed to exec: <error>`

**Module Errors** (Preserve Existing):
- Each module preserves its existing error messages
- No changes to error handling logic
- Examples:
  - hierarchy: "Error: Task directory not found for task path: X"
  - inheritance: "Error: No parent tasks found (this is a top-level task)"
  - format: "Warning: Version Discrepancies..."

## Constraints

### Technical Constraints
1. **Pattern Adherence**: Must follow Task 39's exact trampoline pattern
   - Perl with hash table dispatch
   - No file extensions
   - Executable permissions (u+rx minimum 0500)
   - Proper shebang: `#!/usr/bin/env perl`

2. **Module Preservation**: Cannot refactor module internals
   - Copy existing logic exactly (structural migration only)
   - Preserve all error messages and output formats
   - Maintain version-specific routing where it exists
   - No behavioral changes

3. **Backward Compatibility**: Must not break Tasks 1-39
   - New trampoline calls must produce identical output to old script calls
   - Keep old scripts until migration validated
   - Test against representative v2.0 and v2.1 tasks

4. **Permission Model**: Zero permission prompts required
   - Trampoline invocation is only permission boundary
   - Modules must not trigger additional prompts
   - Test permission behavior after each trampoline creation

### Architectural Boundaries
1. **Scope**: Only migrate 6 specific helper scripts
   - hierarchy-resolver, context-inheritance, format-detector
   - status-aggregator, workflow-control
   - template-version-parser, template-copier
   - Do NOT migrate: cig-* scripts, task-stack, task-context-inference (different purposes)

2. **Directory Structure**: Follow established pattern
   - Trampolines: `.cig/scripts/command-helpers/<name>`
   - Modules: `.cig/scripts/command-helpers/<name>.d/<subcommand>`
   - No nested subdirectories

3. **CIG Commands**: Update all 17 command files consistently
   - cig-config, cig-design-plan, cig-extract, cig-implementation-exec, cig-implementation-plan
   - cig-init, cig-maintenance, cig-new-task, cig-requirements-plan, cig-retrospective
   - cig-rollout, cig-security-check, cig-status, cig-subtask
   - cig-task-plan, cig-testing-exec, cig-testing-plan

### Security Considerations
1. **Script Integrity**: Maintain SHA256 verification
   - Update `.cig/security/script-hashes.json` for new/modified scripts
   - Remove hashes for deleted old scripts after migration validated

2. **Permissions**: Minimum 0500 (u+rx) for all scripts
   - Owner can read and execute
   - No write permissions for security
   - No permissions for group or others

3. **Input Validation**: Preserve existing validation
   - Modules inherit validation from original scripts
   - No new attack vectors introduced
   - Trampoline dispatch uses hash lookup (not eval)

## Migration Strategy

### Phase 1: Context-Manager Expansion
1. Create 3 new modules in context-manager.d/
2. Update context-manager dispatch hash (add 3 entries)
3. Test each subcommand independently
4. Update CIG commands that call hierarchy-resolver, context-inheritance, format-detector

### Phase 2: Workflow-Manager Creation
1. Create workflow-manager trampoline (copy context-manager pattern)
2. Create workflow-manager.d/ directory
3. Create 2 modules: status, control
4. Test each subcommand independently
5. Update CIG commands that call status-aggregator, workflow-control

### Phase 3: Task-Workflow Creation
1. Create task-workflow trampoline (copy context-manager pattern)
2. Create task-workflow.d/ directory
3. Create 1 module: create (always v2.1, no version routing)
4. Test subcommand independently
5. Update CIG commands that call template-copier

### Phase 4: Frontmatter Simplification
1. Review all 17 CIG command frontmatter sections
2. Consolidate to 3 patterns: context-manager:*, workflow-manager:*, task-workflow:*
3. Remove obsolete direct script permission patterns

### Phase 5: Validation & Cleanup
1. Execute comprehensive test suite (functional + non-functional)
2. Verify zero permission prompts across all commands
3. Test backward compatibility with existing tasks
4. Remove old standalone scripts (keep backups)
5. Update security hashes

## Validation
- [ ] Trampoline pattern follows Task 39 exactly (Perl, hash dispatch, no extensions)
- [ ] All 3 trampolines created with proper module organization (context-manager, workflow-manager, task-workflow)
- [ ] All 7 modules (4 context, 2 workflow, 1 task-workflow) preserve original script logic
- [ ] Version routing preserved for 3 modules (inheritance, status, control) that read/write version-specific workflow file contents
- [ ] No version routing for 3 modules (hierarchy, version, create) that are version-agnostic or always-latest
- [ ] CIG command updates maintain identical behavior to old calls
- [ ] Zero permission prompts verified through testing
- [ ] Backward compatibility validated (Tasks 1-39 still work)
- [ ] Frontmatter consolidated to 3 permission patterns (context-manager:*, workflow-manager:*, task-workflow:*)
- [ ] Semantic naming validated (task-workflow create vs template-manager copy)
- [ ] Design review completed and approved

## Status
**Status**: Finished
**Completion**: Design successfully executed - all architectural decisions implemented
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Reference: Complete Call Mapping

### Old Script Calls → New Trampoline Calls

| Old Call | New Call | Trampoline | Module | Version Routing |
|----------|----------|------------|--------|-----------------|
| `hierarchy-resolver <task-path>` | `context-manager hierarchy <task-path>` | context-manager | hierarchy | No |
| `context-inheritance <task-path>` | `context-manager inheritance <task-path>` | context-manager | inheritance | Yes (v2.0/v2.1) |
| `format-detector <dir> <file>` | `context-manager version <dir> <file>` | context-manager | version | No |
| `template-version-parser <dir> <file>` | `context-manager version <dir> <file>` | context-manager | version | No (COMBINED) |
| `status-aggregator [task-path]` | `workflow-manager status [task-path]` | workflow-manager | status | Yes (v2.0/v2.1) |
| `workflow-control --args` | `workflow-manager control --args` | workflow-manager | control | Yes (v2.0/v2.1) |
| `template-copier --args` | `task-workflow create --args` | task-workflow | create | No (always v2.1) |

### Permission Pattern Consolidation

**Before** (7+ patterns):
```yaml
Bash(.cig/scripts/command-helpers/hierarchy-resolver:*)
Bash(.cig/scripts/command-helpers/context-inheritance:*)
Bash(.cig/scripts/command-helpers/format-detector:*)
Bash(.cig/scripts/command-helpers/template-version-parser:*)
Bash(.cig/scripts/command-helpers/status-aggregator:*)
Bash(.cig/scripts/command-helpers/workflow-control:*)
Bash(.cig/scripts/command-helpers/template-copier:*)
```

**After** (3 patterns):
```yaml
Bash(.cig/scripts/command-helpers/context-manager:*)
Bash(.cig/scripts/command-helpers/workflow-manager:*)
Bash(.cig/scripts/command-helpers/task-workflow:*)
```

Or simplified to single wildcard (already present in most CIG commands):
```yaml
Bash(.cig/scripts/command-helpers/*:*)
```

### Version Routing Strategy

**Modules WITH version routing** (read/write version-specific workflow file contents):
- `context-manager inheritance` - Routes to -v2.0 or -v2.1
- `workflow-manager status` - Routes to -v2.0 or -v2.1
- `workflow-manager control` - Routes to -v2.0 or -v2.1

**Modules WITHOUT version routing** (version-agnostic or always-latest):
- `context-manager location` - Version-agnostic (git operations)
- `context-manager hierarchy` - Version-agnostic (directory resolution)
- `context-manager version` - Version-agnostic (detects version, doesn't depend on it)
- `task-workflow create` - Always v2.1 (creates latest format only)

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
