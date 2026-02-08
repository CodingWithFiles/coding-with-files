# complete helper script migration to trampoline architecture - Implementation

## Task Reference
- **Task ID**: internal-40
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/40-complete-helper-script-migration-to-trampoline-architecture
- **Template Version**: 2.1

## Goal
Implement complete helper script migration to trampoline architecture following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify

### New Trampoline Scripts (2 files)
- `.cig/scripts/command-helpers/workflow-manager` - New trampoline for workflow operations (status, control)
- `.cig/scripts/command-helpers/task-workflow` - New trampoline for task workflow creation

### Modified Trampoline (1 file)
- `.cig/scripts/command-helpers/context-manager` - Add 3 new subcommands to dispatch hash

### New Module Directories (2 directories)
- `.cig/scripts/command-helpers/workflow-manager.d/` - Directory for workflow modules
- `.cig/scripts/command-helpers/task-workflow.d/` - Directory for task-workflow modules

### New Module Scripts (6 files)
- `.cig/scripts/command-helpers/context-manager.d/hierarchy` - Copy hierarchy-resolver logic
- `.cig/scripts/command-helpers/context-manager.d/inheritance` - Copy context-inheritance logic (WITH version routing)
- `.cig/scripts/command-helpers/context-manager.d/version` - COMBINE format-detector + template-version-parser
- `.cig/scripts/command-helpers/workflow-manager.d/status` - Copy status-aggregator logic (WITH version routing)
- `.cig/scripts/command-helpers/workflow-manager.d/control` - Copy workflow-control logic (WITH version routing)
- `.cig/scripts/command-helpers/task-workflow.d/create` - Copy template-copier logic (ALWAYS v2.1)

### CIG Command Files (17 files)
All files in `.claude/commands/cig-*.md`:
- cig-config.md - Update helper calls + frontmatter
- cig-design-plan.md - Update helper calls + frontmatter
- cig-extract.md - Update helper calls + frontmatter
- cig-implementation-exec.md - Update helper calls + frontmatter
- cig-implementation-plan.md - Update helper calls + frontmatter
- cig-init.md - Update helper calls + frontmatter
- cig-maintenance.md - Update helper calls + frontmatter
- cig-new-task.md - Update helper calls + frontmatter
- cig-requirements-plan.md - Update helper calls + frontmatter
- cig-retrospective.md - Update helper calls + frontmatter
- cig-rollout.md - Update helper calls + frontmatter
- cig-security-check.md - Update helper calls + frontmatter
- cig-status.md - Update helper calls + frontmatter
- cig-subtask.md - Update helper calls + frontmatter
- cig-task-plan.md - Update helper calls + frontmatter
- cig-testing-exec.md - Update helper calls + frontmatter
- cig-testing-plan.md - Update helper calls + frontmatter

## Implementation Steps

### Step 1: Context-Manager Expansion (45 min)
- [ ] **1.1** Create directory `.cig/scripts/command-helpers/context-manager.d/` if not exists
- [ ] **1.2** Create `context-manager.d/hierarchy` module
  - Copy hierarchy-resolver script content
  - No version routing needed (directory resolution is version-agnostic)
  - Set permissions: `chmod 500 context-manager.d/hierarchy`
- [ ] **1.3** Create `context-manager.d/inheritance` module
  - Copy context-inheritance script content (includes version routing to -v2.0/-v2.1)
  - Preserve existing version detection and routing logic
  - Set permissions: `chmod 500 context-manager.d/inheritance`
- [ ] **1.4** Create `context-manager.d/version` module
  - COMBINE format-detector + template-version-parser logic
  - Read workflow file to detect format version (a-plan.md vs a-task-plan.md)
  - Parse "Template Version:" header from file
  - Output both format version and template version
  - Set permissions: `chmod 500 context-manager.d/version`
- [ ] **1.5** Update `context-manager` trampoline dispatch hash
  - Add entry: `hierarchy => "$script_dir/context-manager.d/hierarchy"`
  - Add entry: `inheritance => "$script_dir/context-manager.d/inheritance"`
  - Add entry: `version => "$script_dir/context-manager.d/version"`
  - Update usage message: `{location|hierarchy|inheritance|version}`
- [ ] **1.6** Test each new subcommand independently
  - `context-manager hierarchy 40` → verify outputs task directory
  - `context-manager inheritance 39` → verify outputs parent context (39 is top-level, should error)
  - `context-manager version implementation-guide/40-bugfix-.../a-task-plan.md` → verify outputs format + template version

### Step 2: Workflow-Manager Creation (60 min)
- [ ] **2.1** Create `workflow-manager` trampoline script
  - Copy context-manager structure (Perl, hash dispatch)
  - Define 2 subcommands: status, control
  - Usage message: `Usage: workflow-manager {status|control}\n`
  - Set permissions: `chmod 500 workflow-manager`
