# Fix order of workflow steps - Design

## Task Reference
- **Task ID**: internal-29
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/29-fix-order-of-workflow-steps
- **Template Version**: 2.0

## Goal
Define the file renaming strategy, component update approach, and migration script design for fixing v2.1 workflow file order.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

**Applied to this task**:
1. **Testability**: Can verify correct order via new task creation + status-aggregator checks
2. **Readability**: File names match logical workflow order (e-testing-plan before f-implementation-exec)
3. **Consistency**: All task types use same naming convention
4. **Simplicity**: Simple file swap (e↔f), no complex logic needed
5. **Reversibility**: Git revert available, migration script can be reversed

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions

### Architecture Choice: Atomic File Swap
- **Decision**: Rename files atomically in git (mv + commit), not gradual migration
- **Rationale**:
  - Only 2 files involved (e, f) makes atomic swap simple
  - Gradual migration would create confusion (which tasks use old/new names?)
  - Git tracks renames automatically, preserving history
- **Trade-offs**:
  - ✅ **Pro**: Clean break, no ambiguity about which naming is current
  - ✅ **Pro**: Git mv preserves file history
  - ✅ **Pro**: Single commit for all changes (atomic)
  - ❌ **Con**: Breaks existing v2.1 tasks (Tasks 25, 26) - mitigated by migration script

### Migration Strategy: Script-Based Batch Rename
- **Decision**: Create Bash migration script that renames files in existing task directories
- **Rationale**:
  - Only 2 tasks affected (Tasks 25, 26) - simple enough for script
  - Script documents transformation for future reference
  - Can be tested on Task 25 before running on Task 26
  - Preserves git history via git mv
- **Trade-offs**:
  - ✅ **Pro**: Safer than manual renaming (repeatable, testable)
  - ✅ **Pro**: Documents the transformation
  - ✅ **Pro**: Can be rolled back (git revert the migration commit)
  - ❌ **Con**: Requires separate migration commit after template changes

## System Design

### Component Overview

**Component 1: Template Pool Files**
- **Location**: `.cig/templates/pool/`
- **Action**: Rename 2 files via git mv
  - `e-implementation-exec.md.template` → `f-implementation-exec.md.template`
  - `f-testing-plan.md.template` → `e-testing-plan.md.template`
- **Responsibility**: Single source of truth for template content

**Component 2: Template Symlinks**
- **Locations**: `.cig/templates/{feature,bugfix,hotfix,chore,discovery}/`
- **Action**: Update symlinks to point to renamed files
  - Delete old symlinks: `e-implementation-exec.md.template`, `f-testing-plan.md.template`
  - Create new symlinks: `e-testing-plan.md.template` → `../pool/e-testing-plan.md.template`, etc.
- **Responsibility**: Task-type-specific template sets

**Component 3: template-copier Script**
- **Location**: `.cig/scripts/command-helpers/template-copier`
- **Action**: No changes needed (uses symlinks, symlinks updated)
- **Responsibility**: Copies templates via symlink resolution

**Component 4: status-aggregator-v2.1 Script**
- **Location**: `.cig/scripts/command-helpers/status-aggregator-v2.1`
- **Action**: Update file recognition array
  - Array currently: `@v21_files = qw(a b c d e f g h i j)`
  - No change to array, but internal logic expects e=testing, f=implementation now
- **Verification needed**: Check if script has hardcoded file name expectations
- **Responsibility**: Aggregates status across workflow files

**Component 5: Template "Next Action" Fields**
- **Location**: Status sections in all 10 template files
- **Action**: Update 4 templates:
  - `d-implementation-plan.md.template`: Next → `/cig-testing-plan <task>`
  - `e-testing-plan.md.template` (newly renamed): Next → `/cig-implementation-exec <task>`
  - `f-implementation-exec.md.template` (newly renamed): Next → `/cig-testing-exec <task>`
  - `g-testing-exec.md.template`: No change (already → `/cig-rollout`)
- **Responsibility**: Guide users through correct workflow progression

**Component 6: Workflow Command Files**
- **Location**: `.claude/commands/cig-*.md`
- **Action**: Update next step suggestions in 4 commands:
  - `cig-implementation-plan.md`: Suggest `/cig-testing-plan` next
  - `cig-testing-plan.md`: Suggest `/cig-implementation-exec` next
  - `cig-implementation-exec.md`: Suggest `/cig-testing-exec` next
  - `cig-testing-exec.md`: Suggest `/cig-rollout` next
