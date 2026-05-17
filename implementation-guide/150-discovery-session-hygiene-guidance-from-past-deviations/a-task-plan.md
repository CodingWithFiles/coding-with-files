# Session hygiene guidance from past deviations - Plan
**Task**: 150 (discovery)

## Task Reference
- **Task ID**: internal-150
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/150-session-hygiene-guidance-from-past-deviations
- **Baseline Commit**: ec00bc80c7a94ebd413d21197ebe55eb17661415
- **Template Version**: 2.1

## Goal
Mine this project's history (retrospectives, memory files, LMM session corpus) for **session-management** deviations — suboptimal `/clear` timing, lossy compactions, context-window pressure incidents, long-session degradation — then produce installed CWF guidance documenting when to `/clear`, when to `/compact` with preservation hints, and how to maintain effective context across the CWF workflow phases.

## Scoping note: what counts as "session hygiene"
This task is bounded to decisions about *the conversation session itself*. Adjacent categories that have **separate** treatment and are **out of scope**:
- CWF workflow process errors (see [`error-patterns.md`](../../../.claude/projects/-home-matt-repo-coding-with-files/memory/error-patterns.md) E1–E7, O1–O4) — already covered by skill Gotchas + MEMORY.md
- Tool-selection / Bash-habit errors (`no_heredocs`, `no_perl_c_check`, etc.) — already covered by feedback memories
- Hash-update discipline — codified in `.cwf/docs/conventions/hash-updates.md`

In scope: `/clear`, `/compact`, context-window-pressure recovery, multi-task session boundaries, what to capture *before* clearing.

## Success Criteria
- [ ] **Audit**: Deviation audit produces a categorised list of distinct session-hygiene patterns drawing on ≥3 evidence sources (j-retrospective files, `memory/*.md`, LMM `search_text`/`search_semantic` results). Each pattern names ≥1 concrete cited instance (task number, commit SHA, memory file, or LMM session ID) — no fabricated citations.
- [ ] **Sparse-signal contingency**: If audit yields <3 distinct patterns, the plan is reshaped before c-design — guidance becomes principle-based with an explicit "no observed instance" label per principle, rather than fabricating evidence.
- [ ] **Guidance installed**: Produced doc(s) placed under `.cwf/docs/` (consumed by external CWF adopters per `CLAUDE.md` "internal to CWF development" rule) and referenced from ≥1 advertised consumer (CLAUDE.md `## Conventions`, or a SKILL.md Gotcha, or a workflow doc).
- [ ] **No duplication**: Guidance cross-references existing CWF docs / MEMORY.md sections rather than restating them. Each section either originates new content or links — not both.
- [ ] **BACKLOG retired**: The `Add Session Hygiene Guidance to CWF Documentation` BACKLOG entry is removed in the same task's squash.

## Original Estimate
**Effort**: 2–4 hours
**Complexity**: Medium (uncertain signal density in the audit step is the main variable)
**Dependencies**: None blocking. LMM MCP server must be reachable for the search step; if unavailable, audit falls back to retrospectives + memory files only and notes the gap.

## Major Milestones
1. **Audit complete**: Categorised pattern list with citations written into b-requirements-plan.md or a discovery-output artefact.
2. **Doc shape decided**: c-design-plan.md fixes (a) placement under `.cwf/docs/`, (b) number of files, (c) advertised-consumer list.
3. **Guidance drafted + wired**: d-implementation-plan.md enumerates exact file paths, exact consumer references, exact BACKLOG retirement edit.
4. **Tests defined**: e-testing-plan.md specifies grep checks for advertised-consumer wiring, line-budget, no-duplication-with-existing-docs.

## Risk Assessment
### High Priority Risks
- **Risk H1 — Sparse evidence**: Session-hygiene events may not be well-documented in retrospectives (retrospectives skew toward CWF workflow issues, not conversation-session issues). LMM corpus may also be thin on session-management metadata.
  - **Mitigation**: Triangulate three sources (retrospectives, memory files, LMM); accept the sparse-signal contingency in Success Criteria — produce principle-based guidance with explicit "no observed instance yet" labels rather than padding with fabricated evidence.

