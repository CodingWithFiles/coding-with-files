# Hierarchical Workflow System with Dynamic Step Transitions - Implementation

## Task Reference
- **Task ID**: internal-3
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/hierarchical-workflow-system

## Goal
Implement a hierarchical task management system that supports infinite task nesting with structured workflow steps and dynamic state transitions.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Primary Changes

**Central Template Pool** (`.cig/templates/pool/`) - Create 8 lettered workflow templates:
- `a-plan.md.template` - Planning workflow step with goals, milestones, risks
- `b-requirements.md.template` - Requirements with FR/NFR, acceptance criteria
- `c-design.md.template` - Architecture decisions, component design, API contracts
- `d-implementation.md.template` - Implementation steps, file changes, validation
- `e-testing.md.template` - Test strategy, test cases, validation criteria
- `f-rollout.md.template` - Deployment strategy, rollback plans, monitoring
- `g-maintenance.md.template` - Ongoing maintenance, incident response, updates
- `h-retrospective.md.template` - Post-completion analysis, lessons learned, variance tracking

**Symlink Structure** (`.cig/templates/<type>/`) - Create symlinks from task type directories to pool:
- `.cig/templates/feature/` - All 8 symlinks (a-h)
- `.cig/templates/bugfix/` - 5 symlinks (a, c, d, e, h) - Skip requirements and rollout
- `.cig/templates/hotfix/` - 5 symlinks (a, d, e, f, h) - Emergency-focused subset
- `.cig/templates/chore/` - 4 symlinks (a, d, e, h) - Non-user-facing tasks

**Helper Scripts** (`.cig/scripts/command-helpers/`) - Create 5 automation scripts:
- `hierarchy-resolver.sh` - Resolve task paths (e.g., "1.1") to full directory paths with JSON output
- `format-detector.sh` - Detect template version, compare against expected, suggest upgrades
- `status-aggregator.sh` - Calculate task progress from status markers, output markdown tree
- `template-version-parser.sh` - Parse Template Version field from workflow files
- `context-inheritance.pl` - Extract parent task context with headers, line ranges, and status markers (Perl-based for text processing)

**Workflow Commands** (`.claude/commands/`) - Create 8 workflow step commands:
- `cig-plan.md` - Guide user through planning phase (a-plan.md)
- `cig-requirements.md` - Guide user through requirements (b-requirements.md)
- `cig-design.md` - Guide user through design (c-design.md)
- `cig-implementation.md` - Guide user through implementation (d-implementation.md)
- `cig-testing.md` - Guide user through testing (e-testing.md)
- `cig-rollout.md` - Guide user through rollout (f-rollout.md)
- `cig-maintenance.md` - Guide user through maintenance (g-maintenance.md)
- `cig-retrospective.md` - Guide user through retrospective (h-retrospective.md) - update existing

**Core Commands** (`.claude/commands/`) - Update existing commands:
- `cig-new-task.md` - **Breaking change**: New signature `<num> <type> "description"`, symlink-based template copying, Template Version 2.0
- `cig-subtask.md` - Updated signature, progressive disclosure, context inheritance from parent
- `cig-status.md` - Integrate helper scripts, visual tree formatting, progress indicators
- `cig-extract.md` - **Breaking change**: Task-based paths, LLM-in-the-loop error handling
- `cig-security-check.md` - Add helper scripts to verification list

**Workflow Documentation** (`.cig/docs/workflow/`) - Create LLM-friendly guides:
- `workflow-overview.md` - System overview, decomposition principle, dynamic transitions (~200-400 words)
- `workflow-steps.md` - Detailed guide for each step with focus/avoid (~800-2400 words total)
- `decomposition-guide.md` - When/how to create subtasks (~200-400 words)

### Supporting Changes

**Configuration Updates**:
- `cig-project.json` - Verify compatibility with new directory structure
- `.cig/security/script-hashes.json` - Add SHA256 hashes for 5 new helper scripts

