# Separate Planning from Execution Phases with Explicit Execution Commands - Implementation

## Task Reference
- **Task ID**: internal-25
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/25-separate-planning-from-execution-phases-with-expli
- **Template Version**: 2.0

## Goal
Implement v2.1 workflow with sequential a-j lettering, trampoline architecture, and 10-phase workflow following the 9-checkpoint strategy defined in c-design.md.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### Checkpoint 1: Extract Core Modules (3 new files)
**Primary Changes**:
- `.cig/lib/CIG/StatusAggregator/Core.pm` - Extract status aggregation algorithm from status-aggregator.pl
- `.cig/lib/CIG/TemplateCopier/Core.pm` - Extract template copying logic from template-copier.pl
- `.cig/lib/CIG/ContextInheritance/Core.pm` - Extract context inheritance logic from context-inheritance.pl

**Supporting Changes**:
- None (Core modules created but not yet used)

### Checkpoint 2: Implement Trampoline Infrastructure (7 new files, 1 modified)
**Primary Changes**:
- `.cig/scripts/command-helpers/status-aggregator` - Convert to entry point with version detection
- `.cig/scripts/command-helpers/template-copier` - Convert to entry point with version detection
- `.cig/scripts/command-helpers/context-inheritance` - Convert to entry point with version detection
- `.cig/scripts/command-helpers/status-aggregator-v2.0` - v2.0 orchestration script
- `.cig/scripts/command-helpers/template-copier-v2.0` - v2.0 orchestration script
- `.cig/scripts/command-helpers/context-inheritance-v2.0` - v2.0 orchestration script
- `.cig/lib/CIG/WorkflowFiles/V20.pm` - Extract v2.0 file mappings from WorkflowFiles.pm

**Supporting Changes**:
- `.cig/lib/CIG/WorkflowFiles.pm` - Refactor to use V20 module

### Checkpoint 3: Deprecate v1.0 (2 modified files)
**Primary Changes**:
- `.cig/lib/CIG/WorkflowFiles.pm` - Remove V10 module support
- Entry point scripts (status-aggregator, template-copier, context-inheritance) - Add v1.0 deprecation errors

**Supporting Changes**:
- `.cig/docs/migration/v10-to-v20.md` - Add note about v1.0 deprecation (if exists)

### Checkpoint 4: Rename v2.0 Templates (8 renames, 50+ symlinks)
**Primary Changes**:
- `.cig/templates/pool/a-task-plan.md.template` - Rename from a-plan.md.template
- `.cig/templates/pool/b-requirements-plan.md.template` - Rename from b-requirements.md.template
- `.cig/templates/pool/c-design-plan.md.template` - Rename from c-design.md.template
- `.cig/templates/pool/d-implementation-plan.md.template` - Rename from d-implementation.md.template
- `.cig/templates/pool/f-testing-plan.md.template` - Rename from e-testing.md.template (re-lettered!)
- `.cig/templates/pool/h-rollout.md.template` - Rename from f-rollout.md.template (re-lettered!)
- `.cig/templates/pool/i-maintenance.md.template` - Rename from g-maintenance.md.template (re-lettered!)
- `.cig/templates/pool/j-retrospective.md.template` - Rename from h-retrospective.md.template (re-lettered!)

**Supporting Changes**:
- `.cig/templates/feature/*.md.template` - Update 10 symlinks
- `.cig/templates/bugfix/*.md.template` - Update 7 symlinks
- `.cig/templates/hotfix/*.md.template` - Update 7 symlinks
- `.cig/templates/chore/*.md.template` - Update 6 symlinks
- `.cig/templates/discovery/*.md.template` - Update 8 symlinks

### Checkpoint 5: Create v2.1 Infrastructure (5 new files)
**Primary Changes**:
- `.cig/templates/pool/e-implementation-exec.md.template` - New execution template
- `.cig/templates/pool/g-testing-exec.md.template` - New execution template
- `.cig/lib/CIG/WorkflowFiles/V21.pm` - v2.1 file mappings with 10-phase workflow
- `.cig/scripts/command-helpers/status-aggregator-v2.1` - v2.1 orchestration script
- `.cig/scripts/command-helpers/template-copier-v2.1` - v2.1 orchestration script
- `.cig/scripts/command-helpers/context-inheritance-v2.1` - v2.1 orchestration script

**Supporting Changes**:
- Update all 5 task-type symlink directories with e-implementation-exec.md.template and g-testing-exec.md.template

### Checkpoint 6: Rename Workflow Commands (5 renames with updates)
**Primary Changes**:
- `.claude/commands/cig-task-plan.md` - Rename from cig-plan.md + add ⚠️ PLANNING PHASE notice
- `.claude/commands/cig-requirements-plan.md` - Rename from cig-requirements.md + add notice
- `.claude/commands/cig-design-plan.md` - Rename from cig-design.md + add notice
- `.claude/commands/cig-implementation-plan.md` - Rename from cig-implementation.md + add notice
- `.claude/commands/cig-testing-plan.md` - Rename from cig-testing.md + add notice

