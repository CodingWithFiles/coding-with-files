# Session hygiene guidance from past deviations - Requirements
**Task**: 150 (discovery)

## Task Reference
- **Task ID**: internal-150
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/150-session-hygiene-guidance-from-past-deviations
- **Template Version**: 2.1

## Goal
Specify what the produced guidance doc(s) must say and how they must be wired — driven by the deviation audit below.

## Deviation Audit (discovery-task input)

### Sources consulted
- `implementation-guide/*/j-retrospective.md` — grep returned 7 candidates; after content read only Task 97 + Task 103 contain genuine session-hygiene material (others false positives — "compact" = doc length, "session" = unrelated).
- `~/.claude/projects/-home-matt-repo-coding-with-files/memory/*.md` — `error-patterns.md`, `feedback_no_fabricated_citations.md`, `feedback_no_heredocs.md`, `feedback_no_find_no_sed_permissions.md`, `MEMORY.md` § "Recurring Process Errors" carry session-relevant evidence.
- `.cwf/docs/workflow/stop-hooks-framework.md:7,13,15` — only installed-CWF doc that explicitly names `/clear`, `/compact`, resume as Stop-hook firing events with context-cost framing AND identifies UserPromptSubmit rules-injection as the per-turn re-injection surface.
- **LMM corpus** — **unavailable this session** (`mcp__lmm__search_semantic` returned `User not found: claude@mattkeenan.net`). Audit proceeds without it per a-plan Risk H1 mitigation; recorded as R-LMM follow-up only — no further restatement.

### Pattern table

| # | Pattern | Evidence | Category |
|---|---------|----------|----------|
| P1 | **Memory-disuse across sessions** — agent does not reload relevant project memories at session start, so corrections that were captured to memory recur. | `memory/error-patterns.md:45` ("Pattern still recurring after the memory entry exists — likely not read/applied in session") | (a) |
| P2 | **Compaction silently drops standing rules** — auto-compaction summarises the conversation; the summary may omit security-relevant standing instructions, forcing the user to restate them mid-session. | This session, 2026-05-17: post-compaction turn-0 summary had to enumerate ~18 standing rules verbatim under "All user messages" because summarisation does not preserve durable instructions by default. | (a) |
| P3 | **Cross-session principle leaks** — same correction needed multiple times across distinct sessions despite a memory entry existing. | `memory/feedback_no_heredocs.md:9` ("Confirmed across multiple sessions including Task 124"); `feedback_no_find_no_sed_permissions.md:9` (generalisation event). | (a) — distinct from P1: P1 is "memory not read", P3 is "memory read but principle still violated". |
| P4 | **Stop-hook context cost on session boundaries** — `/clear`, `/compact`, resume all fire Stop hooks; each token of hook output paid every turn until next compaction. Hook authors do not always price this. | `.cwf/docs/workflow/stop-hooks-framework.md:7,13` | (a) |
| P5 | **Workflow-chain interruption on resume** — agent stops mid-chain when sessions resume mid-task; workflow-pointer state is implicit in the task directory, not re-derived from on-disk wf step files. | `memory/error-patterns.md:104–116` (O1 recurring); MEMORY.md "Retrospective auto-flow" entry. | (c) — workflow-process residue handled by existing skill Gotchas; session-hygiene contribution = "re-derive from on-disk wf state, do not trust resumed conversation's claim". |

**Classification key**: (a) = session-hygiene only, (b) = workflow-process only (out of scope), (c) = both. Only (a) and (c) feed the guidance.

**Patterns folded into guidance**: P1, P2, P3, P4, and the named (c)-residue of P5 (workflow-state re-derivation; see FR3.AC3.3).

### Sparse-signal contingency check
a-plan threshold was "≥3 distinct patterns or pivot to principle-based guidance". Audit found 4 clear (P1–P4) + 1 named residue (P5). **Threshold met**; evidence-cited sections proceed.

## Functional Requirements

### FR1 — Triggering conditions for `/clear`
Guidance MUST enumerate concrete conditions for when `/clear` is the right action.
- **AC1.1**: ≥3 triggering conditions listed
- **AC1.2**: ≥2 of the 3 conditions cite an audit-table pattern (P1–P5). At most one may be "principle — no observed instance" labelled.
- **AC1.3**: Distinguishes `/clear` (full reset) from "continue current session"

### FR2 — Triggering conditions for `/compact` + preservation list
Guidance MUST enumerate when to `/compact` proactively (vs. auto-compaction) and what to preserve across the compaction boundary.
- **AC2.1**: Doc contains the substring `/compact` AND a separate bullet referencing auto-compaction; each has its own guidance entry.
- **AC2.2**: Preservation list names ≥3 specific item categories AND explicitly includes "standing security rules from CLAUDE.md `## Critical Rules` and MEMORY.md" as one named category (security F2 — preservation list must not silently drop the rules).
- **AC2.3**: Maps to P2 with citation.

### FR3 — Cross-session principle salience + workflow-state authoritativeness
Guidance MUST address (a) how an agent ensures memory entries are actually applied (not merely stored), and (b) how an agent on session-resume reconstructs the workflow-state pointer.
- **AC3.1**: Recommends explicit memory-read at session start for the project's MEMORY.md (addresses P1).
- **AC3.2**: Recommends "after a correction, immediately confirm whether a memory entry exists, then write or update if not" (addresses P3).
- **AC3.3**: On session-resume, recommends re-deriving the current wf step from the on-disk task directory (`a-task-plan.md` through `j-retrospective.md` Status fields) as the authoritative source — NOT from the resumed conversation's claim about "what step we're on". Addresses the named (c)-residue of P5.