**Files to Remove** (after migration):
- `.cig/templates/feature/design.md.template` → replaced by pool/c-design.md.template
- `.cig/templates/feature/maintenance.md.template` → replaced by pool/g-maintenance.md.template
- `.cig/templates/feature/plan.md.template` → replaced by pool/a-plan.md.template
- `.cig/templates/feature/requirements.md.template` → replaced by pool/b-requirements.md.template
- `.cig/templates/feature/rollout.md.template` → replaced by pool/f-rollout.md.template
- `.cig/templates/feature/testing.md.template` → replaced by pool/e-testing.md.template
- Similar old templates in bugfix/, hotfix/, chore/ directories

**Repository Documentation**:
- `README.md` - Document new features and hierarchical workflow system
- `COMMANDS.md` - Document 8 new workflow commands and breaking changes
- `CLAUDE.md` - Update with workflow system overview

## Implementation Steps

### Step 1: Create Template Pool
- [ ] Create directory `.cig/templates/pool/`
- [ ] Create `a-plan.md.template` with Template Version 2.0, status markers, workflow guidance
- [ ] Create `b-requirements.md.template` with FR/NFR structure, acceptance criteria
- [ ] Create `c-design.md.template` with architecture sections, API contracts
- [ ] Create `d-implementation.md.template` with implementation steps, validation
- [ ] Create `e-testing.md.template` with test strategy, test cases
- [ ] Create `f-rollout.md.template` with deployment plan, rollback procedures
- [ ] Create `g-maintenance.md.template` with monitoring, incident response
- [ ] Create `h-retrospective.md.template` with variance analysis, lessons learned
- [ ] Verify all templates include Task Reference with metadata (ID, URL, Parent, Branch, Template Version)
- [ ] Verify all templates include status marker sections (Backlog, To-Do, In Progress, Implemented, Testing, Finished)

### Step 2: Create Symlink Structure
- [ ] Create symlinks in `.cig/templates/feature/` pointing to all 8 pool templates
- [ ] Create symlinks in `.cig/templates/bugfix/` for a, c, d, e, h (skip b, f, g)
- [ ] Create symlinks in `.cig/templates/hotfix/` for a, d, e, f, h (skip b, c, g)
- [ ] Create symlinks in `.cig/templates/chore/` for a, d, e, h (skip b, c, f, g)
- [ ] Verify symlinks are readable and resolve to correct pool templates
- [ ] Test template copying via symlink traversal

### Step 3: Implement Helper Scripts
- [ ] Create `.cig/scripts/command-helpers/hierarchy-resolver.sh`
  - Task path parsing (handle "1", "1.1", "1.1.1", "3/3.2", etc.)
  - Directory resolution in `implementation-guide/`
  - Support `--format=json` flag for JSON output (default: markdown)
  - Markdown output: Human/LLM-readable summary of task resolution
  - JSON output: Structured data with fields: full_path, format, task_num, task_type, task_slug, parent_path, depth
  - Error handling, self-documenting header, permissions 0500
- [ ] Create `.cig/scripts/command-helpers/format-detector.sh`
  - Input: `<task-directory> <workflow-file>` (both parameters required)
  - Template Version parsing pattern: `grep "^\- \*\*Template Version\*\*:"`
  - Embed expected version (2.0) in script itself
  - Embed CIG software version in script for comparison
  - Compare workflow file version against CIG software version expectations
  - Detect missing required fields for current version
  - Display discrepancies in workflow file headers
  - Open-ended upgrade question output for LLM to present to user
  - Support `--format=json` flag for JSON output (default: markdown)
  - Markdown output: Version comparison report with upgrade options
  - JSON output: Programmatically parseable version metadata
  - Error handling, permissions 0500
- [ ] Create `.cig/scripts/command-helpers/status-aggregator.sh`
  - Status marker parsing from workflow files using patterns:
    - Pattern 1: `## Status: <status-type>` (header format)
    - Pattern 2: `**Status**: <status-type>` (bold format)
    - Case-insensitive matching for robustness
  - Status-to-percentage mapping (Backlog=0%, To-Do=0%, In Progress=25%, Implemented=50%, Testing=75%, Finished=100%)
  - Progress formula: `MAX(IF(MAX(all) >= 25%) THEN 25% ELSE 0%, MIN(all status))`
  - Support `--format=json` flag for JSON output (default: markdown)
  - Markdown output: Tree with progress percentages and status indicators
  - JSON output: Hierarchical structure with progress data for programmatic use
  - Error handling, permissions 0500
