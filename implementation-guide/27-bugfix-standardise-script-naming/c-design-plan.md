# Standardise Script Naming - Design

## Task Reference
- **Task ID**: internal-27
- **Task URL**: N/A (internal task)
- **Parent Task**: N/A
- **Branch**: bugfix/27-standardise-script-naming
- **Template Version**: 2.0

## Goal
Design a safe, systematic approach to remove file extensions from helper scripts and update all active references throughout the repository.

## Design Priorities
Reversibility → Testability → Consistency → Simplicity → Readability

**Why this order**: Reversibility is critical for this refactoring - must be able to rollback quickly if issues found.

## Architecture Preferences
Explicit over implicit. Fail-fast validation. Incremental changes with validation checkpoints.

## Key Decisions
### Architecture Choice
- **Decision**: Phased execution with validation checkpoints
- **Rationale**:
  - Minimize risk by validating each phase before proceeding
  - Git commits after each phase enable quick rollback
  - Can abort mid-way if issues discovered
- **Trade-offs**:
  - **Benefit**: Low risk, clear rollback points, incremental validation
  - **Drawback**: Slightly more commits, requires discipline to test between phases

### Approach: Five-Phase Strategy
**Phase 1**: Environment configuration (PERL5OPT)
**Phase 2**: Script renaming (git mv preserves history)
**Phase 3**: Shebang updates
**Phase 4**: Reference updates (comprehensive search/replace)
**Phase 5**: Validation (tests + grep verification)

## System Design
### Component Overview

**Phase 1: Environment Configuration**
- Purpose: Configure PERL5OPT before scripts are renamed
- Scope: `.claude/settings.json`
- Validation: Test with `perl -V` to confirm flags applied

**Phase 2: Script Renaming**
- Purpose: Rename 6 scripts using `git mv` (preserves history)
- Scope:
  - 5 Perl scripts: `*.pl` → extensionless
  - 1 Shell script: `*.sh` → extensionless
- Validation: Verify renamed files exist, old names gone

**Phase 3: Shebang Updates**
- Purpose: Standardize to portable shebangs
- Scope: Update first line of each renamed script
  - Perl: `#!/usr/bin/env perl`
  - Shell: `#!/usr/bin/env bash`
- Validation: Execute scripts to verify shebangs work

**Phase 4: Reference Updates**
- Purpose: Update all active references repo-wide
- Scope: Commands, docs, BACKLOG, templates, workflow docs
- Exclusion: `implementation-guide/[0-9]*` (historic tasks)
- Validation: Grep for old extensions, verify no active hits

**Phase 5: Final Validation**
- Purpose: Comprehensive testing before completion
- Scope: Unicode tests, command execution, reference verification
- Validation: All success criteria met

### Execution Flow
```
1. Add PERL5OPT to .claude/settings.json
   ↓ [Commit: "Configure PERL5OPT"]
   ↓ [Test: perl -V confirms flags]

2. Rename scripts with git mv
   ↓ [Commit: "Rename helper scripts (remove extensions)"]
   ↓ [Test: Verify files exist]

3. Update shebangs
   ↓ [Commit: "Standardize shebangs to portable form"]
   ↓ [Test: Execute scripts]

4. Update all references
   ↓ [Commit: "Update all active script references"]
   ↓ [Test: Grep verification]

5. Final validation
   ↓ [Commit: "Add Task 27 to BACKLOG.md" (from Task 26)]
   ↓ [Test: Unicode + E2E command tests]
   ↓
   COMPLETE
```

## Interface Design

### Script Naming Convention (After Refactoring)
**Pattern**: Extensionless executables following Unix convention

**Scripts** (6 total):
```bash
.cig/scripts/command-helpers/
├── hierarchy-resolver       (was hierarchy-resolver.pl)
├── context-inheritance      (was context-inheritance.pl)
├── template-copier          (was template-copier.pl)
├── format-detector          (was format-detector.pl)
├── status-aggregator        (was status-aggregator.pl)
├── template-version-parser  (was template-version-parser.sh)
├── status-aggregator        (already correct)
├── status-aggregator-v2.0   (already correct)
└── status-aggregator-v2.1   (already correct)
```

