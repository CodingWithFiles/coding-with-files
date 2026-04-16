# Research Claude Code best practices for CWF quality improvements - Retrospective
**Task**: 97 (discovery)

## Task Reference
- **Task ID**: internal-97
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/97-research-claude-code-best-practices-for-cwf-qual
- **Template Version**: 2.1
- **Retrospective Date**: 2026-04-16

## Executive Summary
- **Duration**: 1 session (estimated: 1 session, variance: 0%)
- **Scope**: Original scope completed; significant emergent discussion on agent enforcement and post-training added value beyond plan
- **Outcome**: 6 prioritised backlog items, 1 feedback memory, and foundational insights on agent quality management

## Variance Analysis
### Time and Effort
- **Estimated**: 1 session across all phases
- **Actual**: 1 session — discovery task completed within single conversation
- **Variance**: None. Discovery tasks with pre-existing research material are well-suited to single-session completion.

### Scope Changes
- **Additions**: Enforcement discussion (Deming quality model, post-training with rework signal, LMM as training data source, nightly DPO loop, Q8 QAT) — emerged from evaluating suggestions 1/3/6. User-directed exploration that produced the most valuable insights of the task.
- **Removals**: None
- **Impact**: No timeline impact (organic conversation flow). Added significant strategic context for future work.

### Quality Metrics
- **Test Coverage**: 7/7 test cases pass (100%)
- **Defect Rate**: 0 — all outputs correct on first pass
- **Backlog quality**: All 6 items have required fields (type, priority, status, problem, scope, provenance)

## What Went Well
- Parallel agent exploration of both corpora (best practices + CWF) was efficient and comprehensive
- Real-time user evaluation caught two suggestions that violated CWF's architectural principles — would have been missed by automated filtering
- The enforcement discussion emerged naturally and produced the deepest insights
- User feedback on skill auto-triggering was captured immediately as a memory, preventing future repetition of the same mistake

## What Could Be Improved
- Initial suggestion for `disable-model-invocation` showed insufficient understanding of CWF's skill-first philosophy — the agent should have inferred this from existing CLAUDE.md and memory before suggesting
- `@import` suggestion required back-and-forth to determine it was inferior to current progressive disclosure approach — a more thorough analysis of prompt caching implications would have avoided this

## Key Learnings
### Technical Insights
- Path-scoped rules (`.claude/rules/` with glob patterns) are the closest thing to enforcement for skill usage — advisory but auto-injected at the point of action
- Progressive disclosure via Read tool is better than `@import` for prompt cache stability — imports change the prefix, breaking cache
- Agent process enforcement is fundamentally impossible when the agent has full system access — only outcome validation or model training can address the root cause
- Deming's quality model (rework as quality signal, backward propagation through process chain) maps naturally to DPO post-training on agent trajectories
- LMM's existing embedding infrastructure can serve as a sentiment classifier for user feedback (no new model needed)

### Process Learnings
- Discovery tasks benefit from allowing emergent discussion — the enforcement/Deming thread was unplanned but highest-value
- Evaluating portability early (NFR3) correctly and efficiently filtered non-portable suggestions
- The "retrospective insertion" pattern (running wf step skills after work is complete) works cleanly for discovery tasks where research precedes formalisation

### Risk Mitigation Strategies
- Portability constraint (CWF installed into third-party repos) was effective as an early filter — prevented accepting suggestions that would fail in practice

## Recommendations
### Process Improvements
- For future best practices reviews: establish portability filter upfront as a hard constraint
- When suggesting changes to skill behaviour: always check existing feedback memories and CLAUDE.md for architectural preferences before proposing

### Future Work
All future work captured as BACKLOG.md items during implementation:

**High priority**:
1. Path-scoped rules for wf file protection (feature)
2. PreToolUse hook for rule re-injection (feature)
3. Stop event hooks research (discovery)
4. Gotchas via LMM memory analysis (discovery)

**Medium priority**:
5. Compaction failure frequency research (discovery)
6. Session hygiene guidance (chore)

**Beyond CWF scope** (discussed but not backlogged):
- Post-training DPO loop with rework signal from LMM data
- Nightly fine-tuning on Q8 QAT open-weight models
- LMM `list_sessions` capability for training pipeline support

## Status
**Status**: Finished
**Next Action**: Task complete — suggest merge
**Blockers**: None
**Completion Date**: 2026-04-16
**Sign-off**: Matt Keenan / Claude Opus 4.6

## Archived Materials
- Best practices corpus: `../analysis/claude-code-best-practice` (40+ files)
- SSD paper: arxiv 2604.01193v1
- Feedback memory: `~/.claude/projects/-home-matt-repo-coding-with-files/memory/feedback_skill_autotrigger.md`
