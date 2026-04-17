# Identify deterministic operations still handled by agent - Design
**Task**: 100 (discovery)

## Task Reference
- **Task ID**: internal-100
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/100-identify-deterministic-ops-handled-by-agent
- **Template Version**: 2.1

## Goal
Design the audit methodology for identifying deterministic operations across 18 CWF skills.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Audit Methodology
- **Decision**: Read each SKILL.md sequentially, apply the classification test from b-requirements-plan.md to each workflow step, record findings in a structured table
- **Rationale**: Systematic coverage of all 18 skills ensures nothing is missed. Sequential reading is more reliable than grep-based scanning because deterministic operations are described in prose, not with consistent keywords.
- **Trade-offs**: Slower than keyword scanning, but much more accurate for prose-based instructions

### Signals to Watch For
Operations described with imperative verbs and no conditional judgement:
1. **"Read X, add Y, write back"** — JSON/file manipulation the agent does by hand
2. **"Create directory/file/symlink"** — filesystem operations
3. **"Check if X exists, if not do Y"** — idempotent guards
4. **"Run `command`"** — shell commands the agent constructs and runs via Bash tool
5. **"Update Status field to Z"** — status field writes in wf step files
6. **"Stage X, commit with message Y"** — checkpoint commit sequences
7. **"Parse arguments"** — argument validation and extraction

### Output Format
- **Decision**: Markdown table with columns: Skill, Step, Operation, Category, Frequency, Error-Prone?, Extraction Complexity, Rank
- **Rationale**: Table format allows sorting by rank and filtering by category

### Categorisation Taxonomy
| Category | Description | Example |
|----------|-------------|---------|
| JSON manipulation | Read/merge/write `.claude/settings.json` | cwf-init step 6 (permissions), step 6c (hooks) |
| File creation | Create dirs, symlinks, files | cwf-init step 6b, cwf-new-task step 3 |
| Status update | Write Status/Next Action fields in wf files | All wf step skills step 8 |
| Checkpoint commit | Stage + commit sequence | All wf step skills step 8 |
| Argument parsing | Validate and extract task number | All wf step skills step 1 |
| Validation | Check preconditions (file exists, branch correct) | cwf-retrospective pre-step |
| Git operations | Branch creation, checkout | cwf-new-task step 4 |

### Ranking Criteria
Each candidate scored 1-3 on three axes, multiplied for final rank:
- **Frequency** (1=rare, 2=common, 3=every task): How often does the agent perform this?
- **Error-proneness** (1=reliable, 2=occasional errors, 3=frequently wrong): How often does the agent get this wrong?
- **Extraction complexity** (1=easy, 2=moderate, 3=hard): How hard is it to write a script for this?

Rank = Frequency × Error-proneness / Extraction complexity (higher = extract first)

## Audit Scope
18 SKILL.md files to review:
1. cwf-config
2. cwf-current-task
3. cwf-design-plan
4. cwf-extract
5. cwf-implementation-exec
6. cwf-implementation-plan
7. cwf-init
8. cwf-maintenance
9. cwf-new-task
10. cwf-requirements-plan
11. cwf-retrospective
12. cwf-rollout
13. cwf-security-check
14. cwf-status
15. cwf-subtask
16. cwf-task-plan
17. cwf-testing-exec
18. cwf-testing-plan

## Constraints
- Read-only audit — no code changes
- Existing helper scripts (context-manager, workflow-manager, task-workflow, etc.) are the baseline — anything they already handle is out of scope

## Decomposition Check
0/5 signals triggered — no decomposition needed.

## Validation
- [x] Methodology designed with clear classification test
- [x] Output format defined
- [x] All 18 skills enumerated

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 100
**Blockers**: None

## Actual Results
Ranked output format validated: status field updates (6.0), slug generation (4.0), checkpoint commit (3.0), cwf-extract replacement (2.0), JSON settings merge (1.5).

## Lessons Learned
A weighted scoring matrix (determinism x frequency x error-proneness) was more effective than subjective ranking for prioritising candidates.