- [ ] Create `.cig/scripts/command-helpers/template-version-parser.sh`
  - Input: `<workflow-file-path>`
  - Version field parsing pattern: `grep "^\- \*\*Template Version\*\*:"`
  - Default to version "1.0" if field is missing (backward compatibility)
  - Support `--format=json` flag for JSON output (default: markdown)
  - Markdown output: Version number (e.g., "2.0" or "1.0")
  - JSON output: Structured version metadata
  - Error handling, permissions 0500
- [ ] Create `.cig/scripts/command-helpers/context-inheritance.pl`
  - Perl-based script for efficient text processing
  - Recursive upward search from task path to project root
  - Find parent task directories (pattern: `<num>-<type>-<slug>/`)
  - For each parent, find workflow files: a-plan.md, b-requirements.md, c-design.md, d-implementation.md (old format: plan.md, requirements.md, design.md, implementation.md)
  - Extract headers with `grep -n '^#+ '` to get structure and line numbers
  - Calculate section boundaries (start = header line, end = line before next same/higher level header or EOF)
  - Parse status markers from each file (patterns: `## Status: <status>` or `**Status**: <status>`)
  - Support `--format=json` flag for JSON output (default: markdown)
  - Markdown output: Structural map with file paths, status markers, section headers, line ranges (Lstart-end), Read tool parameters (offset, limit)
  - JSON output: Programmatically parseable structure for automation
  - Permissions 0500
- [ ] Test all helper scripts with unit tests (valid/invalid inputs, edge cases)
- [ ] Calculate SHA256 hashes for all scripts
- [ ] Update `.cig/security/script-hashes.json` with new hashes

### Step 4: Create Workflow Commands
- [ ] Create `/cig-plan.md` with complete command structure:
  - Frontmatter with `argument-hint: <task-path>`
  - Step 1: Resolve task directory using hierarchy-resolver.sh
  - Step 2: Load parent context structural map via context-inheritance.pl
  - Step 3: Present context summary with navigable links and status markers
  - Step 4: LLM decides which parent sections to read in detail using Read tool
  - Step 5: Reference workflow documentation: `.cig/docs/workflow/workflow-steps.md#planning`
  - Step 6: Execute planning workflow with focus/avoid guidelines
  - Step 7: Check universal decomposition signals (5 "too big" signals: Time >1 week, People >2, Complexity 3+ concerns, High risk, Independence)
  - Step 8: Suggest next steps with reasoning (dynamic workflow transitions)
- [ ] Create `/cig-requirements.md` with same 8-step structure, focus on FR/NFR, avoid implementation
- [ ] Create `/cig-design.md` with same 8-step structure, focus on architecture, avoid code details
- [ ] Create `/cig-implementation.md` with same 8-step structure, focus on files/steps, avoid design rationale
- [ ] Create `/cig-testing.md` with same 8-step structure, focus on test strategy, avoid implementation
- [ ] Create `/cig-rollout.md` with same 8-step structure, focus on deployment, avoid tests
- [ ] Create `/cig-maintenance.md` with same 8-step structure, focus on monitoring, avoid initial implementation
- [ ] Update `/cig-retrospective.md` for new structure with h-retrospective.md
- [ ] Implement next-step decision logic in all commands:
  - Analyze current step outcome
  - Suggest primary next step based on results
  - Provide alternative paths with reasoning (e.g., if design fails validation → return to requirements)
- [ ] Implement decomposition signal checking in all commands:
  - Time signal: Estimate >1 week for step or >1 month for subtask → suggest decomposition
  - People signal: >2 people needed for different parts → suggest decomposition
  - Complexity signal: 3+ distinct concerns identified → suggest decomposition
  - Risk signal: High risk component that needs isolation → suggest decomposition
  - Independence signal: Parts can be worked separately → suggest decomposition
