# assess current 2026 W6 skills and plugin stds - Design
**Task**: 54 (discovery)

## Task Reference
- **Task ID**: internal-54
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/54-assess-current-2026-w6-skills-and-plugin-stds
- **Template Version**: 2.1

## Goal
Define the research execution approach — phased methodology, tools, data flow between research areas, and output structure — for investigating current skills/plugin standards.

## Design Priorities
Reliability → Freshness → Actionability → Completeness → Efficiency

**Note**: Design priorities adapted for discovery research. Reliable sources and current data take precedence over exhaustive coverage.

## Key Decisions

### Research Methodology
- **Decision**: Phased sequential research with dependency-driven ordering
- **Rationale**: FR7 (design recommendations) depends on FR1-FR6 findings. Earlier phases (API state, community feedback) provide context that sharpens later investigation (technical blockers, recommendations). Sequential ordering avoids rework.
- **Trade-offs**: Slower than parallel research, but produces more coherent findings. Acceptable given 2-3 day budget.

### Source Strategy
- **Decision**: Primary sources first (GitHub commits, official docs), community sources second, inference last
- **Rationale**: NFR5 requires verifiable claims. Primary sources provide commit SHAs and URLs. Community sources (issues, discussions) provide sentiment and patterns. Inference used only when primary evidence is unavailable.
- **Trade-offs**: May miss emerging patterns only visible in community discussion. Mitigated by Phase 2 dedicated community research.

### Output Format
- **Decision**: Single research document (d-implementation-plan.md) with FR-aligned sections, each containing findings, evidence, and CIG implications
- **Rationale**: Consolidates all findings in one place for FR7 synthesis. Avoids fragmenting evidence across multiple files.
- **Trade-offs**: Long document, but table of contents and consistent structure ensure navigability.

### Baseline Approach
- **Decision**: Use Task 16 d-implementation.md as comparison baseline, document only deltas
- **Rationale**: Task 16 captured Jan 2026 state comprehensively. Repeating that work wastes time. Focus on what changed since then (NFR1 freshness requirement).
- **Trade-offs**: Assumes Task 16 findings are accurate. Low risk — findings were verified with multiple sources at the time.

## Research Architecture

### Phase Overview

```
Phase 1: API & Standards (FR1 + FR4)     ─┐
                                           ├─→ Phase 3: Technical (FR5 + FR6) ─┐
Phase 2: Community (FR2 + FR3)            ─┘                                    ├─→ Phase 4: Synthesis (FR7)
                                                                                │
                                                                  FR1-FR6 all ──┘
```

### Phase 1: API Evolution and Standards (FR1 + FR4)
**Purpose**: Establish the current technical landscape — what has changed and where standards are heading.

**Method**:
1. Search Claude Code GitHub repo for commits touching skills/plugin files (Jan 15 - Feb 10, 2026)
2. Search for release notes, changelog entries in official docs
3. Search Agent Skills specification repo for updates since Dec 2025
4. Cross-reference findings with Task 16 baseline (d-implementation.md sections on SKILL.md format, hooks, deployment models)

**Tools**: WebSearch, WebFetch (GitHub, official docs), Read (Task 16 baseline)

**Output per FR**: Findings table (change, date, source, breaking?), comparison to Task 16 baseline, implications for CIG

**Time budget**: 4 hours

### Phase 2: Community Intelligence (FR2 + FR3)
**Purpose**: Capture real-world usage patterns, pain points, and migration examples from early adopters.

**Method**:
1. Search GitHub Issues in anthropics/claude-code for skill/plugin/hook labels (last 30 days)
2. Search GitHub Discussions for Q&A and Ideas related to skills (last 30 days)
3. Search GitHub for repos containing both `.claude/commands/` and `.claude/skills/` (migration candidates)
4. Search for migration guides, blog posts, community examples
5. Categorise findings by theme (pain points, feature requests, workarounds, migration patterns)

**Tools**: WebSearch, WebFetch (GitHub issues/discussions, blog posts), Bash (GitHub API via `gh` if needed)

**Output per FR**: Categorised findings with issue/discussion references, code examples for workarounds, migration case studies with repo URLs

**Time budget**: 6 hours

### Phase 3: Technical Assessment (FR5 + FR6)
**Purpose**: Assess marketplace maturity and identify specific blockers for CIG's architecture.