- **Responsibility**: Guide LLM through correct workflow

**Component 7: Documentation**
- **Location**: `.cig/docs/workflow/`
- **Action**: Update 2 docs:
  - `workflow-steps.md`: Reflect new order, add philosophy explanation
  - `workflow-overview.md`: Update sequence diagram/list
- **Responsibility**: Document correct workflow order

**Component 8: CIG::WorkflowFiles::V21 Perl Module**
- **Location**: `.cig/lib/CIG/WorkflowFiles/V21.pm`
- **Action**: Update file arrays in all 5 task type definitions
  - Feature: Update array element 5 from 'e-implementation-exec.md' to 'e-testing-plan.md', element 6 from 'f-testing-plan.md' to 'f-implementation-exec.md'
  - Bugfix: Same updates (elements 4 and 5 in bugfix array)
  - Hotfix: Update 'e-implementation-exec.md' to 'f-implementation-exec.md'
  - Chore: Update 'e-implementation-exec.md' to 'f-implementation-exec.md'
  - Discovery: Update arrays (elements 4 and 5)
- **Verification**: This module defines canonical v2.1 file lists
- **Responsibility**: Defines v2.1 workflow structure for template-copier and other scripts

**Component 9: blocker-patterns.md References**
- **Location**: `.cig/docs/workflow/blocker-patterns.md`
- **Action**: Update 5 references:
  - Section header: "Implementation Execution Phase (e-implementation-exec.md)" → "Implementation Execution Phase (f-implementation-exec.md)"
  - "Revert to e-implementation-exec.md to fix issues" → "Revert to f-implementation-exec.md to fix issues"
  - "If critical issues found: Revert to e-implementation-exec.md" → "Revert to f-implementation-exec.md"
  - Section header: "Testing Planning Phase (f-testing-plan.md)" → "Testing Planning Phase (e-testing-plan.md)"
  - "Revert to f-testing-plan.md to adjust strategy" → "Revert to e-testing-plan.md to adjust strategy"
- **Responsibility**: Document blocker patterns per workflow phase

**Component 10: Workflow Command Content References**
- **Locations**: Multiple command files
- **Action**: Update inline references in command content:
  - `cig-design-plan.md`: "Implementation (that's d-implementation-plan + e-implementation-exec)" → "...+ f-implementation-exec)"
  - `cig-implementation-plan.md`: "Writing code (that's e-implementation-exec)" → "...f-implementation-exec)"
  - `cig-implementation-exec.md`:
    - "Execute the implementation steps from d-implementation-plan.md and document actual results in e-implementation-exec.md" → "...in f-implementation-exec.md"
    - "--current-step=e-implementation-exec" → "--current-step=f-implementation-exec"
    - "Open and work with the execution file (e-implementation-exec.md)" → "...f-implementation-exec.md"
    - "Execution file (e-implementation-exec.md) opened" → "...f-implementation-exec.md"
  - `cig-testing-exec.md`: "Planning tests (that's f-testing-plan)" → "...e-testing-plan)"
  - `cig-testing-exec.md`: "fixing bugs (that's e-implementation-exec)" → "...f-implementation-exec)"
- **Responsibility**: Provide accurate inline documentation in commands

**Component 11: Migration Script**
- **Location**: `.cig/scripts/migrations/migrate-v21-file-order.sh` (new)
- **Action**: Rename files in existing v2.1 task directories
  - Find tasks with v2.1 format (check for presence of e-implementation-exec.md)
  - Use git mv to rename: e→f, f→e
  - Update "Next Action" fields in affected files
- **Responsibility**: Migrate existing Tasks 25, 26 to new naming

### Data Flow

**Phase 1: Template Renaming**
```
1. Rename pool files (git mv e→f, f→e)
2. Update symlinks in all 5 task type directories
3. Verify symlinks resolve correctly
```

**Phase 2: Reference Updates**
```
1. Update "Next Action" in 4 template files (d, e-new, f-new, g)
2. Update next step suggestions in 4 command files
3. Update CIG::WorkflowFiles::V21 module (5 task type arrays)
4. Update blocker-patterns.md (5 references)
5. Update workflow command content (6 commands, ~10 inline references)
6. Update 2 workflow documentation files (workflow-steps.md, workflow-overview.md)
7. Comprehensive grep verification: no remaining references to old names
```

**Phase 3: Migration**
```
1. Create migration script
2. Test on Task 25 directory
3. Verify Task 25 workflow files renamed correctly
4. Run on Task 26 directory
5. Verify status-aggregator recognizes new file names
```

