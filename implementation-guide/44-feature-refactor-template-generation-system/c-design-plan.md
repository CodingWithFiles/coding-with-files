# refactor template generation system - Design

## Task Reference
- **Task ID**: internal-44
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/44-refactor-template-generation-system
- **Template Version**: 2.1

## Goal
Define architecture and design decisions for refactor template generation system.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice
- **Decision**: Three-component architecture - (1) Static template content, (2) Dynamic template copier with symlink inference, (3) Skill-based git workflow automation
- **Rationale**:
  - Separates concerns: template content (what), copier logic (how), git workflow (when)
  - Maintains DRY: symlinks define phase sequences (single source of truth)
  - Preserves simplicity: templates are static files filled once, not dynamic documents
  - Enables independent evolution: can update templates without changing copier logic
- **Trade-offs**:
  - ✓ Benefits: Simple, testable, maintains backward compatibility, leverages existing symlink structure
  - ✗ Drawbacks: Requires coordinated changes across 3 components for complete feature

### Implementation Strategy
- **Phase 1**: Template Content Changes (10 pool templates)
  - Headers, cross-references, decomposition checks, variable placeholders
  - No logic changes, just content updates
- **Phase 2**: Template Copier Logic (Perl script enhancement)
  - Symlink-based sequence inference
  - Dynamic next-action computation
  - New template variable substitution
- **Phase 3**: Git Workflow Automation (3 skills)
  - Checkpoint commit instructions in workflow docs
  - Auto-branch creation in `/cig-new-task`
  - Checkpoint preservation and squashing in `/cig-retrospective`

## System Design
### Component Overview
- **Template Pool (`.cig/templates/pool/*.template`)**: 10 source templates (a-j phases)
  - Single source of truth for all template content
  - Contains variable placeholders: `{{taskNum}}`, `{{taskType}}`, `{{nextAction}}`
  - Shared across all task types via symlinks
- **Symlink Directories (`.cig/templates/{type}/`)**: Task-type-specific phase selection
  - feature: 10 symlinks (a-j)
  - bugfix: 7 symlinks (a,c,d,e,f,g,j)
  - hotfix: 7 symlinks (a,d,e,f,g,h,j)
  - chore: 7 symlinks (a,d,e,f,g,j)
  - discovery: 8 symlinks (a,b,c,d,e,f,g,j)
  - Defines phase sequences (single source of truth)
- **Template Copier (`template-copier-v2.1`)**: Perl script for template instantiation
  - Discovers templates via symlink traversal
  - Infers phase sequences from discovered symlinks
  - Computes next-action based on current phase + task type
  - Substitutes template variables
  - Creates destination files with 0600 permissions
- **Workflow Skills**: CIG commands for user interaction
  - `/cig-new-task`: Creates task directory, invokes template copier, auto-creates git branch
  - `/cig-task-plan`, `/cig-requirements-plan`, etc: Guide through phases, instruct checkpoint commits
  - `/cig-retrospective`: Creates checkpoints branch, squashes commits, generates "why"-focused message

### Data Flow
#### Template Generation Flow (FR1-FR5)
1. User runs `/cig-new-task <num> <type> "description"`
2. Skill computes task directory path and branch name
3. Skill invokes `template-copier-v2.1 --task-type=<type> --destination=<path> --task-num=<num> --description=<desc>`
4. Template copier discovers symlinks in `.cig/templates/<type>/`
5. Template copier reads pool files via symlink resolution
6. Template copier infers phase sequence from discovered symlinks
7. Template copier computes next-action for each template based on phase + type
8. Template copier substitutes variables: `{{taskNum}}`, `{{taskType}}`, `{{nextAction}}`
9. Template copier writes files to destination with 0600 permissions
10. Skill creates git branch: `git checkout -b <type>/<num>-<slug>`
11. Skill reports completion with file list and branch name

#### Workflow Execution Flow (FR6-FR8)
1. User works through workflow phases using skills (`/cig-task-plan 44`, etc)
2. Each workflow skill guides user through phase-specific content
3. At end of phase, skill instructs checkpoint commit
4. User creates checkpoint commit: `git commit -m "Task N: Complete <phase> phase"`
5. User progresses to retrospective phase
6. `/cig-retrospective` creates checkpoints branch: `git branch "$(git rev-parse --abbrev-ref HEAD)-checkpoints"`
7. `/cig-retrospective` squashes commits via interactive rebase
8. `/cig-retrospective` generates brief "why"-focused commit message
9. Final commit preserves detailed checkpoints in `-checkpoints` branch

