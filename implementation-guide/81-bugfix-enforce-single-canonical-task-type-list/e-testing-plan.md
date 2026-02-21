# enforce single canonical task type list across CWF modules - Testing Plan
**Task**: 81 (bugfix)

## Task Reference
- **Task ID**: internal-81
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/81-enforce-single-canonical-task-type-list
- **Template Version**: 2.1

## Goal
Verify the canonical type list export, bidirectional validation, template fix,
and that no regressions are introduced.

## Test Strategy
All validation logic is in Perl modules with existing unit tests — add new subtests
directly to `t/workflowfiles-v21.t` and `t/validate-config.t`, then confirm with
`prove t/`. No integration test harness needed.

Key concern: 3 existing `validate-config.t` subtests use partial type lists
(`['feature']`, `['feature','bugfix']`) and must be updated alongside the new
validation logic — they will fail until both the implementation AND the test
updates land together.

## Test Cases

### TC-1 — `supported_types()` returns canonical list
- **Given**: `CWF::WorkflowFiles::V21` with new `supported_types()` export
- **When**: `supported_types()` called
- **Then**: Returns exactly 5 types; includes `discovery`; includes `feature`

### TC-2 — `supported_types()` derived from `%WORKFLOW_FILES` keys
- **Given**: `%CWF::WorkflowFiles::V21::WORKFLOW_FILES`
- **When**: `sort supported_types()` vs `sort keys %WORKFLOW_FILES`
- **Then**: Lists are identical — export is not a separate hardcoded list

### TC-3 — Unknown type in project config → violation
- **Given**: `supported-task-types: [feature, bugfix, hotfix, chore, discovery, docs]`
- **When**: `validate_config_hash()` called
- **Then**: Returns ≥1 violation; violation `actual` mentions `docs` as unknown

### TC-4 — Missing canonical type in project config → violation
- **Given**: `supported-task-types: [feature, bugfix, hotfix, chore]` (missing discovery)
- **When**: `validate_config_hash()` called
- **Then**: Returns ≥1 violation; violation `actual` mentions `discovery` as missing

### TC-5 — Exact canonical list → no violations
- **Given**: `supported-task-types: [feature, bugfix, hotfix, chore, discovery]`
- **When**: `validate_config_hash()` called
- **Then**: Zero violations for `supported-task-types`

### TC-6 — Template has exactly canonical types (grep check)
- **Given**: `.cwf/templates/cwf-project.json.template`
- **When**: Parse JSON and check `supported-task-types`
- **Then**: Exactly `[bugfix, chore, discovery, feature, hotfix]` (sorted); no `docs`,
  `refactor`, `test`

### TC-7 — `cwf-manage validate` catches current template's ghost types
- **Given**: A temp `cwf-project.json` with ghost types `[feature,bugfix,hotfix,chore,docs,refactor,test]`
- **When**: `perl -I.cwf/lib .cwf/scripts/cwf-manage validate` run against it
- **Then**: Exit non-zero; output mentions unknown types

### TC-8 — `prove t/` exits 0 (full regression check)
- **Given**: All implementation and test changes applied
- **When**: `prove t/`
- **Then**: All tests pass (≥160 tests expected, 2 new subtests added)

## Test Environment
- Standard: `perl -I.cwf/lib`, existing `prove t/` runner
- TC-7 requires a temp dir with a `cwf-project.json` containing ghost types

## Validation Criteria
- [ ] TC-1: `supported_types()` returns 5 types including discovery
- [ ] TC-2: Export derived from `%WORKFLOW_FILES` keys, not separate list
- [ ] TC-3: Unknown type produces violation naming the unknown type
- [ ] TC-4: Missing type produces violation naming the missing type
- [ ] TC-5: Exact canonical list produces zero violations
- [ ] TC-6: Template has exactly 5 canonical types, no ghosts
- [ ] TC-7: `cwf-manage validate` catches ghost types end-to-end
- [ ] TC-8: `prove t/` exits 0, ≥160 tests

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 81
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
All 8 TCs passed. TC-7 required a test approach correction: `cwf-manage validate` uses
`find_git_root()` internally and cannot be directed at a temp directory. Test was
reworked to write ghost-type config to actual repo path and restore after.

## Lessons Learned
For `cwf-manage validate` end-to-end tests: read the script to understand root detection
before designing the test. Temp-directory approach gives false OK.
