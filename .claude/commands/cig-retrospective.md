---
description: Guide user through retrospective phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.pl:*), Bash(.cig/scripts/command-helpers/context-inheritance.pl:*), Bash(.cig/scripts/command-helpers/format-detector.pl:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the retrospective phase.

**CRITICAL - Argument Parsing**:
- Extract the FIRST space-separated word from the task arguments above as the task path
- Any additional words after the first provide user context about their intent
- Use the extra words to understand what the user wants, but do NOT pass them to script calls
- Example: "11 update the design" → task path is "11", extra text explains what to do

**CRITICAL - Task Path Validation**:
- Task paths MUST match hierarchical number format: digits separated by dots
- Valid formats: "11", "1.2", "12.2.3", "1.1.1.1"
- Invalid formats: "some text", "`date`", "11; rm -rf", "text.text"
- If first word does NOT match valid format, inform user and do not invoke scripts
- This prevents command injection and ensures only valid task identifiers reach scripts

Follow the 8-step workflow structure:

1. **Resolve Task Directory**:
   - Extract first word from task arguments
   - Validate it matches hierarchical number format (digits and dots only)
   - If valid: call `.cig/scripts/command-helpers/hierarchy-resolver.pl <task-path>` using the Bash tool
   - If invalid: inform user the task path format is invalid, do not invoke script

2. **Load Parent Context**:
   - Use the validated task path from step 1
   - Call `.cig/scripts/command-helpers/context-inheritance.pl <task-path>` using the Bash tool
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

   **Status Field**: Use valid status values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.

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