# assess current 2026 W6 skills and plugin stds - Requirements
**Task**: 54 (discovery)

## Task Reference
- **Task ID**: internal-54
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/54-assess-current-2026-w6-skills-and-plugin-stds
- **Template Version**: 2.1

## Goal
Define the research deliverables, quality standards, and acceptance criteria for assessing the current state of Claude Code skills and plugin architecture (Feb 2026 W6), building on Task 16's baseline (Jan 2026) to inform CIG's migration strategy.

## Functional Requirements

**Note**: This is a discovery task. Functional requirements define **research deliverables** rather than software specifications.

### FR1: Skills API Evolution (Jan to Feb 2026)
Document all changes to the Claude Code skills/plugin API between Task 16 (mid-Jan 2026) and present (Feb W6 2026).

- FR1.1: SKILL.md frontmatter field changes (new, deprecated, validation changes)
- FR1.2: Hook type or trigger condition changes
- FR1.3: Plugin vs skill-only deployment model changes
- FR1.4: New capabilities not present in Jan 2026
- FR1.5: Breaking changes requiring migration

**Sources**: Claude Code GitHub commit history (Jan 15 - Feb 10, 2026), official documentation changelog, release notes, GitHub issues mentioning "breaking change" or "deprecation" (last 30 days)

**AC**: All API changes documented with commit references and dates; breaking vs non-breaking changes identified with migration guidance; experimental features flagged; current spec compared to Task 16 baseline

### FR2: User Feedback Analysis (Early Adopters)
Catalogue what users are reporting about skills/plugins in real-world usage.

- FR2.1: Frequently reported pain points
- FR2.2: Requested features
- FR2.3: Workarounds and emergent patterns
- FR2.4: Common pitfalls or gotchas
- FR2.5: Praise vs criticism themes

**Sources**: GitHub Issues with labels "skill", "plugin", "hook" (last 30 days); GitHub Discussions in Q&A and Ideas categories (last 30 days); community example repositories (search: "claude code skill" OR "claude code plugin", created after Jan 1, 2026)

**AC**: 10+ distinct pain points catalogued with issue references; 5+ frequently requested features identified with upvote counts; 3+ common workarounds documented with code examples; sentiment summary (positive, neutral, negative themes)

### FR3: Migration Pattern Catalogue (Commands to Skills)
Document how projects are migrating from commands to skills, with lessons that inform CIG's approach.

- FR3.1: Migration strategies in use (big-bang, incremental, hybrid)
- FR3.2: Technical challenges encountered
- FR3.3: Backward compatibility approaches
- FR3.4: Rollback strategies used
- FR3.5: Effort estimates (duration, lines changed)

**Sources**: GitHub repos with both `.claude/commands/` and `.claude/skills/` directories; repos that removed `.claude/commands/` (commit history); migration guides or blog posts; Anthropic examples or templates; community discussions tagged "migration" (last 60 days)

**AC**: 3+ real-world migration examples documented with repo URLs and commit ranges; for each: strategy, duration, challenges, outcomes; common challenges identified (appears in 2+ examples); reusable patterns and anti-patterns extracted

### FR4: Hooks Standardisation Progress
Assess progress on hooks standardisation across agent platforms since Task 16 identified the Agent Skills spec (Dec 18, 2025).

- FR4.1: Platform adoption beyond Claude Code (Microsoft, GitHub, OpenAI, Cursor)
- FR4.2: Agent Skills specification updates since Dec 2025
- FR4.3: Reference implementations from other platforms
- FR4.4: Current adoption timeline estimate
- FR4.5: Competing hook specifications gaining traction

**Sources**: Agent Skills specification repository (commits Jan 1 - Feb 10, 2026); Microsoft, GitHub, OpenAI, Cursor documentation (search for "hooks" or "Agent Skills"); industry announcements (last 60 days)

**AC**: Adoption status documented per platform; specification changes since Dec 18, 2025 identified; timeline estimate updated with confidence level; divergences or competing standards noted

### FR5: Plugin Marketplace and Distribution Status
Document the current state of plugin discovery, distribution, and installation.

- FR5.1: Public marketplace or directory existence
- FR5.2: Distribution mechanisms (npm, GitHub releases, marketplace)
- FR5.3: Quality standards or review processes
- FR5.4: Plugin discovery mechanisms
- FR5.5: Installation mechanisms and workflow

**Sources**: Claude Code official documentation (marketplace section); GitHub repositories tagged "claude-code-plugin"; community discussions about plugin distribution (last 30 days)

**AC**: Current distribution mechanisms documented with examples; 5+ popular plugins identified with installation counts (if available); discovery workflow described from user perspective; submission or review processes documented

### FR6: Technical Blockers for CIG Migration
Identify specific technical blockers that would prevent or complicate CIG's migration to skills/plugins.

- FR6.1: Perl script compatibility with plugin bundling
- FR6.2: Helper script referencing from skills (`.cig/scripts/`)
- FR6.3: Multi-file template handling (`.cig/templates/pool/`)
- FR6.4: File modification outside `.claude/` directory
- FR6.5: Permission and security restrictions
- FR6.6: Git operation handling from skills

**Sources**: Skills frontmatter `allowed-tools` field specification; reference implementations using shell scripts; security documentation for plugin sandboxing; GitHub issues mentioning "permission denied" or "security" (last 30 days)

**AC**: Blockers documented with severity (critical/high/medium/low); workarounds or solutions identified per blocker; capabilities CIG would lose in migration flagged; security and permission model differences documented

