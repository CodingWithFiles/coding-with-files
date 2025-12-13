# Hierarchical Workflow System with Dynamic Step Transitions - Testing

## Task Reference
- **Task ID**: internal-3
- **Type**: Feature
- **Status**: Not Started

## Test Strategy

### Testing Approach
- Manual validation through command execution
- Real task creation at multiple hierarchy levels
- Integration testing with existing CIG system
- Migration testing with actual repository tasks
- Backward compatibility verification

### Test Environment
- Repository: `/home/matt/repo/code-implementation-guide`
- Branch: `feature/3-hierarchical-workflow-system-with-dynamic-step-transitions`
- Claude Code CLI

## Unit Tests

### UT1: Task Creation

#### UT1.1: Create Top-Level Task
```bash
/cig-new-task 4 feature "Test feature task"
```

**Expected**:
- Directory: `implementation-guide/4-feature-test-feature-task/`
- Files: `a-plan.md`, `b-requirements.md`, `c-design.md`, `d-implementation.md`, `e-testing.md`, `f-rollout.md`, `g-maintenance.md`, `h-retrospective.md`
- Task Reference populated
- Git branch suggested

**Validation**:
- [ ] Directory exists
- [ ] All 8 files created
- [ ] Files contain proper templates
- [ ] Task reference has correct task ID

#### UT1.2: Create First-Level Subtask
```bash
/cig-subtask 4 4.1 chore "Test subtask"
```

**Expected**:
- Directory: `implementation-guide/4-feature-test-feature-task/4.1-chore-test-subtask/`
- Nested within parent directory
- Proper task reference

**Validation**:
- [ ] Directory in correct location
- [ ] Files created
- [ ] Parent reference correct

#### UT1.3: Create Deep Hierarchy
```bash
/cig-subtask 4/4.1 4.1.1 bugfix "Deep subtask"
/cig-subtask 4/4.1/4.1.1 4.1.1.1 hotfix "Deeper subtask"
/cig-subtask 4/4.1/4.1.1/4.1.1.1 4.1.1.1.1 chore "Deepest subtask"
```

**Expected**:
- Full path: `.../4.1.1.1.1-chore-deepest-subtask/`
- 5 levels deep
- All paths resolve correctly

**Validation**:
- [ ] All levels created
- [ ] Numbering correct
- [ ] Files in correct locations

### UT2: Workflow Commands

#### UT2.1: Planning Command
```bash
/cig-plan 4
```

**Expected**:
- Opens `a-plan.md` for editing
- Provides planning guidance
- No parent context (top-level task)
- Suggests `/cig-requirements 4` next

**Validation**:
- [ ] Command executes
- [ ] Appropriate guidance provided
- [ ] Next step suggested

#### UT2.2: Requirements with Context
```bash
/cig-requirements 4/4.1
```

**Expected**:
- Opens `b-requirements.md`
- Shows parent context from `4/a-plan.md`
- Requirements guidance
- Suggests `/cig-design 4/4.1` next

**Validation**:
- [ ] Parent context displayed
- [ ] Context accurate
- [ ] Guidance appropriate

#### UT2.3: Deep Context Inheritance
```bash
/cig-design 4/4.1/4.1.1/4.1.1.1
```

**Expected**:
- Shows context from:
  - `4/a-plan.md`, `4/b-requirements.md`, `4/c-design.md`
  - `4/4.1/a-plan.md`, `4/4.1/b-requirements.md`
  - `4/4.1/4.1.1/a-plan.md`
  - `4/4.1/4.1.1/4.1.1.1/a-plan.md`
- Structured, readable format

**Validation**:
- [ ] All ancestors read
- [ ] Context complete
- [ ] Format clear

### UT3: Helper Scripts

#### UT3.1: Context Inheritance Script
```bash
.cig/scripts/command-helpers/context-inheritance.sh "4/4.1/4.1.1" "c-design"
```

**Expected**:
- Markdown output with ancestor context
- Correct task identification
- Exit code 0

**Validation**:
- [ ] Output format correct
- [ ] Context complete
- [ ] No errors

#### UT3.2: Hierarchy Resolver
```bash
.cig/scripts/command-helpers/hierarchy-resolver.sh "4/4.1"
```

**Expected**:
- JSON output with task metadata
- Correct path resolution
- Format detection

**Validation**:
- [ ] JSON valid
- [ ] Path correct
- [ ] Format detected

### UT4: Decomposition Signals

#### UT4.1: Design Complexity Detection
```bash
/cig-design 4
```

**Simulate**: Complex design with 4+ components

**Expected**:
- Claude detects complexity signal
- Suggests creating subtasks
- Provides specific breakdown
- Offers choice

**Validation**:
- [ ] Signal detected
- [ ] Suggestion made
- [ ] Reasoning provided

### UT5: Dynamic Workflow Transitions

#### UT5.1: Test Failure → Implementation
```bash
/cig-testing 4
```

**Simulate**: Tests fail with simple bugs

**Expected**:
- Claude suggests `/cig-implementation 4`
- Explains reason (fix bugs)
- Offers alternatives

**Validation**:
- [ ] Correct suggestion
- [ ] Reasoning clear
- [ ] Alternatives provided

#### UT5.2: Test Failure → Design Review
**Simulate**: Tests reveal design flaw

**Expected**:
- Claude suggests `/cig-design 4`
- Explains design issue
- Provides context