- [ ] **2.2** Create directory `.cig/scripts/command-helpers/workflow-manager.d/`
- [ ] **2.3** Create `workflow-manager.d/status` module
  - Copy status-aggregator script content (includes version routing to -v2.0/-v2.1)
  - Preserve existing version detection and routing logic
  - Set permissions: `chmod 500 workflow-manager.d/status`
- [ ] **2.4** Create `workflow-manager.d/control` module
  - Copy workflow-control script content (includes version routing to -v2.0/-v2.1)
  - Preserve existing version detection and routing logic
  - Set permissions: `chmod 500 workflow-manager.d/control`
- [ ] **2.5** Test each subcommand independently
  - `workflow-manager status` → verify outputs task tree with progress
  - `workflow-manager status 40` → verify outputs Task 40 status
  - `workflow-manager control --current-step=d-implementation-plan --task-path=40` → verify outputs next step suggestion

### Step 3: Task-Workflow Creation (30 min)
- [ ] **3.1** Create `task-workflow` trampoline script
  - Copy context-manager structure (Perl, hash dispatch)
  - Define 1 subcommand: create
  - Usage message: `Usage: task-workflow {create}\n`
  - Set permissions: `chmod 500 task-workflow`
- [ ] **3.2** Create directory `.cig/scripts/command-helpers/task-workflow.d/`
- [ ] **3.3** Create `task-workflow.d/create` module
  - Copy template-copier script content
  - REMOVE version detection logic - ALWAYS use v2.1
  - Simplify to call template-copier-v2.1 directly (or inline v2.1 logic)
  - Set permissions: `chmod 500 task-workflow.d/create`
- [ ] **3.4** Test create subcommand
  - Create test task: `task-workflow create --task-type=chore --destination=/tmp/test-task-41 --task-num=41 --description="test task"`
  - Verify v2.1 workflow files created (a-task-plan.md, etc.)
  - Clean up test: `rm -rf /tmp/test-task-41`

### Step 4: CIG Command Updates - Context Manager (20 min)
Update all CIG commands that call hierarchy-resolver, context-inheritance, format-detector, template-version-parser:

- [ ] **4.1** Update commands calling `hierarchy-resolver`:
  - cig-design-plan.md, cig-extract.md, cig-implementation-exec.md, cig-implementation-plan.md
  - cig-maintenance.md, cig-new-task.md, cig-requirements-plan.md, cig-retrospective.md
  - cig-rollout.md, cig-status.md, cig-subtask.md, cig-task-plan.md
  - cig-testing-exec.md, cig-testing-plan.md
  - Replace: `hierarchy-resolver <task-path>` → `context-manager hierarchy <task-path>`

- [ ] **4.2** Update commands calling `context-inheritance`:
  - Same files as 4.1 (most CIG commands call both)
  - Replace: `context-inheritance <task-path>` → `context-manager inheritance <task-path>`

- [ ] **4.3** Update commands calling `format-detector` or `template-version-parser`:
  - Most CIG commands call format-detector
  - Replace: `format-detector <dir> <file>` → `context-manager version <dir> <file>`
  - Replace: `template-version-parser <dir> <file>` → `context-manager version <dir> <file>`
  - NOTE: Both map to same call now (combined functionality)

### Step 5: CIG Command Updates - Workflow Manager (15 min)
- [ ] **5.1** Update `cig-status.md`
  - Replace: `status-aggregator` → `workflow-manager status`
  - Replace: `status-aggregator <task-path>` → `workflow-manager status <task-path>`

- [ ] **5.2** Update all commands calling `workflow-control`:
  - All workflow phase commands (cig-design-plan.md, cig-implementation-plan.md, etc.)
  - Replace: `workflow-control --current-step=X --task-path=Y` → `workflow-manager control --current-step=X --task-path=Y`

### Step 6: CIG Command Updates - Task Workflow (10 min)
- [ ] **6.1** Update `cig-new-task.md`
  - Replace: `template-copier --task-type=...` → `task-workflow create --task-type=...`
  - Update documentation to reflect semantic naming

- [ ] **6.2** Update `cig-subtask.md`
  - Replace: `template-copier --task-type=...` → `task-workflow create --task-type=...`

### Step 7: Frontmatter Simplification (15 min)
- [ ] **7.1** Review all 17 CIG command frontmatter sections
- [ ] **7.2** Remove obsolete patterns:
  - Remove: `Bash(.cig/scripts/command-helpers/hierarchy-resolver:*)`
  - Remove: `Bash(.cig/scripts/command-helpers/context-inheritance:*)`
  - Remove: `Bash(.cig/scripts/command-helpers/format-detector:*)`
  - Remove: `Bash(.cig/scripts/command-helpers/template-version-parser:*)`
  - Remove: `Bash(.cig/scripts/command-helpers/status-aggregator:*)`
  - Remove: `Bash(.cig/scripts/command-helpers/workflow-control:*)`
  - Remove: `Bash(.cig/scripts/command-helpers/template-copier:*)`
