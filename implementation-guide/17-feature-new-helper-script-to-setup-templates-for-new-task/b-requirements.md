# new-helper-script-to-setup-templates-for-new-task - Requirements

## Task Reference
- **Task ID**: internal-17
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/17-new-helper-script-to-setup-templates-for-new-task
- **Template Version**: 2.0

## Goal
Define functional and non-functional specifications for template-copier.pl helper script that copies and populates CIG template files for new tasks.

## Functional Requirements

### FR1: Template Discovery and Copying
**Requirement**: Script must discover and copy all templates for a given task type

**Acceptance Criteria**:
- List all symlinks in `.cig/templates/{task-type}/` directory
- Follow each symlink to pool source file (`.cig/templates/pool/`)
- Copy pool file content to destination directory
- Remove `.template` extension (e.g., `a-plan.md.template` → `a-plan.md`)
- Set file permissions to 0600 (read/write owner only)
- Handle all 5 task types with correct file counts:
  - feature: 8 files (a-h)
  - bugfix: 5 files (a, c, d, e, h)
  - hotfix: 5 files (a, d, e, f, h)
  - chore: 4 files (a, d, e, h)
  - discovery: 6 files (a, b, c, d, e, h)

### FR2: Template Variable Substitution
**Requirement**: Script must substitute all template variables with actual values

**Template Variables**:
- `{{description}}` - Task description from --description parameter
- `{{taskId}}` - Task ID from tracking system or "internal-{num}"
- `{{taskUrl}}` - Task URL from tracking system or "N/A (internal task)"
- `{{parentTask}}` - Parent task number or "N/A"
- `{{branchName}}` - Branch name following convention from cig-project.json

**Acceptance Criteria**:
- All 5 template variables replaced in every copied file
- Branch name generated using pattern: `{task-type}/{task-num}-{slug}`
- Parent task computed using `CIG::TaskPath::get_parent()` for subtasks
- Task ID uses "internal-{num}" format for internal tasks
- Slug extracted from destination directory name (last path component)
- No `{{...}}` placeholders left in output files

### FR3: Git Repository Root Detection
**Requirement**: Script must work from any directory within git repository tree

**Acceptance Criteria**:
- Use `git rev-parse --show-toplevel` to find repo root
- Validate `.cig/templates/` exists relative to repo root
- Fall back to relative paths (., .., ../..) if git command fails
- Exit with error code 2 if templates directory not found

### FR4: Path Resolution with Hierarchy Awareness
**Requirement**: Script must use CIG::TaskPath module for path operations

**Acceptance Criteria**:
- Use `CIG::TaskPath::validate()` for task-num validation
- Use `CIG::TaskPath::get_parent()` to compute parent task
- Use `CIG::TaskPath::get_depth()` to determine nesting level
- Support decimal notation (1, 1.1, 1.1.1, etc.)

### FR5: Error Handling and Validation
**Requirement**: Script must validate inputs and handle errors gracefully

