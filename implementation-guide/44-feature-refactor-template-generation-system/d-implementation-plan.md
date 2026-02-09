# refactor template generation system - Implementation

## Task Reference
- **Task ID**: internal-44
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/44-refactor-template-generation-system
- **Template Version**: 2.1

## Goal
Implement refactor template generation system following the approved design and requirements.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Files to Modify
### Phase 1: Template Content (10 files)
- `.cig/templates/pool/a-task-plan.md.template` - Add task type header, update Next Action to use `{{nextAction}}`
- `.cig/templates/pool/b-requirements-plan.md.template` - Add task type header, add decomposition check, update Next Action
- `.cig/templates/pool/c-design-plan.md.template` - Add task type header, add decomposition check, update Next Action
- `.cig/templates/pool/d-implementation-plan.md.template` - Add task type header, fix cross-references (`e-testing-plan.md`), update Next Action
- `.cig/templates/pool/e-testing-plan.md.template` - Add task type header, update Next Action
- `.cig/templates/pool/f-implementation-exec.md.template` - Add task type header, fix cross-references (both plan files), update Next Action
- `.cig/templates/pool/g-testing-exec.md.template` - Add task type header, add cross-references (both plan files), update Next Action
- `.cig/templates/pool/h-rollout.md.template` - Add task type header, update Next Action
- `.cig/templates/pool/i-maintenance.md.template` - Add task type header, update Next Action
- `.cig/templates/pool/j-retrospective.md.template` - Add task type header, update Next Action

### Phase 2: Template Copier Logic (1 file)
- `.cig/scripts/command-helpers/template-copier-v2.1` - Add symlink-based inference and next-action computation

### Phase 3: Git Workflow Automation (3 files)
- `.cig/docs/workflow/workflow-steps.md` - Add checkpoint commit instructions to all phase sections
- `.claude/commands/cig-new-task.md` - Add auto-branch creation after template copier
- `.claude/commands/cig-retrospective.md` - Add checkpoints branch creation and commit squashing

## Implementation Steps
### Phase 1: Template Content Updates
#### Step 1.1: Update Template Headers (all 10 templates)
- [ ] Add line 2 to each template: `**Task**: {{taskNum}} ({{taskType}})`
- [ ] Verify formatting: header on line 1, task info on line 2, blank line, then Task Reference section

#### Step 1.2: Update Next Action Fields (all 10 templates)
- [ ] Replace hardcoded `/cig-command <task>` with `{{nextAction}}` variable
- [ ] Remove `<task>` parameter from all next action commands
- [ ] Verify consistent format: `**Next Action**: {{nextAction}}`

#### Step 1.3: Fix Cross-References
- [ ] d-implementation-plan.md: Change `e-testing.md` → `e-testing-plan.md` (2 occurrences)
- [ ] f-implementation-exec.md: Change `b-requirements.md` → `b-requirements-plan.md`
- [ ] f-implementation-exec.md: Change `c-design.md` → `c-design-plan.md`
- [ ] f-implementation-exec.md: Update Goal and Execution Checklist to reference both plan files (d, e)
- [ ] g-testing-exec.md: Update Goal and Execution Checklist to reference both plan files (d, e)

#### Step 1.4: Add Decomposition Checks
- [ ] b-requirements-plan.md: Add decomposition check section after Constraints
- [ ] c-design-plan.md: Add decomposition check section after Constraints
- [ ] Verify a-task-plan.md retains existing decomposition check
- [ ] Verify d-j templates do NOT have decomposition checks

### Phase 2: Template Copier Enhancement
#### Step 2.1: Add New Template Variables
- [ ] Add `taskNum` variable to `compute_variables()` function
- [ ] Add `taskType` variable to `compute_variables()` function
- [ ] Add `nextAction` variable computed via new function

#### Step 2.2: Implement Symlink-Based Sequence Inference
- [ ] Add `get_phase_sequence()` function to read symlinks from task-type directory
- [ ] Extract phase letters from discovered symlink filenames
- [ ] Return sorted array of phase letters

#### Step 2.3: Implement Next-Action Computation
- [ ] Add phase-to-command mapping hash: `%PHASE_COMMANDS`
- [ ] Add `compute_next_action($task_type, $template_file)` function
- [ ] Extract current phase letter from template filename
- [ ] Call `get_phase_sequence()` to get sequence for task type
- [ ] Find current phase index in sequence
- [ ] Get next phase from sequence, map to command
- [ ] Return formatted next action or "Task complete"

#### Step 2.4: Update Variable Substitution
- [ ] Call `compute_next_action()` in `compute_variables()`
- [ ] Add `nextAction` to `%vars` hash
- [ ] Verify all variables populated correctly

### Phase 3: Git Workflow Automation
#### Step 3.1: Add Checkpoint Commit Instructions
- [ ] Update `.cig/docs/workflow/workflow-steps.md` for all 8 phase sections
- [ ] Add instruction at end of each phase: "Create checkpoint commit: `git add <files> && git commit -m 'Task N: Complete <phase> phase'`"
- [ ] Include Co-developed-by trailer in example