**Supporting Changes**:
- None (original command files deleted after rename)

### Checkpoint 7: Add Blocker Handling (10 modified files)
**Primary Changes**:
- `.claude/commands/cig-task-plan.md` - Add "Blocker Handling" section
- `.claude/commands/cig-requirements-plan.md` - Add "Blocker Handling" section
- `.claude/commands/cig-design-plan.md` - Add "Blocker Handling" section
- `.claude/commands/cig-implementation-plan.md` - Add "Blocker Handling" section
- `.claude/commands/cig-testing-plan.md` - Add "Blocker Handling" section
- `.claude/commands/cig-rollout.md` - Add "Blocker Handling" section
- `.claude/commands/cig-maintenance.md` - Add "Blocker Handling" section
- `.claude/commands/cig-retrospective.md` - Add "Blocker Handling" section

**Supporting Changes**:
- None (blocker sections added to existing command content)

### Checkpoint 8: Create Execution Commands (2 new files)
**Primary Changes**:
- `.claude/commands/cig-implementation-exec.md` - New execution command for e-implementation-exec.md
- `.claude/commands/cig-testing-exec.md` - New execution command for g-testing-exec.md

**Supporting Changes**:
- None (new command files)

### Checkpoint 9: Finalize Documentation (2 modified files, 1 new file)
**Primary Changes**:
- `.cig/docs/workflow/workflow-steps.md` - Add 10-phase workflow, blocker-driven reversion framework
- `.cig/security/script-hashes.json` - Add hashes for 9 new scripts (3 entry points + 6 orchestration)

**Supporting Changes**:
- `COMMANDS.md` - Update command reference with renamed commands and new execution commands (if it exists)

### Summary
**Total Files Modified/Created**: ~55 files
- **New files**: 17 (3 Core modules + 1 V20 module + 1 V21 module + 6 orchestration scripts + 2 execution templates + 2 execution commands + 2 documentation)
- **Renamed files**: 13 (8 templates + 5 commands)
- **Modified files**: ~25 (1 WorkflowFiles.pm + 3 entry points + ~10 blocker handling updates + ~10 symlink directories)

## Implementation Steps

### Checkpoint 1: Extract Core Modules

- [ ] **Step 1.1**: Read existing status-aggregator.pl
  ```bash
  # Identify core aggregation logic to extract
  # Lines handling status calculation, progress computation
  ```

- [ ] **Step 1.2**: Create `.cig/lib/CIG/StatusAggregator/Core.pm`
  - Extract status aggregation algorithm
  - Make version-agnostic (accepts workflow file list as parameter)
  - Return structured status data
  - Add POD documentation

- [ ] **Step 1.3**: Read existing template-copier.pl
  ```bash
  # Identify template copying logic to extract
  # Variable substitution, symlink resolution
  ```

- [ ] **Step 1.4**: Create `.cig/lib/CIG/TemplateCopier/Core.pm`
  - Extract template copying algorithm
  - Make version-agnostic (accepts template list as parameter)
  - Handle variable substitution ({{description}}, {{taskId}}, etc.)
  - Add POD documentation

- [ ] **Step 1.5**: Read existing context-inheritance.pl
  ```bash
  # Identify context inheritance logic to extract
  # Structural map generation, parent traversal
  ```

- [ ] **Step 1.6**: Create `.cig/lib/CIG/ContextInheritance/Core.pm`
  - Extract context inheritance algorithm
  - Make version-agnostic (accepts workflow file list as parameter)
  - Generate structural maps
  - Add POD documentation

- [ ] **Step 1.7**: Validate Core modules created
  ```bash
  # Verify .pm files have valid Perl syntax
  perl -c .cig/lib/CIG/StatusAggregator/Core.pm
  perl -c .cig/lib/CIG/TemplateCopier/Core.pm
  perl -c .cig/lib/CIG/ContextInheritance/Core.pm
  ```

- [ ] **Step 1.8**: Set permissions on Core modules
  ```bash
  chmod 0644 .cig/lib/CIG/StatusAggregator/Core.pm
  chmod 0644 .cig/lib/CIG/TemplateCopier/Core.pm
  chmod 0644 .cig/lib/CIG/ContextInheritance/Core.pm
  ```

- [ ] **Step 1.9**: Commit checkpoint 1
  ```bash
  git add .cig/lib/CIG/**/Core.pm
  git commit -m "Checkpoint 1: Extract Core modules

Extract shared logic from helper scripts into reusable Core modules:
- StatusAggregator::Core: Version-agnostic status aggregation
- TemplateCopier::Core: Version-agnostic template copying
- ContextInheritance::Core: Version-agnostic context generation

Prepares for trampoline architecture. Core modules not yet used.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```

### Checkpoint 2: Implement Trampoline Infrastructure

- [ ] **Step 2.1**: Create `.cig/lib/CIG/WorkflowFiles/V20.pm`
  - Read current WorkflowFiles.pm
  - Extract v2.0 file mappings (a-plan.md through h-retrospective.md)
  - Create get_workflow_files() function
  - Add task type mappings (feature: 8 files, bugfix: 5 files, etc.)
  - Add POD documentation

