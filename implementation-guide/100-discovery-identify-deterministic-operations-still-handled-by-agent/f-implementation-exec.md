# Identify deterministic operations still handled by agent - Implementation Execution
**Task**: 100 (discovery)

## Task Reference
- **Task ID**: internal-100
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/100-identify-deterministic-ops-handled-by-agent
- **Template Version**: 2.1

## Goal
Execute the audit across all 18 CWF skills and produce the findings table, rankings, and backlog items.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Step 1: Read All Skills and Identify Candidates

All 18 SKILL.md files audited. Additionally audited shared docs: `checkpoint-commit.md`, `retrospective-extras.md`, `re-execution.md`, `workflow-preamble.md`.

### Skills with Zero Unique Candidates
- cwf-current-task — already delegates to `task-stack` script
- cwf-security-check — already delegates to `cwf-manage validate`
- cwf-status — already delegates to `workflow-manager status`
- cwf-task-plan — no unique ops beyond shared preamble/checkpoint
- cwf-requirements-plan — same
- cwf-design-plan — same
- cwf-implementation-plan — same
- cwf-testing-plan — same
- cwf-rollout — same
- cwf-maintenance — same

### Skills with Unique Candidates
- cwf-init — 7 candidates (JSON manipulation, file creation, validation)
- cwf-new-task — 4 candidates (validation, slug generation, git branch)
- cwf-subtask — 3 candidates (validation, slug generation)
- cwf-extract — 3 candidates (entire skill is deterministic)
- cwf-config — 3 candidates (file creation)
- cwf-implementation-exec — 1 candidate (status update)
- cwf-testing-exec — 1 candidate (status update)
- cwf-retrospective — 6 unique candidates (via retrospective-extras.md)

### Shared Operations (affect all ~10 workflow step skills)
- Argument parsing/validation from preamble — every skill invocation
- Checkpoint commit procedure — every skill invocation
- Status field update — every skill invocation

## Step 2: Categorise and Score

### Findings Table

| # | Skill | Step | Operation | Category | Freq | Error | Complexity | Rank |
|---|-------|------|-----------|----------|------|-------|------------|------|
| 1 | All wf skills | Preamble | Parse first word as task path, validate format `^\d+(\.\d+)*$` | argument parsing | 3 | 1 | 1 | 3.0 |
| 2 | All wf skills | Preamble | Fallback: extract task_num from task-context-inference output | argument parsing | 2 | 1 | 1 | 2.0 |
| 3 | All wf skills | Step 8 | Update `**Status**:` field in wf file to new value | status update | 3 | 2 | 1 | 6.0 |
| 4 | All wf skills | Step 8 | Stage wf file, format commit message, commit | checkpoint commit | 3 | 2 | 2 | 3.0 |
| 5 | All wf skills | Step 8 | Run `cwf-manage validate` post-commit | validation | 3 | 1 | 1 | 3.0 |
| 6 | cwf-init | Step 6 | Read settings.json, add Skill() entries to permissions.allow, write back | JSON manipulation | 1 | 3 | 2 | 1.5 |
| 7 | cwf-init | Step 6c | Read settings.json, add hooks config with idempotent check, write back | JSON manipulation | 1 | 3 | 2 | 1.5 |
| 8 | cwf-init | Step 4 | Prepend CWF preamble to CLAUDE.md with idempotency check | file creation | 1 | 2 | 1 | 2.0 |
| 9 | cwf-init | Step 5 | Add `.cwf/task-stack` to .gitignore idempotently | file creation | 1 | 1 | 1 | 1.0 |
| 10 | cwf-init | Step 2 | Generate cwf-project.json from template with project name from git remote | file creation | 1 | 2 | 1 | 2.0 |
| 11 | cwf-init | Step 8 | Stage all init files and commit | checkpoint commit | 1 | 2 | 1 | 2.0 |
| 12 | cwf-new-task | Step 1 | Validate num matches decimal notation, type in supported list | validation | 2 | 1 | 1 | 2.0 |
| 13 | cwf-new-task | Step 2 | Generate slug: lowercase, spaces→hyphens, remove special chars, truncate 50 | string formatting | 2 | 2 | 1 | 4.0 |
| 14 | cwf-new-task | Step 4 | Create git branch `<type>/<num>-<slug>` | git operations | 2 | 1 | 1 | 2.0 |
| 15 | cwf-subtask | Step 3 | Validate num follows parent hierarchy, check dir doesn't exist | validation | 1 | 2 | 1 | 2.0 |
| 16 | cwf-subtask | Step 3 | Generate slug (same algorithm as cwf-new-task) | string formatting | 1 | 2 | 1 | 2.0 |
| 17 | cwf-extract | Steps 1-3 | Entire skill: input type detection, section→file mapping, awk extraction | string formatting | 2 | 2 | 2 | 2.0 |
| 18 | cwf-config | Steps 1-3 | Create ~/.cwf/ dirs, generate autoload.yaml, backup+reset | file creation | 1 | 1 | 1 | 1.0 |
| 19 | cwf-retrospective | Pre-step | Verify current branch matches expected task branch format | validation | 1 | 2 | 1 | 2.0 |
| 20 | cwf-retrospective | Step 6 | Verify all phases at 100% via workflow-manager, identify non-terminal | validation | 1 | 2 | 1 | 2.0 |
| 21 | cwf-retrospective | Step 9 | Stage entire task directory (not single file) | git operations | 1 | 2 | 1 | 2.0 |
| 22 | cwf-retrospective | Step 10 | Find base commit from show-history, git reset --soft, format squash message | git operations | 1 | 3 | 2 | 1.5 |
| 23 | impl/test exec | Step 6 | Set status to "In Progress" or "Testing" when starting | status update | 2 | 1 | 1 | 2.0 |
| 24 | impl/test exec | Re-exec | Detect re-execution (grep for placeholder text), count pass number | validation | 1 | 2 | 1 | 2.0 |

