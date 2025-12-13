---
description: Guide user through requirements phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.sh), Bash(.cig/scripts/command-helpers/context-inheritance.pl), Bash(.cig/scripts/command-helpers/format-detector.sh), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.sh $ARGUMENTS 2>/dev/null || echo "Task path required"`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl $ARGUMENTS 2>/dev/null || echo "No parent context (top-level task or invalid path)"`

## Your task
Guide the user through the requirements phase for task: **$ARGUMENTS**

Follow the 8-step workflow structure:

1. **Resolve Task Directory**: Use hierarchy-resolver.sh
2. **Load Parent Context**: Use context-inheritance.pl for subtasks
3. **Present Context Summary**: Show structural map with status markers
4. **LLM Decision**: Read specific parent sections if needed
5. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#requirements`
6. **Execute Requirements Workflow**:
   - Open b-requirements.md (v2.0) or requirements.md (v1.0)
   - **Focus on**: Functional requirements (FR), non-functional requirements (NFR), acceptance criteria
   - **Avoid**: Implementation approaches, code structure, deployment details
   - Define: User stories, performance requirements, security requirements, constraints

   Key questions:
   - What must the system do? (Functional requirements)
   - How well must it do it? (Non-functional requirements: performance, usability, maintainability, security, reliability)
   - How do we verify success? (Acceptance criteria)
   - What are the hard constraints?

7. **Check Decomposition Signals**: Review 5 universal signals
8. **Suggest Next Steps**:
   - **Primary**: Move to design → `/cig-design <task-path>`
   - **Alternative**: Return to planning if requirements reveal scope issues
   - **Alternative**: Create subtasks if complexity signals triggered

## Success Criteria
- [ ] Requirements file opened and updated
- [ ] Functional requirements (FR1-FRn) defined with clear acceptance criteria
- [ ] Non-functional requirements (NFR1-NFR5) specified measurably
- [ ] Acceptance criteria defined as testable checkpoints
- [ ] Constraints documented
- [ ] Next steps suggested
