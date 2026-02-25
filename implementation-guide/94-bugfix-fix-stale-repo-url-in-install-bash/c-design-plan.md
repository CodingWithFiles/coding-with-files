# Fix stale repo URL in install.bash — Design
**Task**: 94 (bugfix)

## Task Reference
- **Task ID**: internal-94
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/94-fix-stale-repo-url-in-install-bash
- **Template Version**: 2.1

## Goal
Define the change needed to correct the stale GitHub org reference in `scripts/install.bash`.

## Key Decision
### Change scope
- **Decision**: Single-line string replacement in `scripts/install.bash:24`
- **Rationale**: The stale value is isolated to one `readonly` variable default. No logic change required.
- **Trade-offs**: None — atomic and reversible.

### URL format
- **Decision**: Keep HTTPS (`https://github.com/...`), not SSH
- **Rationale**: `install.bash` is run by end users who may not have SSH keys configured for GitHub. HTTPS works without credentials for public repos.

## Change
```
# Before
readonly CWF_SOURCE="${CWF_SOURCE:-https://github.com/mattkeenan/coding-with-files.git}"

# After
readonly CWF_SOURCE="${CWF_SOURCE:-https://github.com/CodingWithFiles/coding-with-files.git}"
```

## Audit Scope
Before closing, grep the full codebase for remaining `mattkeenan` references to catch any other stale strings (docs, README, other scripts).

## Constraints
- Do not change the variable name or surrounding logic
- URL must remain overridable via env var (`${CWF_SOURCE:-...}` pattern preserved)

## Decomposition Check
- [ ] **Time**: No
- [ ] **People**: No
- [ ] **Complexity**: No
- [ ] **Risk**: No
- [ ] **Independence**: No

No decomposition needed.

## Status
**Status**: Finished
**Next Action**: /cwf-implementation-plan 94
**Blockers**: None

## Actual Results
*To be filled upon completion*

## Lessons Learned
*To be captured during implementation*