**Shebangs** (standardized):
```perl
#!/usr/bin/env perl    # Finds perl in PATH, flags from PERL5OPT
```
```bash
#!/usr/bin/env bash    # Finds bash in PATH
```

### Reference Update Pattern
**Search pattern** (active files only):
```bash
# Find all references excluding historic tasks
grep -r "hierarchy-resolver\.pl" --exclude-dir=implementation-guide
grep -r "context-inheritance\.pl" --exclude-dir=implementation-guide
grep -r "template-copier\.pl" --exclude-dir=implementation-guide
grep -r "format-detector\.pl" --exclude-dir=implementation-guide
grep -r "status-aggregator\.pl" --exclude-dir=implementation-guide
grep -r "template-version-parser\.sh" --exclude-dir=implementation-guide
```

**Replace pattern**:
- `hierarchy-resolver.pl` → `hierarchy-resolver`
- `context-inheritance.pl` → `context-inheritance`
- `template-copier.pl` → `template-copier`
- `format-detector.pl` → `format-detector`
- `status-aggregator.pl` → `status-aggregator`
- `template-version-parser.sh` → `template-version-parser`

## Constraints

### Technical Constraints
- **Unix-only environment**: Requires Linux/macOS/WSL (not native Windows)
- **Git mv required**: Must use `git mv` to preserve file history, not plain `mv`
- **PERL5OPT support**: Claude Code must support `env` configuration in settings.json
- **Perl in PATH**: `#!/usr/bin/env perl` requires perl accessible via PATH

### Design Constraints
- **Historic tasks unchanged**: `implementation-guide/[0-9]*` directories must NOT be updated
- **Template extensions preserved**: `.template` files keep extensions (data files, not executables)
- **Incremental commits**: Each phase must be committed separately for rollback capability

### Testing Constraints
- **Manual validation required**: No automated test harness exists yet (BACKLOG task)
- **Command execution tests**: Must manually test representative commands after each phase

## Validation

### Design Checklist
- [x] Five-phase strategy defined with clear checkpoints
- [x] Git mv approach preserves file history
- [x] Reference update pattern excludes historic tasks
- [x] Rollback strategy documented (revert commits by phase)
- [x] Validation tests defined for each phase

### Rollback Plan
**If issues discovered**:
```bash
# Rollback Phase 5 (validation)
git revert HEAD

# Rollback Phase 4 (references)
git revert HEAD~1

# Rollback Phase 3 (shebangs)
git revert HEAD~2

# Rollback Phase 2 (rename)
git revert HEAD~3

# Rollback Phase 1 (PERL5OPT)
git revert HEAD~4
```

**Partial rollback supported**: Can rollback specific phases without affecting earlier phases.

## Status
**Status**: Finished
**Next Action**: Proceed to implementation planning → `/cig-implementation-plan 27`
**Blockers**: None

**See `.cig/docs/workflow/workflow-steps.md#status-values` for valid status values**

## Actual Results

### Design Approach Selected
**Five-phase incremental strategy** with validation checkpoints:
1. Environment configuration (PERL5OPT)
2. Script renaming (git mv)
3. Shebang updates
4. Reference updates (comprehensive, excluding historic)
5. Final validation

### Key Design Decisions

**Why phased approach?**
- Reversibility: Each phase can be individually rolled back
- Testability: Validate after each phase before proceeding
- Low risk: Can abort mid-way if issues discovered

**Why git mv?**
- Preserves file history (blame, log still work)
- Git tracks rename vs delete+create
- Standard practice for refactoring file names

**Why exclude historic tasks?**
- Represents historical record (not current documentation)
- Old references don't break anything (files already committed)
- Updating would pollute git history with noise

**Why PERL5OPT first?**
- Must configure environment before removing hardcoded `-CDSL` flags
- Test PERL5OPT works before committing to refactoring
- Fail-fast if environment doesn't support this approach

### Alternative Approaches Considered

**❌ Big-bang approach** (all changes in one commit):
- Rejected: Too risky, no rollback granularity, hard to debug if issues

**❌ Update references first, then rename**:
- Rejected: Creates broken interim state (references point to non-existent files)

**✅ Phased with checkpoints** (chosen):
- Low risk, clear rollback points, incremental validation

## Lessons Learned
*To be captured during retrospective*
