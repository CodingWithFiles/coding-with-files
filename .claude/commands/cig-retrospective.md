---
description: Guide user through retrospective phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.sh), Bash(.cig/scripts/command-helpers/context-inheritance.pl), Bash(.cig/scripts/command-helpers/format-detector.sh), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.sh $ARGUMENTS 2>/dev/null || echo "Task path required"`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl $ARGUMENTS 2>/dev/null || echo "No parent context (top-level task or invalid path)"`

## Your task
Guide the user through the retrospective phase for task: **$ARGUMENTS**

Follow the 8-step workflow structure:

1. **Resolve Task Directory**: Use hierarchy-resolver.sh
2. **Load Parent Context**: Use context-inheritance.pl for subtasks
3. **Present Context Summary**: Show structural map with status markers
4. **LLM Decision**: Read specific parent sections and all task workflow files
5. **Reference Workflow Documentation**: Read `.cig/docs/workflow/workflow-steps.md#retrospective`
6. **Execute Retrospective Workflow**:
   - Open h-retrospective.md (v2.0 only - retrospective is new format only)
   - **Focus on**: Variance analysis, what went well, what could be improved, key learnings, recommendations
   - **Avoid**: Future work planning (unless captured as recommendations)

   Steps to complete retrospective:
   - **Extract planning data**: Read original estimates, success criteria, goals from a-plan.md/plan.md
   - **Gather actual results**: Review status sections, implementation timeline
   - **Calculate variances**: Compare time estimates vs actual, scope changes, dependency resolution
   - **Generate retrospective report**:
     - Executive Summary: Duration, scope comparison, outcome
     - Variance Analysis: Time/effort, scope changes, quality metrics
     - What Went Well: Successes, effective processes, collaboration highlights
     - What Could Be Improved: Challenges, inefficiencies, gaps
     - Key Learnings: Technical insights, process learnings, risk mitigation strategies
     - Recommendations: Process improvements, tool recommendations, future work
   - **Update task documents**: Fill in Actual Results and Lessons Learned sections in all workflow files

7. **Check Decomposition Signals**: N/A for retrospective (task is complete)
8. **Suggest Next Steps**:
   - **Primary**: Task complete, archive materials, update knowledge base
   - **Alternative**: Create follow-up tasks based on recommendations
   - **Alternative**: Share learnings with team

## Success Criteria
- [ ] Retrospective file (h-retrospective.md) opened and updated
- [ ] Planning data extracted from workflow files
- [ ] Actual results gathered from task execution
- [ ] Variance analysis completed (time, scope, quality)
- [ ] What went well documented
- [ ] What could be improved identified
- [ ] Key learnings captured
- [ ] Recommendations provided for future work
- [ ] Actual Results sections updated in all workflow files
- [ ] Task marked as complete with retrospective date