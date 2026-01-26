# Fix order of workflow steps - Implementation

## Task Reference
- **Task ID**: internal-29
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/29-fix-order-of-workflow-steps
- **Template Version**: 2.0

## Goal
Rename v2.1 workflow files to place test planning (e-testing-plan.md) before implementation execution (f-implementation-exec.md), and update all references across the CIG system.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

**Applied to this task**:
- **Patterns first**: Use git mv to preserve history, follow existing symlink pattern
- **Test**: Verify with new task creation + status-aggregator checks
- **Minimal impl**: Simple file swap (e↔f), no complex logic
- **Refactor green**: N/A (no code to refactor, file operations only)
- **Commit message**: Explain philosophy (test planning as thinking tool)

## Files to Modify

### Phase 1: Template Renaming (2 files + 10 symlinks)
**Template Pool**:
- `.cig/templates/pool/e-implementation-exec.md.template` → rename to `f-implementation-exec.md.template`
- `.cig/templates/pool/f-testing-plan.md.template` → rename to `e-testing-plan.md.template`

**Template Symlinks** (delete old, create new in 5 directories):
- `.cig/templates/feature/{e,f}-*.md.template` (2 symlinks)
- `.cig/templates/bugfix/{e,f}-*.md.template` (2 symlinks)
- `.cig/templates/hotfix/{e,f}-*.md.template` (2 symlinks)
- `.cig/templates/chore/{e,f}-*.md.template` (2 symlinks)
- `.cig/templates/discovery/{e,f}-*.md.template` (2 symlinks)

### Phase 2: Reference Updates (22+ files)
**Template "Next Action" Fields** (4 files):
- `.cig/templates/pool/d-implementation-plan.md.template`
- `.cig/templates/pool/e-testing-plan.md.template` (after rename)
- `.cig/templates/pool/f-implementation-exec.md.template` (after rename)
- `.cig/templates/pool/g-testing-exec.md.template`

**Perl Module** (1 file):
- `.cig/lib/CIG/WorkflowFiles/V21.pm` - 5 task type arrays

**Documentation** (3 files):
- `.cig/docs/workflow/workflow-steps.md`
- `.cig/docs/workflow/workflow-overview.md`
- `.cig/docs/workflow/blocker-patterns.md`

**Workflow Commands** (6 files):
- `.claude/commands/cig-design-plan.md`
- `.claude/commands/cig-implementation-plan.md`
- `.claude/commands/cig-implementation-exec.md`
- `.claude/commands/cig-testing-plan.md`
- `.claude/commands/cig-testing-exec.md`

### Phase 3: Migration Script (1 new file)
**New Migration Script**:
- `.cig/scripts/migrations/migrate-v21-file-order.sh` (create new)

### Phase 4: Apply Migration (2 task directories)
**Existing v2.1 Tasks**:
- `implementation-guide/25-feature-implement-v21-workflow-format-with-execution-phases/*`
- `implementation-guide/26-feature-update-cig-status-to-use-workflow-flag/*`

**Total**: ~40 files modified/created, ~4 files renamed (via git mv)

## Implementation Steps

### Step 1: Phase 1 - Template Renaming
- [ ] **1.1** Create checkpoint: `git add -A && git commit -m "Checkpoint before Task 29 template renaming"`
- [ ] **1.2** Rename pool files:
  ```bash
  cd .cig/templates/pool
  git mv e-implementation-exec.md.template temp-f.md.template
  git mv f-testing-plan.md.template e-testing-plan.md.template
  git mv temp-f.md.template f-implementation-exec.md.template
  ```
- [ ] **1.3** Update symlinks in feature/:
  ```bash
  cd .cig/templates/feature
  rm e-implementation-exec.md.template f-testing-plan.md.template
  ln -s ../pool/e-testing-plan.md.template e-testing-plan.md.template
  ln -s ../pool/f-implementation-exec.md.template f-implementation-exec.md.template
  ```
