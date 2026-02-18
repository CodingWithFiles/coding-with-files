# cwf-manage validate and CWF::Validate module suite - Design Plan
**Task**: 64 (feature)

## Task Reference
- **Task ID**: internal-64
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/64-cwf-manage-validate-and-cwf-validate-module-suite
- **Template Version**: 2.1

## Architecture Overview

Four independent `CWF::Validate::*` modules under `.cwf/lib/CWF/Validate/`, each with a single public function `validate($git_root)` returning a list of violation hashrefs. `cwf-manage validate` is a thin wrapper that calls all four, collects results, and prints them.

```
.cwf/lib/CWF/Validate/
    Config.pm       — cwf-project.json schema
    Workflow.pm     — workflow step file fields
    Consistency.pm  — cross-file checks
    Security.pm     — script hash verification

.cwf/scripts/cwf-manage              — adds 'validate' to dispatch table
.cwf/docs/skills/checkpoint-commit.md — adds post-commit validate call
```

## Design Decisions

### D1 — Violation struct as plain hashref
Each violation is `{ file => $path, field => $name, actual => $val, expected => $desc, fix => $suggestion }`. No objects — plain hashrefs are sufficient, easy to test, and require no extra modules.

**Rationale**: Keeps modules dependency-free. `fix` field satisfies FR2 (actionable messages).

### D2 — Single public entry point per module: `validate($git_root)`
Each module exports one function. It discovers all relevant files itself (e.g. Config finds `implementation-guide/cwf-project.json`), runs all checks, and returns `@violations`. Individual modules may also export lower-level functions for helper script use (e.g. `validate_config_hash($hashref)` for template-copier to call with an already-loaded config).

**Rationale**: Callers don't need to know file paths. Consistent interface across all four modules.

### D3 — CWF::Validate::Config
Checks:
- `supported-task-types` key present and is an arrayref
- `source-management` key present and is a hashref
- `source-management.branch-naming-convention` key present and is a non-empty string

Non-strict — unknown/optional keys do not cause failures (NFR5).

Example violation message:
```
[CONFIG]  implementation-guide/cwf-project.json
  Field:    supported-task-types
  Actual:   (missing)
  Expected: array of task type strings
  Fix:      Add "supported-task-types": ["feature","bugfix","hotfix","chore","discovery"]
```

### D4 — CWF::Validate::Workflow
Scans all `implementation-guide/*/` task directories. For each workflow `.md` file:
- Extracts `**Status**:` value via `CWF::MarkdownParser::extract_status()`
- Validates against allowed set: `Backlog|In Progress|Implemented|Testing|Finished|Blocked|Skipped|Cancelled`
- Checks `## Status` section is present

Format version detected before validating — does not reject valid v1.0/v2.0 files for missing v2.1-only fields.

### D5 — CWF::Validate::Consistency
Checks:
- Task directory name prefix (e.g. `63-bugfix-`) matches `**Task**:` field in workflow files
- Current git branch matches `**Branch**:` field — only for tasks with at least one in-progress file (skip Finished/Skipped/Cancelled tasks)

**Rationale**: Branch check only for active tasks — completed tasks legitimately have a non-current branch recorded.

### D6 — CWF::Validate::Security
Wraps the hash verification currently done manually by the `/cwf-security-check` skill:
- Reads `.cwf/security/script-hashes.json`
- For each entry: checks file exists, permissions ≥ 0500, SHA256 matches

Uses `Digest::SHA` (Perl core since 5.10) rather than `sha256sum` backtick — consistent with Perl idioms from Task 62.

The `/cwf-security-check` skill is updated to call `CWF::Validate::Security::validate($git_root)` and format results. Skill behaviour is unchanged from the user's perspective.

### D7 — cwf-manage validate subcommand
Added to dispatch table:
```perl
'validate' => sub { cmd_validate($git_root) },
```

`cmd_validate` calls all four modules, collects all violations, prints each, exits 1 if any violations, 0 if clean.

### D8 — Post-skill guard in checkpoint-commit.md
Add step 4:
```
4. **Validate** (post-commit guard):
   .cwf/scripts/cwf-manage validate
   Fix any violations before proceeding to the next skill.
```

## Data Flow

```
cwf-manage validate
  → CWF::Validate::Config::validate($root)      → @violations
  → CWF::Validate::Workflow::validate($root)    → @violations
  → CWF::Validate::Consistency::validate($root) → @violations
  → CWF::Validate::Security::validate($root)    → @violations
  → collect all → print each → exit 0 or 1
```

## Module Dependencies

| Module | Uses |
|--------|------|
| `CWF::Validate::Config` | `JSON::PP` (already in codebase) |
| `CWF::Validate::Workflow` | `CWF::MarkdownParser` |
| `CWF::Validate::Consistency` | `CWF::MarkdownParser` |
| `CWF::Validate::Security` | `Digest::SHA` (Perl core) |

## Files to Create/Modify

| File | Change |
|------|--------|
| `.cwf/lib/CWF/Validate/Config.pm` | New |
| `.cwf/lib/CWF/Validate/Workflow.pm` | New |
| `.cwf/lib/CWF/Validate/Consistency.pm` | New |
| `.cwf/lib/CWF/Validate/Security.pm` | New |
| `.cwf/scripts/cwf-manage` | Add `validate` subcommand + `cmd_validate()` |
| `.cwf/security/script-hashes.json` | Add entries for 4 new modules |
| `.cwf/docs/skills/checkpoint-commit.md` | Add step 4 (post-commit validate) |
| `.cwf-skills/cwf-security-check/SKILL.md` | Update to call `CWF::Validate::Security` |

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 64
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned deliverables met. See j-retrospective.md for full variance analysis.

## Lessons Learned
See j-retrospective.md Key Learnings section.