- [ ] **Step 2.2**: Backup existing helper scripts
  ```bash
  cp .cig/scripts/command-helpers/status-aggregator .cig/scripts/command-helpers/status-aggregator.bak
  cp .cig/scripts/command-helpers/template-copier .cig/scripts/command-helpers/template-copier.bak
  cp .cig/scripts/command-helpers/context-inheritance .cig/scripts/command-helpers/context-inheritance.bak
  ```

- [ ] **Step 2.3**: Convert status-aggregator to entry point
  - Save current logic to status-aggregator-v2.0
  - Replace status-aggregator with trampoline logic:
    - Call format-detector to get version
    - If v2.0: exec status-aggregator-v2.0
    - If v1.0: die with deprecation error (added in checkpoint 3)
    - If unknown: die with error

- [ ] **Step 2.4**: Create status-aggregator-v2.0 orchestration script
  - Use CIG::WorkflowFiles::V20
  - Use CIG::StatusAggregator::Core
  - v2.0-specific formatting
  - Handle 8-phase workflow

- [ ] **Step 2.5**: Convert template-copier to entry point
  - Follow same pattern as status-aggregator
  - Trampoline based on requested version (new tasks default to v2.1)

- [ ] **Step 2.6**: Create template-copier-v2.0 orchestration script
  - Use CIG::WorkflowFiles::V20
  - Use CIG::TemplateCopier::Core
  - Handle 8-file workflow

- [ ] **Step 2.7**: Convert context-inheritance to entry point
  - Follow same pattern as status-aggregator
  - Trampoline based on detected version

- [ ] **Step 2.8**: Create context-inheritance-v2.0 orchestration script
  - Use CIG::WorkflowFiles::V20
  - Use CIG::ContextInheritance::Core
  - Handle 8-phase parent context

- [ ] **Step 2.9**: Set permissions on all new scripts
  ```bash
  chmod 0500 .cig/scripts/command-helpers/status-aggregator
  chmod 0500 .cig/scripts/command-helpers/status-aggregator-v2.0
  chmod 0500 .cig/scripts/command-helpers/template-copier
  chmod 0500 .cig/scripts/command-helpers/template-copier-v2.0
  chmod 0500 .cig/scripts/command-helpers/context-inheritance
  chmod 0500 .cig/scripts/command-helpers/context-inheritance-v2.0
  chmod 0644 .cig/lib/CIG/WorkflowFiles/V20.pm
  ```

- [ ] **Step 2.10**: Test trampoline on existing tasks
  ```bash
  # Test status-aggregator on Tasks 1-24 (must show correct progress)
  .cig/scripts/command-helpers/status-aggregator 1
  .cig/scripts/command-helpers/status-aggregator 24

  # Verify trampolines to v2.0 orchestration script
  ```

- [ ] **Step 2.11**: Update WorkflowFiles.pm to use V20 module
  - Refactor to delegate to V20 for v2.0 tasks
  - Keep backward compatibility layer

- [ ] **Step 2.12**: Commit checkpoint 2
  ```bash
  git add .cig/scripts/command-helpers/*-v2.0
  git add .cig/scripts/command-helpers/{status-aggregator,template-copier,context-inheritance}
  git add .cig/lib/CIG/WorkflowFiles/V20.pm
  git add .cig/lib/CIG/WorkflowFiles.pm
  git commit -m "Checkpoint 2: Implement trampoline infrastructure

Convert helper scripts to three-layer trampoline architecture:
- Entry points detect version and trampoline to orchestration scripts
- v2.0 orchestration scripts handle 8-phase workflow
- Core modules provide shared logic

Tested on Tasks 1-24, all working correctly.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```

### Checkpoint 3: Deprecate v1.0

- [ ] **Step 3.1**: Update entry point scripts to handle v1.0 deprecation
  - Add deprecation error messages in trampoline logic
  - Error: "v1.0 format deprecated. Use migration tools to upgrade to v2.0."

- [ ] **Step 3.2**: Remove V10 support from WorkflowFiles.pm
  - Delete v1.0 file mappings
  - Remove V10 module loading
  - Update documentation

- [ ] **Step 3.3**: Test v1.0 deprecation (if v1.0 tasks exist)
  ```bash
  # Run status-aggregator on v1.0 task (should show clear error)
  # Verify error message is helpful
  ```

- [ ] **Step 3.4**: Commit checkpoint 3
  ```bash
  git add .cig/scripts/command-helpers/{status-aggregator,template-copier,context-inheritance}
  git add .cig/lib/CIG/WorkflowFiles.pm
  git commit -m "Checkpoint 3: Deprecate v1.0 format

Remove v1.0 support from CIG system:
- Entry points show clear deprecation error for v1.0 tasks
- WorkflowFiles.pm no longer loads V10 module
- Migration tools preserved for reference

v1.0 tasks must be migrated to v2.0 before using CIG commands.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```

### Checkpoint 4: Rename v2.0 Templates

