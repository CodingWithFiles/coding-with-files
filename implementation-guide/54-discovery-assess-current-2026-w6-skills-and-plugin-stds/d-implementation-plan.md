# assess current 2026 W6 skills and plugin stds - Implementation Plan
**Task**: 54 (discovery)

## Task Reference
- **Task ID**: internal-54
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/54-assess-current-2026-w6-skills-and-plugin-stds
- **Template Version**: 2.1

## Goal
Plan the concrete research steps for each phase defined in the design, with specific search queries, URLs, tools, and validation criteria.

## Workflow
Read baseline → Search primary sources → Search community sources → Cross-reference → Document findings → Synthesise

## Files to Modify
### Primary Changes
- `f-implementation-exec.md` — Research findings for FR1-FR7 (structured per c-design-plan.md output format)

### Supporting Changes
- `c-design-plan.md` — Status update to Finished after implementation plan complete

## Implementation Steps

### Step 1: Load Task 16 Baseline
- [ ] Read Task 16 findings: `implementation-guide/16-discovery-investigate-skills-configuration-and-integration/d-implementation.md`
- [ ] Extract key baseline data points:
  - SKILL.md frontmatter fields known in Jan 2026
  - Hook types and behaviour documented
  - Plugin vs skill-only deployment models
  - Agent Skills specification status (Dec 18, 2025)
  - Task 16 recommendation (Keep Commands, 47/55 score)
- [ ] Note specific sections and line ranges for cross-reference during research

### Step 2: Phase 1 Research — API Evolution and Standards (FR1 + FR4)

**FR1: Skills API Evolution**
- [ ] WebSearch: `site:github.com/anthropics/claude-code "skill" OR "SKILL.md" OR "plugin" 2026`
- [ ] WebSearch: `"claude code" skills changelog OR "release notes" 2026`
- [ ] WebSearch: `"claude code" "breaking change" skills OR plugin 2026`
- [ ] WebFetch: Claude Code official documentation (skills/plugin section)
- [ ] WebFetch: Claude Code GitHub releases page (Jan-Feb 2026 releases)
- [ ] Cross-reference each finding against Task 16 baseline
- [ ] Document: changes table (what, when, source, breaking?)

**FR4: Hooks Standardisation**
- [ ] WebSearch: `"agent skills" specification 2026`
- [ ] WebSearch: `"agent skills" hooks Microsoft OR GitHub OR OpenAI OR Cursor 2026`
- [ ] WebSearch: `agentskills.md OR "agent-skills" specification update 2026`
- [ ] WebFetch: Agent Skills spec repository (if URL found)
- [ ] Document: platform adoption status table, spec changes since Dec 2025

**Phase 1 validation**: FR1 has changes documented with dates and sources; FR4 has adoption status per platform

### Step 3: Phase 2 Research — Community Intelligence (FR2 + FR3)

**FR2: User Feedback Analysis**
- [ ] Bash: `gh search issues --repo anthropics/claude-code "skill" --sort updated --limit 20`
- [ ] Bash: `gh search issues --repo anthropics/claude-code "plugin" --sort updated --limit 20`
- [ ] Bash: `gh search issues --repo anthropics/claude-code "hook" --sort updated --limit 20`
- [ ] WebSearch: `site:github.com/anthropics/claude-code/discussions skills OR plugin 2026`
- [ ] For top issues (5+ comments or 10+ reactions): read full thread via `gh issue view`
- [ ] Categorise: pain points, feature requests, workarounds, praise, criticism
- [ ] Document: categorised findings with issue numbers and reaction counts

**FR3: Migration Pattern Catalogue**
- [ ] WebSearch: `"claude code" command to skill migration 2026`
- [ ] WebSearch: `site:github.com ".claude/skills" ".claude/commands"` (repos with both)
- [ ] WebSearch: `"claude code" migrate commands skills blog OR guide 2026`
- [ ] For each migration example found: document strategy, challenges, outcome
- [ ] Document: migration case studies with repo URLs, patterns and anti-patterns

**Phase 2 validation**: FR2 has 10+ pain points catalogued; FR3 has 3+ migration examples (or documented that fewer exist with evidence of thorough search)

### Step 4: Phase 3 Research — Technical Assessment (FR5 + FR6)