#### Step 3.2: Auto-Branch Creation in cig-new-task
- [ ] Locate branch name computation in `/cig-new-task` skill
- [ ] After template copier succeeds, add: `git checkout -b "$BRANCH_NAME"`
- [ ] Update output to report branch created (not just suggested)
- [ ] Handle error if branch already exists

#### Step 3.3: Checkpoints Branch and Squashing in cig-retrospective
- [ ] After retrospective doc complete, add: `git branch "$(git rev-parse --abbrev-ref HEAD)-checkpoints"`
- [ ] Add interactive rebase: `git rebase -i <base-commit>`
- [ ] Guide user to squash all task commits
- [ ] Guide user to write brief "why"-focused commit message
- [ ] Verify checkpoints branch preserves all commits

## Code Changes
### Template Header (Before)
```markdown
# {{description}} - Plan

## Task Reference
```

### Template Header (After)
```markdown
# {{description}} - Plan
**Task**: {{taskNum}} ({{taskType}})

## Task Reference
```

### Next Action Field (Before)
```markdown
**Next Action**: Begin requirements analysis
```

### Next Action Field (After)
```markdown
**Next Action**: {{nextAction}}
```

### Cross-Reference (Before - d-implementation-plan.md)
```markdown
## Test Coverage
**See e-testing.md for complete test plan**
```

### Cross-Reference (After - d-implementation-plan.md)
```markdown
## Test Coverage
**See e-testing-plan.md for complete test plan**
```

### Template Copier - New Functions (Perl)
```perl
# Get phase sequence from symlinks
sub get_phase_sequence {
    my ($templates_dir, $task_type) = @_;
    my $type_dir = "$templates_dir/$task_type";

    opendir(my $dh, $type_dir) or return ();
    my @phases;

    while (my $file = readdir($dh)) {
        next unless $file =~ /^([a-j])-.*\.template$/;
        push @phases, $1;
    }

    closedir($dh);
    return sort @phases;  # Returns ('a', 'b', 'c', ...) or ('a', 'c', 'd', ...)
}

# Compute next action based on phase and task type
sub compute_next_action {
    my ($task_type, $template_file) = @_;

    my ($phase) = $template_file =~ /^([a-j])-/;
    return "Begin next phase" unless $phase;

    my @sequence = get_phase_sequence($templates_dir, $task_type);
    return "Unknown task type" unless @sequence;

    # Find current index
    my $idx;
    for my $i (0..$#sequence) {
        if ($sequence[$i] eq $phase) {
            $idx = $i;
            last;
        }
    }

    # Last phase
    return "Task complete → /cig-retrospective" if $idx >= $#sequence;

    # Get next phase and map to command
    my $next_phase = $sequence[$idx + 1];
    my %commands = (
        'a' => '/cig-requirements-plan',
        'b' => '/cig-design-plan',
        'c' => '/cig-implementation-plan',
        'd' => '/cig-testing-plan',
        'e' => '/cig-implementation-exec',
        'f' => '/cig-testing-exec',
        'g' => '/cig-rollout',
        'h' => '/cig-maintenance',
        'i' => '/cig-retrospective',
    );

    return $commands{$next_phase} || "Unknown next phase";
}
```

### Git Workflow - Auto-Branch Creation (Bash)
```bash
# In /cig-new-task skill, after template-copier-v2.1 succeeds
git checkout -b "$BRANCH_NAME"
echo "✓ Branch created and checked out: $BRANCH_NAME"
```

### Git Workflow - Checkpoints Branch (Bash)
```bash
# In /cig-retrospective skill, after retrospective doc complete
git branch "$(git rev-parse --abbrev-ref HEAD)-checkpoints"
echo "✓ Checkpoints branch created for archaeology"
echo "Now squash commits via: git rebase -i <base-commit>"
```

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

### Phase 1 Validation (Template Content)
- [ ] All 10 templates have task type header on line 2
- [ ] All Next Action fields use `{{nextAction}}` variable
- [ ] All cross-references use correct v2.1 filenames
- [ ] Decomposition checks present in a, b, c only
- [ ] No decomposition checks in d-j templates

### Phase 2 Validation (Template Copier)
- [ ] Generate test task for each type (feature/bugfix/hotfix/chore/discovery)
- [ ] Verify `get_phase_sequence()` returns correct sequence for each type
- [ ] Verify `compute_next_action()` returns correct command for each phase
- [ ] Verify template variables populated: `{{taskNum}}`, `{{taskType}}`, `{{nextAction}}`
- [ ] Verify next actions are task-type-aware (different per type)

### Phase 3 Validation (Git Workflow)
- [ ] Workflow docs include checkpoint commit instructions
- [ ] `/cig-new-task` creates and checks out branch automatically
- [ ] `/cig-retrospective` creates checkpoints branch before squashing
- [ ] Squashed commit message is brief and focuses on "why"
- [ ] Checkpoints branch preserves all detailed commits

### Integration Validation
- [ ] Run all CIG commands with new template format (no regressions)
- [ ] Verify existing tasks 1-43 still work (backward compatibility)
- [ ] Verify Task 44 progresses through workflow correctly
- [ ] Verify all 12 acceptance criteria from requirements phase met

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
**Next Action**: Move to testing planning → `/cig-testing-plan 44`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