- [ ] Verify all commands include argument-hint in frontmatter
- [ ] Verify all commands reference `.cig/docs/workflow/workflow-steps.md` (progressive disclosure)
- [ ] Test each command shows correct guidance and opens correct workflow file

### Step 5: Update Core Commands
- [ ] Update `/cig-new-task` with breaking change warning, new signature `<num> <type> "description"`
  - Directory creation: `<num>-<type>-<slug>/`
  - Slug generation algorithm:
    - Convert description to lowercase
    - Replace spaces with hyphens
    - Remove special characters (keep only alphanumeric and hyphens)
    - Truncate to 50 characters maximum
    - Example: "Add User Authentication" → "add-user-authentication"
  - Symlink-based template copying (copy files that have symlinks in task type directory)
  - Add Template Version 2.0 to task reference sections
  - Add workflow file content guidance and doc references
  - Support decimal numbering (1, 1.1, 1.1.1)
- [ ] Update `/cig-subtask` with new signature `<parent-path> <num> <type> "description"` (matches FR3.2)
  - Resolve parent directory using hierarchy-resolver.sh
  - Next subtask number calculation (1 → 1.1, 1.1 → 1.1.1, 1.1.1 → 1.1.1.1)
  - Context inheritance from parent via context-inheritance.pl (not manual reading)
  - Call context-inheritance.pl to get parent context structural map
  - LLM uses structural map to understand parent context
  - Progressive disclosure (reference /cig-new-task docs)
- [ ] Update `/cig-status` to integrate helper scripts
  - Call hierarchy-resolver.sh for path resolution
  - Call status-aggregator.sh for progress calculation
  - Visual tree formatting with status indicators (✓, ⚙️, ○)
  - Support no-path (all tasks) and with-path (specific task + descendants) modes
- [ ] Update `/cig-extract` with breaking change warning, new signature `<task-path> <section-name>`
  - Integrate hierarchy-resolver.sh and format-detector.sh
  - Section name to file mapping (case-insensitive):
    - "goal" → plan.md (old) / a-plan.md (new)
    - "requirements" → requirements.md (old) / b-requirements.md (new)
    - "design" → design.md (old) / c-design.md (new)
    - "implementation" → implementation.md (old) / d-implementation.md (new)
    - "testing" → testing.md (old) / e-testing.md (new)
    - "rollout" → rollout.md (old) / f-rollout.md (new)
    - "maintenance" → maintenance.md (old) / g-maintenance.md (new)
    - "retrospective" → (none - old) / h-retrospective.md (new)
  - LLM-in-the-loop error handling for corrupted files
  - Backward compatibility with full file paths
- [ ] Update `/cig-security-check` to verify helper scripts
  - Add 5 helper scripts to verification list (hierarchy-resolver.sh, format-detector.sh, status-aggregator.sh, template-version-parser.sh, context-inheritance.pl)
  - Verify 0500 permissions and SHA256 hashes

### Step 6: Create Workflow Documentation
- [ ] Create `.cig/docs/workflow/` directory
- [ ] Write `workflow-overview.md` (200-400 words)
  - System overview, universal decomposition principle
  - Hierarchical structure benefits, dynamic workflow transitions
- [ ] Write `workflow-steps.md` (800-2400 words, 8 sections)
  - Each step: purpose, focus/avoid, key questions, typical structure, transition triggers
- [ ] Write `decomposition-guide.md` (200-400 words)
  - When to create subtasks, signals task is too large
  - Decimal numbering system, context inheritance
- [ ] Review all docs for clarity, conciseness, LLM-friendliness
- [ ] Test that LLM can parse and use documentation