## Interface Design
### Template Variables
New variables for template substitution:
```perl
$vars{taskNum} = $params->{task_num};      # e.g., "44", "1.2.3"
$vars{taskType} = $params->{task_type};    # e.g., "feature", "bugfix"
$vars{nextAction} = compute_next_action(   # e.g., "Move to design → /cig-design-plan"
    $params->{task_type},
    $template_filename
);
```

### Template Copier Functions
```perl
# Infer phase sequence from symlinks
sub get_phase_sequence {
    my ($templates_dir, $task_type) = @_;
    # Read symlinks in .cig/templates/{task_type}/
    # Extract phase letters (a-j) from filenames
    # Return sorted array: ['a', 'b', 'c', ...] or ['a', 'c', 'd', ...]
}

# Compute next action based on current phase and task type
sub compute_next_action {
    my ($task_type, $current_template_file) = @_;
    # Extract phase letter from filename: "a-task-plan.md.template" → "a"
    # Get sequence: get_phase_sequence($templates_dir, $task_type)
    # Find current index in sequence
    # Get next phase from sequence[index + 1]
    # Map phase letter to command: 'b' → '/cig-requirements-plan'
    # Return formatted next action or "Task complete → /cig-retrospective"
}

# Phase-to-command mapping
my %PHASE_COMMANDS = (
    'a' => '/cig-requirements-plan',
    'b' => '/cig-design-plan',
    'c' => '/cig-implementation-plan',
    'd' => '/cig-testing-plan',
    'e' => '/cig-implementation-exec',
    'f' => '/cig-testing-exec',
    'g' => '/cig-rollout',
    'h' => '/cig-maintenance',
    'i' => '/cig-retrospective',
    'j' => undef,  # Task complete
);
```

### Git Workflow Commands
```bash
# In /cig-new-task skill (after template copier succeeds)
git checkout -b "$BRANCH_NAME"

# In workflow phase skills (at end of each phase)
echo "Create checkpoint commit:"
echo "git add <files>"
echo "git commit -m 'Task N: Complete <phase> phase'"

# In /cig-retrospective skill (after retrospective doc complete)
git branch "$(git rev-parse --abbrev-ref HEAD)-checkpoints"
git rebase -i <base-commit>  # Interactive squash
# Generate commit message focusing on "why"
```

## Constraints
### Technical Constraints
- **Perl Dependency**: Template copier is Perl-based, must maintain Perl compatibility
- **Symlink Structure**: Cannot change existing symlink organization (task types share pool files)
- **Static Templates**: Templates filled once at creation, not dynamic (influences where logic lives)
- **Backward Compatibility**: Existing tasks 1-43 must continue working with old format

### Performance Constraints
- Template generation must complete in < 2 seconds (NFR1)
- Symlink discovery and variable substitution must complete in < 1 second (NFR1)
- No noticeable performance regression vs current system

### Security Constraints
- Generated files must have 0600 permissions (NFR4)
- Template variable substitution must prevent injection attacks (NFR4)
- Script integrity must be verifiable via SHA256 (NFR4)

### Design Constraints
- Must preserve DRY principle (single source of truth in pool directory)
- Must infer from existing structure (no hardcoded phase sequences)
- Must maintain separation of concerns (templates ≠ logic ≠ workflow)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **No** - estimated 6-9 hours (1-2 days)
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer task
- [x] **Complexity**: Does this involve 3+ distinct concerns? **Yes** - 3 components (templates, copier, git workflow), but design shows clear separation
- [ ] **Risk**: Are there high-risk components that need isolation? **No** - phased approach mitigates risk
- [ ] **Independence**: Can parts be worked on separately? **Yes** - phases can be done sequentially (templates → copier → git)

**Decomposition Decision**: Not needed. Design clarifies separation into 3 sequential phases. Each phase is independently testable. Total effort < 1 week.

## Validation
- [x] Design review completed - three-component architecture with clear separation
- [x] Architecture approved - maintains DRY, backward compatible, testable
- [x] Integration points verified:
  - Template copier reads symlinks (filesystem interface)
  - Skills invoke template copier via command-line interface
  - Git commands invoked via bash (standard git CLI)
  - Workflow docs provide user instructions (text interface)

## Status
**Status**: Finished
**Next Action**: Move to implementation planning → `/cig-implementation-plan 44`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
