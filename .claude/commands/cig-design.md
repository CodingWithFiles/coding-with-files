---
description: Guide user through design phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.sh), Bash(.cig/scripts/command-helpers/context-inheritance.pl), Bash(.cig/scripts/command-helpers/format-detector.sh), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.sh $ARGUMENTS 2>/dev/null || echo "Task path required"`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl $ARGUMENTS 2>/dev/null || echo "No parent context (top-level task or invalid path)"`

## Your task
Guide the user through the design phase for task: **$ARGUMENTS**

Follow the 8-step workflow structure:

1. **Resolve Task Directory**: Use hierarchy-resolver.sh
2. **Load Parent Context**: Use context-inheritance.pl for subtasks
3. **Present Context Summary**: Show structural map with status markers
4. **LLM Decision**: Read specific parent sections if needed
5. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#design`
6. **Execute Design Workflow**:
   - Open c-design.md (v2.0) or design.md (v1.0)
   - **Focus on**: Architecture decisions, component design, API contracts, data models, interface design
   - **Avoid**: Detailed implementation code, specific test cases, deployment procedures
   - Apply design priorities: Testability → Readability → Consistency → Simplicity → Reversibility
   - Follow architecture preferences: Composition over inheritance, interfaces over singletons, explicit over implicit

   Key questions:
   - What architecture pattern best fits the requirements?
   - What are the key components and their responsibilities?
   - How do components interact (data flow)?
   - What are the critical interfaces (API endpoints, data models)?
   - What constraints influenced the design?
   - What are the trade-offs of this approach?

7. **Check Decomposition Signals**: Review 5 universal signals
8. **Suggest Next Steps**:
   - **Primary**: Move to implementation → `/cig-implementation <task-path>`
   - **Alternative**: Return to requirements if design reveals missing requirements
   - **Alternative**: Create spike/prototype task if design uncertainty is high

## Success Criteria
- [ ] Design file opened and updated
- [ ] Architecture choice documented with rationale and trade-offs
- [ ] Component overview defined with clear responsibilities
- [ ] Data flow documented
- [ ] Interface design specified (API endpoints, data models)
- [ ] Design validated and approved
- [ ] Next steps suggested
