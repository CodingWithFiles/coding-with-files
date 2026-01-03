# Remove old v1.0 templates and files - Testing

## Task Reference
- **Task ID**: internal-10
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/10-remove-old-v1.0-templates-and-files
- **Template Version**: 2.0

## Goal
Verify that 18 v1.0 template files were deleted and v2.0 system remains functional.

## Test Strategy
### Test Levels
- **System Tests**: Verify template system still works end-to-end
- **Regression Tests**: Ensure `/cig-new-task` creates tasks correctly for all types

## Test Cases
### Functional Test Cases

**TC-1: Verify v1.0 files deleted**
- **Given**: Template directories (.cig/templates/{feature,bugfix,chore,hotfix})
- **When**: List non-symlink template files (excluding pool/)
- **Then**: Only cig-project.json.template exists, no v1.0 files remain

**TC-2: Verify v2.0 symlinks intact**
- **Given**: Template directories
- **When**: Count symlinks in all type directories
- **Then**: 28 symlinks present (feature:8, bugfix:5, chore:4, hotfix:5, discovery:6)

**TC-3: Verify symlinks resolve correctly**
- **Given**: v2.0 symlink (e.g., feature/a-plan.md.template)
- **When**: Read file through symlink
- **Then**: Content matches pool template, no broken links

**TC-4: Create feature task**
- **Given**: CIG system with v2.0 templates only
- **When**: Run `/cig-new-task 999 feature "test-feature"`
- **Then**: 8 workflow files created (a-h)

**TC-5: Create bugfix task**
- **Given**: CIG system with v2.0 templates only
- **When**: Run `/cig-new-task 998 bugfix "test-bugfix"`
- **Then**: 5 workflow files created (a, c, d, e, h)

**TC-6: Create discovery task**
- **Given**: CIG system with v2.0 templates only
- **When**: Run `/cig-new-task 997 discovery "test-discovery"`
- **Then**: 6 workflow files created (a, b, c, d, e, h)

## Test Results

### TC-1: v1.0 files deleted ✓
```bash
find .cig/templates -name "*.template" -type f ! -path "*/pool/*"
# Result: .cig/templates/cig-project.json.template only
```
**Status**: PASS

### TC-2: v2.0 symlinks intact ✓
```bash
find .cig/templates -type l | wc -l
# Result: 28 symlinks
```
**Status**: PASS

### TC-3: Symlinks resolve correctly ✓
```bash
cat .cig/templates/feature/a-plan.md.template | head -5
# Result: Shows template content from pool
```
**Status**: PASS

### TC-4: Feature task creation
**Status**: PENDING (manual test needed)

### TC-5: Bugfix task creation
**Status**: PENDING (manual test needed)

### TC-6: Discovery task creation
**Status**: PENDING (manual test needed)

## Validation Criteria
- [x] TC-1: v1.0 files deleted
- [x] TC-2: Symlinks intact (28 total)
- [x] TC-3: Symlinks resolve correctly
- [ ] TC-4: Feature task creation works
- [ ] TC-5: Bugfix task creation works
- [ ] TC-6: Discovery task creation works

## Status
**Status**: Testing
**Next Action**: Run manual test cases TC-4, TC-5, TC-6
**Blockers**: None

## Actual Results
3 of 6 test cases passed (TC-1: files deleted, TC-2: symlinks intact, TC-3: symlinks resolve). TC-4, TC-5, TC-6 remain pending (manual task creation tests not yet executed).

## Lessons Learned
Separating automated validation tests (file/symlink checks) from manual integration tests (task creation) clarified validation status. Could have automated task creation tests for complete coverage.