- [ ] **1.4** Update symlinks in bugfix/ (same commands as 1.3)
- [ ] **1.5** Update symlinks in hotfix/ (same commands as 1.3)
- [ ] **1.6** Update symlinks in chore/ (same commands as 1.3)
- [ ] **1.7** Update symlinks in discovery/ (same commands as 1.3)
- [ ] **1.8** Verify symlinks resolve: `ls -la .cig/templates/feature/{e,f}-*.md.template`
- [ ] **1.9** Stage symlink changes: `git add .cig/templates/*/`

### Step 2: Phase 2a - Update Template "Next Action" Fields
- [ ] **2.1** Update d-implementation-plan.md.template:
  - Find: `**Next Action**: Move to implementation execution`
  - Replace: `**Next Action**: Move to testing planning → \`/cig-testing-plan <task>\``
- [ ] **2.2** Update e-testing-plan.md.template (newly renamed):
  - Find: `**Next Action**: Move to rollout`
  - Replace: `**Next Action**: Move to implementation execution → \`/cig-implementation-exec <task>\``
- [ ] **2.3** Update f-implementation-exec.md.template (newly renamed):
  - Find: `**Next Action**: Move to testing planning`
  - Replace: `**Next Action**: Move to testing execution → \`/cig-testing-exec <task>\``
- [ ] **2.4** Verify g-testing-exec.md.template unchanged (already → `/cig-rollout`)
- [ ] **2.5** Stage template changes: `git add .cig/templates/pool/{d,e,f,g}-*.md.template`

### Step 3: Phase 2b - Update CIG::WorkflowFiles::V21 Module
- [ ] **3.1** Open `.cig/lib/CIG/WorkflowFiles/V21.pm`
- [ ] **3.2** Update feature array (line ~30):
  - Element 5: `'e-implementation-exec.md'` → `'e-testing-plan.md'`
  - Element 6: `'f-testing-plan.md'` → `'f-implementation-exec.md'`
- [ ] **3.3** Update bugfix array (line ~40):
  - Element 4: `'e-implementation-exec.md'` → `'f-implementation-exec.md'`
  - Element 5: `'f-testing-plan.md'` → `'e-testing-plan.md'`
- [ ] **3.4** Update hotfix array (line ~50):
  - Element 4: `'e-implementation-exec.md'` → `'f-implementation-exec.md'`
- [ ] **3.5** Update chore array (line ~60):
  - Element 3: `'e-implementation-exec.md'` → `'f-implementation-exec.md'`
- [ ] **3.6** Update discovery array (line ~70):
  - Element 4: `'e-implementation-exec.md'` → `'e-testing-plan.md'`
  - Element 5: `'f-testing-plan.md'` → `'f-implementation-exec.md'`
- [ ] **3.7** Stage module: `git add .cig/lib/CIG/WorkflowFiles/V21.pm`

### Step 4: Phase 2c - Update blocker-patterns.md
- [ ] **4.1** Open `.cig/docs/workflow/blocker-patterns.md`
- [ ] **4.2** Update section header (line ~120): "Implementation Execution Phase (e-implementation-exec.md)" → "(f-implementation-exec.md)"
- [ ] **4.3** Update revert reference (line ~130): "Revert to e-implementation-exec.md to fix issues" → "f-implementation-exec.md"
- [ ] **4.4** Update revert reference (line ~200): "Revert to e-implementation-exec.md" → "f-implementation-exec.md"
- [ ] **4.5** Update section header (line ~100): "Testing Planning Phase (f-testing-plan.md)" → "(e-testing-plan.md)"
- [ ] **4.6** Update revert reference (line ~110): "Revert to f-testing-plan.md to adjust strategy" → "e-testing-plan.md"
- [ ] **4.7** Stage: `git add .cig/docs/workflow/blocker-patterns.md`