**Total: 24 candidate operations across 18 skills (10 with zero unique candidates).**

## Step 3: Top Candidates for Extraction (Backlog Items)

### 1. `cwf-set-status` — Status Field Update Script
**Rank: 6.0** (highest) | Category: status update | Affects: all workflow skills
- Script takes `(file-path, new-status)`, validates against canonical status list, performs regex replacement on `**Status**: <value>` line
- Currently the agent does this by hand in every checkpoint commit — most frequent deterministic operation in the system
- Already in backlog as "Add Status Update Helper Script" — this discovery confirms it as highest priority

### 2. `cwf-checkpoint-commit` — Checkpoint Commit Script
**Rank: 3.0** | Category: checkpoint commit | Affects: all workflow skills
- Script takes `(task-path, phase-name, why-message)` and performs: status update → stage file → format commit message with trailer → commit → validate
- Consolidates items #3, #4, #5 from findings table into a single atomic operation
- Most error-prone shared operation: agents frequently forget to stage, use wrong message format, or skip validation

### 3. `cwf-slug` — Slug Generation Script
**Rank: 4.0** | Category: string formatting | Affects: cwf-new-task, cwf-subtask
- Script takes description string, outputs slug (lowercase, hyphens, no special chars, truncate 50)
- Currently duplicated in prose across two skills — algorithm is identical but described separately
- Low complexity extraction, eliminates duplication

### 4. `cwf-settings-merge` — Settings.json Merge Script
**Rank: 1.5** | Category: JSON manipulation | Affects: cwf-init
- Script takes `(key-path, value)` and performs idempotent merge into `.claude/settings.json`
- Currently the agent reads JSON, manipulates it by hand, and writes back — the most error-prone operation in the system (JSON escaping, key ordering, idempotency logic)
- Low frequency (only during init) but highest error-proneness

### 5. `cwf-extract` — Full Skill Replacement
**Rank: 2.0** | Category: string formatting | Affects: cwf-extract skill
- The entire cwf-extract skill is deterministic: input type detection (regex), section→file lookup (fixed table), content extraction (awk)
- Could be replaced entirely by a helper script, making the skill a one-line wrapper

## Step 4: Edge Cases (Partially Deterministic)

| Operation | Deterministic Part | Judgemental Part | Verdict |
|-----------|-------------------|-------------------|---------|
| Checkpoint commit message | Template structure, trailer, task number | The "why" body sentence | Partially extractable — script takes "why" as parameter |
| CHANGELOG entry | Template structure (task num, date, sections) | Content of findings/changes | Partially extractable — script generates skeleton |
| BACKLOG item | Template structure (headers, fields) | Description, scope, rationale | Partially extractable — script generates skeleton |
| Re-execution decision | Detection (is this a re-run?) | What to do about it (reset, append, skip) | Split: detection is scriptable, decision stays with agent |
| cwf-init step 4 CLAUDE.md preamble | Idempotency check, prepend position | None — content is fixed | Fully extractable |

## Blockers Encountered
None.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All requirements from b-requirements-plan.md addressed
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 100
**Blockers**: None

## Actual Results
24 candidate operations identified across 18 skills. 5 backlog items drafted. Edge cases documented.

## Lessons Learned
Auditing skills in batch (rather than one at a time) revealed cross-cutting patterns like shared preamble that would have been missed in isolation.
