# Separate Planning from Execution Phases with Explicit Execution Commands - Plan

## Task Reference
- **Task ID**: internal-25
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/25-separate-planning-from-execution-phases-with-expli
- **Template Version**: 2.0

## Goal
Expand CIG from 8-phase to 10-phase workflow by adding explicit execution commands (cig-implementation-exec, cig-testing-exec) that separate planning from execution, and formalize blocker-driven workflow reversion to support iterative development.

## Success Criteria
- [ ] Two new workflow commands created: cig-implementation-exec.md and cig-testing-exec.md with execution-focused guidance
- [ ] 10-phase workflow documented in workflow-steps.md with clear distinction between planning and execution phases
- [ ] Blocker-driven workflow reversion formalized with examples of when to revert to earlier phases
- [ ] Template files created for execution phases (d2-implementation-exec.md, e2-testing-exec.md) or execution sections added to existing templates
- [ ] status-aggregator.pl updated to support 10-phase workflow and recognize new file patterns
- [ ] template-copier.pl updated to handle new file counts per task type (feature: 10 files, bugfix: 7 files, etc.)
- [ ] Backward compatibility maintained: existing 8-phase tasks continue working, new tasks use 10-phase workflow
- [ ] All workflow command files include blocker handling guidance with reversion examples

## Original Estimate
**Effort**: 3-5 days
- Requirements and design: 1 day
- Implementation: 2-3 days (2 new commands, 2 templates, script updates, documentation)
- Testing and validation: 1 day

**Complexity**: High
- Touches core CIG workflow architecture (8 commands, helper scripts, templates, documentation)
- Backward compatibility requirement adds complexity
- Needs comprehensive blocker handling documentation across all phases

**Dependencies**:
- Understanding of current 8-phase workflow (complete)
- Access to existing workflow command files for pattern consistency
- format-detector.pl must support version detection (already present)

## Major Milestones
1. **Design Complete**: File naming convention decided (d2 vs d-results), backward compatibility strategy defined, blocker reversion patterns documented
2. **Execution Commands Created**: cig-implementation-exec.md and cig-testing-exec.md commands operational with clear execution guidance
3. **Template Infrastructure Updated**: New template files created, template-copier.pl handles 10-phase file counts, symlinks configured
4. **Helper Scripts Updated**: status-aggregator.pl recognizes 10-phase workflow, format-detector.pl distinguishes v2.0 vs v2.1 (if needed)
5. **Documentation Complete**: workflow-steps.md updated with 10-phase order, blocker-driven reversion guidance, all commands include blocker handling sections
6. **Validation Complete**: Existing 8-phase tasks still work, new 10-phase task created and validated, backward compatibility confirmed

## Risk Assessment
### High Priority Risks
- **Backward Compatibility Breakage**: Changes to status-aggregator.pl or template-copier.pl could break existing 8-phase tasks
  - **Mitigation**: Implement format detection to handle both 8-phase and 10-phase tasks, test extensively with existing tasks before merging, use conditional logic in scripts based on detected format

- **Confusing Planning vs Execution Split**: Users may be unclear when to use cig-implementation vs cig-implementation-exec
  - **Mitigation**: Clear documentation in each command file explaining the split, examples in workflow-steps.md showing typical flow, blocker handling guidance that references when to return to planning phases

### Medium Priority Risks
- **Template Naming Ambiguity**: File naming (d2 vs d-results vs d-exec) could be confusing
  - **Mitigation**: Follow existing CIG naming conventions (lettered templates: a-h), use d2 and e2 for consistency with alphabetical ordering, document naming rationale in design phase

- **Incomplete Blocker Guidance**: Missing blocker scenarios could leave users uncertain when to revert
  - **Mitigation**: Document common blocker patterns in each workflow command, provide decision tree or flowchart for reversion decisions, include examples from real CIG usage

- **Status Aggregator Complexity**: Supporting both 8-phase and 10-phase could make status calculations complex
  - **Mitigation**: Use file presence detection (if d2 exists → 10-phase), keep percentage calculation formula consistent, add tests for both formats

- **Migration Path Unclear**: Users may wonder if they should migrate existing tasks to 10-phase
  - **Mitigation**: Explicit documentation that migration is optional, existing 8-phase tasks remain supported indefinitely, only new tasks need to use 10-phase

## Dependencies
- **Current 8-phase workflow must remain stable**: Changes cannot break existing tasks (Tasks 1-24)
- **format-detector.pl capability**: Must be able to distinguish workflow versions (already supports v1.0 vs v2.0)
- **Template pool structure**: Symlink-based template system must support additional files per task type

## Constraints
- **Backward compatibility required**: Cannot break existing 8-phase tasks (Tasks 1-24 use current workflow)
- **Naming conventions must follow CIG patterns**: Use lettered templates (a-h, d2, e2) for consistency
- **Script permissions maintained**: All new scripts must use u+rx minimum 0500 permissions
- **Security verification**: New command files and templates must be added to .cig/security/script-hashes.json

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [x] **Time**: Will this take >1 week? **Yes** - estimated 3-5 days (approaching 1 week threshold)
- [ ] **People**: Does this need >2 people working on different parts? **No** - single developer can handle all components
- [x] **Complexity**: Does this involve 3+ distinct concerns? **Yes** - (1) new workflow commands, (2) template infrastructure, (3) helper script updates, (4) documentation, (5) blocker handling framework
- [x] **Risk**: Are there high-risk components that need isolation? **Yes** - backward compatibility risk with helper scripts
- [x] **Independence**: Can parts be worked on separately? **Partially** - commands can be created independently, but helper scripts and templates are tightly coupled

**Decomposition Analysis**: 4/5 signals triggered

**Recommendation**: Consider decomposition into 2-3 subtasks:
- **Subtask 25.1**: Create execution workflow commands (cig-implementation-exec, cig-testing-exec) - can be done independently
- **Subtask 25.2**: Update template infrastructure (new templates, template-copier.pl, symlinks) - depends on naming decisions from 25.1
- **Subtask 25.3**: Update helper scripts and documentation (status-aggregator.pl, workflow-steps.md, blocker guidance) - can happen in parallel with 25.1

**Decision**: Defer decomposition decision to requirements phase. If requirements reveal scope is manageable as single task, proceed without decomposition. If scope expands or risks increase, decompose at that point.

## Status
**Status**: Finished
**Next Action**: Proceed to requirements phase with `/cig-requirements 25`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
