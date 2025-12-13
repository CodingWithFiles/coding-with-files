# Hierarchical Workflow System with Dynamic Step Transitions - Plan

## Task Reference
- **Task ID**: internal-3
- **Type**: Feature
- **Status**: Not Started
- **Created**: 2025-10-07
- **Tracking**: Internal (migrate to GitHub issue when created)

## Goal
Implement a hierarchical task management system that supports infinite task nesting with structured workflow steps and dynamic state transitions.

## Success Criteria
- [ ] Hierarchical task structure with decimal numbering (1, 1.1, 1.1.1, etc.)
- [ ] Eight workflow steps (a-plan through h-retrospective) with lettered naming
- [ ] Commands to create and manage hierarchical tasks
- [ ] Context inheritance from parent tasks
- [ ] Dynamic workflow transitions based on step outcomes
- [ ] Universal decomposition principle implemented
- [ ] Backward compatibility with existing task structure
- [ ] Migration of existing tasks to new structure
- [ ] Workflow file content guidance (focus/avoid) in task creation commands
- [ ] Command refactoring with progressive disclosure (no duplication)
- [ ] Standardised status markers in workflow files (minimum 6 status types)

## Scope

### In Scope
- New directory structure: `<num>-<type>-<slug>/`
- Lettered workflow files: `a-plan.md`, `b-requirements.md`, etc.
- Central template pool in `.cig/templates/pool/` with symlinks from task type directories (DRY)
- Hierarchical subtask creation with decimal numbering
- Eight new workflow commands (`/cig-plan`, `/cig-requirements`, etc.)
- Updated `/cig-new-task`, `/cig-subtask`, `/cig-status`, `/cig-extract` commands
- `/cig-extract` refactored to use task-based paths and helper scripts (LLM in the loop)
- Workflow file content guidance (focus/avoid) in task creation commands
- Command refactoring: `/cig-subtask` references `/cig-new-task` (progressive disclosure)
- Workflow system documentation in `.cig/docs/workflow/` (LLM-friendly, concise)
- Four helper scripts for common operations
- Context inheritance helper system
- Migration subtask for existing tasks
- Complete documentation updates

### Out of Scope
- Automated task scheduling
- Integration with external project management tools (beyond GitHub issues)
- Real-time collaboration features
- Web UI for task management

## Milestones

1. **Requirements & Design** (Est: 0.5 days)
   - Finalize requirements based on scratchpad design
   - Document architecture and command structure

2. **Core Implementation** (Est: 2 days)
   - Create workflow file templates
   - Implement 8 new workflow commands
   - Update existing commands for new format
   - Build context inheritance system

3. **Testing** (Est: 1 day)
   - Create test tasks at multiple hierarchy levels
   - Validate all commands with new structure
   - Test backward compatibility

4. **Migration & Rollout** (Est: 1 day)
   - Plan migration strategy (via subtask)
   - Execute migration of existing tasks
   - Validate migration success
   - Update all documentation

5. **Documentation & Retrospective** (Est: 0.5 days)
   - Update README, COMMANDS.md, CLAUDE.md
   - Document maintenance procedures
   - Complete retrospective analysis

## Risk Assessment

### High Risk
- **Migration complexity**: Moving existing tasks could break git history
  - Mitigation: Use `git mv` for renames, isolated commits

### Medium Risk
- **Backward compatibility**: Supporting both old and new structures
  - Mitigation: Detection logic based on file names, comprehensive testing
- **Command complexity**: Eight new commands with context awareness
  - Mitigation: Shared helper scripts, consistent patterns

### Low Risk
- **User adoption**: Learning new structure and commands
  - Mitigation: Clear documentation, examples, dogfooding approach

## Estimates
- **Total Development Time**: 5 days
- **Complexity**: High (major architectural change)
- **Team Size**: 1 (Claude + User)

## Dependencies
- Existing CIG system operational
- Git repository in good state
- Scratchpad design document complete

## Notes
- This feature uses "dogfooding" - building CIG with CIG
- Design already complete in scratchpad.md
- Migration will be handled as subtask 3.1 during rollout
- Demonstrates the dynamic workflow pattern we're implementing