- [ ] **7.3** Verify trampoline patterns present:
  - Verify: `Bash(.cig/scripts/command-helpers/context-manager:*)` exists
  - Add: `Bash(.cig/scripts/command-helpers/workflow-manager:*)` if not covered by wildcard
  - Add: `Bash(.cig/scripts/command-helpers/task-workflow:*)` if not covered by wildcard
  - NOTE: Most commands already have `Bash(.cig/scripts/command-helpers/*:*)` wildcard

### Step 8: Validation & Testing (30 min)
- [ ] **8.1** Execute test suite (defer to e-testing-plan.md for details)
- [ ] **8.2** Verify zero permission prompts across all 17 CIG commands
- [ ] **8.3** Test backward compatibility with existing tasks (1-39)
- [ ] **8.4** Verify version routing works for 3 modules (inheritance, status, control)
- [ ] **8.5** Verify no version routing for 4 modules (location, hierarchy, version, create)

## Code Changes

### Example 1: Context-Manager Trampoline Update

**Before** (1 subcommand):
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;

my $subcommand = shift @ARGV or die "Usage: context-manager {location}\n";
my $script_dir = dirname(__FILE__);

my %commands = (
    location => "$script_dir/context-manager.d/location",
);

die "Unknown subcommand: $subcommand\n" unless exists $commands{$subcommand};
exec $commands{$subcommand}, @ARGV or die "Failed to exec: $!\n";
```

**After** (4 subcommands):
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;

my $subcommand = shift @ARGV or die "Usage: context-manager {location|hierarchy|inheritance|version}\n";
my $script_dir = dirname(__FILE__);

my %commands = (
    location => "$script_dir/context-manager.d/location",
    hierarchy => "$script_dir/context-manager.d/hierarchy",
    inheritance => "$script_dir/context-manager.d/inheritance",
    version => "$script_dir/context-manager.d/version",
);

die "Unknown subcommand: $subcommand\n" unless exists $commands{$subcommand};
exec $commands{$subcommand}, @ARGV or die "Failed to exec: $!\n";
```

### Example 2: New Workflow-Manager Trampoline

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;

my $subcommand = shift @ARGV or die "Usage: workflow-manager {status|control}\n";
my $script_dir = dirname(__FILE__);

my %commands = (
    status => "$script_dir/workflow-manager.d/status",
    control => "$script_dir/workflow-manager.d/control",
);

die "Unknown subcommand: $subcommand\n" unless exists $commands{$subcommand};
exec $commands{$subcommand}, @ARGV or die "Failed to exec: $!\n";
```

### Example 3: New Task-Workflow Trampoline

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;

my $subcommand = shift @ARGV or die "Usage: task-workflow {create}\n";
my $script_dir = dirname(__FILE__);

my %commands = (
    create => "$script_dir/task-workflow.d/create",
);

die "Unknown subcommand: $subcommand\n" unless exists $commands{$subcommand};
exec $commands{$subcommand}, @ARGV or die "Failed to exec: $!\n";
```

### Example 4: Module Script (hierarchy)

```perl
#!/usr/bin/env perl
#
# Copy entire content from hierarchy-resolver script
# This is structural migration - preserve all existing logic exactly
# No refactoring, no changes to behavior
#
use strict;
use warnings;
# ... rest of hierarchy-resolver content ...
```

### Example 5: Module Script with Version Routing (inheritance)

```perl
#!/usr/bin/env perl
#
# Copy entire content from context-inheritance script
# Preserves existing version routing to -v2.0/-v2.1 scripts
# This is structural migration - keep all routing logic intact
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";

# ... existing version detection logic ...
# Routes to context-inheritance-v2.0 or context-inheritance-v2.1
# ... rest of context-inheritance content ...
```

### Example 6: CIG Command Update

**Before**:
```bash
!{bash}
.cig/scripts/command-helpers/hierarchy-resolver 40
.cig/scripts/command-helpers/context-inheritance 40
.cig/scripts/command-helpers/format-detector $TASK_DIR $WORKFLOW_FILE
```

**After**:
```bash
!{bash}
.cig/scripts/command-helpers/context-manager hierarchy 40
.cig/scripts/command-helpers/context-manager inheritance 40
.cig/scripts/command-helpers/context-manager version $TASK_DIR $WORKFLOW_FILE
```

### Example 7: Frontmatter Simplification

