# Session hygiene guidance from past deviations - Design
**Task**: 150 (discovery)

## Task Reference
- **Task ID**: internal-150
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/150-session-hygiene-guidance-from-past-deviations
- **Template Version**: 2.1

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

Documentation-only deliverable; design decisions are about *doc shape* and *consumer wiring*, not runtime architecture.

## Key Design Decisions

### D1 — Doc placement: `.cwf/docs/conventions/session-hygiene.md`
- **Decision**: Single file at `.cwf/docs/conventions/session-hygiene.md`, peer to `hash-updates.md`, `tmp-paths.md`, `subagent-tool-selection.md`. Tier-sizing data: existing convention docs are 49, 57, 118 lines (`wc -l .cwf/docs/conventions/*.md`); the 60-line budget sits with the dominant cluster (49, 57).
- **Installed vs project-development tier (M1)**: This convention applies at agent runtime (in this repo and in downstream CWF installs), so it belongs under `.cwf/docs/conventions/` (sibling of `hash-updates.md`, `tmp-paths.md`). The other `## Conventions` bullets in `CLAUDE.md` (Commit Messages, Design Alignment, Perl, Git-Path) reference `docs/conventions/` — those are CWF-author-only conventions per the CLAUDE.md "internal to CWF development" guardrail.
- **Alternatives rejected**: Two files (forces two consumer wirings; violates AC4.1). `.cwf/docs/skills/` (skills-tier is for skill-mechanics docs like `workflow-preamble.md`). `.cwf/docs/workflow/` (phase/framework tier).

### D2 — Advertised consumer: CLAUDE.md `## Conventions` entry
- **Decision**: One bullet under `CLAUDE.md` `## Conventions`, after the `**Hash Updates**` entry, following the `CLAUDE.md:73-90` precedent.
- **Rationale**: AC4.2(a) + AC4.6 require a consumer reachable post-`/compact`. **Structural mechanism**: CLAUDE.md is reloaded fresh into context on each turn by the harness (Security F5 reframe of Robustness F1) — so any bullet under `## Conventions` is retained by construction. This is distinct from "compaction preserves the bullet"; compaction may rewrite the *conversation* summary but the CLAUDE.md preamble is reloaded independently.
- **Alternatives rejected**: `.claude/rules/` rules-injection (adds new tooling — forbidden by a-plan "no new code"); SKILL.md Gotcha alone (only loads when skill runs); `.cwf/docs/workflow/stop-hooks-framework.md` reference (read only by hook authors, wrong reach).
- **Fallback (AC4.5 wired)**: If d-implementation finds the CLAUDE.md wiring rejected (e.g. CLAUDE.md size pressure, maintainer veto), the task pivots per a-plan Risk H2 to MEMORY.md additions and the doc-shaped artefact is retired.

### D3 — Section shape: 4 content sections + cross-refs (≤60 lines total)
Section count reduced from a prior 8-section draft after plan-review surfaced header/blank-line overhead would compress content to ~5.5 lines/section. The shape below tracks `hash-updates.md`'s mix of short opening sections and one denser body section.

| § | Heading | Maps to | Content target |
|---|---------|---------|----------------|
| 1 | **Convention** (rule + why in one opening) | All FRs frame | ~6 lines |
| 2 | **When to `/clear`** | FR1 (≥3 conditions, ≥2 cite audit patterns) | ~10 lines |
| 3 | **When to `/compact` + what to preserve** (carries inline security principle) | FR2 (`/compact` vs auto), NFR4.1 (inline principle), NFR4.2 (enumerate forbidden anti-patterns), NFR4.3 (defender framing) | ~16 lines |
| 4 | **Session boundaries: memory + workflow-state on resume** | FR3.AC3.1, AC3.2 (memory salience), AC3.3 (re-derive wf state from on-disk task files) | ~10 lines |
| Tail | **See also** (bare-path cross-refs) | AC4.4 single-source-of-truth | ~2 lines |

**Slack-allocation policy (Robustness F4)**: If budget pressure arises, the **Tail** cross-refs compress first; **§3 security content is non-negotiable per NFR4.1**. §1 and §4 may merge if absolutely required.

**§3 anti-pattern handling (Robustness F6 clarification)**: §3 explicitly enumerates the NFR4.2 forbidden patterns *in-doc* (`recompute-hashes`, `validate --fix`, `validate --ignore`, `/clear`-as-gate-bypass, compaction-induced rule drop) under a "Do not propose" sub-bullet, so future readers see the boundary. The write-time grep (NFR4.2 testing) verifies these strings appear only in defender-framed context, not as recipes.