**Method**:
1. Search for plugin marketplace, distribution docs, installation mechanisms
2. Map CIG's specific architecture against skills capabilities:
   - Perl scripts in `.cig/scripts/` — can skills reference external scripts?
   - Template pool in `.cig/templates/pool/` — can skills handle multi-file operations?
   - File operations outside `.claude/` — what are the permission boundaries?
   - Git operations — how do skills interact with git?
3. Cross-reference with Phase 1 (API capabilities) and Phase 2 (community workarounds) to identify solutions

**Tools**: WebSearch, WebFetch (docs), Read (CIG architecture files for reference)

**Output per FR**: Marketplace status summary, blocker table (blocker, severity, workaround, evidence)

**Time budget**: 4 hours

### Phase 4: Synthesis and Recommendations (FR7)
**Purpose**: Produce actionable decision matrix and recommendation grounded in FR1-FR6 evidence.

**Method**:
1. Compile decision-relevant findings from FR1-FR6
2. Define decision criteria with weights (informed by findings, not predetermined)
3. Score 4 options: Plugin, Skills-Only, Hybrid, Status Quo
4. Compare to Task 16 recommendation (Keep Commands with monitor-and-adapt)
5. Document confidence level and trigger conditions for revisiting

**Tools**: Read (FR1-FR6 findings), Edit (write FR7 section)

**Output**: Decision matrix table, scored options, recommendation with rationale, risk mitigation, review triggers

**Time budget**: 6 hours

## Data Flow

### Cross-Phase Dependencies
- **FR1 → FR6**: API capabilities determine what CIG can/cannot do with skills
- **FR4 → FR7**: Standardisation timeline affects timing recommendation
- **FR2 → FR7**: Pain points and community sentiment inform risk assessment
- **FR3 → FR7**: Migration patterns provide effort estimates and strategy options
- **FR5 → FR7**: Marketplace maturity affects distribution feasibility
- **FR6 → FR7**: Technical blockers may eliminate options from decision matrix

### Baseline Reference
- **Task 16 d-implementation.md** serves as the comparison baseline throughout
- Each FR section explicitly notes what has changed since Task 16

## Output Structure

The research output (d-implementation-plan.md) will follow this structure per FR section:

```
### FR<N>: <Title>

#### Findings
<Factual discoveries with dates and sources>

#### Evidence
<Source references: commit SHAs, issue URLs, doc links>

#### Implications for CIG
<What this means for migration decision>

#### Delta from Task 16
<What changed since Jan 2026 baseline>
```

FR7 section follows a different structure:

```
### FR7: Design Recommendations

#### Decision Criteria
<Criteria with weights and rationale>

#### Decision Matrix
<Table: 4 options × N criteria with scores>

#### Recommendation
<Clear recommendation with rationale>

#### Risk Mitigation
<Strategy for managing risks of chosen approach>

#### Confidence and Review Triggers
<Confidence level + conditions for revisiting>
```

## Constraints
- Read-only research — no CIG modifications, no proof-of-concept skills
- Public sources only — cannot access internal Anthropic repositories or docs
- Time-boxed per phase — move on when threshold met, document gaps
- Task 16 baseline assumed accurate — verify only if contradicting evidence found

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** — 20 hours across 4 phases
- [ ] **People**: Does this need >2 people working on different parts? **NO** — single researcher
- [x] **Complexity**: Does this involve 3+ distinct concerns? **YES** — 4 phases, 7 FRs
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** — research only
- [x] **Independence**: Can parts be worked on separately? **YES** — Phases 1-2 are independent

**Decision**: **Do NOT decompose** — Consistent with planning and requirements decisions. Phases 1-2 could run in parallel but sequential execution benefits from cross-pollination of findings. Total time (20 hours) within single-task budget.

## Validation
- [ ] Research methodology covers all 7 FRs from requirements
- [ ] Phase dependencies correctly ordered (FR7 last)
- [ ] Time budget sums to ~20 hours (within 2-3 day constraint)
- [ ] Output structure satisfies NFR2 (actionability) and NFR3 (organisation)
- [ ] Baseline approach avoids duplicating Task 16 work

## Status
**Status**: Finished
**Next Action**: N/A (complete)
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
