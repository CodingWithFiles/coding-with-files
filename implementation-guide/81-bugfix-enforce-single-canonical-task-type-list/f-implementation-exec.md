# enforce single canonical task type list across CWF modules - Implementation Execution
**Task**: 81 (bugfix)

## Task Reference
- **Task ID**: internal-81
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/81-enforce-single-canonical-task-type-list
- **Template Version**: 2.1

## Goal
Execute the implementation following the plan in d-implementation-plan.md and e-testing-plan.md.

## Execution Checklist
- [x] Read d-implementation-plan.md and e-testing-plan.md thoroughly
- [x] Verify all prerequisites met
- [x] Execute implementation steps sequentially
- [x] Update "Actual Results" for each step
- [x] Document any deviations from plan
- [x] Update status to "Finished" when complete

## Implementation Steps

### Step 1: Add `supported_types()` to `CWF::WorkflowFiles::V21`
- **Planned**: Export `supported_types()` returning sorted keys of `%WORKFLOW_FILES`; add `Exporter` and `@EXPORT_OK`
- **Actual**: Added `use Exporter 'import'`, `our @EXPORT_OK = qw(get_workflow_files supported_types)`, and `sub supported_types { return sort keys %WORKFLOW_FILES; }` — exactly as planned
- **Deviations**: None

### Step 2: Update `CWF::Validate::Config` with bidirectional validation
- **Planned**: Import `supported_types()` and replace one-directional type check with bidirectional set-difference
- **Actual**: Added `use CWF::WorkflowFiles::V21 qw(supported_types)` import. Rewrote the `else` block to:
  1. Extract `@project_types` from the config array
  2. Build `%canonical` and `%project` lookup hashes
  3. `@unknown = sort grep { !exists $canonical{$_} } @project_types` — types in config not in canonical
  4. `@missing = sort grep { !exists $project{$_} } supported_types()` — canonical types absent from config
  5. Push violations for each non-empty set, using postfix `if @unknown` / `if @missing`
- **Deviations**: Rewrote code again after initial version per user feedback ("not very Perlish"). Final version iterates the original arrays (not hash keys) and uses postfix `if`, which is idiomatic Perl.

### Step 3: Fix `cwf-project.json.template`
- **Planned**: Replace ghost types (`docs`, `refactor`, `test`) with canonical five; add `discovery`
- **Actual**: Replaced with `["feature","bugfix","hotfix","chore","discovery"]` — exactly as planned
- **Deviations**: None

### Step 4: Update tests
- **Planned**: Add `supported_types()` tests to `workflowfiles-v21.t`; update `validate-config.t` to use canonical list and add bidirectional violation tests
- **Actual**:
  - `t/workflowfiles-v21.t`: Added two new subtests covering `supported_types()` count, `discovery`/`feature` inclusion, and all types having workflow files
  - `t/validate-config.t`: Updated 3 existing subtests from `['feature']` to full canonical list; added unknown-type and missing-type subtests
  - **Trap encountered**: `sort supported_types()` parsed as `sort SUBNAME LIST` (comparator syntax); fixed by using `for my $type (supported_types())` to iterate directly
  - `prove t/` passes all 162 tests across 17 files
- **Deviations**: Test approach adjusted for `supported_types()` due to Perl parsing trap

### Step 5: Update SHA256 hashes in `script-hashes.json`
- **Planned**: Recompute and update hashes for `WorkflowFiles::V21` and `Validate::Config`
- **Actual**: Updated both hashes. After the idiomatic Perl rewrite of `Validate::Config`, the hash was recomputed again (`6496ced7...`). Final values verified against `sha256sum`.
- **Deviations**: Extra hash recompute needed after Step 2 rewrite

### Step 6: Fix `decomposition-guide.md` file count table
- **Planned**: Add `discovery` type and update file counts to v2.1 actuals
- **Actual**: Updated line 81 from `(feature: 8 files, bugfix: 5 files, hotfix: 5 files, chore: 4 files)` to `(feature: 10 files, bugfix: 7 files, hotfix: 7 files, chore: 6 files, discovery: 8 files)` based on actual `%WORKFLOW_FILES` entries in V21.pm
- **Deviations**: None

## Blockers Encountered

**Perl parsing trap** (`sort supported_types()`): Perl interpreted `supported_types` as a named comparator function and `()` as an empty list to sort. Result was sorting an empty list, returning `''`. Fixed by iterating with `for my $type (supported_types())` instead.

## Deferral Check
- [x] All steps from d-implementation-plan.md executed
- [x] All success criteria from a-task-plan.md met
- [x] All design guidance in c-design-plan.md followed
- [x] No planned work deferred without user approval

## Status
**Status**: Finished
**Next Action**: /cwf-testing-exec 81
**Blockers**: None

## Lessons Learned
`sort supported_types()` is a Perl parsing trap — use `for my $type (supported_types())`
to iterate. Postfix `if` (`push @v, ... if @items`) is more idiomatic than an `if` block.
For `cwf-manage validate` E2E tests: write to actual repo config (it uses `find_git_root()`
internally), not a temp directory.
