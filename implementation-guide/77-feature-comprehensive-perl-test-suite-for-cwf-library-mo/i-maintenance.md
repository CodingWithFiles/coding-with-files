# Comprehensive Perl Test Suite for CWF Library Modules - Maintenance
**Task**: 77 (feature)

## Task Reference
- **Task ID**: internal-77
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: feature/77-comprehensive-perl-test-suite-for-cwf-library-mo
- **Template Version**: 2.1

## Goal
Define ongoing maintenance requirements for the `t/` test suite — keeping it green,
current, and growing as the CWF library evolves.

## Monitoring Requirements

No runtime monitoring — this is an offline test suite. "Monitoring" means keeping
`prove t/` green across future changes.

### Health Signal
- **Green**: `prove t/` exits 0 on main branch
- **Red**: Any test file exits non-zero — investigate before merging the offending change

## Maintenance Tasks

### Per-task maintenance (ongoing)
- When a task modifies a `.pm` file under `.cwf/lib/`, update the corresponding `.t`
- When a task adds a new `.pm`, add a new `.t` following the naming convention in `c-design-plan.md`
- Run `prove t/` before checkpoint commits that touch library code

### Coverage growth
- New exported subs require ≥1 new named `subtest` in the corresponding `.t`
- New modules require a new `.t` with Tier classification (A/B/C per design plan)

### Dependency hygiene
- Test files must remain core-only (no CPAN). Verify with:
  `grep '^use ' t/*.t | grep -v 'Test::More\|File::\|FindBin\|Cwd\|strict\|warnings\|CWFTest\|use lib\|use CWF'`

## Incident Response

### Common Issues

**Issue: test fails after module refactor**
- Symptoms: `prove t/foo.t` exits non-zero, error points to changed sub signature
- Resolution: Update the test to match the new interface; confirm intent hasn't changed

**Issue: Tier C test fails in CI without git**
- Symptoms: SKIP count changes, but a SKIP-guarded test runs and fails
- Resolution: Verify `system("git --version >/dev/null 2>&1") == 0` guard is present; if a new git sub was added to a Tier A/B file without a guard, add one

**Issue: `grep` message-in-list bug reintroduced**
- Symptoms: `Can't use string (...) as a HASH ref` in a test file
- Resolution: Add extra parens around `grep`: `ok((grep { ... } @list), $msg)` — see f-implementation-exec.md for full explanation

**Issue: `qw()` used for multi-word status values**
- Symptoms: `'In\' is a valid status` appears in test output
- Resolution: Replace `qw(In\ Progress)` with quoted list: `('In Progress', ...)`

## Performance Optimisation

Suite currently runs in ~0.9s. No optimisation needed. If a future `.t` file is slow:
1. Check for unnecessary `tempdir` calls or filesystem setup in Tier A tests
2. Move filesystem ops to `tempdir(CLEANUP => 1)` at the subtest level, not file level
3. Tier C git fixture creation is fast (~0.1s); only add `create_git_repo` when needed

## Documentation

### Coverage contract (from c-design-plan.md)
- ≥1 named `subtest` per exported/public sub
- Exception: subs that call `exit()` or `exec()` — document exclusion in test file header

### Naming convention
- `CWF/Foo.pm` → `t/foo.t`
- `CWF/Foo/Bar.pm` → `t/foo-bar.t`
- `CWF/WorkflowFiles/V20.pm` → `t/workflowfiles-v20.t`

### Adding a new test file
```bash
# 1. Create t/<module>.t following naming convention
# 2. Add lib paths at top:
#    use lib "$FindBin::Bin/../.cwf/lib";
#    use lib "$FindBin::Bin/lib";
# 3. Classify as Tier A/B/C; add SKIP guard if Tier C
# 4. Run: prove t/<module>.t
# 5. Run: prove t/  (full suite)
```

## Success Criteria
- [x] Maintenance procedures documented
- [x] Common issues catalogued with resolutions
- [x] Growth path defined (per-task coverage updates)
- [x] No monitoring infrastructure needed (offline tool)

## Status
**Status**: Finished
**Next Action**: /cwf-retrospective 77
**Blockers**: None

## Actual Results
Maintenance plan established. Key ongoing commitment: run `prove t/` before merging
any change to `.cwf/lib/`. Coverage grows organically with each task.

## Lessons Learned
The four common failure patterns found during implementation are now the primary
maintenance concern — future contributors adding tests should read these patterns
first (documented under "Common Issues" above).