**FR5: Plugin Marketplace Status**
- [ ] WebSearch: `"claude code" plugin marketplace OR directory 2026`
- [ ] WebSearch: `"claude code" plugin install OR distribution 2026`
- [ ] WebFetch: Claude Code docs — plugin installation/marketplace sections
- [ ] Bash: `gh search repos "claude-code-plugin" --sort updated --limit 10`
- [ ] Document: distribution mechanisms, popular plugins, discovery workflow

**FR6: Technical Blockers for CIG**
- [ ] Review FR1 findings for capability constraints relevant to CIG
- [ ] Check: can skills reference scripts outside `.claude/` directory?
  - WebSearch: `"claude code" skill "allowed-tools" OR permissions script 2026`
- [ ] Check: can skills handle multi-file template operations?
  - WebSearch: `"claude code" skill multiple files OR template 2026`
- [ ] Check: skill permission model and file access boundaries
  - WebSearch: `"claude code" skill security OR sandbox OR permission 2026`
- [ ] Check: git operation support from skills
  - Search community workarounds from FR2 findings
- [ ] Map each CIG component against skill capabilities:
  - `.cig/scripts/command-helpers/` (5 Perl scripts) — bundling/referencing?
  - `.cig/templates/pool/` (multi-file templates) — file operations?
  - `implementation-guide/` (task directories) — write access outside `.claude/`?
  - Git operations (commit, branch, status) — allowed?
- [ ] Document: blocker table (blocker, severity, workaround, evidence)

**Phase 3 validation**: FR5 has marketplace status documented; FR6 has blockers with severity ratings

### Step 5: Phase 4 Research — Synthesis and Recommendations (FR7)

**Prerequisites**: FR1-FR6 findings complete

- [ ] Compile decision-relevant findings from each FR section
- [ ] Define decision criteria based on what emerged from research:
  - Candidate criteria: migration risk, hooks value, portability, marketplace maturity, technical feasibility, reversibility, effort, timing
  - Assign weights based on CIG's specific situation
- [ ] Score 4 options against criteria:
  - Option A: Convert to Claude Code Plugin
  - Option B: Convert to Skills-Only
  - Option C: Hybrid (skills + commands)
  - Option D: Keep Commands (status quo)
- [ ] Compare result to Task 16 recommendation (Keep Commands)
- [ ] Document: what changed in the recommendation (if anything) and why
- [ ] Define confidence level and trigger conditions for revisiting
- [ ] Document: decision matrix, recommendation, risk mitigation, review triggers

**Phase 4 validation**: Decision matrix complete; recommendation actionable with confidence level stated

### Step 6: Cross-Reference and Quality Check
- [ ] Verify NFR1 (Freshness): 80%+ sources from Jan 15 - Feb 10, 2026
- [ ] Verify NFR2 (Actionability): each FR section has "Implications for CIG"
- [ ] Verify NFR3 (Organisation): all claims link to sources
- [ ] Verify NFR4 (Completeness): all FR AC thresholds met
- [ ] Verify NFR5 (Reliability): critical claims have 2+ sources
- [ ] Document any gaps or "out of scope" areas explicitly

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
- [ ] All Phase 1-4 steps completed (checkboxes in f-implementation-exec.md)
- [ ] FR1-FR6 each meet their acceptance criteria from b-requirements-plan.md
- [ ] FR7 decision matrix produced with scored options
- [ ] NFR1-NFR5 quality standards verified in Step 6
- [ ] All acceptance criteria from b-requirements-plan.md addressed (AC1-AC7)

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

**Discovery-specific note**: If research yields insufficient evidence for an FR (e.g., FR3 finds fewer than 3 migration examples), document the search effort and adjust the FR7 analysis accordingly rather than fabricating data.

## Status
**Status**: Finished
**Next Action**: N/A (complete)
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
- All 6 steps executed: Task 16 baseline loaded, Phase 1-4 research completed, cross-reference quality check done
- 6 parallel research agents used for Steps 2-4 (FR1-FR6), FR7 synthesised sequentially
- `gh` CLI unavailable initially; compensated with WebSearch; later enriched with `gh` data after installation
- NFR verification (Step 6) confirmed: 85% freshness, 100% implications coverage, all claims sourced

## Lessons Learned
- Parallel agent execution is the natural pattern for independent research questions — plan should have specified this
- `gh` CLI should have been validated as a prerequisite before starting Step 3
- WebSearch is a viable fallback for structured issue searches but lacks engagement metrics
