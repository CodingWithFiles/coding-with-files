# cwf-manage validate and CWF::Validate module suite - Implementation Execution
**Task**: 64 (feature)

## Task Reference
- **Task ID**: internal-64
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/64-cwf-manage-validate-and-cwf-validate-module-suite
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md.

## Implementation Steps (from d-implementation-plan.md)

### Step 1: CWF::Validate::Config
- **Planned**: Create `.cwf/lib/CWF/Validate/Config.pm` validating `cwf-project.json`
- **Actual**: Created with `validate($git_root)` and `validate_config_hash($hashref, $path)`. Returns empty list when file absent (pre-init state is valid). Checks: `supported-task-types` (arrayref), `source-management` (hashref), `source-management.branch-naming-convention` (non-empty string).
- **Deviations**: None

### Step 2: CWF::Validate::Workflow
- **Planned**: Create `.cwf/lib/CWF/Validate/Workflow.pm` checking Status sections
- **Actual**: Created. Scans all `implementation-guide/*/*.md`. Checks `## Status` section present and `**Status**:` value is in the allowed set. Code block tracking prevents false positives from fenced examples.
- **Deviations**: Used raw line-by-line parsing rather than `CWF::MarkdownParser::extract_status()` — the MarkdownParser interface wasn't suitable for the two-phase check (section presence + value validity) needed here.

### Step 3: CWF::Validate::Consistency
- **Planned**: Create `.cwf/lib/CWF/Validate/Consistency.pm` checking task num and branch
- **Actual**: Created. Task number extracted from dirname prefix, compared to `**Task**:` field. Branch check only runs for active tasks (status not in Finished/Skipped/Cancelled). Reads up to 200 lines per file to avoid scanning large implementation sections.
- **Deviations**: None

### Step 4: CWF::Validate::Security
- **Planned**: Create `.cwf/lib/CWF/Validate/Security.pm` using `Digest::SHA`
- **Actual**: Created. Key design decision: permissions check is skipped when the JSON entry has no `permissions` field — lib `.pm` entries have no `permissions` key by design, so they're only SHA256-checked. This fixed a false positive where `0600` lib files were being flagged against a `0500` default.
- **Deviations**: Permission check is conditional on `defined $entry->{permissions}` rather than always defaulting to `0500`.

### Step 5: cwf-manage validate subcommand
- **Planned**: Add `validate` to dispatch table, call all four modules, exit 1 on violations
- **Actual**: Done. Used empty import `()` on all four modules to avoid symbol collision (all four export `validate`); called as `CWF::Validate::Config::validate($git_root)` etc. Added to `cmd_help()`.
- **Deviations**: Import style changed from `qw(validate)` to `()` to avoid symbol redefinition.

### Step 6: Update cwf-security-check skill
- **Planned**: Delegate to `cwf-manage validate` rather than manual LLM checks
- **Actual**: Rewrote `.claude/skills/cwf-security-check/SKILL.md` as a thin wrapper. Removed the multi-step manual process; skill now runs `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` and reports results.
- **Deviations**: None

### Step 7: Update checkpoint-commit.md
- **Planned**: Add step 4 (post-commit validate guard)
- **Actual**: Added step 4 with the exact command to run after each checkpoint commit.
- **Deviations**: None

### Step 8: Security hash updates
- **Planned**: Add 4 new module entries; update cwf-manage hash
- **Actual**: Added all 4 modules to `lib` section. Updated cwf-manage hash. Updated `last_updated` date. Also fixed pre-existing permission mismatches for `task-context-inference`, `task-stack`, and `migrate-v2.1-file-order` (chmod 0755 per recorded expectation).
- **Deviations**: Three pre-existing permission violations fixed as a side effect of running validate.

### Step 9: perlcritic --stern
- **Planned**: All new/modified files pass perlcritic --stern
- **Actual**: Three violations found and fixed:
  - `Workflow.pm`: `InputOutput::RequireBriefOpen` — refactored to slurp lines into array, then process
  - `Consistency.pm`: same fix applied
  - `Security.pm`: `ValuesAndExpressions::ProhibitLeadingZeros` — changed `07777` to `oct('07777')`
- **Deviations**: Fixes required after initial write; all pass on re-check.

## Blockers Encountered

**Lib file permissions false positive**: First validate run flagged all `.pm` files for permissions. Root cause: the `permissions` key is absent from lib entries in `script-hashes.json`, so the code was defaulting to `'0500'`. Fix: skip permissions check when `permissions` key is absent.

**Task 37 c-design-plan.md**: Workflow validator correctly flagged this file as missing `## Status` section. Root cause: unclosed ` ```perl ` code fence at line 112 caused the parser to treat the entire remainder of the file as inside a code block. Fixed by adding the missing closing fence.

**cwf-project.json missing source-management**: Config validator correctly flagged the project's own config file. Fixed by adding the `source-management` object. Removed the legacy top-level `branch-naming-convention` key (was duplicated content from old format).

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] `cwf-manage validate` exits 0 on clean repo
- [x] `cwf-manage validate` exits 1 with actionable output on violations
- [x] perlcritic --stern passes on all new/modified files
- [x] No planned work deferred

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 64
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Lessons Learned
See j-retrospective.md Key Learnings section.