- [ ] **Step 4.1**: Rename planning templates (add -plan suffix)
  ```bash
  cd .cig/templates/pool
  git mv a-plan.md.template a-task-plan.md.template
  git mv b-requirements.md.template b-requirements-plan.md.template
  git mv c-design.md.template c-design-plan.md.template
  git mv d-implementation.md.template d-implementation-plan.md.template
  ```

- [ ] **Step 4.2**: Re-letter existing templates (e→f, f→h, g→i, h→j)
  ```bash
  cd .cig/templates/pool
  git mv e-testing.md.template f-testing-plan.md.template
  git mv f-rollout.md.template h-rollout.md.template
  git mv g-maintenance.md.template i-maintenance.md.template
  git mv h-retrospective.md.template j-retrospective.md.template
  ```

- [ ] **Step 4.3**: Update Template Version header in all renamed templates
  ```bash
  # Each renamed template should have:
  # - **Template Version**: 2.0
  # (NOT 2.1 yet - we're just renaming v2.0 templates)
  ```

- [ ] **Step 4.4**: Update feature task type symlinks
  ```bash
  cd .cig/templates/feature
  rm *.md.template  # Remove old symlinks
  ln -s ../pool/a-task-plan.md.template .
  ln -s ../pool/b-requirements-plan.md.template .
  ln -s ../pool/c-design-plan.md.template .
  ln -s ../pool/d-implementation-plan.md.template .
  ln -s ../pool/f-testing-plan.md.template .
  ln -s ../pool/h-rollout.md.template .
  ln -s ../pool/i-maintenance.md.template .
  ln -s ../pool/j-retrospective.md.template .
  # (No e or g yet - those are v2.1)
  ```

- [ ] **Step 4.5**: Update bugfix task type symlinks
  ```bash
  cd .cig/templates/bugfix
  rm *.md.template
  ln -s ../pool/a-task-plan.md.template .
  ln -s ../pool/c-design-plan.md.template .
  ln -s ../pool/d-implementation-plan.md.template .
  ln -s ../pool/f-testing-plan.md.template .
  ln -s ../pool/j-retrospective.md.template .
  ```

- [ ] **Step 4.6**: Update hotfix task type symlinks
  ```bash
  cd .cig/templates/hotfix
  rm *.md.template
  ln -s ../pool/a-task-plan.md.template .
  ln -s ../pool/d-implementation-plan.md.template .
  ln -s ../pool/f-testing-plan.md.template .
  ln -s ../pool/h-rollout.md.template .
  ln -s ../pool/j-retrospective.md.template .
  ```

- [ ] **Step 4.7**: Update chore task type symlinks
  ```bash
  cd .cig/templates/chore
  rm *.md.template
  ln -s ../pool/a-task-plan.md.template .
  ln -s ../pool/d-implementation-plan.md.template .
  ln -s ../pool/f-testing-plan.md.template .
  ln -s ../pool/j-retrospective.md.template .
  ```

- [ ] **Step 4.8**: Update discovery task type symlinks
  ```bash
  cd .cig/templates/discovery
  rm *.md.template
  ln -s ../pool/a-task-plan.md.template .
  ln -s ../pool/b-requirements-plan.md.template .
  ln -s ../pool/c-design-plan.md.template .
  ln -s ../pool/d-implementation-plan.md.template .
  ln -s ../pool/f-testing-plan.md.template .
  ln -s ../pool/j-retrospective.md.template .
  ```

- [ ] **Step 4.9**: Update V20 module to use renamed files
  ```bash
  # Edit .cig/lib/CIG/WorkflowFiles/V20.pm
  # Update file names: a-task-plan.md (not a-plan.md), etc.
  ```

- [ ] **Step 4.10**: Test template copying with renamed templates
  ```bash
  # Create test v2.0 task (should use renamed templates)
  # Verify all 8 files created with correct names
  ```

- [ ] **Step 4.11**: Commit checkpoint 4
  ```bash
  git add .cig/templates/pool/*.md.template
  git add .cig/templates/*/*.md.template
  git add .cig/lib/CIG/WorkflowFiles/V20.pm
  git commit -m "Checkpoint 4: Rename v2.0 templates

Rename templates for clarity and re-letter for v2.1 preparation:
- Add -plan suffix to planning templates (a-d)
- Re-letter e→f, f→h, g→i, h→j (makes room for e and g execution)
- Update all task-type symlinks
- Update V20 module with new file names

Still v2.0 format (8 files), but renamed for consistency.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```

### Checkpoint 5: Create v2.1 Infrastructure

- [ ] **Step 5.1**: Create e-implementation-exec.md.template
  - Based on design in c-design.md lines 326-374
  - Template Version: 2.1
  - Cross-references d-implementation-plan.md
  - Execution checklist, actual results sections

- [ ] **Step 5.2**: Create g-testing-exec.md.template
  - Based on design in c-design.md lines 376-430
  - Template Version: 2.1
  - Cross-references f-testing-plan.md
  - Test results table, test failures sections

