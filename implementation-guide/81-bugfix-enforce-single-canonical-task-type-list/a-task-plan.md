# enforce single canonical task type list across CWF modules - Plan
**Task**: 81 (bugfix)

## Task Reference
- **Task ID**: internal-81
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/81-enforce-single-canonical-task-type-list
- **Template Version**: 2.1

## Goal
Make `CWF::WorkflowFiles::V21` the single source of truth for valid task types and
enforce bidirectional consistency — project config must match the canonical list
exactly, caught by `cwf-manage validate`.

## Background / Audit Findings

Full recursive grep identified all locations with task type lists:

| Location | Types listed | Status |
|---|---|---|
| `CWF::WorkflowFiles::V21` `%WORKFLOW_FILES` keys | feature, bugfix, hotfix, chore, discovery | ✓ canonical |
| `CWF::WorkflowFiles::V20` `%WORKFLOW_FILES` keys | feature, bugfix, hotfix, chore, discovery | ✓ in sync |
| `CWF::Validate::Config` error message strings | feature, bugfix, hotfix, chore, discovery | ✓ correct but hardcoded, not enforced |
| `CWF::TemplateCopier::Core` comment | feature, bugfix, hotfix, chore, discovery | ✓ correct, comment only |
| `cwf-project.json.template` | feature, bugfix, hotfix, chore, docs, refactor, test | ❌ missing discovery, 3 ghost types |
| `retrospective-extras.md:48` | bugfix, chore, feature, hotfix, discovery | ✓ correct |
| `decomposition-guide.md:81` | feature, bugfix, hotfix, chore (no discovery) | ⚠ incomplete |

Two bugs:
1. `cwf-project.json.template` has 3 ghost types (`docs`, `refactor`, `test`) with no
   workflow step mapping, and is missing `discovery`
2. `CWF::Validate::Config` checks that `supported-task-types` exists and is an array
   but never validates the *values* — unknown types pass silently, missing types never caught

## Success Criteria
- [ ] `CWF::WorkflowFiles::V21` exports a `supported_types()` function returning the
      canonical list derived from `%WORKFLOW_FILES` keys (not a separate hardcoded list)
- [ ] `CWF::Validate::Config` uses `supported_types()` for bidirectional validation:
  - Unknown types in project config → violation
  - Missing canonical types in project config → violation
- [ ] `cwf-project.json.template` updated to exactly `[feature, bugfix, hotfix, chore, discovery]`
- [ ] `cwf-manage validate` catches ghost types and missing discovery
- [ ] SHA256 hashes updated for all modified `.pm` files
- [ ] All existing tests pass; new tests cover the bidirectional validation

## Original Estimate
**Effort**: <1 session
**Complexity**: Low-Medium (Perl module changes + test additions)
**Dependencies**: None

## Major Milestones
1. Add `supported_types()` export to `CWF::WorkflowFiles::V21`
2. Update `CWF::Validate::Config` with bidirectional validation using `supported_types()`
3. Fix `cwf-project.json.template`
4. Add tests; update SHA256s; fix doc references

## Risk Assessment
### Medium Priority Risks
- **Existing projects with non-canonical types**: Any project using `docs`, `refactor`,
  or `test` in their `cwf-project.json` will start failing `cwf-manage validate`.
  - **Mitigation**: Intentional — violation message will list invalid types and the
    correct canonical set.

### Low Priority Risks
- **V20 / V21 divergence**: `CWF::WorkflowFiles::V20` also has the 5 types but
  `supported_types()` should live in V21 only — V20 is legacy.
  - **Mitigation**: Verify `Validate::Config` import path during implementation.

## Dependencies
- None external

## Constraints
- `supported_types()` must derive the list from `%WORKFLOW_FILES` keys dynamically —
  not a new hardcoded list, which would just move the duplication problem

## Decomposition Check
- [x] **Time**: <1 session — no decomposition needed
- [ ] **People**: Single-person task
- [x] **Complexity**: 3 concerns (new export, validator update, template fix) but all
      small and tightly coupled — decomposing would add overhead without benefit
- [ ] **Risk**: Low
- [ ] **Independence**: Changes are interdependent (validator needs the export)

No decomposition — all changes are small and must ship together.

## Status
**Status**: Finished
**Next Action**: Complete
**Blockers**: None

**See `.cwf/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results
Delivered exactly as planned in <1 session. All 6 success criteria met:
`supported_types()` exported from V21, bidirectional validation in Config, template fixed,
`cwf-manage validate` catches ghost types and missing discovery, SHA256s updated, all
162 tests pass with new coverage for the bidirectional validation.

## Lessons Learned
Recursive grep before coding confirmed all 7 type-list locations. Postfix `if` and
iterating original arrays (not hash keys) is more idiomatic Perl for this pattern.
`cwf-manage validate` uses `find_git_root()` internally — end-to-end tests must write
to the actual repo config and restore, not a temp directory.