**Acceptance Criteria**:
- Validate task-type is in supported-task-types from cig-project.json
- Validate destination directory exists or create if missing
- Check template pool files exist before copying
- Detect and report broken symlinks with clear error messages
- Exit with appropriate codes:
  - 0: Success (files copied and substituted)
  - 1: Invalid arguments (bad task-type, missing param, invalid format)
  - 2: Not found (template directory missing, pool file missing)
  - 3: Permission error (can't read templates or write to destination)
- Write error messages to STDERR, output to STDOUT

### FR6: Idempotency (Upsert Behavior)
**Requirement**: Script must support re-running on existing task directories

**Acceptance Criteria**:
- If destination files already exist, overwrite them with warning message
- Warning format: "Warning: Overwriting existing template files in {destination}"
- Do NOT block execution - trust git for rollback capability
- Return success (exit 0) even when overwriting
- List which files were overwritten in output
- Track overwritten files separately from newly created files

### FR7: Output Format Options
**Requirement**: Script must support both human-readable and JSON output

**Acceptance Criteria**:
- Default: Human-readable markdown format with file list
- `--format=json` flag: JSON output with structured data
- JSON includes: destination, task_type, files_created[], files_overwritten[], warnings[], total_files
- Output goes to STDOUT, errors to STDERR
- Valid JSON parseable by jq and other tools

### User Stories
- **As a** CIG user **I want** template files automatically copied when creating a new task **so that** my coding agent doesn't need to prompt me for permission to copy and edit the template files
- **As a** developer **I want** template variables substituted automatically **so that** I don't have to manually edit Task Reference sections in every file
- **As a** developer **I want** the script to work from any directory **so that** I can run `/cig-new-task` regardless of my current working directory
- **As a** developer **I want** idempotent behavior **so that** I can re-run task creation to update templates without manual cleanup

## Non-Functional Requirements

### Performance (NFR1)
- Template copying completes in <1 second for feature type (8 files)
- No redundant file reads - read each pool template once
- Minimal memory footprint - process templates sequentially, not all in memory
- Startup time <100ms (Perl module loading)

### Usability (NFR2)
- Clear error messages with actionable guidance
  - Example: "Error: Invalid task type 'feat'. Supported types: feature, bugfix, hotfix, chore, discovery"
- Self-documenting parameter names (--task-type, --destination, --task-num, --description)
- Help text via --help flag showing usage and examples
- Consistent with other CIG helper scripts (same patterns, exit codes, output format)

### Maintainability (NFR3)
- Follow existing helper script patterns (Perl with CIG:: modules)
- Use same exit code conventions as hierarchy-resolver.pl, context-inheritance.pl, etc.
- Document parameter meanings in script header comments
- Modular functions with single responsibility:
  - Symlink discovery
  - Template reading
  - Variable substitution
  - File writing
- Self-documenting code with minimal comments needed

### Security (NFR4)
- Validate file paths to prevent directory traversal attacks
- Use CIG security model: script permissions 0500 (read/execute owner only)
- Add script hash to `.cig/security/script-hashes.json` for integrity verification
- No eval() or system() calls with unsanitized user input
- Sanitize all user-provided parameters before use in file operations

### Reliability (NFR5)
- Graceful handling of broken symlinks (error message, don't crash)
- Atomic file writes - use temp file + rename pattern to prevent partial writes
- Validate template variables are all substituted (no {{...}} left in output)
- Test coverage for all 5 task types and error conditions (12 test cases minimum)
- Deterministic behavior - same inputs always produce same outputs

## Constraints

### Technical Constraints
- Must use Perl (not bash) for CIG:: module compatibility and template substitution
- Must work from any directory within git repository tree
- Must maintain backward compatibility with existing task creation workflow
- Must follow CIG security model (0500 permissions for scripts, hash verification)
- Must not modify template pool files (read-only operations only)
- Must use existing CIG::TaskPath, CIG::WorkflowFiles modules (no reinventing)

### Behavioral Constraints
- Idempotency: warn on overwrite, don't block execution
- Trust git for safety: no complex protection mechanisms or confirmations
- Deterministic output: same inputs → same outputs (no randomness)
- Error messages to STDERR, results to STDOUT (Unix convention)

### Integration Constraints
- Must integrate with `/cig-new-task` command without breaking existing workflow
- Must be callable from `/cig-subtask` command (reusability requirement)
- Output format must match existing helper script patterns (markdown/JSON)

### Resource Constraints
- Implementation time: 0.5-1 day (per planning estimate)
- No external dependencies beyond existing CIG:: modules
- Must work with existing template pool structure (no template format changes)

## Script Interface Specification

### Command-Line Parameters

**Required**:
- `--task-type=<type>` - One of: feature, bugfix, hotfix, chore, discovery
- `--destination=<path>` - Full path to task directory (e.g., `implementation-guide/17-feature-...`)
- `--task-num=<num>` - Task number in decimal notation (e.g., "17", "1.2.3")
- `--description=<text>` - Task description for {{description}} variable

**Optional**:
- `--format=<format>` - Output format: markdown (default) or json
- `--help` - Show usage and exit

### Exit Codes
- `0` - Success (files copied and substituted)
- `1` - Invalid arguments (bad task-type, missing param, invalid task-num format)
- `2` - Not found (template directory missing, pool file missing)
- `3` - Permission error (can't read templates or write to destination)

## Acceptance Criteria

### Script Implementation
- [ ] Script created in `.cig/scripts/command-helpers/template-copier.pl` with 0500 permissions
- [ ] All 7 functional requirements (FR1-FR7) implemented and working
- [ ] All 5 non-functional requirements (NFR1-NFR5) satisfied
- [ ] Git repo root detection working from any subdirectory within repo
- [ ] All 5 template variables substituted correctly (no {{...}} in output)
- [ ] Idempotency with warning messages working (can run multiple times)
- [ ] Exit codes match specification (0, 1, 2, 3 for different error types)

### Testing
- [ ] All 12 test cases passing:
  - TC1-TC5: All 5 task types create correct number of files
  - TC6: Subtask parent computation working
  - TC7-TC9: Error handling for invalid input, missing files, permissions
  - TC10: Idempotency warning message appears
  - TC11: Working directory independence verified
  - TC12: JSON output valid and parseable

### Integration
- [ ] `/cig-new-task` command updated to use template-copier.pl
- [ ] Script hash added to `.cig/security/script-hashes.json`
- [ ] Help text (--help) includes usage examples
- [ ] Works with all existing CIG commands without breaking changes

### Documentation
- [ ] Script header comments document all parameters
- [ ] Usage examples shown in --help text
- [ ] Integration documented in cig-new-task.md (Step 5 updated)

## Status
**Status**: Finished
**Next Action**: Design phase completed
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
