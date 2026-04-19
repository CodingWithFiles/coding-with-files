# Add Checkpoint Commit Helper Script (cwf-checkpoint-commit) - Design
**Task**: 102 (feature)

## Task Reference
- **Task ID**: internal-102
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/102-add-checkpoint-commit-helper-script-cwf-checkpoin
- **Template Version**: 2.1

## Goal
Design a Perl helper script that orchestrates the 5-step checkpoint commit procedure using existing CWF modules.

## Design Priorities
Testability → Readability → Consistency → Simplicity → Reversibility

## Key Decisions

### Thin orchestrator, no new library code
All primitives exist (`CWF::TaskPath::resolve`, `CWF::TaskState::status_set`). Script sequences them — ~30 lines following the `cwf-set-status` pattern.

### Glob `{letter}-*.md` for wf file resolution
Both v2.0 and v2.1 use `{letter}-{name}.md`. Globbing is version-agnostic. Validate exactly one match.

### List-form `system()` for git, not `File::Temp`
`system('git', 'commit', '-m', $msg)` bypasses shell entirely — no interpolation risk. Simpler than writing a temp file.

### Hardcoded `Co-developed-by:` trailer
Changes rarely. One-line edit when it does. Not worth a parameter.

### `cwf-manage validate` runs inside the script
Post-commit validation must be baked in — agents will skip optional work. Warn on failure (don't abort), but always run it.

## System Design

### Interface
```
cwf-checkpoint-commit <task-path> <phase-letter> <why-message>
```

### Data Flow
1. Validate 3 args, resolve task via `CWF::TaskPath::resolve`
2. Glob `$full_path/$letter-*.md` → one wf file
3. `CWF::TaskState::status_set($wf_file, 'Finished')`
4. `system('git', 'add', $wf_file)`
5. Build commit message, `system('git', 'commit', '-m', $msg)`
6. `system('.cwf/scripts/cwf-manage', 'validate')` — warn on failure, don't abort

### Exit Codes
- 0: Success
- 1: Any failure (bad args, task not found, wf file not found, git error) — stderr describes what failed

### Commit Message Format
```
Task {num}: Complete {phase-name} phase

{why-message}

Co-developed-by: Claude Opus 4.6 <noreply@anthropic.com>
```
Phase name derived from filename: `a-task-plan.md` → "task plan" (strip letter prefix, `.md` suffix, hyphens to spaces).

## Skill Integration
Skills already reference `checkpoint-commit.md` at their checkpoint step. Update that doc to describe the script as the primary method. No SKILL.md edits needed — skills follow the doc.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 102
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
