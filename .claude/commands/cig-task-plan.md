---
description: Guide user through planning phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.pl:*), Bash(.cig/scripts/command-helpers/context-inheritance.pl:*), Bash(.cig/scripts/command-helpers/format-detector.pl:*), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

**Task arguments**: $ARGUMENTS

**Helper scripts location**: `.cig/scripts/command-helpers/`

## Your task
Guide the user through the planning phase.

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

1. **Resolve Task Directory**:

Parse the task path argument and resolve to full directory:
- Extract first word from task arguments
- Validate it matches hierarchical number format (digits and dots only)
- If valid: call `.cig/scripts/command-helpers/hierarchy-resolver.pl <task-path>` using the Bash tool
- If invalid: inform user the task path format is invalid, do not invoke script
- If task not found, provide clear error with available tasks
- Extract task number, type, and slug from resolution

2. **Load Parent Context**:

If this is a subtask (not top-level), load parent context for inherited context:
- Use the validated task path from Step 1
- Call `.cig/scripts/command-helpers/context-inheritance.pl <task-path>` using the Bash tool
- Parent context includes: file paths, status markers, section headers, line ranges
- This provides ~50-100 tokens per parent instead of 500-1000 for full files

3. **Present Context Summary**:

Present the parent context structural map to help inform planning:
- Show navigable links with file paths and line ranges
- Display status markers to indicate reliability of parent context
- Highlight key parent decisions that may influence this task's planning

4. **LLM Decision Point - Read Parent Details**:

Based on the structural map, decide if you need to read specific parent sections:
- Use Read tool with offset/limit parameters from structural map
- Only read sections that directly inform this task's planning
- Skip irrelevant parent context to conserve tokens

5. **Reference Workflow Documentation**:

Review planning workflow guidance:
- Read `.cig/docs/workflow/workflow-steps.md#planning` for detailed guidance
- Understand focus/avoid guidelines for planning phase
- Apply key questions and typical structure

6. **Execute Planning Workflow**:

Open and work with the planning file (a-plan.md or plan.md based on format):
- Use `format-detector.pl <task-dir> <workflow-file>` to check version
- **Focus on**: Goals, success criteria, milestones, risks, decomposition signals
- **Avoid**: Implementation details, code specifics, detailed design decisions
- Capture: Original estimates, dependencies, constraints

Key questions to address:
- What is the single-sentence objective?
- What are 3-5 measurable success criteria?
- What are the major milestones?
- What are the top 3-5 risks and mitigation strategies?
- What dependencies exist (external, team, technical)?
- What constraints limit the approach?

**Status Field**: Use valid status values only. See `.cig/docs/workflow/workflow-steps.md#status-values`.

7. **Check Universal Decomposition Signals**:

Review these 5 signals to determine if this task should be broken into subtasks:
1. **Time Signal**: Will this take >1 week? If yes, consider decomposition
2. **People Signal**: Does this need >2 people working on different parts? If yes, consider decomposition
3. **Complexity Signal**: Does this involve 3+ distinct concerns? If yes, consider decomposition
4. **Risk Signal**: Are there high-risk components that need isolation? If yes, consider decomposition
5. **Independence Signal**: Can parts be worked on separately? If yes, consider decomposition

If 2+ signals are triggered, strongly recommend creating subtasks.

8. **Suggest Next Steps with Reasoning**:

Analyze the planning outcome and suggest the next step:

**Primary Next Step** (if planning is complete and approved):
- Move to requirements phase: `/cig-requirements <task-path>`
- Rationale: Planning establishes goals, requirements define specifics

**Alternative Paths**:
- If decomposition signals triggered → Create subtasks with `/cig-subtask <parent-path> <num> <type> "description"`
- If planning reveals missing context → Request clarification from user
- If risks are too high → Recommend spike/investigation task first
- If dependencies block → Document blockers and suggest parallel work

Provide clear reasoning for the suggested path based on planning outcome.

## Blocker Handling

**Common Blockers in Planning**:
- Unclear scope or missing requirements → Revert to stakeholder discussion/clarification
- Conflicting stakeholder goals → Revert to goal alignment before continuing
- Too many unknowns to estimate → Recommend creating discovery/spike task first
- Dependencies cannot be resolved → Update status to "Blocked", document blockers
- Decomposition needed but unclear how → Create investigation subtask to explore options

**Reversion Guidance**:
- If reverting to earlier phase: Update status to "Backlog" or "To-Do", document reason
- Document the blocker in "Actual Results" or "Blockers" section of a-task-plan.md
- Update status to "Blocked" until blocker is resolved
- When blocker resolved, restart planning with new information

**When to Revert**:
- Planning reveals the task description is fundamentally wrong
- Planning shows task is not feasible with current constraints
- Planning requires information that must come from earlier work

## Success Criteria
- [ ] Task directory resolved successfully
- [ ] Parent context loaded (if applicable) and relevant sections reviewed
- [ ] Planning file (a-plan.md or plan.md) opened and updated
- [ ] Goals, success criteria, and milestones defined
- [ ] Risks identified with mitigation strategies
- [ ] Decomposition check completed
- [ ] Next steps suggested with clear reasoning
