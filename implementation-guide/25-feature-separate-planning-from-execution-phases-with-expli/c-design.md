# Separate Planning from Execution Phases with Explicit Execution Commands - Design

## Task Reference
- **Task ID**: internal-25
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/25-separate-planning-from-execution-phases-with-expli
- **Template Version**: 2.0

## Goal
Define architecture and design decisions for expanding CIG from 8-phase to 10-phase workflow with explicit execution commands, sequential a-j lettering, trampoline architecture, and formalized blocker-driven workflow reversion.

## Design Priorities
Testability → Maintainability → Readability → Consistency → Simplicity

## Architecture Preferences
Composition over inheritance. Versioned orchestration over monolithic scripts. Explicit over implicit.

## Key Decisions

### 1. File Naming Architecture: Sequential a-j Lettering

**Decision**: Sequential a-j lettering (v2.1) instead of d2/e2 numeric suffixes

**New v2.1 Naming**:
- a-task-plan.md (renamed from a-plan.md)
- b-requirements-plan.md (renamed from b-requirements.md)
- c-design-plan.md (renamed from c-design.md)
- d-implementation-plan.md (renamed from d-implementation.md)
- **e-implementation-exec.md** (NEW)
- f-testing-plan.md (re-lettered from e-testing.md)
- **g-testing-exec.md** (NEW)
- h-rollout.md (re-lettered from f-rollout.md)
- i-maintenance.md (re-lettered from g-maintenance.md)
- j-retrospective.md (re-lettered from h-retrospective.md)