- [ ] **Step 5.3**: Create `.cig/lib/CIG/WorkflowFiles/V21.pm`
  - Based on design in c-design.md lines 619-650
  - 10-phase workflow file mappings
  - Task type mappings (feature: 10 files, bugfix: 7 files, etc.)
  - get_workflow_files() function

- [ ] **Step 5.4**: Create status-aggregator-v2.1
  - Use CIG::WorkflowFiles::V21
  - Use CIG::StatusAggregator::Core
  - v2.1-specific formatting (10-phase display)

- [ ] **Step 5.5**: Create template-copier-v2.1
  - Use CIG::WorkflowFiles::V21
  - Use CIG::TemplateCopier::Core
  - Default to v2.1 for new tasks

- [ ] **Step 5.6**: Create context-inheritance-v2.1
  - Use CIG::WorkflowFiles::V21
  - Use CIG::ContextInheritance::Core
  - Handle 10-phase parent context

- [ ] **Step 5.7**: Update entry points to support v2.1
  ```perl
  # Add v2.1 branch to trampoline logic
  if ($version eq 'v2.1') {
      exec('script-name-v2.1', @ARGV);
  } elsif ($version eq 'v2.0') {
      exec('script-name-v2.0', @ARGV);
  }
  ```

- [ ] **Step 5.8**: Update format-detector to detect v2.1
  - Read "Template Version" header
  - Return 'v2.1' if Template Version: 2.1

- [ ] **Step 5.9**: Update all task-type symlinks to include e and g
  ```bash
  cd .cig/templates/feature
  ln -s ../pool/e-implementation-exec.md.template .
  ln -s ../pool/g-testing-exec.md.template .
  # Repeat for bugfix, hotfix, chore (skip discovery - no h, i)
  ```

- [ ] **Step 5.10**: Set permissions on new files
  ```bash
  chmod 0644 .cig/templates/pool/e-implementation-exec.md.template
  chmod 0644 .cig/templates/pool/g-testing-exec.md.template
  chmod 0644 .cig/lib/CIG/WorkflowFiles/V21.pm
  chmod 0500 .cig/scripts/command-helpers/status-aggregator-v2.1
  chmod 0500 .cig/scripts/command-helpers/template-copier-v2.1
  chmod 0500 .cig/scripts/command-helpers/context-inheritance-v2.1
  ```

- [ ] **Step 5.11**: Test v2.1 template copying
  ```bash
  # Create test v2.1 feature task
  # Verify all 10 files created (a-j)
  # Verify Template Version: 2.1 in headers
  ```

- [ ] **Step 5.12**: Test v2.1 status aggregation
  ```bash
  # Run status-aggregator on test v2.1 task
  # Verify 10-phase display
  # Verify correct progress calculation
  ```

- [ ] **Step 5.13**: Commit checkpoint 5
  ```bash
  git add .cig/templates/pool/{e-implementation-exec,g-testing-exec}.md.template
  git add .cig/lib/CIG/WorkflowFiles/V21.pm
  git add .cig/scripts/command-helpers/*-v2.1
  git add .cig/scripts/command-helpers/{status-aggregator,template-copier,context-inheritance}
  git add .cig/templates/*/{e-implementation-exec,g-testing-exec}.md.template
  git commit -m "Checkpoint 5: Create v2.1 infrastructure

Implement v2.1 workflow with 10-phase sequential naming:
- New execution templates (e-implementation-exec, g-testing-exec)
- WorkflowFiles::V21 module with 10-phase mappings
- v2.1 orchestration scripts for all helpers
- Updated entry points to detect and trampoline to v2.1

New tasks default to v2.1. Existing v2.0 tasks unaffected.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```

### Checkpoint 6: Rename Workflow Commands

- [ ] **Step 6.1**: Rename planning commands
  ```bash
  cd .claude/commands
  git mv cig-plan.md cig-task-plan.md
  git mv cig-requirements.md cig-requirements-plan.md
  git mv cig-design.md cig-design-plan.md
  git mv cig-implementation.md cig-implementation-plan.md
  git mv cig-testing.md cig-testing-plan.md
  ```

- [ ] **Step 6.2**: Add ⚠️ PLANNING PHASE notice to cig-task-plan.md
  - Add after "## Your task"
  - Text: "⚠️ **PLANNING PHASE**: This command is for planning the task, not executing it."

- [ ] **Step 6.3**: Add ⚠️ PLANNING PHASE notice to cig-requirements-plan.md
  - Same pattern as cig-task-plan.md
  - Text: "⚠️ **PLANNING PHASE**: This command is for defining requirements, not implementing them."

- [ ] **Step 6.4**: Add ⚠️ PLANNING PHASE notice to cig-design-plan.md
  - Same pattern
  - Text: "⚠️ **PLANNING PHASE**: This command is for designing the solution, not implementing it."

- [ ] **Step 6.5**: Add ⚠️ PLANNING PHASE notice to cig-implementation-plan.md
  - Same pattern
  - Text: "⚠️ **PLANNING PHASE**: This command is for planning implementation, not executing it. Execution is done in /cig-implementation-exec."

