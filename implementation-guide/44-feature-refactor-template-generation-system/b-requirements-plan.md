# refactor template generation system - Requirements

## Task Reference
- **Task ID**: internal-44
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/44-refactor-template-generation-system
- **Template Version**: 2.1

## Goal
Define functional and non-functional specifications for refactor template generation system.

## Functional Requirements
### Core Features
- **FR1**: Template headers must include task type identifier on line 2
  - Format: `**Task**: {{taskNum}} ({{taskType}})`
  - All 10 templates (a-j) must include this header
  - Template copier must populate variables correctly
- **FR2**: Next Action fields must use task inference (no `<task>` parameter)
  - Replace hardcoded `/cig-command <task>` with `/cig-command` (inference-based)
  - Template copier must compute correct next action based on task type and current phase
  - Next action must be task-type-aware (different sequences for feature/bugfix/hotfix/chore/discovery)
- **FR3**: Cross-references must use correct v2.1 filenames
  - Fix `e-testing.md` → `e-testing-plan.md` in d-implementation-plan.md
  - Fix `b-requirements.md` → `b-requirements-plan.md` in f-implementation-exec.md
  - Fix `c-design.md` → `c-design-plan.md` in f-implementation-exec.md
  - Both exec templates (f, g) must reference both plan files (d, e)
- **FR4**: Decomposition checks must appear in planning phases only
  - Add decomposition check section to b-requirements-plan.md
  - Add decomposition check section to c-design-plan.md
  - Retain existing decomposition check in a-task-plan.md
  - Remove/omit from execution phases (d-j)
- **FR5**: Template copier must infer phase sequences from symlink structure
  - Read actual symlinks in `.cig/templates/{type}/` directories
  - Determine phase sequence dynamically (not hardcoded maps)
  - Compute next action based on discovered sequence
- **FR6**: Workflow documentation must instruct checkpoint commits
  - Add checkpoint commit instructions to all workflow phase docs
  - Instructions appear at end of each phase section
- **FR7**: `/cig-new-task` must auto-create task branch
  - Create branch after computing branch name
  - Checkout branch automatically (not just suggest)
  - Report branch creation to user
- **FR8**: `/cig-retrospective` must handle checkpoint branch and squashing
  - Create `{branch-name}-checkpoints` branch before squashing
  - Squash all task commits to single commit
  - Commit message must be brief and focus on "why" not "what"

### User Stories
- **As a** CIG user **I want** task types visible in file headers **so that** I can quickly identify what kind of task I'm working on
- **As a** CIG user **I want** next action commands to work without passing task numbers **so that** I can leverage the inference system and save typing
- **As a** developer **I want** cross-references to resolve correctly **so that** I can navigate between related workflow files
- **As a** CIG user **I want** decomposition prompts in planning phases **so that** I reconsider task size when discovering new complexity
- **As a** developer **I want** automatic checkpoint commits **so that** my work is saved incrementally without having to remember
- **As a** developer **I want** automatic branch creation **so that** I don't have to manually create branches for every task
- **As a** developer **I want** checkpoint preservation and commit squashing **so that** I have both detailed history for archaeology and clean history for review

## Non-Functional Requirements
### Performance (NFR1)
- Template generation time: < 2 seconds for all task types
- Template copier execution: < 1 second for symlink discovery and variable substitution
- No performance regression vs current system

### Usability (NFR2)
- Learning curve: No change - existing CIG users see immediate benefits
- Error recovery: Template copier errors must clearly indicate which variable/file failed
- Consistency: Follow established CIG naming conventions and file structure
- Inference transparency: Users can still pass task numbers explicitly if desired

### Maintainability (NFR3)
- Code clarity: Template copier logic must be self-documenting
- Modularity: Symlink inference separate from variable substitution
- Testability: Template generation testable with all 5 task types
- DRY principle: Single source of truth in pool directory maintained
- No hardcoded phase sequences - infer from symlinks

### Security (NFR4)
- File permissions: Maintain 0600 for generated workflow files
- No injection vulnerabilities: Template variable substitution must sanitize inputs
- Script integrity: Maintain SHA256 verification for template-copier script

### Reliability (NFR5)
- Backward compatibility: Existing tasks (1-43) continue working with old format
- Graceful degradation: If symlink discovery fails, fall back to explicit error (not silent failure)
- Data integrity: Template variable substitution must not corrupt file content
- Idempotency: Running template copier twice produces identical results

## Constraints
- **Backward Compatibility**: Cannot break existing tasks 1-43 using old template format
- **Symlink Structure**: Cannot change symlink-based template selection (task types share pool files)
- **DRY Principle**: Must maintain single source of truth in `.cig/templates/pool/`
- **Static Templates**: Templates filled once at creation, then edited manually (not dynamic)
- **Git Safety**: Checkpoint commits and squashing must not lose work or corrupt history
- **Perl Dependency**: Template copier script is Perl-based, changes must maintain Perl compatibility
- **No Breaking Changes**: All existing CIG commands must continue working

## Acceptance Criteria
- [ ] AC1: Generate test task for each type (feature/bugfix/hotfix/chore/discovery), verify headers show task type
- [ ] AC2: Generate test task, verify Next Action contains command without `<task>` parameter
- [ ] AC3: Generate test tasks, verify all cross-references resolve to correct filenames
- [ ] AC4: Verify decomposition checks appear in a-task-plan.md, b-requirements-plan.md, c-design-plan.md only
- [ ] AC5: Verify decomposition checks do NOT appear in d-j files
- [ ] AC6: Test template copier with all 5 task types, verify correct phase sequences inferred from symlinks
- [ ] AC7: Run all existing CIG commands on new task, verify backward compatibility
- [ ] AC8: Verify workflow docs include checkpoint commit instructions
- [ ] AC9: Run `/cig-new-task`, verify branch is auto-created and checked out (not just suggested)
- [ ] AC10: Run `/cig-retrospective`, verify `-checkpoints` branch created and commits squashed
- [ ] AC11: Verify squashed commit message is brief and focuses on "why"
- [ ] AC12: Verify no regressions in existing tasks 1-43

## Status
**Status**: Finished
**Next Action**: Move to design phase → `/cig-design-plan 44`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