**§4 scope boundary (Robustness F5)**: "memory + workflow-state on resume" — limited to the session-hygiene slice (re-derive wf pointer from disk, re-read MEMORY.md). Workflow auto-flow rules (proceed-from-g-to-j without prompt, run status sweep before retrospective) remain in MEMORY.md "Recurring Process Errors" and are cross-referenced, not duplicated.

### D4 — Cross-reference policy
- **Decision**: For each concept covered by an existing CWF doc / MEMORY.md section, the new doc states the session-hygiene-specific consequence in ≤1 sentence and links the source. No verbatim copy >1 sentence.
- **Reference syntax (M2)**: Bare relative paths for committed CWF docs (e.g. `` `.cwf/docs/workflow/stop-hooks-framework.md` ``). `[[slug]]` wiki-link permitted only for MEMORY.md slug references — matching the `tmp-paths.md:38,41` precedent.
- **§3 inline-exception (Security F6)**: NFR4.1 mandates *inline* embedding of the "surface, never smooth" principle, which overrides the >1-sentence cap for that paragraph. The principle's prior committed-CWF residence is `hash-updates.md` `## What NOT to build` (sibling precedent — that doc inlines the same principle for its own domain); §3 inlines only the session-hygiene-specific consequence and cross-references the sibling.

### D5 — Explicit non-goals (design-level only)
- **No retroactive edits to past retrospectives**. The audit cites the gap; the gap is data.
- (Other a-plan-level non-goals — no new code, no rules-injection wiring, no LMM re-audit — remain in force from a-plan; not re-listed here.)

## Component Overview
| Component | Purpose | New / Modified |
|-----------|---------|----------------|
| `.cwf/docs/conventions/session-hygiene.md` | Canonical guidance doc (≤60 lines, 4 content sections + tail) | NEW |
| `CLAUDE.md` `## Conventions` | Advertised entry-point bullet after `**Hash Updates**` | MODIFIED |

(BACKLOG-entry retirement is a d-implementation step, not a design component.)

## Data Flow
N/A — documentation only. Reader navigation:
1. Agent encounters a session-hygiene decision (about to `/clear`, `/compact`, or resume).
2. CLAUDE.md `## Conventions` (reloaded per turn) names the canonical doc.
3. Agent Reads `.cwf/docs/conventions/session-hygiene.md`.
4. Doc points to specific sections of MEMORY.md / stop-hooks-framework.md / CLAUDE.md `## Critical Rules` for detail.

## Interface Design
Section headings (D3 §1–§4 + Tail) are the contract. Every requirement in b-requirements maps to a section:
- FR1 → §2
- FR2 → §3 (`/compact` + preservation list)
- FR3.AC3.1, AC3.2 → §4 (memory)
- FR3.AC3.3 → §4 (workflow-state on resume)
- FR4 (entry-point) → CLAUDE.md modification, not a doc section
- NFR4.1, NFR4.2, NFR4.3 → §3 (inline security principle + anti-pattern enumeration + defender framing)

## Constraints
- ≤60 lines (NFR2.1) with the slack-allocation policy in D3
- Bare relative paths for committed-CWF cross-refs; `[[slug]]` for MEMORY.md only
- Inline-principle exception in §3 (D4 + Security F6)
- British spelling

## Decomposition Check
- [ ] **Time**: >1 week? No.
- [ ] **People**: >2? No.
- [ ] **Complexity**: 3+ distinct concerns? No.
- [ ] **Risk**: High-risk isolation? No.
- [ ] **Independence**: Parts separable? No.

**Decomposition decision**: No subtasks.

## Validation (testable, wired to e-testing)
- [ ] Each FR1–FR4 sub-AC maps to a section per Interface Design table above.
- [ ] `wc -l .cwf/docs/conventions/session-hygiene.md` ≤ 60 (NFR2.1).
- [ ] NFR4.2 anti-pattern grep returns empty for the four prohibited strings and two regex patterns from b-requirements (Robustness F2 + Security F4 — wired into e-testing TC).
- [ ] Manual content review by writer: NFR4.3 defender-framing held (no input-condition-as-recipe phrasing). Acknowledged as judgement-gate, not grep-gate (Robustness F7).
- [ ] `CLAUDE.md` post-modification contains one bullet referencing `.cwf/docs/conventions/session-hygiene.md` (AC4.2 + AC4.3 + AC4.6 — verified by grep).

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 150
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*Plan-review collapsed an 8-section first draft to 4 content sections + tail after subagent math (`hash-updates.md` analogue: ~7 lines/section gross becomes ~5.5 content lines after H2 + blank-line overhead). Restructure preserves all FR/NFR coverage with ~12 content lines per section average.*