- [ ] **Step 6.6**: Add ⚠️ PLANNING PHASE notice to cig-testing-plan.md
  - Same pattern
  - Text: "⚠️ **PLANNING PHASE**: This command is for planning tests, not executing them. Test execution is done in /cig-testing-exec."

- [ ] **Step 6.7**: Validate command file syntax
  ```bash
  # Verify YAML frontmatter valid
  # Verify markdown renders correctly
  ```

- [ ] **Step 6.8**: Commit checkpoint 6
  ```bash
  git add .claude/commands/cig-*-plan.md
  git commit -m "Checkpoint 6: Rename workflow commands

Rename planning commands with -plan suffix for clarity:
- cig-plan → cig-task-plan
- cig-requirements → cig-requirements-plan
- cig-design → cig-design-plan
- cig-implementation → cig-implementation-plan
- cig-testing → cig-testing-plan

Added ⚠️ PLANNING PHASE notices to distinguish from execution.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```

### Checkpoint 7: Add Blocker Handling

- [ ] **Step 7.1**: Add blocker handling section to cig-task-plan.md
  - Based on design in c-design.md lines 172-187
  - Phase-specific blocker examples
  - Reversion guidance
  - When to revert criteria

- [ ] **Step 7.2**: Add blocker handling section to cig-requirements-plan.md
  - Common blockers: Stakeholder unavailable, Requirements conflict, Scope unclear
  - Revert to: /cig-task-plan

- [ ] **Step 7.3**: Add blocker handling section to cig-design-plan.md
  - Common blockers: Requirements incomplete, Technology constraints unknown, Design complexity too high
  - Revert to: /cig-requirements-plan or /cig-task-plan

- [ ] **Step 7.4**: Add blocker handling section to cig-implementation-plan.md
  - Common blockers: Design insufficient, Implementation approach unclear
  - Revert to: /cig-design-plan

- [ ] **Step 7.5**: Add blocker handling section to cig-testing-plan.md
  - Common blockers: Testability issues, Test environment unavailable
  - Revert to: /cig-implementation-plan or /cig-design-plan

- [ ] **Step 7.6**: Add blocker handling section to cig-rollout.md
  - Common blockers: Production environment not ready, Deployment process blocked
  - Revert to: /cig-testing-plan or /cig-implementation-plan

- [ ] **Step 7.7**: Add blocker handling section to cig-maintenance.md
  - Common blockers: Monitoring gaps, Support process undefined
  - Revert to: /cig-rollout

- [ ] **Step 7.8**: Add blocker handling section to cig-retrospective.md
  - Common blockers: Incomplete data, Team unavailable
  - No reversion (final phase)

- [ ] **Step 7.9**: Review blocker section consistency
  ```bash
  # Verify all 8 command files have blocker handling
  # Verify consistent format across all files
  ```

- [ ] **Step 7.10**: Commit checkpoint 7
  ```bash
  git add .claude/commands/cig-*.md
  git commit -m "Checkpoint 7: Add blocker handling sections

Add standardized blocker handling to all workflow commands:
- Common blockers in each phase
- Reversion guidance (which phase to revert to)
- When to revert criteria

Formalizes blocker-driven workflow reversion framework.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```

### Checkpoint 8: Create Execution Commands

- [ ] **Step 8.1**: Create cig-implementation-exec.md
  - Based on design in c-design.md lines 434-490
  - YAML frontmatter with description, argument-hint, allowed-tools
  - ⚠️ EXECUTION PHASE notice
  - References d-implementation-plan.md
  - Updates e-implementation-exec.md
  - Blocker handling section included

- [ ] **Step 8.2**: Create cig-testing-exec.md
  - Based on design in c-design.md lines 492-546
  - YAML frontmatter with description, argument-hint, allowed-tools
  - ⚠️ EXECUTION PHASE notice
  - References f-testing-plan.md
  - Updates g-testing-exec.md
  - Blocker handling section included

- [ ] **Step 8.3**: Set permissions on new command files
  ```bash
  chmod 0644 .claude/commands/cig-implementation-exec.md
  chmod 0644 .claude/commands/cig-testing-exec.md
  ```

- [ ] **Step 8.4**: Test execution commands on v2.1 task
  ```bash
  # Create test v2.1 task
  # Run /cig-implementation-exec <test-task>
  # Verify command guides through execution correctly
  # Run /cig-testing-exec <test-task>
  # Verify command guides through testing correctly
  ```

- [ ] **Step 8.5**: Commit checkpoint 8
  ```bash
  git add .claude/commands/cig-implementation-exec.md
  git add .claude/commands/cig-testing-exec.md
  git commit -m "Checkpoint 8: Create execution commands

Add new execution commands for v2.1 workflow:
- cig-implementation-exec: Execute planned implementation
- cig-testing-exec: Execute planned tests

Separates planning from execution with explicit commands.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```

### Checkpoint 9: Finalize Documentation

- [ ] **Step 9.1**: Update workflow-steps.md with 10-phase workflow
  - Add section documenting v2.1 workflow order
  - List all 10 phases: a-task-plan → b-requirements-plan → ... → j-retrospective
  - Explain planning vs execution distinction
  - Document new execution phases (e, g)