**Before** (7 patterns):
```yaml
allowed-tools: Read, Write, Edit,
  Bash(.cig/scripts/command-helpers/hierarchy-resolver:*),
  Bash(.cig/scripts/command-helpers/context-inheritance:*),
  Bash(.cig/scripts/command-helpers/format-detector:*),
  Bash(.cig/scripts/command-helpers/status-aggregator:*),
  Bash(.cig/scripts/command-helpers/workflow-control:*),
  Bash(.cig/scripts/command-helpers/template-version-parser:*),
  Bash(.cig/scripts/command-helpers/template-copier:*)
```

**After** (3 patterns or wildcard):
```yaml
allowed-tools: Read, Write, Edit,
  Bash(.cig/scripts/command-helpers/context-manager:*),
  Bash(.cig/scripts/command-helpers/workflow-manager:*),
  Bash(.cig/scripts/command-helpers/task-workflow:*)

# OR use existing wildcard (cleaner):
allowed-tools: Read, Write, Edit,
  Bash(.cig/scripts/command-helpers/*:*)
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

### Unit Tests (Per Module)
- **context-manager hierarchy**: Test task path resolution (top-level, subtask, invalid path)
- **context-manager inheritance**: Test parent context loading (subtask, top-level error, version routing)
- **context-manager version**: Test format detection + template version parsing (v2.0, v2.1, combined output)
- **workflow-manager status**: Test status aggregation (single task, hierarchy, version routing)
- **workflow-manager control**: Test next-step logic (different phases, version routing)
- **task-workflow create**: Test workflow file creation (always v2.1, all task types)

### Integration Tests
- Test complete workflow: `/cig-task-plan 40` → verify uses new trampoline calls
- Test permission prompts: Execute all 17 CIG commands → verify zero prompts
- Test backward compatibility: Execute CIG commands on Tasks 1-39 → verify still work
- Test version routing: Execute commands on v2.0 task → verify routes to v2.0 modules
- Test version routing: Execute commands on v2.1 task → verify routes to v2.1 modules

### Regression Tests
- Test existing Task 39: `/cig-status 39` → verify still shows 100% complete
- Test mixed versions: `/cig-status` → verify shows both v2.0 and v2.1 tasks correctly

## Validation Criteria

### Success Criteria (From Planning)
- [ ] **SC1**: All 6 helper scripts migrated to 7 trampoline subcommands
- [ ] **SC2**: Two new trampolines created (workflow-manager, task-workflow)
- [ ] **SC3**: Context-manager expanded with 3 new subcommands
- [ ] **SC4**: All 17 CIG commands updated with new trampoline calls
- [ ] **SC5**: Frontmatter consolidated to 3 permission patterns
- [ ] **SC6**: Zero permission prompts verified across all commands
- [ ] **SC7**: Backward compatibility validated (Tasks 1-39 work)
- [ ] **SC8**: Version routing preserved for 3 modules (inheritance, status, control)

### Implementation Validation
- [ ] All trampolines have proper Perl structure (shebang, hash dispatch, error messages)
- [ ] All modules have executable permissions (chmod 500)
- [ ] All modules preserve original script logic (no behavior changes)
- [ ] All CIG commands use new trampoline calls (no direct script calls remain)
- [ ] Frontmatter simplified (old patterns removed, new patterns present)
- [ ] Git status clean (all changes committed)

### Functional Validation
- [ ] Execute `/cig-status` → shows all tasks including 40
- [ ] Execute `/cig-task-plan 41` → would work if Task 41 existed (uses trampolines)
- [ ] Execute `context-manager hierarchy 40` → outputs Task 40 directory
- [ ] Execute `workflow-manager status 40` → outputs Task 40 status
- [ ] Execute `task-workflow create --task-type=chore --destination=/tmp/test --task-num=99 --description="test"` → creates v2.1 files
- [ ] No permission prompts during any command execution

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Completion**: Implementation plan fully executed - all 7 steps completed successfully
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Notes

### Key Implementation Principles
1. **Structural Migration Only**: Copy existing script logic exactly, no refactoring
2. **Preserve Version Routing**: 3 modules (inheritance, status, control) must keep -v2.0/-v2.1 routing
3. **Pattern Consistency**: All trampolines follow Task 39 pattern exactly (Perl, hash dispatch)
4. **Permission Model**: Trampoline invocation is only permission boundary
5. **Semantic Naming**: task-workflow create (what) vs template-manager copy (how)

### Critical Files
- **Source Scripts**: hierarchy-resolver, context-inheritance, format-detector, template-version-parser, status-aggregator, workflow-control, template-copier
- **Trampolines**: context-manager (modify), workflow-manager (new), task-workflow (new)
- **Modules**: 6 new modules in 3 .d/ directories
- **CIG Commands**: 17 files in .claude/commands/cig-*.md

### Testing Focus
- Zero permission prompts (critical success criterion)
- Version routing works correctly (3 modules preserve routing)
- Backward compatibility (Tasks 1-39 continue working)
- CIG commands use new trampoline calls consistently

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