### FR7: Design Recommendations
Produce a decision matrix and actionable recommendation for CIG's migration approach, grounded in FR1-FR6 findings.

- FR7.1: Timing decision (migrate now, wait, or phased)
- FR7.2: Approach decision (plugin, skills-only, hybrid, status quo)
- FR7.3: Migration strategy (big-bang, incremental, phased)
- FR7.4: Decision criteria and weights
- FR7.5: Confidence level with reasoning

**Inputs**: All findings from FR1-FR6

**AC**: Decision matrix with 4+ options scored against 6+ criteria; clear recommendation with rationale grounded in FR1-FR6 evidence; risk mitigation strategy for chosen approach; confidence level (high/medium/low) with reasoning; trigger conditions for revisiting decision

### User Stories
- **As a** CIG maintainer **I want** a current assessment of skills/plugin API state **so that** I can make an informed migration decision based on facts rather than assumptions
- **As a** CIG maintainer **I want** to understand technical blockers specific to CIG's architecture **so that** I can estimate migration effort accurately
- **As a** CIG user **I want** to know whether the command-based workflow will remain supported **so that** I can plan my workflow accordingly

## Non-Functional Requirements

**Note**: NFR categories adapted for discovery research quality rather than software characteristics.

### Freshness (NFR1)
- Primary focus: sources dated Feb 1-10, 2026 (current week)
- Secondary: sources from Jan 15-31, 2026 (context since Task 16)
- Information older than Jan 15 flagged as "historical"
- Each finding explicitly dated
- **Target**: 80% of cited sources dated Jan 15 - Feb 10, 2026

### Actionability (NFR2)
- Every finding connects to a decision factor (timing, approach, risk)
- Each FR section includes "Implications for CIG" analysis
- Facts distinguished from interpretation
- Concrete examples preferred over abstract concepts
- **Target**: All FR sections include an "Implications for CIG" subsection

### Organisation (NFR3)
- Consistent structure per FR: findings, evidence, implications
- Headings, lists, tables for scannability
- All claims link to sources (GitHub issues, commits, docs URLs)
- Raw findings separated from analysis
- **Target**: 100% of claims link to verifiable sources

### Completeness (NFR4)
- Each FR has minimum evidence thresholds (see AC criteria above)
- Research stops when threshold met (avoid diminishing returns)
- "Out of scope" areas documented explicitly
- Each FR section time-boxed to 4 hours maximum
- **Target**: All FR sections meet their minimum AC thresholds

### Reliability (NFR5)
- Primary sources preferred (GitHub commits, official docs) over secondary
- Critical claims require 2+ independent sources
- Source credibility noted (official Anthropic, community, speculation)
- Commit SHAs, issue numbers, and URLs included
- **Target**: 100% of claims have 1+ source; critical claims have 2+ sources

## Constraints

### Scope
- Research limited to publicly available information (no internal Anthropic docs)
- Focus on Claude Code skills/plugins (not broader MCP unless directly relevant)
- No implementation or proof-of-concept (pure research)
- Builds on Task 16 baseline — avoid duplicating pre-Jan 2026 research

### Resources
- Time-boxed to 2-3 days total (16-24 hours)
- Read-only tools only (WebSearch, WebFetch, Read, Bash for git)
- Must not modify CIG system during research

### Timing
- Must complete before Q2 2026 checkpoint (target: Feb 14, 2026)
- Findings must inform an immediate decision (not long-term strategy only)

### Out of Scope
- Implementation details (how to migrate CIG — that belongs in design phase if recommendation is "migrate")
- MCP ecosystem deep-dive (unless it impacts skills/plugins directly)
- Alternative agent platforms (unless Agent Skills adoption is relevant)
- Historical analysis pre-Jan 2026 (Task 16 covered this)
- Performance benchmarking
- User surveys (use existing public feedback only)

## Decomposition Check
Review these signals to determine if this task should be broken into subtasks:
- [ ] **Time**: Will this take >1 week? **NO** — 2-3 days estimated
- [ ] **People**: Does this need >2 people working on different parts? **NO** — single researcher
- [x] **Complexity**: Does this involve 3+ distinct concerns? **YES** — 7 FRs across API, community, migration, ecosystem, technical, and strategy
- [ ] **Risk**: Are there high-risk components that need isolation? **NO** — research only
- [x] **Independence**: Can parts be worked on separately? **YES** — FR1-FR6 are independent; FR7 depends on FR1-FR6

**Decision**: **Do NOT decompose** — Consistent with planning phase decision. Sequential research is more efficient because findings from earlier FRs inform later ones (particularly FR7). Total time (2-3 days) does not justify decomposition overhead.

## Acceptance Criteria
- [ ] AC1: FR1-FR6 research deliverables each meet their minimum evidence thresholds
- [ ] AC2: FR7 decision matrix produced with 4+ options scored against 6+ weighted criteria
- [ ] AC3: NFR1-NFR5 quality standards met across all findings
- [ ] AC4: All claims link to verifiable sources (commit SHAs, issue numbers, URLs)
- [ ] AC5: Each FR section includes "Implications for CIG" analysis
- [ ] AC6: Clear actionable recommendation with confidence level and trigger conditions for revisiting
- [ ] AC7: Constraints and scope boundaries respected (no scope creep into implementation)

## Status
**Status**: Finished
**Next Action**: N/A (complete)
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