- [ ] **Step 9.2**: Add blocker-driven reversion framework to workflow-steps.md
  - Document reversion concept
  - Provide examples of when to revert
  - Explain status handling during reversion (Blocked status)

- [ ] **Step 9.3**: Update script-hashes.json with new scripts
  ```bash
  # Add hashes for:
  # - 3 entry points (status-aggregator, template-copier, context-inheritance)
  # - 6 orchestration scripts (*-v2.0, *-v2.1)
  # Calculate SHA256 hashes
  ```

- [ ] **Step 9.4**: Update COMMANDS.md (if exists)
  - List renamed commands (cig-*-plan)
  - List new execution commands (cig-implementation-exec, cig-testing-exec)
  - Organize by planning vs execution

- [ ] **Step 9.5**: Run cig-security-check
  ```bash
  # Verify script hashes match
  # Verify all scripts have correct permissions
  ```

- [ ] **Step 9.6**: Test multi-version detection
  ```bash
  # Test v2.0 task detection
  # Test v2.1 task detection
  # Test v1.0 deprecation error
  ```

- [ ] **Step 9.7**: Run regression tests on Tasks 1-24
  ```bash
  # Verify all existing tasks still work
  # Run status-aggregator on random sample
  # Verify correct version detection
  ```

- [ ] **Step 9.8**: Commit checkpoint 9
  ```bash
  git add .cig/docs/workflow/workflow-steps.md
  git add .cig/security/script-hashes.json
  git add COMMANDS.md  # if exists
  git commit -m "Checkpoint 9: Finalize documentation

Complete v2.1 workflow implementation:
- Update workflow-steps.md with 10-phase workflow
- Document blocker-driven reversion framework
- Update security hashes for all new scripts
- Update command reference

v2.1 workflow fully operational. All 9 checkpoints complete.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```

### Final Validation

- [ ] **Step 10.1**: Create comprehensive test v2.1 task
  ```bash
  # Create feature task with all 10 phases
  # Verify all files created correctly
  # Verify Template Version: 2.1 in headers
  ```

- [ ] **Step 10.2**: Walk through v2.1 workflow end-to-end
  ```bash
  # /cig-task-plan → updates a-task-plan.md
  # /cig-requirements-plan → updates b-requirements-plan.md
  # /cig-design-plan → updates c-design-plan.md
  # /cig-implementation-plan → updates d-implementation-plan.md
  # /cig-implementation-exec → updates e-implementation-exec.md
  # /cig-testing-plan → updates f-testing-plan.md
  # /cig-testing-exec → updates g-testing-exec.md
  # /cig-rollout → updates h-rollout.md
  # /cig-maintenance → updates i-maintenance.md
  # /cig-retrospective → updates j-retrospective.md
  ```

- [ ] **Step 10.3**: Test blocker reversion
  ```bash
  # Simulate blocker in e-implementation-exec
  # Update d-implementation-plan to resolve
  # Set e-implementation-exec status to "Blocked"
  # Restart from /cig-implementation-plan
  # Verify workflow continues correctly
  ```

- [ ] **Step 10.4**: Verify backward compatibility
  ```bash
  # Existing v2.0 tasks (Tasks 1-24) still work
  # No breaking changes to v2.0 workflow
  # Trampoline correctly routes v2.0 vs v2.1
  ```

- [ ] **Step 10.5**: Performance validation
  ```bash
  # Measure trampoline overhead (<50ms)
  # Measure status-aggregator on 10-file task (<500ms)
  # Measure template-copier for 10 files (<1s)
  ```

- [ ] **Step 10.6**: Mark implementation complete
  - Update d-implementation.md status to "Implemented"
  - Document any deviations from plan
  - Capture lessons learned

## Code Changes

### Before (Monolithic Scripts)
```perl
# status-aggregator.pl (monolithic, ~400 lines)
#!/usr/bin/env perl
use CIG::WorkflowFiles;

my $task_dir = $ARGV[0];
my $format = detect_format($task_dir);

if ($format eq 'v2.0') {
    # v2.0-specific logic (200 lines)
    my @files = ('a-plan.md', 'b-requirements.md', ...);
    # Status aggregation algorithm (100 lines)
    # Formatting and display (100 lines)
} elsif ($format eq 'v1.0') {
    # v1.0-specific logic (200 lines)
    # Duplicated status aggregation
}
```

