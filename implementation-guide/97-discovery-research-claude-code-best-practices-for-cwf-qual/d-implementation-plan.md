# Research Claude Code best practices for CWF quality improvements - Implementation Plan
**Task**: 97 (discovery)

## Task Reference
- **Task ID**: internal-97
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/97-research-claude-code-best-practices-for-cwf-qual
- **Template Version**: 2.1

## Goal
Execute the discovery: review best practices, compare to CWF, produce suggestions, evaluate with user, and populate backlog.

## Files to Modify
### Primary Changes
- `BACKLOG.md` — Add 6 new backlog items for accepted suggestions

### Supporting Changes
- `~/.claude/projects/-home-matt-repo-coding-with-files/memory/feedback_skill_autotrigger.md` — New feedback memory for skill auto-triggering preference
- `~/.claude/projects/-home-matt-repo-coding-with-files/memory/MEMORY.md` — Index update for new feedback memory

## Implementation Steps

### Step 1: Corpus Review
- [x] Read all files in `../analysis/claude-code-best-practice` (40+ documents)
- [x] Read CWF skills, CLAUDE.md, settings, docs, and template structure

### Step 2: Gap Analysis
- [x] Map best practice areas to CWF current implementation
- [x] Identify 10 suggestion areas:
  1. Path-scoped rules (`.claude/rules/`) — **Accepted, High**
  2. `context: fork` for heavy skills — **Rejected** (agent needs skill output in context)
  3. PreToolUse hook for rule re-injection — **Accepted, High**
  4. Stop event verification hooks — **Accepted, High (discovery)**
  5. `@import` in CLAUDE.md — **Deferred** (progressive disclosure better for cache)
  6. `disable-model-invocation` on skills — **Rejected** (contradicts skill-first philosophy)
  7. Gotchas-first in skills — **Accepted, High (discovery)**
  8. Notification hooks on Stop — **Elided** (not portable)
  9. `/compact` customisation — **Accepted, Medium (discovery)**
  10. Session hygiene guidance — **Accepted, Medium**

### Step 3: User Evaluation
- [x] Present each suggestion to user
- [x] Capture accept/reject/modify decisions with rationale
- [x] Record critical feedback on item 6 (skill auto-triggering)

### Step 4: Backlog Population
- [x] Add 6 accepted items to BACKLOG.md with priority, type, scope, and provenance
- [x] Save feedback memory for architectural decision (skill auto-triggering)

### Step 5: Enforcement Discussion (Emergent)
- [x] Explored agent process enforcement limitations
- [x] Discussed Deming-inspired post-training approach (rework as quality signal)
- [x] Reviewed SSD paper (arxiv 2604.01193v1) for post-training methodology
- [x] Explored LMM as data source for training pipeline
- [x] Discussed nightly DPO loop with Q8 QAT on open-weight models

## Validation Criteria
**See e-testing-plan.md for validation criteria**

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan 97
**Blockers**: None

## Actual Results
All 5 steps completed. 10 suggestions evaluated, 6 accepted as backlog items, 2 rejected with documented rationale, 1 deferred, 1 elided. Enforcement discussion produced insights beyond original scope (Deming quality model, post-training with rework signal, LMM as training data source).

## Lessons Learned
- Discovery tasks benefit from emergent discussion — the enforcement/Deming thread was unplanned but produced the most valuable architectural insights