**Rationale**:
- ✓ Clean alphabetical progression (no numeric suffixes)
- ✓ No confusing d2/e2 patterns
- ✓ Easier mental model (a→b→c→d→e→...)
- ✓ Justified by trampoline architecture (version management becomes trivial)
- ⚠️ Requires renaming existing templates (e→f, f→h, g→i, h→j)
- ⚠️ Requires v2.1 version (can't extend v2.0)

**Alternative Considered (d2/e2 numeric suffixes)**:
- ✓ No renames needed
- ✓ Can extend v2.0
- ❌ Confusing numeric suffixes
- ❌ Breaks alphabetical sorting
- **Rejected**: Trampoline architecture makes v2.1 cost acceptable for cleaner naming

### 2. Trampoline Architecture Design

**Decision**: Three-layer trampoline pattern with version-specific orchestration

**Components**:

1. **Entry Point Scripts** (~20 lines each):
   - status-aggregator
   - template-copier
   - context-inheritance
   - **Responsibilities**: Detect version, trampoline to version-specific script
   - **Example**:
     ```perl
     # Entry point: status-aggregator
     my $version = detect_version($task_dir);  # calls format-detector
     if ($version eq 'v2.1') {
         exec('status-aggregator-v2.1', @ARGV);
     } elsif ($version eq 'v2.0') {
         exec('status-aggregator-v2.0', @ARGV);
     } else {
         die "Unsupported version: $version (v1.0 deprecated)";
     }
     ```

2. **Version-Specific Orchestration Scripts** (~50 lines each):
   - status-aggregator-v2.0, status-aggregator-v2.1
   - template-copier-v2.0, template-copier-v2.1
   - context-inheritance-v2.0, context-inheritance-v2.1
   - **Responsibilities**: Load version data, call Core modules, handle version quirks
   - **Example**:
     ```perl
     # Orchestration: status-aggregator-v2.1
     use CIG::WorkflowFiles::V21;
     use CIG::StatusAggregator::Core;

     my $files = CIG::WorkflowFiles::V21::get_workflow_files($task_type);
     my $status = CIG::StatusAggregator::Core::aggregate($task_dir, $files);
     print_status($status);  # v2.1-specific formatting
     ```

3. **Core Modules** (shared logic, ~200+ lines each):
   - CIG::StatusAggregator::Core
   - CIG::TemplateCopier::Core
   - CIG::ContextInheritance::Core
   - **Responsibilities**: Algorithms, formatting, validation (version-agnostic)

4. **Version Data Modules**:
   - CIG::WorkflowFiles::V20 (a-plan.md through h-retrospective.md)
   - CIG::WorkflowFiles::V21 (a-task-plan.md through j-retrospective.md)
   - **Note**: V10 removed (v1.0 deprecated)

**Data Flow**:
```
User runs: status-aggregator 25
  ↓
Entry point: status-aggregator
  ↓ calls format-detector
  ↓ detects v2.1 (via "Template Version: 2.1" header)
  ↓ trampolines to:
status-aggregator-v2.1
  ↓ loads WorkflowFiles::V21
  ↓ calls StatusAggregator::Core
  ↓ returns results with v2.1 formatting
```

**Rationale**:
- ✓ Clean v1.0 deprecation (just remove *-v1.0 scripts)
- ✓ DRY via Core modules (<25% duplication)
- ✓ Future v3.0 easy to add
- ✓ Version isolation (v2.1 changes can't break v2.0)
- ⚠️ More files (18 total)
- ⚠️ Initial extraction effort
- ⚠️ Testing complexity (must test both v2.0 and v2.1)

### 3. Template Infrastructure Design

**Template Pool Structure** (`.cig/templates/pool/`):
- a-task-plan.md.template (renamed from a-plan.md.template)
- b-requirements-plan.md.template (renamed from b-requirements.md.template)
- c-design-plan.md.template (renamed from c-design.md.template)
- d-implementation-plan.md.template (renamed from d-implementation.md.template)
- **e-implementation-exec.md.template** (NEW)
- f-testing-plan.md.template (renamed + re-lettered from e-testing.md.template)
- **g-testing-exec.md.template** (NEW)
- h-rollout.md.template (re-lettered from f-rollout.md.template)
- i-maintenance.md.template (re-lettered from g-maintenance.md.template)
- j-retrospective.md.template (re-lettered from h-retrospective.md.template)

**Symlink Updates** (per task type):
- **Feature**: 10 files (a-j)
- **Bugfix**: 7 files (a, c, d, e, f, g, j)
- **Hotfix**: 7 files (a, d, e, f, g, h, j)
- **Chore**: 6 files (a, d, e, f, g, j)
- **Discovery**: 8 files (a-g, j - no h, i)

**Template Version Detection**:
All v2.1 templates include:
```markdown
- **Template Version**: 2.1
```
format-detector.pl uses existing `get_template_version()` logic (no need for file-based detection).

### 4. Workflow Command Design

**Renamed Commands** (with -plan suffix):
- cig-task-plan.md (renamed from cig-plan.md)
- cig-requirements-plan.md (renamed from cig-requirements.md)
- cig-design-plan.md (renamed from cig-design.md)
- cig-implementation-plan.md (renamed from cig-implementation.md)
- cig-testing-plan.md (renamed from cig-testing.md)

**New Execution Commands**:
- cig-implementation-exec.md (reads d-implementation-plan.md, updates e-implementation-exec.md)
- cig-testing-exec.md (reads f-testing-plan.md, updates g-testing-exec.md)

**Unchanged Commands**:
- cig-rollout.md (already execution-focused)
- cig-maintenance.md (already execution-focused)
- cig-retrospective.md (already execution-focused)

**Blocker Handling Section** (added to all 10 commands):
```markdown
## Blocker Handling

**Common Blockers in [Phase Name]**:
- Blocker scenario 1 → Recommended reversion point
- Blocker scenario 2 → Recommended reversion point

**Reversion Guidance**:
- If reverting to [earlier phase], update that phase's file and restart from there
- Document blocker in current phase's "Actual Results" section
- Update status to "Blocked" until reversion complete

**When to Revert**:
- [Phase-specific criteria]
```

### 5. Checkpoint Commit Strategy (6-9 commits)

**Proposed Sequence**:

1. **Checkpoint 1: Extract Core modules** (FR12)
   - Create `.cig/lib/CIG/StatusAggregator/Core.pm`
   - Create `.cig/lib/CIG/TemplateCopier/Core.pm`
   - Create `.cig/lib/CIG/ContextInheritance/Core.pm`
   - Extract shared logic from existing scripts
   - **Validation**: Run existing scripts (should still work via monolithic code paths)

2. **Checkpoint 2: Implement trampoline infrastructure** (FR12)
   - Create entry point scripts (status-aggregator, template-copier, context-inheritance)
   - Create v2.0 orchestration scripts (*-v2.0)
   - Create `.cig/lib/CIG/WorkflowFiles/V20.pm` (extract from WorkflowFiles.pm)
   - **Validation**: Run status-aggregator on Tasks 1-24 (must show correct progress)

3. **Checkpoint 3: Deprecate v1.0** (AC44)
   - Remove V10 modules
   - Add deprecation errors to entry points
   - Update documentation
   - **Validation**: Verify v1.0 tasks show clear error message

4. **Checkpoint 4: Rename v2.0 templates** (FR5)
   - Add -plan suffix to a-e templates (a-plan → a-task-plan, etc.)
   - Re-letter e→f, f→h, g→i, h→j
   - Update symlinks
   - **Validation**: Run template-copier to create test v2.0 task

5. **Checkpoint 5: Create v2.1 infrastructure** (FR2)
   - Create e-implementation-exec.md.template
   - Create g-testing-exec.md.template
   - Create `.cig/lib/CIG/WorkflowFiles/V21.pm`
   - Create v2.1 orchestration scripts (*-v2.1)
   - Update symlinks for all task types
   - **Validation**: Run template-copier to create test v2.1 task

6. **Checkpoint 6: Rename workflow commands** (FR6, FR7)
   - Rename 5 planning commands with -plan suffix
   - Add prominent ⚠️ PLANNING PHASE notices
   - **Validation**: Validate command file syntax

7. **Checkpoint 7: Add blocker handling** (FR10)
   - Update all 10 command files with blocker sections
   - Phase-specific blocker examples
   - **Validation**: Review blocker section consistency

8. **Checkpoint 8: Create execution commands** (FR1)
   - Create cig-implementation-exec.md
   - Create cig-testing-exec.md
   - **Validation**: Test commands on v2.1 test task

9. **Checkpoint 9: Finalize documentation** (FR3, FR4)
   - Update workflow-steps.md with 10-phase workflow
   - Document blocker-driven reversion framework
   - Update security hashes
   - **Validation**: Run cig-security-check, test multi-version detection

**Validation per checkpoint**: Run status-aggregator on Tasks 1-24 to ensure no regression

## System Design

### Component Overview

**Component 1: Template System**
- **Purpose**: Generate workflow files for new tasks
- **Responsibility**: Provide templates for all 10 workflow phases (v2.1)
- **Files**:
  - `.cig/templates/pool/` - Central template storage (10 templates)
  - `.cig/templates/{feature,bugfix,hotfix,chore,discovery}/` - Task-type-specific symlinks
- **Changes**: Rename 8 existing templates, add 2 new templates

**Component 2: Workflow Commands**
- **Purpose**: Guide users through each workflow phase
- **Responsibility**: Provide step-by-step instructions for planning and execution
- **Files**: `.claude/commands/cig-*.md` (10 command files after changes)
- **Changes**: Rename 5 commands, create 2 new commands, add blocker handling to all 10

**Component 3: Helper Scripts (Trampoline Architecture)**
- **Purpose**: Automate deterministic operations with version isolation
- **Responsibility**: Detect version, orchestrate version-specific logic, execute core algorithms
- **Files**:
  - Entry points: status-aggregator, template-copier, context-inheritance
  - v2.0 orchestration: *-v2.0 scripts
  - v2.1 orchestration: *-v2.1 scripts
  - Core modules: CIG::StatusAggregator::Core, etc.
  - Version data: CIG::WorkflowFiles::V20, CIG::WorkflowFiles::V21
- **Changes**: Major refactoring to trampoline architecture

**Component 4: Workflow Documentation**
- **Purpose**: Document workflow semantics and state machine
- **Responsibility**: Define 10-phase workflow, transitions, blocker handling
- **Files**: `.cig/docs/workflow/workflow-steps.md`
- **Changes**: Add 10-phase workflow order, blocker reversion framework

### Data Flow

**Task Creation Flow** (via /cig-new-task):
1. User invokes `/cig-new-task <num> <type> "description"`
2. Entry point: template-copier
3. Detects latest version (v2.1 for new tasks)
4. Trampolines to: template-copier-v2.1
5. Loads WorkflowFiles::V21 to get file list
6. Calls TemplateCopier::Core for variable substitution
7. Copies 10 templates (feature) or subset (other types) from pool
8. Task directory created with all workflow files

**Status Aggregation Flow** (via /cig-status):
1. User invokes `/cig-status [task-path]`
2. Entry point: status-aggregator
3. Calls format-detector to detect v2.0 vs v2.1 (via "Template Version" header)
4. Trampolines to: status-aggregator-v2.0 or status-aggregator-v2.1
5. Loads appropriate WorkflowFiles module (V20 or V21)
6. Calls StatusAggregator::Core
7. Version-specific formatting and display

**Workflow Execution Flow** (user-driven):
1. Planning phases (a-d): cig-task-plan → cig-requirements-plan → cig-design-plan → cig-implementation-plan
2. Implementation execution (e): cig-implementation-exec
3. Testing planning (f): cig-testing-plan
4. Testing execution (g): cig-testing-exec
5. Rollout phases (h-j): cig-rollout → cig-maintenance → cig-retrospective

**Blocker Reversion Flow**:
1. User encounters blocker in current phase (e.g., cig-implementation-exec)
2. User identifies appropriate reversion point (e.g., cig-design-plan)
3. User updates earlier phase file to resolve blocker
4. User updates current phase "Actual Results" with blocker documentation
5. User sets current phase status to "Blocked"
6. User restarts workflow from reversion point
7. User progresses forward again after blocker resolved

## Interface Design

### Template File Interfaces

**New Template: e-implementation-exec.md.template**
```markdown
# {{description}} - Implementation Execution

## Task Reference
- **Task ID**: {{taskId}}
- **Task URL**: {{taskUrl}}
- **Parent Task**: {{parentTask}}
- **Branch**: {{branchName}}
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md.

## Execution Checklist
- [ ] Read d-implementation-plan.md thoroughly
- [ ] Verify all prerequisites met
- [ ] Execute implementation steps sequentially
- [ ] Update "Actual Results" for each step
- [ ] Document any deviations from plan
- [ ] Update status to "Implemented" when complete

## Implementation Steps (from d-implementation-plan.md)

[Reference to planning file, updated with actual results]

## Actual Results

### Step 1: [Step name from plan]
- **Planned**: [What was planned]
- **Actual**: [What actually happened]
- **Deviations**: [Any differences from plan]

## Blockers Encountered

[Document any blockers and resolutions]

## Status
**Status**: Finished
**Next Action**: Implementation complete, refer to d-implementation.md
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
```

**New Template: g-testing-exec.md.template**
```markdown
# {{description}} - Testing Execution

## Task Reference
- **Task ID**: {{taskId}}
- **Task URL**: {{taskUrl}}
- **Parent Task**: {{parentTask}}
- **Branch**: {{branchName}}
- **Template Version**: 2.1

## Goal
Execute the tests defined in f-testing-plan.md and record results.

## Execution Checklist
- [ ] Read f-testing-plan.md test strategy
- [ ] Verify test environment ready
- [ ] Execute test cases sequentially
- [ ] Record pass/fail for each test
- [ ] Document failures with reproduction steps
- [ ] Update status to "Testing" when in progress, "Finished" when all pass

## Test Results

### Functional Tests
[Table of test cases from f-testing-plan.md with results]

| Test ID | Test Case | Expected | Actual | Status | Notes |
|---------|-----------|----------|--------|--------|-------|
| FT1     | ...       | ...      | ...    | PASS   | ...   |

### Non-Functional Tests
[Performance, security, usability, reliability test results]

## Test Failures

[Detailed documentation of any test failures with reproduction steps]

## Coverage Report

[Test coverage metrics if available]

## Status
**Status**: Finished
**Next Action**: Testing complete, refer to e-testing.md
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during retrospective*
```

### Command File Interfaces

**New Command: cig-implementation-exec.md**
```markdown
---
description: Execute implementation following plan
argument-hint: <task-path>
allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, Task]
---

## Context
You are guiding the user through the **Implementation Execution** phase of the CIG workflow.

## Your task
Execute the implementation following the plan in d-implementation-plan.md.

⚠️ **EXECUTION PHASE**: This command is for executing the planned implementation, not planning it. Planning was done in /cig-implementation-plan.

Follow the 8-step workflow structure:
1. Resolve Task Directory
2. Load Parent Context (if subtask)
3. Present Context Summary
4. LLM Decision
5. Reference Workflow Documentation: `.cig/docs/workflow/workflow-steps.md#implementation-execution`
6. Execute Implementation:
   - Read d-implementation-plan.md thoroughly
   - Execute each implementation step
   - Update e-implementation-exec.md with actual results
   - Document deviations from plan
   - Update status as work progresses
7. Check Decomposition Signals
8. Suggest Next Steps: /cig-testing-plan <task-path>

## Blocker Handling

**Common Blockers in Implementation Execution**:
- Design insufficient for implementation → Revert to /cig-design-plan
- Requirements unclear during coding → Revert to /cig-requirements-plan
- Implementation approach not working → Revert to /cig-design-plan
- Missing dependencies or prerequisites → Revert to /cig-task-plan

**Reversion Guidance**:
- If reverting to earlier phase, update that phase's file and restart from there
- Document blocker in e-implementation-exec.md "Actual Results" section
- Update status to "Blocked" until reversion complete

**When to Revert**:
- When fundamental assumptions prove incorrect
- When implementation reveals design flaws
- When blockers cannot be resolved within current phase

## Success Criteria
- [ ] All implementation steps from plan executed
- [ ] Actual results documented for each step
- [ ] Deviations from plan documented with rationale
- [ ] Code compiles and runs
- [ ] Status updated to "Implemented"
- [ ] e-implementation-exec.md complete
```

**New Command: cig-testing-exec.md**
```markdown
---
description: Execute tests following plan
argument-hint: <task-path>
allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, Task]
---

## Context
You are guiding the user through the **Testing Execution** phase of the CIG workflow.

## Your task
Execute the tests defined in f-testing-plan.md.

⚠️ **EXECUTION PHASE**: This command is for executing planned tests, not planning them. Test planning was done in /cig-testing-plan.

Follow the 8-step workflow structure:
1-5. [Standard steps]
6. Execute Testing:
   - Read f-testing-plan.md test strategy
   - Execute each test case
   - Record results in g-testing-exec.md
   - Document failures with reproduction steps
   - Fix failures and rerun tests
   - Update status when all tests pass
7. Check Decomposition Signals
8. Suggest Next Steps: /cig-rollout <task-path> (if all pass) or revert to /cig-implementation-exec (if failures persist)

## Blocker Handling

**Common Blockers in Testing Execution**:
- Tests reveal implementation bugs → Revert to /cig-implementation-exec
- Test plan insufficient → Revert to /cig-testing-plan
- Tests reveal design flaws → Revert to /cig-design-plan
- Tests reveal requirements gaps → Revert to /cig-requirements-plan

**Reversion Guidance**:
- If reverting to earlier phase, update that phase's file and restart from there
- Document blocker in g-testing-exec.md "Test Failures" section
- Update status to "Blocked" until reversion complete

**When to Revert**:
- When test failures indicate fundamental implementation issues
- When test plan proves inadequate
- When tests reveal design or requirements problems

## Success Criteria
- [ ] All test cases from plan executed
- [ ] Test results recorded with pass/fail status
- [ ] Failures documented with reproduction steps
- [ ] All critical tests passing
- [ ] Coverage metrics captured
- [ ] Status updated to "Finished"
- [ ] g-testing-exec.md complete
```

### Helper Script Interfaces

**Entry Point: status-aggregator**
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Detect version
my $task_dir = $ARGV[0] || '.';
my $version = detect_version($task_dir);

# Trampoline to version-specific script
if ($version eq 'v2.1') {
    exec("$FindBin::Bin/status-aggregator-v2.1", @ARGV);
} elsif ($version eq 'v2.0') {
    exec("$FindBin::Bin/status-aggregator-v2.0", @ARGV);
} else {
    die "ERROR: v1.0 format deprecated. Use migration tools to upgrade.\n";
}

sub detect_version {
    my ($task_dir) = @_;
    # Call format-detector to read "Template Version" header
    my $version = `$FindBin::Bin/format-detector "$task_dir"`;
    chomp $version;
    return $version;
}
```

**Orchestration: status-aggregator-v2.1**
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CIG::WorkflowFiles::V21;
use CIG::StatusAggregator::Core;

my $task_dir = $ARGV[0] || '.';

# Load v2.1 workflow files
my $files = CIG::WorkflowFiles::V21::get_workflow_files($task_type);

# Call Core module
my $status = CIG::StatusAggregator::Core::aggregate($task_dir, $files);

# v2.1-specific formatting
print_status_v21($status);
```

**Core Module: CIG::StatusAggregator::Core**
```perl
package CIG::StatusAggregator::Core;
use strict;
use warnings;

sub aggregate {
    my ($task_dir, $workflow_files) = @_;

    # Version-agnostic status aggregation algorithm
    # Returns structured status data
    # Called by both v2.0 and v2.1 orchestration scripts
}

1;
```

**Version Data: CIG::WorkflowFiles::V21**
```perl
package CIG::WorkflowFiles::V21;
use strict;
use warnings;

sub get_workflow_files {
    my ($task_type) = @_;

    my %files = (
        feature   => ['a-task-plan.md', 'b-requirements-plan.md', 'c-design-plan.md',
                      'd-implementation-plan.md', 'e-implementation-exec.md',
                      'f-testing-plan.md', 'g-testing-exec.md',
                      'h-rollout.md', 'i-maintenance.md', 'j-retrospective.md'],
        bugfix    => ['a-task-plan.md', 'c-design-plan.md', 'd-implementation-plan.md',
                      'e-implementation-exec.md', 'f-testing-plan.md', 'g-testing-exec.md',
                      'j-retrospective.md'],
        hotfix    => ['a-task-plan.md', 'd-implementation-plan.md', 'e-implementation-exec.md',
                      'f-testing-plan.md', 'g-testing-exec.md', 'h-rollout.md',
                      'j-retrospective.md'],
        chore     => ['a-task-plan.md', 'd-implementation-plan.md', 'e-implementation-exec.md',
                      'f-testing-plan.md', 'g-testing-exec.md', 'j-retrospective.md'],
        discovery => ['a-task-plan.md', 'b-requirements-plan.md', 'c-design-plan.md',
                      'd-implementation-plan.md', 'e-implementation-exec.md',
                      'f-testing-plan.md', 'g-testing-exec.md', 'j-retrospective.md'],
    );

    return $files{$task_type} || $files{feature};
}

1;
```

## Critical Files to Modify

### Helper Scripts (Trampoline Refactoring)
**Entry Points** (~20 lines each):
- `.cig/scripts/command-helpers/status-aggregator`
- `.cig/scripts/command-helpers/template-copier`
- `.cig/scripts/command-helpers/context-inheritance`

**v2.0 Orchestration** (~50 lines each):
- `.cig/scripts/command-helpers/status-aggregator-v2.0`
- `.cig/scripts/command-helpers/template-copier-v2.0`
- `.cig/scripts/command-helpers/context-inheritance-v2.0`

**v2.1 Orchestration** (~50 lines each):
- `.cig/scripts/command-helpers/status-aggregator-v2.1`
- `.cig/scripts/command-helpers/template-copier-v2.1`
- `.cig/scripts/command-helpers/context-inheritance-v2.1`

### Core Modules (NEW)
- `.cig/lib/CIG/StatusAggregator/Core.pm`
- `.cig/lib/CIG/TemplateCopier/Core.pm`
- `.cig/lib/CIG/ContextInheritance/Core.pm`

### Version Data Modules
- `.cig/lib/CIG/WorkflowFiles/V20.pm` (extracted from WorkflowFiles.pm)
- `.cig/lib/CIG/WorkflowFiles/V21.pm` (NEW)
- `.cig/lib/CIG/WorkflowFiles.pm` (UPDATE - remove V10, keep backward compat)

### Templates (10 files - 8 renames + 2 new)
**Renames**:
- `.cig/templates/pool/a-task-plan.md.template` (was a-plan.md.template)
- `.cig/templates/pool/b-requirements-plan.md.template` (was b-requirements.md.template)
- `.cig/templates/pool/c-design-plan.md.template` (was c-design.md.template)
- `.cig/templates/pool/d-implementation-plan.md.template` (was d-implementation.md.template)
- `.cig/templates/pool/f-testing-plan.md.template` (was e-testing.md.template)
- `.cig/templates/pool/h-rollout.md.template` (was f-rollout.md.template)
- `.cig/templates/pool/i-maintenance.md.template` (was g-maintenance.md.template)
- `.cig/templates/pool/j-retrospective.md.template` (was h-retrospective.md.template)

**New**:
- `.cig/templates/pool/e-implementation-exec.md.template`
- `.cig/templates/pool/g-testing-exec.md.template`

### Symlinks (5 task types × up to 10 files)
- `.cig/templates/feature/` - Update all 10 symlinks
- `.cig/templates/bugfix/` - Update 7 symlinks
- `.cig/templates/hotfix/` - Update 7 symlinks
- `.cig/templates/chore/` - Update 6 symlinks
- `.cig/templates/discovery/` - Update 8 symlinks

### Workflow Commands (5 renames + 2 new + 3 updates)
**Renames**:
- `.claude/commands/cig-task-plan.md` (was cig-plan.md)
- `.claude/commands/cig-requirements-plan.md` (was cig-requirements.md)
- `.claude/commands/cig-design-plan.md` (was cig-design.md)
- `.claude/commands/cig-implementation-plan.md` (was cig-implementation.md)
- `.claude/commands/cig-testing-plan.md` (was cig-testing.md)

**New**:
- `.claude/commands/cig-implementation-exec.md`
- `.claude/commands/cig-testing-exec.md`

**Updates** (add blocker sections):
- `.claude/commands/cig-rollout.md`
- `.claude/commands/cig-maintenance.md`
- `.claude/commands/cig-retrospective.md`

### Documentation
- `.cig/docs/workflow/workflow-steps.md` (add 10-phase workflow, blocker framework)

### Security
- `.cig/security/script-hashes.json` (add new scripts)

**Total**: ~55 files modified/created

## Constraints

### Technical Constraints
1. **Backward Compatibility**: Tasks 1-24 must continue working with v2.0
   - Trampoline entry points detect version via "Template Version" header
   - v2.0 orchestration scripts handle 8-phase workflow
   - v2.1 orchestration scripts handle 10-phase workflow

2. **File Naming Conventions**: Sequential a-j lettering
   - Planning suffixes ("-plan") for clarity
   - Execution suffixes ("-exec") for new e and g files
   - No numeric suffixes (cleaner than d2/e2)

3. **Script Permissions**: All scripts maintain u+rx (minimum 0500)
   - Entry points: 0500
   - Orchestration scripts: 0500
   - Core modules: 0644
   - Security verification via script-hashes.json

4. **Symlink-Based Templates**: Must work with existing architecture
   - Central pool: `.cig/templates/pool/`
   - Task-type-specific: `.cig/templates/{type}/`
   - DRY principle maintained

### Integration Constraints
1. **Template Pool Structure**: Preserve symlink architecture
   - Rename existing templates in pool
   - Add new templates to pool
   - Update all symlinks in task-type directories

2. **format-detector Updates**: Use existing "Template Version" header mechanism
   - v2.0 templates: `- **Template Version**: 2.0`
   - v2.1 templates: `- **Template Version**: 2.1`
   - No file-based detection needed

3. **Security Verification**: New files integrate with script-hashes.json
   - Add hashes for 9 new orchestration/entry scripts
   - Update verification logic if needed

### Performance Constraints
1. **Trampoline Overhead**: Minimal (<50ms per invocation)
   - Entry point detection: 1 file read
   - Exec call: OS-level, no fork overhead
   - Total: <50ms additional latency

2. **status-aggregator**: Complete in <500ms for 10-file tasks
   - Efficient version detection
   - Optimized status parsing in Core module

3. **template-copier**: Complete in <1s for 10 files
   - Efficient symlink resolution
   - Batch file operations

## Validation

### Design Review Checklist
- [x] Architecture choice: Sequential a-j lettering documented
- [x] Trampoline pattern: Three-layer architecture specified
- [x] Template infrastructure: 10 files designed (8 renames + 2 new)
- [x] Workflow commands: 5 renames + 2 new + 3 updates specified
- [x] Checkpoint strategy: 9 checkpoints defined
- [x] Critical files identified: ~55 files
- [x] Verification strategy: Unit tests, integration tests, regression tests
- [x] Backward compatibility: v2.0 tasks unaffected via trampoline
- [x] All 13 FRs traceable to design decisions

### Requirements Traceability
- **FR1**: cig-implementation-exec.md and cig-testing-exec.md designed ✓
- **FR2**: e-implementation-exec.md.template and g-testing-exec.md.template designed ✓
- **FR3**: 10-phase workflow order documented ✓
- **FR4**: Blocker-driven reversion framework designed ✓
- **FR5**: Template rename strategy: sequential a-j with -plan suffix ✓
- **FR6**: Command rename strategy: -plan suffix for planning commands ✓
- **FR7**: Prominent ⚠️ PLANNING/EXECUTION PHASE notices designed ✓
- **FR8**: status-aggregator updates: trampoline architecture ✓
- **FR9**: template-copier updates: v2.1 orchestration with WorkflowFiles::V21 ✓
- **FR10**: Blocker handling sections standardized ✓
- **FR11**: 9 checkpoint commits defined ✓
- **FR12**: Trampoline architecture: three-layer design specified ✓
- **FR13**: Multi-version testing: v2.0 and v2.1 orchestration scripts ✓

### Design Trade-off Analysis

**Chosen: Sequential a-j lettering + Trampoline architecture**
- ✓ Clean naming (no numeric suffixes)
- ✓ Version isolation (v2.1 can't break v2.0)
- ✓ Future-proof (v3.0 easy to add)
- ✓ DRY via Core modules
- ✓ Clean v1.0 deprecation
- ⚠️ More files initially (18 total)
- ⚠️ Extraction effort (Core modules)
- ⚠️ Testing complexity (multi-version)

**Rejected: d2/e2 numeric suffixes + Monolithic scripts**
- ✓ Fewer files
- ✓ No extraction effort
- ❌ Confusing naming
- ❌ No version isolation
- ❌ Code duplication
- ❌ v1.0 deprecation harder

**Justification**: Expected future evolution (v3.0+) and clean architecture justify initial investment

### Backward Compatibility Verification
- Tasks 1-24 use v2.0 workflow (8 files)
- Trampoline entry points detect version via "Template Version: 2.0" header
- v2.0 orchestration scripts handle existing tasks
- v2.1 orchestration scripts handle new tasks
- No breaking changes to existing workflows

## Open Questions & Resolutions

### 1. WorkflowFiles.pm Migration
**Question**: How to handle transition in WorkflowFiles.pm?
**Resolution**: Keep WorkflowFiles.pm as thin wrapper for backward compatibility, move mappings to V20/V21 modules

### 2. format-detector Updates
**Question**: What logic to detect v2.1?
**Resolution**: Use existing "Template Version" header mechanism (more explicit than file-based detection)

### 3. Cross-References in Execution Templates
**Question**: How should e-implementation-exec.md reference planning file?
**Resolution**: Explicit reference to d-implementation-plan.md (not just "d-implementation.md")

### 4. Backward Compatibility Risk
**Question**: Will renaming e→f, f→h templates break existing tasks?
**Resolution**: No - trampoline detects v2.0 vs v2.1, uses appropriate orchestration script

## Next Steps After Design Approval

1. Update status to "Finished"
2. Proceed to `/cig-implementation-plan 25` (implementation planning)
3. Implementation plan will detail:
   - Exact code for each Core module extraction
   - Exact trampoline dispatch logic
   - Template content for e/g execution files
   - Blocker handling examples for each phase
   - Test cases for verification

## Status
**Status**: Finished
**Next Action**: Proceed to implementation planning with `/cig-implementation-plan 25`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Design complete with:
- Sequential a-j lettering architecture chosen
- Trampoline pattern fully specified (three layers)
- Template infrastructure designed (8 renames + 2 new)
- Workflow commands designed (5 renames + 2 new + 3 updates)
- 9 checkpoint commits defined
- ~55 critical files identified
- Backward compatibility via trampoline architecture
- All 13 FRs addressed

## Lessons Learned
*To be captured during retrospective*
