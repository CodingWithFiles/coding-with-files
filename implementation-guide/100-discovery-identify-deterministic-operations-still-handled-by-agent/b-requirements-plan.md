# Identify deterministic operations still handled by agent - Requirements
**Task**: 100 (discovery)

## Task Reference
- **Task ID**: internal-100
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: discovery/100-identify-deterministic-ops-handled-by-agent
- **Template Version**: 2.1

## Goal
Specify what the audit must cover, what constitutes a "deterministic operation," and what the output format should be.

## Functional Requirements
### Core Features
- **FR1**: Audit all CWF SKILL.md files for operations the agent performs that are fully determined by input (no judgement, creativity, or interpretation required)
- **FR2**: Categorise each candidate by type: file I/O, JSON manipulation, validation, git operations, string formatting, template substitution, path resolution, status updates
- **FR3**: Rank candidates by extraction value (frequency x error-proneness x extraction complexity)
- **FR4**: Document each candidate with: skill name, operation description, current location (file:line or step reference), category, rank, and proposed script name
- **FR5**: Produce backlog items for the top candidates

### Audit Scope
- **In scope**: All files in `.claude/skills/cwf-*/SKILL.md`
- **In scope**: Prose instructions within skills that describe deterministic file operations (read/write/merge JSON, create directories, create symlinks, update status fields, etc.)
- **Out of scope**: The helper scripts themselves (`.cwf/scripts/command-helpers/`) — these already are code
- **Out of scope**: The skills framework (how skills are invoked) — that's Claude Code infrastructure

### Classification Test
An operation is deterministic if and only if:
1. Given the same inputs, it always produces the same output
2. No LLM judgement is needed to decide what to do
3. A bash or Perl script could perform it with zero ambiguity

Examples:
- **Deterministic**: "Read `.claude/settings.json`, add entry to `permissions.allow` array, write back" — pure JSON manipulation
- **Not deterministic**: "Review the design and identify risks" — requires judgement
- **Edge case**: "If `hooks.PreToolUse` already exists, check for existing matcher" — the check is deterministic, but the decision about what to do if it's missing may require judgement about existing user configuration

## Non-Functional Requirements
### Completeness (NFR1)
- Every SKILL.md must be audited — no skills skipped
- Each skill's workflow steps must be reviewed individually

### Actionability (NFR2)
- Each finding must be specific enough that a developer could create a task from it
- Proposed script names should follow existing conventions (`.cwf/scripts/command-helpers/`)

### Efficiency (NFR3)
- Audit should complete in a single session
- Focus on high-value candidates, not exhaustive cataloguing of trivial operations

## Constraints
- Discovery only — no code changes
- Output is a ranked list and backlog items, not implementations
- Must respect the architectural boundary: if it requires judgement, it stays with the agent
- Existing helper scripts are the reference implementation — new scripts should follow their patterns

## Decomposition Check
0/5 signals triggered — no decomposition needed.

## Acceptance Criteria
- [ ] AC1: All CWF SKILL.md files listed and audited
- [ ] AC2: At least 5 candidate operations identified (or documented justification for fewer)
- [ ] AC3: Each candidate has category, rank, and proposed script name
- [ ] AC4: Top 3-5 candidates written as backlog items
- [ ] AC5: Edge cases documented (operations that are partially deterministic)

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 100
**Blockers**: None

## Actual Results
Requirements validated: all 24 candidates assessed against determinism, frequency, and error-proneness criteria. Scoring matrix produced clear ranking.

## Lessons Learned
Shared preamble and checkpoint commit affect ~10 skills each — highest leverage targets are cross-cutting concerns, not individual skill operations.