### After (Trampoline Architecture)
```perl
# status-aggregator (entry point, ~20 lines)
#!/usr/bin/env perl
use FindBin;

my $task_dir = $ARGV[0] || '.';
my $version = detect_version($task_dir);  # calls format-detector

if ($version eq 'v2.1') {
    exec("$FindBin::Bin/status-aggregator-v2.1", @ARGV);
} elsif ($version eq 'v2.0') {
    exec("$FindBin::Bin/status-aggregator-v2.0", @ARGV);
} else {
    die "ERROR: v1.0 format deprecated.\n";
}

# status-aggregator-v2.1 (orchestration, ~50 lines)
#!/usr/bin/env perl
use CIG::WorkflowFiles::V21;
use CIG::StatusAggregator::Core;

my $task_dir = $ARGV[0];
my $files = CIG::WorkflowFiles::V21::get_workflow_files($task_type);
my $status = CIG::StatusAggregator::Core::aggregate($task_dir, $files);
print_status_v21($status);  # v2.1-specific formatting

# CIG::StatusAggregator::Core (shared, ~200 lines)
package CIG::StatusAggregator::Core;

sub aggregate {
    my ($task_dir, $workflow_files) = @_;
    # Version-agnostic status aggregation algorithm
    # Returns structured status data
    # <25% duplication (shared by v2.0 and v2.1)
}
```

### Template Changes

**Before (v2.0)**:
- a-plan.md.template
- b-requirements.md.template
- c-design.md.template
- d-implementation.md.template
- e-testing.md.template
- f-rollout.md.template
- g-maintenance.md.template
- h-retrospective.md.template

**After (v2.1)**:
- a-task-plan.md.template (renamed, -plan suffix)
- b-requirements-plan.md.template (renamed, -plan suffix)
- c-design-plan.md.template (renamed, -plan suffix)
- d-implementation-plan.md.template (renamed, -plan suffix)
- **e-implementation-exec.md.template** (NEW execution)
- f-testing-plan.md.template (re-lettered from e, -plan suffix)
- **g-testing-exec.md.template** (NEW execution)
- h-rollout.md.template (re-lettered from f)
- i-maintenance.md.template (re-lettered from g)
- j-retrospective.md.template (re-lettered from h)

## Test Coverage

**See e-testing.md for complete test plan**

### Unit Tests (Checkpoint 1)
- Test CIG::StatusAggregator::Core::aggregate() with mock workflow files
- Test CIG::TemplateCopier::Core with mock template data
- Test CIG::ContextInheritance::Core with mock parent structure

### Integration Tests (Checkpoints 2-5)
- Test trampoline entry points detect version correctly
- Test v2.0 orchestration scripts work with Tasks 1-24
- Test v2.1 orchestration scripts work with new test tasks
- Test v1.0 deprecation shows correct error messages

### Regression Tests (All Checkpoints)
- Run status-aggregator on all Tasks 1-24 after each checkpoint
- Verify no breaking changes to existing v2.0 workflow
- Verify existing tasks continue to work correctly

### System Tests (Checkpoint 9)
- End-to-end v2.1 workflow (all 10 phases)
- Blocker reversion workflow
- Multi-version detection (v1.0, v2.0, v2.1)
- Performance validation (<50ms trampoline overhead)

## Validation Criteria

- [ ] All 9 checkpoints completed with passing tests
- [ ] ~55 files modified/created as planned
- [ ] v2.0 tasks (1-24) continue working without changes
- [ ] v2.1 workflow creates 10 files (a-j) with correct naming
- [ ] Trampoline detects version correctly (v2.0 vs v2.1)
- [ ] v1.0 deprecation shows helpful error message
- [ ] All Core modules have <25% code duplication
- [ ] All scripts have correct permissions (0500 for executables, 0644 for modules)
- [ ] Security hashes updated and verified
- [ ] Documentation updated with 10-phase workflow and blocker framework
- [ ] Performance criteria met (<50ms trampoline, <500ms status, <1s template copy)
- [ ] All workflow commands renamed with -plan suffix or created as execution commands
- [ ] All 10 command files have blocker handling sections
- [ ] Blocker reversion workflow tested and documented

## Status
**Status**: Finished
**Next Action**: Proceed to testing phase - `/cig-testing-plan 25`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

**Implementation Completed**: All 9 checkpoints executed successfully

**Commits Created**:
1. Checkpoint 1 (2381819): Extract Core modules
2. Checkpoint 2 (162498c): Implement trampoline infrastructure
3. Checkpoint 3 (0fd698e): Deprecate v1.0 format
4. Checkpoint 4 (7a01515): Rename v2.0 templates
5. Checkpoint 5 (6abe07e): v2.1 infrastructure with 10-phase workflow
6. Checkpoint 6 (8b545ec): Rename workflow commands with -plan suffix
7. Checkpoint 7 (9415717): Add blocker handling to 8 workflow commands
8. Checkpoint 8 (bea1c54): Create execution commands
9. Checkpoint 9 (6e962ac): Finalize documentation and security

**Files Modified**: ~80 files across templates, scripts, modules, commands, and documentation

**Architecture Delivered**:
- 3 Core Perl modules (StatusAggregator, TemplateCopier, ContextInheritance)
- 2 Version modules (V20, V21)
- 3 Entry point scripts (trampoline architecture)
- 6 Orchestration scripts (v2.0 and v2.1)
- 10 Workflow templates (sequential a-j lettering)
- 10 Workflow commands (8 renamed with -plan, 2 new execution commands)
- 50+ symlinks updated across 5 task types

## Lessons Learned
*To be captured during retrospective*