### Step 7: Integration Testing
- [ ] **Functional Integration Tests**:
  - Create test task with `/cig-new-task 4 feature "test hierarchical workflow"`
  - Verify directory structure: `4-feature-test-hierarchical-workflow/`
  - Verify all 8 templates copied (feature task type)
  - Verify Template Version 2.0 in all workflow files
  - Create subtask with `/cig-subtask 4 <num> chore "setup"`
  - Verify subtask directory: `4.1-chore-setup/`
  - Verify only 4 templates copied (chore task type)
  - Verify context inheritance from parent task
  - Execute all 8 workflow commands on test tasks
  - Test `/cig-status` shows correct progress and visual tree
  - Test `/cig-extract` with task-based paths
  - Test backward compatibility with old format tasks
  - Verify all helper scripts work in integration
  - Run `/cig-security-check` to verify all scripts pass
- [ ] **NFR1: Performance Testing**:
  - Create 100+ test tasks in hierarchical structure
  - Measure `/cig-status` rendering time (requirement: <2 seconds for 100 tasks)
  - Measure context-inheritance.pl execution time (requirement: <1 second)
  - Measure overall command execution time (requirement: feels instantaneous)
  - Verify no significant performance regression from old system
- [ ] **NFR2: Usability Testing**:
  - Test error messages are clear and actionable
  - Verify examples exist in all command documentation
  - Test command naming is intuitive
  - Verify consistent patterns across all commands
- [ ] **NFR3: Maintainability Testing**:
  - Verify helper scripts have self-documenting names
  - Verify comments explain complex logic
  - Test modular design allows easy updates
  - Verify shared helper scripts reduce duplication
- [ ] **NFR4: Security Testing**:
  - Verify all scripts have 0500 permissions (u+rx only)
  - Verify SHA256 verification works for all helper scripts
  - Test that modified scripts are detected by security check
  - Verify no execution of untrusted code
  - Test git-based version tracking works
- [ ] **NFR5: Reliability Testing**:
  - Test graceful handling of missing files
  - Test validation before destructive operations
  - Verify rollback capability exists for migrations
  - Test no data loss during format transitions

### Step 8: Documentation and Migration
- [ ] Update `README.md` with hierarchical workflow system features
- [ ] Update `COMMANDS.md` with 8 new commands and breaking changes
- [ ] Update `CLAUDE.md` with workflow system overview
- [ ] Create migration guide (reference subtask 3.1 for actual migration)
- [ ] Document breaking changes clearly (cig-new-task, cig-extract signatures)
- [ ] Remove old templates from task type directories (after migration complete)
- [ ] Final validation: all acceptance criteria met

## Code Changes

### Before (Current Template Structure)
```
.cig/templates/
├── feature/
│   ├── design.md.template
│   ├── maintenance.md.template
│   ├── plan.md.template
│   ├── requirements.md.template
│   ├── rollout.md.template
│   └── testing.md.template
├── bugfix/
│   └── implementation.md.template
├── hotfix/
│   └── implementation.md.template
└── chore/
    └── implementation.md.template
```

Current commands: `/cig-new-task <task-type> [task-id] <description>`

No helper scripts for automation.

### After (New Hierarchical Workflow Structure)
```
.cig/templates/
├── pool/                          # Central template pool (DRY)
│   ├── a-plan.md.template
│   ├── b-requirements.md.template
│   ├── c-design.md.template
│   ├── d-implementation.md.template
│   ├── e-testing.md.template
│   ├── f-rollout.md.template
│   ├── g-maintenance.md.template
│   └── h-retrospective.md.template
├── feature/
│   ├── a-plan.md.template → ../pool/a-plan.md.template
│   ├── b-requirements.md.template → ../pool/b-requirements.md.template
│   └── ... (all 8 symlinks)
├── bugfix/
│   ├── a-plan.md.template → ../pool/a-plan.md.template
│   └── ... (5 symlinks: a, c, d, e, h)
└── ... (similar for hotfix, chore)

.cig/scripts/command-helpers/
├── hierarchy-resolver.sh
├── format-detector.sh
├── status-aggregator.sh
├── template-version-parser.sh
└── context-inheritance.pl

.cig/docs/workflow/
├── workflow-overview.md
├── workflow-steps.md
└── decomposition-guide.md
```

New commands: `/cig-new-task <num> <type> "description"` (breaking change)