### FR4 — Single source of truth + reachable advertised consumer (merged FR4+FR5+NFR3.1)
Guidance MUST live in exactly one canonical file and be reachable from a consumer that survives `/compact` boundaries.
- **AC4.1**: Exactly ONE canonical guidance file is added under `.cwf/docs/`. Multiple files violate this AC.
- **AC4.2**: Reachable from at least ONE of: (a) `CLAUDE.md` `## Conventions` entry (always-loaded), OR (b) any TWO of {`.claude/rules/*.md` (rules-injection), SKILL.md Gotcha, `.cwf/docs/workflow/*.md` section}. A single SKILL.md-only or single rules-only consumer is insufficient under (b).
- **AC4.3**: Link uses bare relative-path syntax (e.g. `` `.cwf/docs/skills/<name>.md` ``) matching the `CLAUDE.md:73-90` precedent. **No `[[X]]` wiki-link notation in committed CWF docs** when referencing other committed CWF docs (M1 misalignment — `[[X]]` is acceptable only for private MEMORY.md slug references, e.g. `[[feedback_no_heredocs]]` in `tmp-paths.md:38`).
- **AC4.4**: Cross-references replace any verbatim restatement >1 sentence from existing CWF docs / MEMORY.md.
- **AC4.5 (contingency)**: If c-design or d-implementation finds AC4.2 cannot be satisfied, the doc-shaped solution is retired and the task pivots to MEMORY.md additions per a-plan Risk H2.
- **AC4.6 (self-application)**: Because the guidance documents a failure mode (P2) that affects the guidance itself, the AC4.2 advertised consumer MUST be one that survives `/compact` — `CLAUDE.md`, `.claude/rules/`, or project memory. Arbitrary `.cwf/docs/` files do not qualify as the sole consumer because they are not auto-reloaded post-compact.

## Non-Functional Requirements

### Usability (NFR2)
- **NFR2.1**: Line budget ≤60 per guidance doc — deliberate constraint, sized to the conventions-doc tier (counter-precedent: `tmp-paths.md` is 118 lines, so this is a *new* constraint not a precedent-match). Declarative `when X → do Y` framing.

### Security (NFR4) — inline principle + anti-pattern enumeration
- **NFR4.1**: Guidance MUST embed inline (not by external citation) the principle: "Surface security signals; never propose preserving a *summary* of standing security rules in place of the rules themselves; never propose `/clear` as a way to escape a stuck security gate." (Lifted inline because the principle's prior residence is operator-private memory — Security F1.)
- **NFR4.2**: Doc MUST NOT contain the strings `recompute-hashes`, `validate --fix`, `validate --ignore`. MUST NOT contain phrase patterns matching `/clear.*(?:escape|bypass|skip)` or `compact.*(?:drop|forget|skip).*(?:security|rule)` (Robustness F9 — concrete anti-pattern grep).
- **NFR4.3 (defender-framing)**: Guidance MUST describe the P2 failure mode from the defender's side (what to preserve, when to act). MUST NOT enumerate inputs/conditions that reliably trigger rule-loss as a recipe (Security F4). Permitted: "after compaction, restate standing rules". Forbidden: "to induce rule drop, write a long irrelevant preamble".

## Constraints
- **Installed-only**: guidance under `.cwf/docs/`, not `docs/` (per CLAUDE.md "internal to CWF development" rule)
- **No new code / no skill behaviour changes** — doc + cross-references only
- **No fabricated citations**: every empirical claim cites a specific source; principle-only sections are explicitly labelled
- **British spelling** in prose

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2 people? No.
- [ ] **Complexity**: 3+ distinct concerns? No.
- [ ] **Risk**: High-risk isolation? No.
- [ ] **Independence**: Parts separable? No.

**Decomposition decision**: No subtasks. Confirmed from a-plan.

## Acceptance Criteria (rollup)
- [ ] **AC1**: FR1–FR4 sub-ACs all satisfied (verified by e-testing TCs).
- [ ] **AC2**: NFR2.1 line budget held (`wc -l` ≤ 60).
- [ ] **AC3**: NFR4.1 inline principle present; NFR4.2 anti-pattern grep returns empty; NFR4.3 defender-framing verified by manual read of the produced doc.

(BACKLOG-entry retirement is a process step in d-implementation, not a content acceptance criterion — see a-plan Success Criteria.)

## Recommendations (out of scope, captured for follow-up)
- **R-LMM**: Re-audit when LMM access is restored. The separate BACKLOG entry "Research Compaction Failure Frequency via LMM Memory Analysis" covers the quantitative measurement gap; if picked up, fold findings back into this guidance.

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 150
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*Plan-review surfaced an M1 misalignment in this task's own a-task-plan: `[[hash-updates]]` / `[[tmp-paths]]` wiki-link references should be bare relative paths per CLAUDE.md `:73-90` precedent. Fixed in this phase commit alongside b-requirements-plan.md. Note: `[[X]]` referencing operator-private MEMORY.md slugs (like `[[feedback_no_heredocs]]`) is acceptable per `tmp-paths.md:38,41` precedent.*
