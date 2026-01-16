# Add --workflow Option to status-aggregator - Requirements

## Task Reference
- **Task ID**: internal-18
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/18-add-workflow-option-to-status-aggregator
- **Template Version**: 2.0

## Goal
Define functional and non-functional specifications for enhanced status-aggregator.pl with hierarchy depth control, workflow step visibility, and flexible sorting options.

## Functional Requirements

### FR1: Help Display with Short Option Support
**Requirement**: Implement --help flag with short option -h for displaying usage information

**Acceptance Criteria**:
- `status-aggregator.pl --help` displays formatted usage information
- `status-aggregator.pl -h` displays same help output
- Help text shows all available options with descriptions
- Help text includes examples of common usage patterns
- Exit code 0 after displaying help

### FR2: Workflow Step Visibility with --workflow Flag
**Requirement**: Add --workflow (-w) flag to display individual workflow file statuses

**Acceptance Criteria**:
- Without flag: Show aggregated task percentage (current behavior)
- With `--workflow` or `-w`: Show individual workflow files (a-plan.md, b-requirements.md, etc.)
- Workflow files indented 2 spaces from parent task
- Each workflow file shows: status indicator, filename, status text, percentage
- Status and percentage aligned in tab-separated columns
- Only displays workflow files that exist for task type (feature=8, bugfix=5, etc.)

### FR3: Hierarchy Depth Control with --depth Option
**Requirement**: Add --depth=N option to control task hierarchy visibility

**Acceptance Criteria**:
- `--depth=0` (default): Show only top-level tasks (1, 2, 3, ...)
- `--depth=1`: Show top-level + one level deep (1, 1.1, 2, 2.1, ...)
- `--depth=N`: Show N levels deep from starting point
- `--depth=-1`: Show unlimited depth (full hierarchy)
- Depth calculated relative to starting point (root or specified task)
- Positional arg + depth work together: `status-aggregator.pl 18 --depth=1` shows task 18 and immediate children

### FR4: Task Sorting Options
**Requirement**: Add --sort option to control task ordering at each hierarchy level

**Acceptance Criteria**:
- `--sort=numeric` (default): Natural numeric sort (2.10 after 2.9, 3.1 after 2.999)
- `--sort=date`: Sort by creation date (min creation timestamp across workflow files in git log)
- `--sort=modified`: Sort by last modified date (max modification timestamp across workflow files in git log)
- Sorting applies to tasks at each level independently
- Workflow file order unchanged (always a-h sequence)
- Git log timestamps use Unix epoch format for comparison

### FR5: CIG::Options Integration
**Requirement**: Use CIG::Options module for consistent option parsing across CIG scripts

**Acceptance Criteria**:
- Replace manual @ARGV parsing with CIG::Options::parse()
- Support long options: --help, --workflow, --depth=N, --sort=MODE, --format=json
- Support short options: -h, -w
- Short option bundling works: -wh equivalent to --workflow --help
- Error messages match CIG::Options format with --help suggestion
- Backward compatibility: existing usage without new options unchanged

### FR6: Backward Compatibility
**Requirement**: Maintain all existing status-aggregator.pl functionality

**Acceptance Criteria**:
- Positional argument still filters to task subtree: `status-aggregator.pl 18`
- `--format=json` continues to work (JSON output mode)
- Default behavior unchanged: `status-aggregator.pl` shows top-level tasks with percentages
- Exit codes unchanged: 0 (success), 1 (invalid args), 2 (not found)
- Visual indicators changed to single-width ASCII: `*` (finished), `+` (in progress), `-` (not started)

### FR7: ASCII Status Indicators
**Requirement**: Replace emoji with single-character ASCII indicators for proper tab alignment

**Acceptance Criteria**:
- `*` indicates Finished (100% progress)
- `+` indicates In Progress (1-99% progress)
- `-` indicates Not Started (0% progress)
- All indicators are single-character width for consistent tab alignment
- Rationale: Emoji like ⚙️ are double-width and break tab column alignment

### User Stories
- **As a** CIG user **I want** `--help` support **so that** I can quickly learn available options without reading documentation
- **As a** developer **I want** `--workflow` flag **so that** I can see which specific workflow steps are complete vs. pending
- **As a** project manager **I want** `--depth` control **so that** I can view high-level progress without subtask noise
- **As a** developer **I want** `--sort=modified` **so that** I can identify recently active tasks for status updates
- **As a** team lead **I want** `--sort=date` **so that** I can review tasks in chronological order of creation

