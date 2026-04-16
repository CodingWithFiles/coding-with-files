# Research Claude Code best practices for CWF quality improvements - Design
**Task**: 97 (discovery)

## Task Reference
- **Task ID**: internal-97
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/97-research-claude-code-best-practices-for-cwf-qual
- **Template Version**: 2.1

## Goal
Design the research methodology and output structure for the best practices discovery.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Research Methodology
- **Decision**: Parallel exploration — read best practices corpus and CWF current state simultaneously, then compare
- **Rationale**: Both corpora are large; parallel agent exploration avoids sequential bottleneck
- **Trade-offs**: Higher token cost for parallel agents, but faster and more comprehensive than serial reading

### Suggestion Evaluation Framework
- **Decision**: 10-point checklist per suggestion, evaluated with user in real-time
- **Rationale**: User domain knowledge is essential — some best practices don't apply to meta-tools
- **Categories evaluated**: Path-scoped rules, context isolation, rule re-injection, stop hooks, CLAUDE.md structure, skill triggering, gotchas, notifications, compaction, session hygiene

### Output Format
- **Decision**: Accepted suggestions become BACKLOG.md entries; rejected suggestions documented in wf step files with rationale
- **Rationale**: Backlog is the canonical place for future work; wf step files capture the decision context

### Enforcement Discussion
- **Decision**: Document the fundamental impossibility of agent process enforcement, capture Deming-inspired post-training discussion as context for future work
- **Rationale**: The conversation revealed deep architectural insights about agent behaviour that inform future backlog items

## Constraints
- Discovery only — no code changes
- Suggestions must be portable (CWF installed into third-party repos)
- Best practices corpus is external to this repo; findings must be self-contained in backlog items

## Decomposition Check
0/5 signals triggered — no decomposition needed.

## Validation
- [x] Methodology reviewed with user
- [x] Evaluation framework applied to all 10 suggestions
- [x] User approved/rejected each item individually

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 97
**Blockers**: None

## Actual Results
Methodology worked well. Parallel agent exploration produced comprehensive coverage of both corpora. Real-time user evaluation caught two suggestions that violated CWF's architectural principles (context:fork reducing agent context, disable-model-invocation contradicting skill-first philosophy).

## Lessons Learned
- Real-time user evaluation is essential for discovery tasks — automated filtering would have missed the architectural nuance around skill auto-triggering
- The enforcement discussion (Deming, post-training, rework signal) emerged organically and produced the most valuable insights of the task