### Step 5: Phase 2d - Update Workflow Command Content
- [ ] **5.1** Update `.claude/commands/cig-design-plan.md`:
  - Find: "Implementation (that's d-implementation-plan + e-implementation-exec)"
  - Replace: "Implementation (that's d-implementation-plan + f-implementation-exec)"
- [ ] **5.2** Update `.claude/commands/cig-implementation-plan.md`:
  - Find: "Writing code (that's e-implementation-exec)"
  - Replace: "Writing code (that's f-implementation-exec)"
  - Find: "**Primary**: Move to implementation execution → `/cig-implementation-exec`"
  - Replace: "**Primary**: Move to testing planning → `/cig-testing-plan`"
- [ ] **5.3** Update `.claude/commands/cig-testing-plan.md`:
  - Find: "**Primary**: Move to rollout → `/cig-rollout`"
  - Replace: "**Primary**: Move to implementation execution → `/cig-implementation-exec`"
- [ ] **5.4** Update `.claude/commands/cig-implementation-exec.md` (4 references):
  - Find: "document actual results in e-implementation-exec.md"
  - Replace: "document actual results in f-implementation-exec.md"
  - Find: "--current-step=e-implementation-exec"
  - Replace: "--current-step=f-implementation-exec"
  - Find: "Open and work with the execution file (e-implementation-exec.md)"
  - Replace: "...f-implementation-exec.md"
  - Find: "Execution file (e-implementation-exec.md) opened"
  - Replace: "...f-implementation-exec.md"
- [ ] **5.5** Update `.claude/commands/cig-testing-exec.md` (2 references):
  - Find: "Planning tests (that's f-testing-plan)"
  - Replace: "Planning tests (that's e-testing-plan)"
  - Find: "fixing bugs (that's e-implementation-exec)"
  - Replace: "fixing bugs (that's f-implementation-exec)"
- [ ] **5.6** Stage: `git add .claude/commands/cig-*.md`

### Step 6: Phase 2e - Update Workflow Documentation
- [ ] **6.1** Update `.cig/docs/workflow/workflow-steps.md`:
  - Find: "**v2.1 Format** (10 phases): v2.0 phases + e-implementation-exec, g-testing-exec"
  - Replace: "**v2.1 Format** (10 phases): v2.0 phases + e-testing-plan, f-implementation-exec, g-testing-exec (note: e and f swapped from v2.0 order)"
  - Find: "**File**: `e-implementation-exec.md` (v2.1 only)"
  - Replace: "**File**: `f-implementation-exec.md` (v2.1 only)"
  - Find: "**File**: `f-testing-plan.md` (v2.0 and v2.1)"
  - Replace: "**File**: `e-testing-plan.md` (v2.1 - moved from f position) OR `f-testing-plan.md` (v2.0 only)"
  - Add philosophy section explaining test planning as thinking tool
- [ ] **6.2** Update `.cig/docs/workflow/workflow-overview.md`:
  - Update workflow sequence list to show correct order
  - Add philosophy explanation about test planning
- [ ] **6.3** Stage: `git add .cig/docs/workflow/workflow-*.md`

### Step 7: Phase 2f - Comprehensive Verification
- [ ] **7.1** Run grep to verify no remaining old references:
  ```bash
  grep -r "e-implementation-exec" --include="*.md" --include="*.pl" --include="*.pm" .cig/ .claude/ BACKLOG.md CLAUDE.md README.md
  ```
  - Expected: Only matches in this implementation plan and BACKLOG (documenting old problem)
- [ ] **7.2** Run grep for f-testing-plan:
  ```bash
  grep -r "f-testing-plan" --include="*.md" --include="*.pl" --include="*.pm" .cig/ .claude/ BACKLOG.md CLAUDE.md README.md
  ```
  - Expected: Only matches in workflow-steps.md (v2.0 reference) and this plan/BACKLOG
- [ ] **7.3** Commit Phase 1 + Phase 2: `git commit -m "Task 29: Fix v2.1 workflow file order (templates + references)"`