**Validation**:
- [ ] Correct suggestion
- [ ] Reason explained

## Integration Tests

### IT1: Complete Workflow Execution

Execute full workflow for task 4:
```bash
/cig-plan 4
/cig-requirements 4
/cig-design 4
/cig-implementation 4
/cig-testing 4
/cig-rollout 4
/cig-maintenance 4
/cig-retrospective 4
```

**Validation**:
- [ ] All commands execute successfully
- [ ] Context flows through steps
- [ ] Next-step suggestions appropriate
- [ ] Files properly populated

### IT2: Hierarchical Workflow

Execute workflow for subtask:
```bash
/cig-plan 4/4.1
/cig-requirements 4/4.1
/cig-design 4/4.1
/cig-implementation 4/4.1
/cig-testing 4/4.1
```

**Validation**:
- [ ] Parent context available at each step
- [ ] Context inheritance works
- [ ] Suggestions account for hierarchy

### IT3: Status Display

#### IT3.1: Hierarchical Status
```bash
/cig-status 4
```

**Expected**:
- Tree view of task 4 and all subtasks
- Progress percentages
- Status indicators (✓, in-progress, pending)
- Proper indentation

**Validation**:
- [ ] Tree structure correct
- [ ] All subtasks shown
- [ ] Progress accurate
- [ ] Visual hierarchy clear

#### IT3.2: Full Status
```bash
/cig-status
```

**Expected**:
- All tasks shown (1, 2, 3, 4)
- Hierarchies visible
- Old and new formats both displayed

**Validation**:
- [ ] All tasks present
- [ ] Both formats work
- [ ] No errors

## Backward Compatibility Tests

### BC1: Old Format Tasks Accessible

```bash
/cig-status 1  # Old chore task
/cig-status 2  # Old feature task
/cig-extract implementation.md 2
```

**Validation**:
- [ ] Old tasks readable
- [ ] Status display works
- [ ] Extraction works
- [ ] No errors

### BC2: Format Detection

**Test**: Verify automatic format detection

**Validation**:
- [ ] New tasks use new format
- [ ] Old tasks use old format
- [ ] Commands adapt automatically
- [ ] No manual configuration needed

### BC3: Mixed Environment

**Test**: New and old tasks coexist

**Validation**:
- [ ] Both formats in status display
- [ ] No conflicts
- [ ] All commands work
- [ ] Clear which format is which

## Migration Tests

**Note**: Migration tests will be executed in subtask 3.1 during rollout

### MT1: Migration Execution
- [ ] `git mv` commands preserve history
- [ ] Directory structure correct post-migration
- [ ] File renames successful
- [ ] No data loss

### MT2: Post-Migration Validation
- [ ] All migrated tasks accessible
- [ ] Commands work with migrated tasks
- [ ] Status display correct
- [ ] Git history intact

### MT3: Reference Updates
- [ ] No broken links
- [ ] Documentation references updated
- [ ] Command examples updated

## Performance Tests

### PT1: Large Hierarchy
Create 10 tasks with 5 levels each (50 tasks total)

**Validation**:
- [ ] Status display <2 seconds
- [ ] Commands responsive
- [ ] No errors

### PT2: Context Inheritance Performance
Test with 10-level deep hierarchy

**Validation**:
- [ ] Context loads <1 second
- [ ] All ancestors read
- [ ] No timeout errors

## Security Tests

### ST1: Path Traversal Prevention
```bash
/cig-subtask "../../../etc" 1 chore "Malicious"
```

**Expected**: Command rejects invalid path

**Validation**:
- [ ] Attempt blocked
- [ ] Error message clear
- [ ] No directory created

### ST2: Script Permissions
```bash
ls -la .cig/scripts/command-helpers/
```

**Validation**:
- [ ] All scripts 0500
- [ ] Owner execute only
- [ ] No write permissions

### ST3: SHA256 Verification
```bash
/cig-security-check verify
```

**Validation**:
- [ ] All scripts verified
- [ ] Hashes match
- [ ] No tampering detected

## Test Execution

### Pre-Testing Checklist
- [ ] Implementation complete
- [ ] Helper scripts in place
- [ ] Templates created
- [ ] Commands deployed
- [ ] Git branch created

### Test Execution Order
1. Unit tests (UT1-UT5)
2. Integration tests (IT1-IT3)
3. Backward compatibility tests (BC1-BC3)
4. Performance tests (PT1-PT2)
5. Security tests (ST1-ST3)
6. Migration tests (MT1-MT3) - in subtask 3.1

### Test Results

| Test Category | Tests | Passed | Failed | Notes |
|---------------|-------|--------|--------|-------|
| Unit Tests | 0/15 | 0 | 0 | Not started |
| Integration Tests | 0/3 | 0 | 0 | Not started |
| Backward Compat | 0/3 | 0 | 0 | Not started |
| Performance | 0/2 | 0 | 0 | Not started |
| Security | 0/3 | 0 | 0 | Not started |
| Migration | 0/3 | 0 | 0 | Deferred to subtask 3.1 |

### Test Status: NOT STARTED

## Issues Found

(To be populated during testing)

## Test Sign-Off

- [ ] All critical tests passing
- [ ] Known issues documented
- [ ] Performance acceptable
- [ ] Security verified
- [ ] Ready for rollout