8 new workflow commands: `/cig-plan`, `/cig-requirements`, `/cig-design`, `/cig-implementation`, `/cig-testing`, `/cig-rollout`, `/cig-maintenance`, `/cig-retrospective`

Helper scripts automate deterministic tasks, LLM provides intelligence.

## Test Coverage

### Regression Tests
- Test that old format tasks (v1.0) continue to work with updated commands
- Test that `/cig-status` works with mixed old/new task hierarchies
- Test that `/cig-extract` works with both old format (plan.md) and new format (a-plan.md)
- Test format-detector.sh correctly identifies v1.0 vs v2.0 templates
- Test backward compatibility mode in /cig-extract (full file paths still work during migration)
- Verify no existing functionality is broken by new changes

### Integration Tests
- **Task Creation Flow**: Create parent task (1), create subtask (1.1), verify directory structure, verify template copying based on symlinks, verify Template Version 2.0
- **Workflow Command Flow**: Execute all 8 workflow commands on test task, verify correct files opened, verify focus/avoid guidance displayed, update status markers, verify `/cig-status` shows progress
- **Extract Command Flow**: Test with old format task (maps to plan.md), test with new format task (maps to a-plan.md), test with corrupted file (verify LLM error handling)
- **Status Command Flow**: Create 5-level hierarchy (1 → 1.1 → 1.1.1 → 1.1.1.1 → 1.1.1.1.1), set different statuses, run `/cig-status` with and without path, verify progress percentages, verify visual indicators
- **Helper Script Integration**: Test hierarchy-resolver.sh resolves paths with JSON output, test format-detector.sh suggests upgrades, test status-aggregator.sh calculates progress correctly, test context-inheritance.pl extracts parent context with headers/line ranges/status markers, test all scripts have 0500 permissions
- **Context Inheritance Flow**: Create 3-level hierarchy with completed parent tasks, run context-inheritance.pl on deepest task, verify output includes all ancestors, verify file paths and line ranges are correct, verify status markers are extracted, verify LLM can use Read tool with provided offset/limit parameters
- **Security Validation**: Run `/cig-security-check`, verify all helper scripts pass SHA256 verification, test that modified scripts are detected

### Acceptance Testing
- **AC1.1**: Create tasks 5 levels deep, verify decimal numbering system works
- **AC2.1**: Create feature/bugfix/hotfix/chore tasks, verify correct number of templates created
- **AC3.1-3.7**: Verify central pool exists, verify symlinks in task type directories, test template propagation
- **AC4.1-4.8**: Test all 8 workflow commands, verify argument-hints, verify focus/avoid guidance
- **AC8.1-8.9**: Test /cig-extract with task-based paths, test backward compatibility, test LLM error handling
- **AC11.1-11.5**: Review focus/avoid guidance in all commands, verify examples helpful
- **AC12.1-12.3**: Verify commands reference docs (no duplication), test progressive disclosure
- **AC13.1-13.9**: Test all helper scripts, verify permissions, verify SHA256 verification
- **AC14.1-14.4**: Review workflow docs for clarity and conciseness, verify LLM can parse

## Validation Criteria
- [ ] All 8 workflow templates created in central pool with Template Version 2.0
- [ ] Symlink structure created correctly for all 4 task types
- [ ] All 5 helper scripts implemented with 0500 permissions and SHA256 verification
- [ ] All 8 workflow commands created with argument-hints and focus/avoid guidance
- [ ] Core commands updated: /cig-new-task, /cig-subtask, /cig-status, /cig-extract, /cig-security-check
- [ ] Workflow documentation created (3 files, concise and LLM-friendly)
- [ ] End-to-end test passes: create task, create subtask, execute workflow commands, check status
- [ ] Backward compatibility verified: old format tasks work with updated commands
- [ ] Breaking changes documented clearly in README, COMMANDS.md
- [ ] Security check passes for all helper scripts
- [ ] Migration path documented (subtask 3.1)
- [ ] All acceptance criteria from requirements.md validated

## Current Status
**Status**: Not Started
**Next Action**: Begin Step 1 - Create Template Pool
**Blockers**: None identified

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