### Step 8: Phase 3 - Create Migration Script
- [ ] **8.1** Create directory: `mkdir -p .cig/scripts/migrations`
- [ ] **8.2** Create `.cig/scripts/migrations/migrate-v21-file-order.sh`:
  ```bash
  #!/usr/bin/env bash
  # Migrates existing v2.1 tasks to new file order
  set -euo pipefail

  TASK_DIR="$1"

  if [[ ! -d "$TASK_DIR" ]]; then
      echo "Error: Task directory not found: $TASK_DIR" >&2
      exit 1
  fi

  if [[ ! -f "$TASK_DIR/e-implementation-exec.md" ]]; then
      echo "Error: Not a v2.1 task (e-implementation-exec.md not found)" >&2
      exit 1
  fi

  cd "$TASK_DIR"
  git mv e-implementation-exec.md temp-f.md
  git mv f-testing-plan.md e-testing-plan.md
  git mv temp-f.md f-implementation-exec.md

  echo "Migration complete for $TASK_DIR"
  ```
- [ ] **8.3** Set permissions: `chmod +x .cig/scripts/migrations/migrate-v21-file-order.sh`
- [ ] **8.4** Update `.cig/security/script-hashes.json` with new script hash
- [ ] **8.5** Stage: `git add .cig/scripts/migrations/ .cig/security/script-hashes.json`
- [ ] **8.6** Commit: `git commit -m "Task 29: Add v2.1 migration script"`

### Step 9: Phase 4 - Migrate Existing Tasks
- [ ] **9.1** Test migration on Task 25:
  ```bash
  .cig/scripts/migrations/migrate-v21-file-order.sh implementation-guide/25-feature-implement-v21-workflow-format-with-execution-phases
  ```
- [ ] **9.2** Verify Task 25 files renamed correctly: `ls implementation-guide/25-*/{e,f}-*.md`
- [ ] **9.3** Run migration on Task 26:
  ```bash
  .cig/scripts/migrations/migrate-v21-file-order.sh implementation-guide/26-feature-update-cig-status-to-use-workflow-flag
  ```
- [ ] **9.4** Verify Task 26 files renamed correctly
- [ ] **9.5** Commit: `git commit -m "Task 29: Migrate Tasks 25 and 26 to new file order"`

### Step 10: Validation
- [ ] **10.1** Create new test task to verify template-copier:
  ```bash
  /cig-new-task 30 feature "test-v21-file-order"
  ```
- [ ] **10.2** Verify files created with correct names: `ls implementation-guide/30-*/e-testing-plan.md implementation-guide/30-*/f-implementation-exec.md`
- [ ] **10.3** Run status-aggregator on test task:
  ```bash
  .cig/scripts/command-helpers/status-aggregator --workflow 30
  ```
  - Expected: Recognizes all 10 files in correct order
- [ ] **10.4** Clean up test task: `rm -rf implementation-guide/30-*`
- [ ] **10.5** Verify workflow commands suggest correct next steps (manual check via /cig-implementation-plan, /cig-testing-plan)

## Test Coverage
**See f-testing-plan.md for complete test plan**

Quick verification tests:
- New task creation produces correct file names (e-testing-plan, f-implementation-exec)
- status-aggregator recognizes all 10 files
- Symlinks resolve correctly
- V21 module arrays match new order
- No grep matches for old file names (except docs explaining change)

## Validation Criteria
**See f-testing-plan.md for detailed validation criteria**

Success indicators:
- ✅ Template pool files renamed (git log shows renames)
- ✅ All symlinks resolve correctly (ls -la verification)
- ✅ V21 module updated (all 5 task types)
- ✅ Zero grep matches for old names (excluding docs/plans)
- ✅ Tasks 25 and 26 migrated successfully
- ✅ New task creates files in correct order
- ✅ status-aggregator recognizes new file order

## Status
**Status**: Finished
**Next Action**: Move to testing planning → `/cig-testing-plan 29`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled during f-implementation-exec*

## Lessons Learned
*To be captured during implementation*
