# cwf-manage validate and CWF::Validate module suite - Requirements
**Task**: 64 (feature)

## Task Reference
- **Task ID**: internal-64
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/64-cwf-manage-validate-and-cwf-validate-module-suite
- **Template Version**: 2.1

## Functional Requirements

### FR1 — cwf-manage validate subcommand
`cwf-manage validate` must run all validation checks and exit 0 if clean, non-zero if any violations found. It must print all violations before exiting — not stop at the first failure.

**Acceptance criteria**:
- `cwf-manage validate` on a clean repo exits 0 with no output (or a brief "OK" summary)
- `cwf-manage validate` on a repo with violations exits non-zero and prints every violation
- Running `cwf-manage help` lists `validate` with a one-line description

### FR2 — Actionable error messages
Every violation message must include enough context for an agent to fix the problem without further investigation.

**Acceptance criteria**:
- Each message includes: file path, field name, actual value, expected value/format
- Each message includes a suggested fix (e.g. "Set `supported-task-types` to an array in `implementation-guide/cwf-project.json`")
- No message requires the agent to open a file to understand what is wrong

### FR3 — CWF::Validate::Config
Validates `cwf-project.json` schema.

**Acceptance criteria**:
- Detects missing required keys: `supported-task-types`, `source-management`, `source-management.branch-naming-convention`
- Detects wrong types (e.g. `supported-task-types` is a string instead of array)
- Does not fail if optional keys are absent
- Callable independently: `use CWF::Validate::Config; my @errors = CWF::Validate::Config::validate($config_path);`

### FR4 — CWF::Validate::Workflow
Validates individual workflow step files.

**Acceptance criteria**:
- Detects invalid `**Status**:` values (not in the allowed set: Backlog, In Progress, Finished, Blocked, Skipped, Cancelled)
- Detects missing required sections (e.g. `## Status`) for a given template version
- Does not reject valid v1.0, v2.0, or v2.1 files based on format differences
- Callable independently with a file path

### FR5 — CWF::Validate::Consistency
Cross-file and cross-system consistency checks.

**Acceptance criteria**:
- Detects task number mismatch between directory name and workflow file header
- Detects branch name in task reference that doesn't match the current git branch
- Callable independently with a task path

### FR6 — CWF::Validate::Security
Script hash verification, consolidating existing logic.

**Acceptance criteria**:
- Produces same results as current `/cwf-security-check verify`
- Existing `/cwf-security-check` skill continues to work (calls the module, not duplicates logic)
- Callable independently

### FR7 — Post-skill guard integration
`cwf-manage validate` (or a subset) is called at the end of each skill's checkpoint commit step.

**Acceptance criteria**:
- `checkpoint-commit.md` (read by all skills) instructs calling `cwf-manage validate` after committing
- A failed validate at checkpoint does not block the commit but surfaces the violations clearly
- At minimum, `CWF::Validate::Config` is always called (catches the most common onboarding failures)

## Non-Functional Requirements

### NFR1 — Performance
Validation must not add noticeable delay to skill execution.

**Acceptance criteria**: `cwf-manage validate` completes in under 2 seconds on a repo with 20 tasks

### NFR2 — Independence
Each `CWF::Validate::*` module must be usable without loading the others.

**Acceptance criteria**: `use CWF::Validate::Config` alone must not `require` Workflow, Consistency, or Security modules

### NFR3 — No new CPAN dependencies
All modules must use only Perl core or modules already present in `.cwf/lib/`.

### NFR4 — Perlcritic stern compliance
All new modules and changes to `cwf-manage` must pass `perlcritic --stern`.

### NFR5 — Backward compatibility
Validation must not reject v1.0 or v2.0 workflow files simply because they predate v2.1 fields. Format version must be detected before validating.

## Constraints
- New modules live under `.cwf/lib/CWF/Validate/`
- `/cwf-security-check` skill must continue to work after Security module extraction
- Violations are written to STDOUT (for capture); informational output to STDERR

## Status
**Status**: Finished
**Next Action**: /cwf-design-plan 64
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All planned deliverables met. See j-retrospective.md for full variance analysis.

## Lessons Learned
See j-retrospective.md Key Learnings section.