**Phase 4: Validation**
```
1. Create new test task with template-copier
2. Verify files created with correct names (e=testing, f=implementation)
3. Walk through workflow: plan → requirements → design → implementation → testing (e) → exec impl (f) → exec test (g)
4. Verify "Next Action" progression correct
```

## Interface Design

### Migration Script Interface
```bash
#!/usr/bin/env bash
# .cig/scripts/migrations/migrate-v21-file-order.sh
#
# Migrates existing v2.1 tasks to new file order (e-testing-plan, f-implementation-exec)
#
# Usage: ./migrate-v21-file-order.sh <task-directory>
# Example: ./migrate-v21-file-order.sh implementation-guide/25-feature-...

set -euo pipefail

TASK_DIR="$1"

# Validate task directory exists and has v2.1 format
if [[ ! -d "$TASK_DIR" ]]; then
    echo "Error: Task directory not found: $TASK_DIR" >&2
    exit 1
fi

if [[ ! -f "$TASK_DIR/e-implementation-exec.md" ]]; then
    echo "Error: Not a v2.1 task (e-implementation-exec.md not found)" >&2
    exit 1
fi

# Rename files using git mv (preserves history)
cd "$TASK_DIR"
git mv e-implementation-exec.md temp-f.md
git mv f-testing-plan.md e-testing-plan.md
git mv temp-f.md f-implementation-exec.md

# Update "Next Action" references in affected files
sed -i 's|/cig-implementation-exec|/cig-testing-plan|g' d-implementation-plan.md
sed -i 's|/cig-rollout|/cig-implementation-exec|g' e-testing-plan.md
sed -i 's|/cig-testing-exec|/cig-testing-exec|g' f-implementation-exec.md

echo "Migration complete for $TASK_DIR"
```

### File Naming Convention (After Fix)
```
v2.1 Workflow Files:
a-task-plan.md           → Plan the task
b-requirements-plan.md   → Define requirements
c-design-plan.md         → Design architecture
d-implementation-plan.md → Plan implementation steps
e-testing-plan.md        → Plan tests (NEW POSITION)
f-implementation-exec.md → Execute implementation (NEW POSITION)
g-testing-exec.md        → Execute tests
h-rollout.md             → Deploy
i-maintenance.md         → Maintain
j-retrospective.md       → Reflect
```

### Symlink Structure (After Fix)
```
.cig/templates/feature/
  e-testing-plan.md.template → ../pool/e-testing-plan.md.template
  f-implementation-exec.md.template → ../pool/f-implementation-exec.md.template

.cig/templates/bugfix/
  (same, subset of files)

.cig/templates/hotfix/
  (same, subset of files)

... etc for chore, discovery
```

## Constraints

**Technical Constraints**:
- Must use git mv to preserve file history
- Symlinks must use relative paths (../pool/)
- Migration script must be idempotent (safe to run multiple times)
- status-aggregator-v2.1 must recognize both old and new names during transition (NO - clean break)

**Backward Compatibility**:
- v2.0 tasks (8-file format) unaffected - no e/f files in v2.0
- v1.0 tasks unaffected - use different naming convention
- Only v2.1 tasks (Tasks 25, 26) affected

**Philosophy Constraint**:
- Test planning is a **thinking tool**, not traditional TDD
- File order must reflect: plan tests → understand feasibility → execute implementation
- Documentation must explain "why" (cognitive benefit) not just "what" (new order)

## Validation

- [ ] Template pool files renamed successfully (git mv shows renames)
- [ ] All symlinks updated and resolve correctly (ls -la verification)
- [ ] CIG::WorkflowFiles::V21 module updated (all 5 task type arrays)
- [ ] template-copier creates new tasks with correct file names
- [ ] status-aggregator-v2.1 recognizes all 10 files in correct order
- [ ] "Next Action" references correct in all 4 affected templates
- [ ] Next step suggestions correct in all 4 workflow commands
- [ ] Inline content references updated in all 6 workflow commands
- [ ] blocker-patterns.md updated (5 references)
- [ ] workflow-steps.md updated with new order and philosophy
- [ ] workflow-overview.md updated with correct sequence
- [ ] Comprehensive grep shows zero remaining old references
- [ ] Migration script tested on Task 25
- [ ] Tasks 25 and 26 migrated successfully
- [ ] New test task created and workflow progression verified

## Status
**Status**: Finished
**Next Action**: Move to implementation planning → `/cig-implementation-plan 29`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
