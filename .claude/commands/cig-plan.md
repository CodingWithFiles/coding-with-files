---
description: Guide user through planning phase
argument-hint: <task-path>
allowed-tools: Read, Write, Edit, Bash(.cig/scripts/command-helpers/hierarchy-resolver.sh), Bash(.cig/scripts/command-helpers/context-inheritance.pl), Bash(.cig/scripts/command-helpers/format-detector.sh), Bash(egrep:*), Bash(echo:*), Bash(find:*)
---

## Context
See `.cig/docs/context/tools.md` for context tool documentation.

- Task resolution: !`.cig/scripts/command-helpers/hierarchy-resolver.sh $ARGUMENTS 2>/dev/null || echo "Task path required"`
- Parent context: !`.cig/scripts/command-helpers/context-inheritance.pl $ARGUMENTS 2>/dev/null || echo "No parent context (top-level task or invalid path)"`

## Your task
Guide the user through the planning phase for task: **$ARGUMENTS**

### Step 1: Resolve Task Directory
Parse the task path argument and resolve to full directory:
- Use `hierarchy-resolver.sh <task-path>` to find the task directory
- If task not found, provide clear error with available tasks
- Extract task number, type, and slug from resolution

### Step 2: Load Parent Context
If this is a subtask (not top-level), load parent context for inherited context:
- Use `context-inheritance.pl <task-path>` to get structural map of parent tasks
- Parent context includes: file paths, status markers, section headers, line ranges
- This provides ~50-100 tokens per parent instead of 500-1000 for full files

### Step 3: Present Context Summary
Present the parent context structural map to help inform planning:
- Show navigable links with file paths and line ranges
- Display status markers to indicate reliability of parent context
- Highlight key parent decisions that may influence this task's planning

### Step 4: LLM Decision Point - Read Parent Details
Based on the structural map, decide if you need to read specific parent sections:
- Use Read tool with offset/limit parameters from structural map
- Only read sections that directly inform this task's planning
- Skip irrelevant parent context to conserve tokens

### Step 5: Reference Workflow Documentation
Review planning workflow guidance:
- Read `.cig/docs/workflow/workflow-steps.md#planning` for detailed guidance
- Understand focus/avoid guidelines for planning phase
- Apply key questions and typical structure

### Step 6: Execute Planning Workflow
Open and work with the planning file (a-plan.md or plan.md based on format):
- Use `format-detector.sh <task-dir> <workflow-file>` to check version
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

### Step 7: Check Universal Decomposition Signals
Review these 5 signals to determine if this task should be broken into subtasks:
1. **Time Signal**: Will this take >1 week? If yes, consider decomposition
2. **People Signal**: Does this need >2 people working on different parts? If yes, consider decomposition
3. **Complexity Signal**: Does this involve 3+ distinct concerns? If yes, consider decomposition
4. **Risk Signal**: Are there high-risk components that need isolation? If yes, consider decomposition
5. **Independence Signal**: Can parts be worked on separately? If yes, consider decomposition

If 2+ signals are triggered, strongly recommend creating subtasks.

### Step 8: Suggest Next Steps with Reasoning
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

## Success Criteria
- [ ] Task directory resolved successfully
- [ ] Parent context loaded (if applicable) and relevant sections reviewed
- [ ] Planning file (a-plan.md or plan.md) opened and updated
- [ ] Goals, success criteria, and milestones defined
- [ ] Risks identified with mitigation strategies
- [ ] Decomposition check completed
- [ ] Next steps suggested with clear reasoning