- **Risk H2 — Doc-cargo-cult / orphan doc**: Producing a guidance doc that no skill or convention points to, so it never gets read.
  - **Mitigation**: Success Criterion 3 mandates ≥1 advertised consumer before merge. If no advertised consumer can be justified, the doc itself is the wrong artefact and the task pivots to MEMORY.md additions instead.

### Medium Priority Risks
- **Risk M1 — Drift from actual tool behaviour**: Claude Code `/clear`, `/compact` semantics could be misremembered; producing guidance that contradicts the tool is worse than no guidance.
  - **Mitigation**: Per the "No fabricated citations" rule in MEMORY.md — empirical claims about `/clear`/`/compact` behaviour must be verified in-session (write a 3-line test) or labelled "principle, behaviour to verify at consumption time".

- **Risk M2 — Scope creep into generic best-practice writing**: Temptation to produce a general "Claude Code best practices" guide. The BACKLOG entry was specific to CWF session management; the discovery framing must constrain the deliverable to *this repo's* observed deviation patterns + the gaps those expose.
  - **Mitigation**: c-design-plan.md will pin a hard line-budget (≤60 lines per doc — sized to the conventions-doc tier; deliberate constraint, not a precedent-match since `tmp-paths.md` is 118 lines) and require every section to be either evidence-derived or explicitly principle-labelled.

- **Risk M3 — Misclassification of CWF-workflow errors as session-hygiene errors**: E.g., "agent failed to call retrospective until prompted" looks similar to "session ran out of context before retrospective" but the fix differs. Conflating the two would produce guidance that overlaps with existing skill Gotchas.
  - **Mitigation**: Audit step in b-requirements-plan.md will explicitly classify each candidate finding as (a) session-hygiene, (b) workflow-process, (c) both, with the classification rule recorded. Only (a) and (c) enter the guidance.

## Dependencies
- LMM MCP server reachable for `mcp__lmm__search_text` / `search_semantic` queries against the conversation corpus (degrades gracefully if unavailable; see Risk H1 mitigation)
- Existing `j-retrospective.md` files in `implementation-guide/*/` for retrospective mining
- `~/.claude/projects/-home-matt-repo-coding-with-files/memory/` for memory-file mining

## Constraints
- **Installed-only**: Guidance goes under `.cwf/docs/` per CLAUDE.md "internal to CWF development" rule — external CWF adopters must benefit too. No content placed under `docs/` (which is repo-internal).
- **No fabricated citations**: Every empirical claim cites a specific source readable at audit time. No "Per Claude Code docs…" unless the docs were actually read in this task.
- **No new code**: Documentation-only task. No skill behaviour changes, no helper-script changes. If the audit reveals a skill needs a Gotcha addition, that is a follow-up task (filed in BACKLOG, not absorbed).
- **No fix for in-flight retrospective gaps**: If the audit notices that a past task should have captured session-hygiene lessons but didn't, do NOT retroactively edit those retrospectives. Cite them as evidence of the gap; the gap itself is data.
- **British spelling** in prose.
- **Discovery-task scope discipline**: The c-design and d-implementation phases here are still narrow — design covers *guidance-doc shape*, implementation covers *writing the doc and wiring the references*. Anything that would require new tooling or skill behaviour gets deferred to a follow-up task.

## Decomposition Check
- [ ] **Time**: Will this take >1 week? No — 2–4 hours.
- [ ] **People**: Does this need >2 people working on different parts? No — single operator.
- [ ] **Complexity**: Does this involve 3+ distinct concerns? No — audit + write doc + wire references = sequential, single concern (session-hygiene guidance).
- [ ] **Risk**: Are there high-risk components that need isolation? No — H1 and H2 are content risks, not isolation candidates.
- [ ] **Independence**: Can parts be worked on separately? No — audit informs design informs implementation; sequential.

**Decomposition decision**: No subtasks. Single-task workflow proceeds.

## Status
**Status**: Finished
**Next Action**: /cwf-requirements-plan 150
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
