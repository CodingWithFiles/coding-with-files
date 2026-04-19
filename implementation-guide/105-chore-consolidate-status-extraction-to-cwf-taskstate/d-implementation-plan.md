# Consolidate Status Extraction to CWF::TaskState - Implementation Plan
**Task**: 105 (chore)

## Task Reference
- **Task ID**: internal-105
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: chore/105-consolidate-status-extraction-to-cwf-taskstate
- **Template Version**: 2.1

## Goal
Generalise `CWF::MarkdownParser` as the single canonical structured field parser, layer `TaskState` on top for status-specific operations, and consolidate all 4 independent implementations onto this stack.

## Workflow
Patterns first → Test → Minimal impl → Refactor green → Commit message explains "why"

## Layering

```
Callers (StatusAggregator, Validate, scripts, hooks)
    │
    ├── status operations ──→ CWF::TaskState (get, set, validate, percent)
    │                              │
    └── non-status fields ─┐      │
                           ▼      ▼
                     CWF::MarkdownParser (extract_field, find_field_line)
```

## Files to Modify

### Generalise (MarkdownParser)
- `.cwf/lib/CWF/MarkdownParser.pm` — Add `extract_field($file, $section_re, $key_re)` and `find_field_line($file, $section_re, $key_re)`, rewrite `extract_status` as wrapper

### Refactor (TaskState)
- `.cwf/lib/CWF/TaskState.pm` — Replace `_find_status_line` body with `MarkdownParser::find_field_line()` call, add `status_is_valid()` predicate

### Migrate status callers → TaskState
- `.cwf/lib/CWF/StatusAggregator/Core.pm` — Replace `MarkdownParser` + `WorkflowFiles` imports with `use CWF::TaskState qw(status_get status_percent)`
- `.cwf/lib/CWF/ContextInheritance/Core.pm` — Replace `MarkdownParser` import with `TaskState`
- `.cwf/scripts/command-helpers/workflow-manager.d/control` — Same
- `.cwf/scripts/command-helpers/context-inheritance-v2.0` — Same, delete stale comment (line 149)
- `.cwf/scripts/command-helpers/context-inheritance-v2.1` — Same

### Fix Validate modules
- `.cwf/lib/CWF/Validate/Workflow.pm` — Replace inline parsing + hardcoded status list with `TaskState::status_get` + `TaskState::status_is_valid`
- `.cwf/lib/CWF/Validate/Consistency.pm` — Replace `_extract_fields` inline parsing with `MarkdownParser::extract_field()` calls

### Tests
- `t/markdownparser.t` — Keep and extend: add subtests for `extract_field` and `find_field_line`

### Hash updates
- `.cwf/security/script-hashes.json` — Updated automatically via `cwf-manage validate`

## Implementation Steps

### Step 1: Generalise MarkdownParser
- [ ] Add `find_field_line($file, $section_re, $key_re)` — core parsing loop, returns `($line_index, $value, @lines)` or `()`. Single implementation of code-block-aware, section-scoped field extraction
- [ ] Add `extract_field($file, $section_re, $key_re)` — thin wrapper, returns value string or "Unknown"
- [ ] Delete `extract_status` — zero callers after Step 2
- [ ] Export `extract_field` and `find_field_line` from `@EXPORT_OK`
- [ ] Add subtests to `t/markdownparser.t` for `extract_field` (non-status section, non-status key)

### Step 2: Refactor TaskState + migrate status callers
- [ ] `TaskState::_find_status_line` — replace body with `MarkdownParser::find_field_line()` call using status-specific regexes
- [ ] Add `status_is_valid($status)` to TaskState (one-liner using `_ensure_status_map`), add to `@EXPORT_OK`
- [ ] `StatusAggregator/Core.pm` — `use CWF::TaskState qw(status_get status_percent)`, drop both old imports
- [ ] `ContextInheritance/Core.pm` — `use CWF::TaskState qw(status_get)`, drop MarkdownParser import
- [ ] `workflow-manager.d/control` — same pattern
- [ ] `context-inheritance-v2.0` — same pattern, delete stale comment
- [ ] `context-inheritance-v2.1` — same pattern

### Step 3: Fix Validate modules
- [ ] `Validate::Workflow` — replace `extract_status` import + hardcoded lists with `use CWF::TaskState qw(status_get status_is_valid)`, simplify `_check_file`
- [ ] `Validate::Consistency` — replace `_extract_fields` inline parsing with `MarkdownParser::extract_field()` calls for Task, Branch, and Status fields

### Step 4: Validate
- [ ] `prove t/` — full suite passes
- [ ] `.cwf/scripts/cwf-manage validate` — no violations
- [ ] `grep -rn 'extract_status' .cwf/lib/ .cwf/scripts/` — zero hits
- [ ] `grep -c 'in_code_block' .cwf/lib/` — only hits in MarkdownParser.pm (no duplicated parsing loops)

## Test Coverage
**See e-testing-plan.md for complete test plan**

## Validation Criteria
**See e-testing-plan.md for validation criteria and test results**

## Scope Completion
**IMPORTANT**: Complete all planned implementation before marking task Finished.

Deferring work creates technical debt and scope creep. Task 37 deferred documentation updates,
marked the task complete anyway, and created Task 38 to fix the deferred work.

**If you must defer work**:
1. Get user approval with clear rationale
2. Update success criteria to reflect descoped work
3. Create follow-up task immediately
4. Document deferral in Actual Results section

## Status
**Status**: Finished
**Next Action**: /cwf-testing-plan
**Blockers**: None identified

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