## Non-Functional Requirements

### Performance (NFR1)
- Response time: < 2 seconds for --depth=-1 on repository with 100+ tasks
- Response time: < 500ms for --depth=0 (default, top-level only)
- Git log queries optimized: single git log call per task, not per workflow file
- Memory usage: < 50MB for large repositories (efficient task tree construction)
- Sorting overhead: < 200ms additional for --sort=date or --sort=modified

### Usability (NFR2)
- Help text: Clear, scannable format matching CIG::Options standard
- Error messages: Specific and actionable (e.g., "Invalid depth value: 'abc', expected integer or -1")
- Learning curve: < 2 minutes to understand --depth and --workflow from help text
- Consistency: Tab-aligned columns for easy visual scanning
- Indentation: Clear visual hierarchy (4-space tasks, 2-space workflow steps)

### Maintainability (NFR3)
- Code clarity: Reuse existing calculate_progress() and build_tree() functions where possible
- Modularity: Separate sorting logic into dedicated function
- CIG::Options integration: Single spec definition, no manual @ARGV parsing
- Comments: Only for non-obvious algorithms (natural sort, git timestamp extraction)
- Backward compatibility: No changes to CIG::WorkflowFiles or CIG::MarkdownParser modules

### Security (NFR4)
- Input validation: CIG::Options validates all option values
- Command injection: No direct shell execution of user input
- Path traversal: Task paths already validated by hierarchy-resolver.pl pattern
- Script hash: Update .cig/security/script-hashes.json after changes

### Reliability (NFR5)
- Error handling: Graceful fallback if git log fails (use filesystem mtime)
- Missing files: Handle tasks with incomplete workflow files without crashing
- Edge cases: Empty repositories, single task, deeply nested hierarchies (10+ levels)
- Exit codes: Consistent with existing convention (0=success, 1=invalid args, 2=not found)
- Backward compatibility testing: Verify existing usage patterns unchanged

## Constraints

### Technical Constraints
- Must use Perl (existing CIG standard)
- Must use CIG::Options module (created for this task)
- Must maintain compatibility with existing CIG::WorkflowFiles and CIG::MarkdownParser
- Must work on macOS Perl 5.30.3+ (no external CPAN dependencies)
- Git log parsing must handle edge cases (no commits, shallow clones)

### Integration Constraints
- Existing /cig-status command expects same output format for non-flagged usage
- JSON output mode (--format=json) must extend to include new fields when applicable
- Must not break existing scripts or workflows that parse status-aggregator.pl output

### Resource Constraints
- Implementation time: 0.5-1 day (per planning estimate)
- No new external dependencies beyond CIG::Options
- Must work within existing helper script patterns and conventions

## Acceptance Criteria

### Implementation Criteria
- [ ] AC1: CIG::Options integrated, manual @ARGV parsing removed
- [ ] AC2: --help / -h displays formatted usage with examples
- [ ] AC3: --workflow / -w displays individual workflow file statuses with correct indentation
- [ ] AC4: --depth=N correctly limits hierarchy visibility from starting point
- [ ] AC5: --sort=numeric (default) produces natural numeric ordering
- [ ] AC6: --sort=date orders by task creation timestamp (min of workflow files)
- [ ] AC7: --sort=modified orders by task modification timestamp (max of workflow files)

### Backward Compatibility Criteria
- [ ] AC8: `status-aggregator.pl` (no args) shows top-level tasks at --depth=0
- [ ] AC9: `status-aggregator.pl 18` shows task 18 subtree at unlimited depth
- [ ] AC10: `status-aggregator.pl --format=json` produces valid JSON output
- [ ] AC11: Exit codes unchanged (0, 1, 2)
- [ ] AC12: Visual indicators changed to ASCII (* + -) for proper tab alignment

### Quality Criteria
- [ ] AC13: Performance targets met (< 2s for 100+ tasks, < 500ms for top-level)
- [ ] AC14: Script hash updated in .cig/security/script-hashes.json
- [ ] AC15: Help text matches CIG::Options standard format
- [ ] AC16: Error messages clear and actionable

## Status
**Status**: Finished
**Next Action**: Proceed to design phase
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
