# Fix subtask resolution to support nested directory hierarchy — Testing Plan
**Task**: 96 (bugfix)

## Task Reference
- **Task ID**: internal-96
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/96-fix-subtask-resolution-nested-hierarchy
- **Template Version**: 2.1

## Test Strategy
Create temporary nested directory fixtures under `implementation-guide/`, run resolution/status/inheritance commands against them, then clean up. Existing top-level tasks serve as regression fixtures.

### Test Environment
Fixtures created in `implementation-guide/` (same location the scripts search). Each fixture is a minimal task directory with one `.md` file containing a Template Version header so `detect_format()` works. Fixtures are removed after testing.

### Fixture Structure
```
implementation-guide/
└── 900-feature-test-parent/
    ├── a-task-plan.md            (Status: Finished)
    └── 900.1-bugfix-test-child/
        ├── a-task-plan.md        (Status: In Progress)
        └── 900.1.1-chore-test-grandchild/
            └── a-task-plan.md    (Status: Backlog)
```

Task numbers 900+ chosen to avoid collision with real tasks.

## Test Cases

### Resolution (TaskPath)

#### TC-1: Top-level task resolves (regression)
- **Given**: Existing task 95 at `implementation-guide/95-bugfix-*/`
- **When**: `context-manager hierarchy 95`
- **Then**: Resolves with correct num, type, slug, format

#### TC-2: Nested subtask resolves (2-level)
- **Given**: Fixture `900-feature-test-parent/900.1-bugfix-test-child/`
- **When**: `context-manager hierarchy 900.1`
- **Then**: Resolves with num=900.1, type=bugfix, full_path ending in `900.1-bugfix-test-child`

#### TC-3: Nested subtask resolves (3-level)
- **Given**: Fixture `900-feature-test-parent/900.1-bugfix-test-child/900.1.1-chore-test-grandchild/`
- **When**: `context-manager hierarchy 900.1.1`
- **Then**: Resolves with num=900.1.1, type=chore

#### TC-4: Missing subtask returns error
- **Given**: No `900.2` directory exists
- **When**: `context-manager hierarchy 900.2`
- **Then**: Exit code 2, "Task not found: 900.2"

#### TC-5: Missing parent chain returns error
- **Given**: No `901` directory exists
- **When**: `context-manager hierarchy 901.1`
- **Then**: Exit code 2, "Task not found: 901.1"

### Context Inheritance

#### TC-6: Inheritance resolves parent for nested subtask
- **Given**: Fixture with 900 → 900.1
- **When**: `context-manager inheritance 900.1`
- **Then**: Returns parent context for task 900 (structural map with headers/line ranges)

#### TC-7: Inheritance resolves ancestor chain (3-level)
- **Given**: Fixture with 900 → 900.1 → 900.1.1
- **When**: `context-manager inheritance 900.1.1`
- **Then**: Returns context for both 900 and 900.1

### Status Aggregation

#### TC-8: Status aggregator traverses nested hierarchy
- **Given**: Fixture with 900 → 900.1 → 900.1.1
- **When**: `.cwf/scripts/command-helpers/workflow-manager status 900 --workflow`
- **Then**: Output includes 900, 900.1, and 900.1.1 with their statuses

### Task Creation

#### TC-9: `construct_destination()` nests subtasks inside parent
- **Given**: Task 900 exists at `implementation-guide/900-feature-test-parent/`
- **When**: `template-copier-v2.1 --task-type=bugfix --task-num=900.2 --description="test-creation"` (no `--destination`)
- **Then**: Directory created at `implementation-guide/900-feature-test-parent/900.2-bugfix-test-creation/`

#### TC-10: `construct_destination()` keeps top-level tasks flat
- **Given**: No parent needed
- **When**: `template-copier-v2.1 --task-type=feature --task-num=901 --description="test-toplevel"` (no `--destination`)
- **Then**: Directory created at `implementation-guide/901-feature-test-toplevel/`

### find_children / find_siblings

#### TC-11: `find_children` returns nested children
- **Given**: Fixture with 900 → 900.1
- **When**: Perl one-liner calling `find_children("900")`
- **Then**: Returns list containing 900.1

### Skill Docs

#### TC-12: `cwf-new-task` SKILL.md contains explicit nested path example
- **Given**: Updated skill doc
- **When**: Grep for nested path example
- **Then**: Match found showing `implementation-guide/<parent-dir>/<subtask-dir>/` pattern

#### TC-13: `cwf-subtask` SKILL.md contains explicit nested path example
- **Given**: Updated skill doc
- **When**: Grep for nested path example
- **Then**: Match found

## Validation Criteria
- [ ] TC-1 passes — top-level resolution regression
- [ ] TC-2, TC-3 pass — nested subtask resolution (2 and 3 levels)
- [ ] TC-4, TC-5 pass — error cases
- [ ] TC-6, TC-7 pass — inheritance for nested subtasks
- [ ] TC-8 passes — status aggregation across nesting
- [ ] TC-9, TC-10 pass — creation places subtasks correctly
- [ ] TC-11 passes — find_children works with nesting
- [ ] TC-12, TC-13 pass — skill docs updated

## Cleanup
After testing, remove all fixture directories (900-*, 901-*) from `implementation-guide/`.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-exec 96
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
