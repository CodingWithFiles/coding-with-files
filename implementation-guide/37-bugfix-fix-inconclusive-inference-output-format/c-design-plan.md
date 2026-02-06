# fix inconclusive inference output format - Design

## Task Reference
- **Task ID**: internal-37
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/37-fix-inconclusive-inference-output-format
- **Template Version**: 2.1

## Goal
Define structured output format specification for TaskContextInference.pm to always return parseable, consistent output regardless of conclusive/inconclusive status.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Architecture Preferences
Composition over inheritance. Interfaces over singletons. Explicit over implicit.

## Key Decisions
### Architecture Choice: Unified Structured Output Format
- **Decision**: Always output `key: value` format for all scenarios (conclusive, inconclusive, no_signals)
- **Rationale**:
  - Current implementation only outputs structured format when correlated
  - Uncorrelated outputs human-readable prose (unparseable by scripts/LLMs)
  - Commands need programmatic parsing regardless of correlation
- **Trade-offs**:
  - ✓ Pros: Deterministic parsing, automation-friendly, LLM-friendly, consistent
  - ✓ Pros: Backward compatible via `current` field check
  - ✗ Cons: Less human-readable for uncorrelated (mitigated by `--verbose` flag)

### Field Naming Convention: Semantic Pluralization
- **Decision**: Use plural field names (`task_nums`, `task_slugs`, `workflow_steps`) for multiple values
- **Rationale**:
  - Self-documenting (plural = expect comma-separated list)
  - Consistent with data model (singular when one, plural when multiple)
  - Easier to parse (field name indicates value format)
- **Trade-offs**:
  - ✓ Pros: Self-documenting, consistent naming convention
  - ✓ Pros: Parsers know whether to split on comma
  - ✗ Cons: Different field names for conclusive vs inconclusive (mitigated by clear documentation)

## System Design
### Component Overview
- **TaskContextInference.pm**: Core inference module that collects signals and correlates
- **format_output()**: Formats correlated results (currently only handles conclusive)
- **_format_uncorrelated()**: Formats uncorrelated results (currently prose, needs restructuring)
- **task-context-inference wrapper**: Bash script that calls module and handles exit codes

### Data Flow
1. **Signal Collection**: `get_all_signals()` → gathers branch, recency, progress signals
2. **Correlation**: `correlate_signals()` → determines if signals agree (correlated/uncorrelated/no_signals)
3. **Output Formatting**:
   - **Current**: If correlated → `format_output()`, if uncorrelated → `_format_uncorrelated()`
   - **New**: Always → `format_output()` with unified structure
4. **Wrapper Script**: Receives formatted output, sets exit code (0/1/3), prints to stdout

## Interface Design
### Output Format Specification

**Conclusive (signals correlated)**:
```
current: conclusive
task_num: 37
task_slug: fix-inconclusive-inference-output-format
workflow_step: c-design-plan
confidence: correlated
```

**Inconclusive (signals disagree)**:
```
current: inconclusive
task_nums: 14,32,37
task_slugs: retro-suggest-updating,task-tracking-inference,fix-inconclusive-output
workflow_steps: j-retrospective,j-retrospective,c-design-plan
confidence: uncorrelated
candidates: 3
reasons: branch_signal,recency_signal,progress_signal
```

**No Signals**:
```
current: inconclusive
task_nums: unknown
task_slugs: unknown
workflow_steps: unknown
confidence: no_signals
candidates: 0
reasons: none
```

### Field Definitions

**Common Fields** (all scenarios):
- `current`: `conclusive | inconclusive` - Can inference determine single task?
- `confidence`: `correlated | uncorrelated | no_signals` - Internal correlation status
- `candidates`: integer - Number of candidate tasks (0, 1, or N)

**Conclusive Fields** (when current=conclusive):
- `task_num`: single integer - The determined task number
- `task_slug`: single string - The task slug
- `workflow_step`: single string - The inferred workflow step

**Inconclusive Fields** (when current=inconclusive):
- `task_nums`: comma-separated integers or "unknown" - Candidate task numbers
- `task_slugs`: comma-separated strings or "unknown" - Candidate task slugs
- `workflow_steps`: comma-separated strings or "unknown" - Candidate workflow steps
- `reasons`: comma-separated signal names - Which signals contributed to candidates

### Data Models

**Context Hash** (internal structure returned by `infer_task_context()`):
```perl
{
    confidence => 'correlated|uncorrelated|no_signals',
    current => 'conclusive|inconclusive',
    candidates => 0..N,

    # Conclusive fields (when confidence=correlated)
    task_num => '37',
    task_slug => 'fix-inconclusive-output',
    workflow_step => 'c-design-plan',

    # Inconclusive fields (when confidence=uncorrelated|no_signals)
    task_nums => ['14', '32', '37'],
    task_slugs => ['slug1', 'slug2', 'slug3'],
    workflow_steps => ['step1', 'step2', 'step3'],
    reasons => ['branch_signal', 'recency_signal'],

    # Internal metadata (not output)
    signals => \@signals,
}

## Constraints

### Backward Compatibility
- **Exit codes unchanged**: Wrapper script must maintain exit code contract
  - 0 = conclusive (correlated)
  - 1 = inconclusive (uncorrelated)
  - 3 = inconclusive (no_signals)
- **Field presence**: Commands can detect format version by checking for `current` field
  - If `current` field exists → new format (v2)
  - If `current` field missing → old format (v1, conclusive only)
- **Parsing safety**: All values must be simple strings (no nested structures, no JSON)

### Technical Constraints
- **Perl compatibility**: Module uses Perl 5.10+ features (given/when, say)
- **No external dependencies**: Pure Perl implementation, uses only core modules
- **File I/O only**: No database, no network calls, reads from filesystem
- **Wrapper script contract**: Module outputs to STDOUT, wrapper sets exit code

### Performance Considerations
- **Minimal overhead**: String concatenation for field generation is O(n) where n = candidate count
- **No additional file reads**: All data already collected during signal gathering phase
- **Format change impact**: Negligible - just different sprintf format strings

### Security Requirements
- **No code injection**: All values from filesystem (task numbers, slugs) are sanitized during parsing
- **Safe defaults**: Unknown/missing values default to "unknown" string, never empty
- **Delimiter safety**: Comma separator chosen because task slugs use hyphens, not commas

## Validation
- [x] Design review completed
- [x] Architecture approved by team
- [x] Integration points verified

## Status
**Status**: Finished
**Next Action**: Begin implementation planning → `/cig-implementation-plan 37`
**Blockers**: None identified

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
